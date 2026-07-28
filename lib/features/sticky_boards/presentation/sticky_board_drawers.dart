import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/floatick_hover_motion.dart';
import '../../../l10n/l10n.dart';
import '../../todos/domain/todo_item.dart';
import '../../todos/presentation/todo_view_model.dart';
import '../domain/sticky_board.dart';
import 'sticky_board_palette.dart';
import 'sticky_board_view_model.dart';
import 'widgets/sticky_board_management_todo_row.dart';
import 'widgets/sticky_board_todo_details.dart';

const BorderRadius _selectionRowRadius = BorderRadius.all(Radius.circular(11));

class StickyBoardManagementDrawer extends StatefulWidget {
  const StickyBoardManagementDrawer({
    required this.controller,
    required this.todoController,
    required this.isOpen,
    required this.borderOnLeft,
    required this.onClose,
    required this.onOpenBoard,
    required this.onTogglePin,
    required this.onDeleteBoard,
    required this.closeFocusNode,
    super.key,
  });

  final StickyBoardViewModel controller;
  final TodoViewModel todoController;
  final bool isOpen;
  final bool borderOnLeft;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenBoard;
  final ValueChanged<String> onTogglePin;
  final ValueChanged<String> onDeleteBoard;
  final FocusNode closeFocusNode;

  @override
  State<StickyBoardManagementDrawer> createState() =>
      _StickyBoardManagementDrawerState();
}

class _StickyBoardManagementDrawerState
    extends State<StickyBoardManagementDrawer> {
  final _queryController = TextEditingController();
  final _queryFocusNode = FocusNode();

  String? _editingBoardId;
  String? _validationMessage;
  int _selectedColorValue = StickyBoardPalette.teal;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      _requestQueryFocus();
    }
  }

  @override
  void didUpdateWidget(covariant StickyBoardManagementDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isOpen && widget.isOpen) {
      _requestQueryFocus();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  void _requestQueryFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isOpen) {
        _queryFocusNode.requestFocus();
      }
    });
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    final name = _queryController.text.trim();
    if (name.isEmpty) {
      setState(
        () => _validationMessage = context.l10n.stickyBoardNameRequiredMessage,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _validationMessage = null;
    });
    final result = _editingBoardId == null
        ? await widget.controller.createBoard(
            name: name,
            colorValue: _selectedColorValue,
          )
        : await widget.controller.updateBoard(
            id: _editingBoardId!,
            name: name,
            colorValue: _selectedColorValue,
          );
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      if (result == StickyBoardMutationResult.success) {
        _editingBoardId = null;
        _queryController.clear();
        _selectedColorValue = StickyBoardPalette.teal;
      } else {
        _validationMessage = _messageForResult(result);
      }
    });
    if (result == StickyBoardMutationResult.success) {
      _queryFocusNode.requestFocus();
    }
  }

  void _beginEditing(StickyBoard board) {
    setState(() {
      _editingBoardId = board.id;
      _validationMessage = null;
      _selectedColorValue = board.colorValue;
      _queryController.text = board.name;
      _queryController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: board.name.length,
      );
    });
    _queryFocusNode.requestFocus();
  }

  void _cancelEditing() {
    setState(() {
      _editingBoardId = null;
      _validationMessage = null;
      _queryController.clear();
      _selectedColorValue = StickyBoardPalette.teal;
    });
    _queryFocusNode.requestFocus();
  }

  Future<void> _requestDeleteConfirmation(StickyBoard board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          key: ValueKey<String>('sticky-board-delete-confirmation-${board.id}'),
          title: Text(dialogContext.l10n.deleteStickyBoardTitle),
          content: Text(dialogContext.l10n.deleteStickyBoardMessage),
          actions: <Widget>[
            TextButton(
              key: ValueKey<String>('cancel-delete-sticky-board-${board.id}'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.cancelAction),
            ),
            TextButton(
              key: ValueKey<String>('confirm-delete-sticky-board-${board.id}'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(dialogContext.l10n.confirmAction),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }
    if (_editingBoardId == board.id) {
      setState(() {
        _editingBoardId = null;
        _queryController.clear();
        _selectedColorValue = StickyBoardPalette.teal;
      });
    }
    widget.onDeleteBoard(board.id);
  }

  String _messageForResult(StickyBoardMutationResult result) {
    return switch (result) {
      StickyBoardMutationResult.emptyName =>
        context.l10n.stickyBoardNameRequiredMessage,
      StickyBoardMutationResult.nameTooLong =>
        context.l10n.stickyBoardNameTooLongMessage(StickyBoard.maxNameLength),
      StickyBoardMutationResult.duplicateName =>
        context.l10n.duplicateStickyBoardNameMessage,
      StickyBoardMutationResult.notFound =>
        context.l10n.stickyBoardNotFoundMessage,
      StickyBoardMutationResult.invalidColor =>
        context.l10n.invalidTagColorMessage,
      StickyBoardMutationResult.storageFailure =>
        context.l10n.stickyBoardStorageFailureMessage,
      StickyBoardMutationResult.success => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _queryController.text.trim().toLowerCase();
    return _StickyBoardDrawerSurface(
      key: const Key('sticky-board-management-drawer'),
      borderOnLeft: widget.borderOnLeft,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final filteredBoards = widget.controller.boards
              .where(
                (board) =>
                    query.isEmpty || board.name.toLowerCase().contains(query),
              )
              .toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _DrawerHeader(
                title: context.l10n.stickyBoardsTitle,
                closeTooltip: context.l10n.closeStickyBoardsTooltip,
                onClose: widget.onClose,
                closeFocusNode: widget.closeFocusNode,
              ),
              const _DrawerDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      key: const Key('sticky-board-search-create-field'),
                      controller: _queryController,
                      focusNode: _queryFocusNode,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.done,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(
                          StickyBoard.maxNameLength,
                        ),
                      ],
                      onChanged: (_) {
                        setState(() => _validationMessage = null);
                      },
                      onSubmitted: (_) => unawaited(_submit()),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchOrCreateStickyBoardHint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (_editingBoardId != null)
                              IconButton(
                                tooltip: context.l10n.cancelEditTooltip,
                                onPressed: _isSaving ? null : _cancelEditing,
                                icon: const Icon(Icons.close_rounded, size: 16),
                              ),
                            IconButton(
                              key: const Key('submit-sticky-board'),
                              tooltip: context.l10n.createStickyBoardTooltip,
                              onPressed: _isSaving
                                  ? null
                                  : () => unawaited(_submit()),
                              icon: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                      ),
                                    )
                                  : Icon(
                                      _editingBoardId == null
                                          ? Icons.add_rounded
                                          : Icons.check_rounded,
                                      size: 18,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      key: const Key('sticky-board-color-palette'),
                      spacing: 9,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final colorValue in StickyBoardPalette.values)
                          _ColorButton(
                            colorValue: colorValue,
                            selected: _selectedColorValue == colorValue,
                            enabled: !_isSaving,
                            onPressed: () {
                              setState(() => _selectedColorValue = colorValue);
                            },
                          ),
                      ],
                    ),
                    if (_validationMessage != null) ...[
                      const SizedBox(height: 9),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _validationMessage!,
                          key: const Key('sticky-board-validation-message'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const _DrawerDivider(),
              Expanded(
                child: _buildBoardList(
                  context: context,
                  boards: filteredBoards,
                  hasQuery: query.isNotEmpty,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        context.l10n.stickyBoardDeleteKeepsTodosHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoardList({
    required BuildContext context,
    required List<StickyBoard> boards,
    required bool hasQuery,
  }) {
    if (boards.isEmpty) {
      return _EmptyBoards(hasQuery: hasQuery);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 360 ? 2 : 1;
        return GridView.builder(
          key: const Key('sticky-board-thumbnail-grid'),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 150,
          ),
          itemCount: boards.length,
          itemBuilder: (context, index) {
            final board = boards[index];
            final previewItems = widget.controller
                .todoIdsForBoard(board.id)
                .map(widget.todoController.itemById)
                .whereType<TodoItem>()
                .take(2)
                .toList(growable: false);
            return _ManagedBoardCard(
              key: ValueKey<String>('sticky-board-${board.id}'),
              board: board,
              previewItems: previewItems,
              todoCount: widget.controller.todoCountForBoard(board.id),
              isEditing: _editingBoardId == board.id,
              onOpen: () => widget.onOpenBoard(board.id),
              onEdit: () => _beginEditing(board),
              onTogglePin: () => widget.onTogglePin(board.id),
              onDelete: () => unawaited(_requestDeleteConfirmation(board)),
            );
          },
        );
      },
    );
  }
}

class StickyBoardDetailDrawer extends StatefulWidget {
  const StickyBoardDetailDrawer({
    required this.board,
    required this.todoController,
    required this.boardController,
    required this.borderOnLeft,
    required this.onBack,
    required this.onClose,
    required this.onTogglePin,
    required this.onAddExisting,
    required this.onCreateTodo,
    required this.closeFocusNode,
    super.key,
  });

  final StickyBoard board;
  final TodoViewModel todoController;
  final StickyBoardViewModel boardController;
  final bool borderOnLeft;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onTogglePin;
  final VoidCallback onAddExisting;
  final VoidCallback onCreateTodo;
  final FocusNode closeFocusNode;

  @override
  State<StickyBoardDetailDrawer> createState() =>
      _StickyBoardDetailDrawerState();
}

class _StickyBoardDetailDrawerState extends State<StickyBoardDetailDrawer> {
  String? _detailsTodoId;

  void _openDetails(String todoId) {
    setState(() => _detailsTodoId = todoId);
  }

  void _closeDetails() {
    setState(() => _detailsTodoId = null);
  }

  @override
  Widget build(BuildContext context) {
    final boardTodoIds = widget.boardController.todoIdsForBoard(
      widget.board.id,
    );
    final items = boardTodoIds
        .map(widget.todoController.itemById)
        .whereType<TodoItem>()
        .where((item) => !item.isArchived)
        .toList(growable: false);
    final detailsCandidate = _detailsTodoId == null
        ? null
        : widget.todoController.itemById(_detailsTodoId!);
    final detailsItem =
        detailsCandidate != null &&
            !detailsCandidate.isArchived &&
            boardTodoIds.contains(detailsCandidate.id)
        ? detailsCandidate
        : null;

    return _StickyBoardDrawerSurface(
      key: const Key('sticky-board-detail-drawer'),
      borderOnLeft: widget.borderOnLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 10, 9, 10),
            child: Row(
              children: <Widget>[
                IconButton(
                  key: const Key('sticky-board-back'),
                  tooltip: context.l10n.backToStickyBoardsTooltip,
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(widget.board.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.board.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.l10n.stickyBoardTodoCount(items.length),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ),
                FloatickHoverMotion(
                  hoverScale: FloatickMotion.emphasisHoverScale,
                  pressedScale: FloatickMotion.emphasisPressedScale,
                  hoverTurns: FloatickMotion.emphasisHoverTurns,
                  child: IconButton(
                    key: const Key('sticky-board-pin'),
                    tooltip: widget.board.isPinned
                        ? context.l10n.unpinStickyBoardTooltip
                        : context.l10n.pinStickyBoardTooltip,
                    onPressed: widget.onTogglePin,
                    style: const ButtonStyle(
                      foregroundBuilder:
                          FloatickMotion.passthroughForegroundBuilder,
                    ),
                    icon: Icon(
                      widget.board.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 18,
                      color: widget.board.isPinned
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  focusNode: widget.closeFocusNode,
                  tooltip: context.l10n.closeStickyBoardsTooltip,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
          const _DrawerDivider(),
          Expanded(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: detailsItem == null
                  ? _buildBoardMembers(items)
                  : StickyBoardTodoDetails(
                      key: ValueKey<String>(
                        'sticky-board-managed-details-${detailsItem.id}',
                      ),
                      item: detailsItem,
                      tags: widget.todoController.tags
                          .where(
                            (tag) => widget.todoController
                                .tagIdsForTodo(detailsItem.id)
                                .contains(tag.id),
                          )
                          .toList(growable: false),
                      onBack: _closeDetails,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardMembers(List<TodoItem> items) {
    return Column(
      key: ValueKey<String>('sticky-board-members-${widget.board.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('sticky-board-add-existing'),
                  onPressed: widget.onAddExisting,
                  icon: const Icon(Icons.playlist_add_rounded, size: 17),
                  label: Text(context.l10n.addExistingTodoAction),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('sticky-board-new-todo'),
                  onPressed: widget.onCreateTodo,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: Text(context.l10n.newTodoInStickyBoardAction),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyBoardTodos(onCreateTodo: widget.onCreateTodo)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return StickyBoardManagementTodoRow(
                      key: ValueKey<String>('sticky-board-todo-${item.id}'),
                      item: item,
                      tags: widget.todoController.tags,
                      assignedTagIds: widget.todoController.tagIdsForTodo(
                        item.id,
                      ),
                      onOpenDetails: () => _openDetails(item.id),
                      onRemove: () => unawaited(
                        widget.boardController.removeTodo(
                          boardId: widget.board.id,
                          todoId: item.id,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class StickyBoardTodoPickerDrawer extends StatefulWidget {
  const StickyBoardTodoPickerDrawer({
    required this.board,
    required this.todoController,
    required this.boardController,
    required this.borderOnLeft,
    required this.onBack,
    required this.onClose,
    required this.closeFocusNode,
    super.key,
  });

  final StickyBoard board;
  final TodoViewModel todoController;
  final StickyBoardViewModel boardController;
  final bool borderOnLeft;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;

  @override
  State<StickyBoardTodoPickerDrawer> createState() =>
      _StickyBoardTodoPickerDrawerState();
}

class _StickyBoardTodoPickerDrawerState
    extends State<StickyBoardTodoPickerDrawer> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.todoController.itemsForView(
      archived: false,
      query: _searchController.text,
    );
    return _StickyBoardDrawerSurface(
      key: const Key('sticky-board-todo-picker-drawer'),
      borderOnLeft: widget.borderOnLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 10, 9, 10),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: context.l10n.backToStickyBoardsTooltip,
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                ),
                Expanded(
                  child: Text(
                    context.l10n.addExistingTodoTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  focusNode: widget.closeFocusNode,
                  tooltip: context.l10n.closeStickyBoardsTooltip,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
          const _DrawerDivider(),
          Padding(
            padding: const EdgeInsets.all(13),
            child: TextField(
              key: const Key('sticky-board-todo-search'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.l10n.searchTodosToAddHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.noTodosAvailableForBoardMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.46),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = widget.boardController.containsTodo(
                        boardId: widget.board.id,
                        todoId: item.id,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          type: MaterialType.transparency,
                          shape: const RoundedRectangleBorder(
                            borderRadius: _selectionRowRadius,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CheckboxListTile(
                            key: ValueKey<String>(
                              'sticky-board-picker-${item.id}',
                            ),
                            value: selected,
                            onChanged: (value) {
                              unawaited(
                                widget.boardController.setTodoMembership(
                                  boardId: widget.board.id,
                                  todoId: item.id,
                                  selected: value ?? false,
                                ),
                              );
                            },
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: _selectionRowRadius,
                            ),
                            hoverColor: theme.colorScheme.onSurface.withValues(
                              alpha: 0.045,
                            ),
                            title: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StickyBoardDrawerSurface extends StatelessWidget {
  const _StickyBoardDrawerSurface({
    required this.borderOnLeft,
    required this.child,
    super.key,
  });

  final bool borderOnLeft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderSide = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.07),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202A2E) : const Color(0xFFF9FBFA),
        border: Border(
          left: borderOnLeft ? borderSide : BorderSide.none,
          right: borderOnLeft ? BorderSide.none : borderSide,
        ),
      ),
      child: child,
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.title,
    required this.closeTooltip,
    required this.onClose,
    required this.closeFocusNode,
  });

  final String title;
  final String closeTooltip;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 10, 9, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            focusNode: closeFocusNode,
            tooltip: closeTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.colorValue,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final int colorValue;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = StickyBoardPalette.color(colorValue);
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.tagColorSemanticsLabel,
      child: FloatickHoverMotion(
        enabled: enabled,
        hoverScale: FloatickMotion.swatchHoverScale,
        pressedScale: FloatickMotion.swatchPressedScale,
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _ManagedBoardCard extends StatefulWidget {
  const _ManagedBoardCard({
    required this.board,
    required this.previewItems,
    required this.todoCount,
    required this.isEditing,
    required this.onOpen,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
    super.key,
  });

  final StickyBoard board;
  final List<TodoItem> previewItems;
  final int todoCount;
  final bool isEditing;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  @override
  State<_ManagedBoardCard> createState() => _ManagedBoardCardState();
}

class _ManagedBoardCardState extends State<_ManagedBoardCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boardColor = Color(widget.board.colorValue);
    final showActions = _hovered || widget.isEditing;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final cardBackground = StickyBoardPalette.surfaceColor(
      value: widget.board.colorValue,
      baseColor: theme.colorScheme.surfaceContainerHighest,
      brightness: theme.brightness,
      hovered: _hovered,
    );
    return Semantics(
      button: true,
      label: widget.board.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          key: ValueKey<String>('sticky-board-thumbnail-${widget.board.id}'),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isEditing
                  ? theme.colorScheme.primary
                  : _hovered
                  ? boardColor.withValues(alpha: 0.58)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.10),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(11, 7, 5, 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.board.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FloatickHoverMotion(
                          hoverScale: FloatickMotion.emphasisHoverScale,
                          pressedScale: FloatickMotion.emphasisPressedScale,
                          hoverTurns: FloatickMotion.emphasisHoverTurns,
                          child: IconButton(
                            key: ValueKey<String>(
                              'toggle-sticky-board-pin-${widget.board.id}',
                            ),
                            tooltip: widget.board.isPinned
                                ? context.l10n.unpinStickyBoardTooltip
                                : context.l10n.pinStickyBoardTooltip,
                            onPressed: widget.onTogglePin,
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 30,
                            ),
                            padding: const EdgeInsets.all(6),
                            style: const ButtonStyle(
                              foregroundBuilder:
                                  FloatickMotion.passthroughForegroundBuilder,
                            ),
                            icon: Icon(
                              widget.board.isPinned
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              size: 15,
                              color: widget.board.isPinned
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                      child: widget.previewItems.isEmpty
                          ? const _EmptyBoardPreview()
                          : Column(
                              children: <Widget>[
                                for (final item in widget.previewItems)
                                  _BoardPreviewTodoLine(item: item),
                              ],
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.view_agenda_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.38,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.l10n.stickyBoardTodoCount(widget.todoCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.46,
                            ),
                          ),
                        ),
                        const Spacer(),
                        AnimatedOpacity(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 140),
                          opacity: showActions ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !showActions,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip:
                                      context.l10n.renameStickyBoardTooltip,
                                  onPressed: widget.onEdit,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 28,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey<String>(
                                    'delete-sticky-board-${widget.board.id}',
                                  ),
                                  tooltip:
                                      context.l10n.deleteStickyBoardTooltip,
                                  onPressed: widget.onDelete,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 28,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPreviewTodoLine extends StatelessWidget {
  const _BoardPreviewTodoLine({required this.item});

  final TodoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.42);
    return SizedBox(
      height: 24,
      child: Row(
        children: <Widget>[
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? theme.colorScheme.primary.withValues(alpha: 0.78)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: item.isCompleted
                    ? theme.colorScheme.primary
                    : mutedColor,
                width: 1.2,
              ),
            ),
            child: item.isCompleted
                ? Icon(
                    Icons.check_rounded,
                    size: 8,
                    color: theme.colorScheme.onPrimary,
                  )
                : null,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: item.isCompleted ? 0.40 : 0.66,
                ),
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBoardPreview extends StatelessWidget {
  const _EmptyBoardPreview();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.12);
    return Column(
      children: <Widget>[
        for (final widthFactor in <double>[0.86, 0.64])
          SizedBox(
            height: 24,
            child: Row(
              children: <Widget>[
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: color, width: 1.2),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyBoards extends StatelessWidget {
  const _EmptyBoards({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.sticky_note_2_outlined,
              size: 30,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 11),
            Text(
              hasQuery
                  ? context.l10n.noMatchingStickyBoardsMessage
                  : context.l10n.emptyStickyBoardsTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 5),
              Text(
                context.l10n.emptyStickyBoardsMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyBoardTodos extends StatelessWidget {
  const _EmptyBoardTodos({required this.onCreateTodo});

  final VoidCallback onCreateTodo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onCreateTodo,
        icon: const Icon(Icons.add_rounded, size: 17),
        label: Text(context.l10n.newTodoInStickyBoardAction),
      ),
    );
  }
}
