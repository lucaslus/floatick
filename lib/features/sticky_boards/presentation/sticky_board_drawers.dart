import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../todos/domain/todo_item.dart';
import '../../todos/presentation/todo_view_model.dart';
import '../../todos/presentation/widgets/todo_list_row.dart';
import '../domain/sticky_board.dart';
import 'sticky_board_palette.dart';
import 'sticky_board_view_model.dart';

class StickyBoardManagementDrawer extends StatefulWidget {
  const StickyBoardManagementDrawer({
    required this.controller,
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
  String? _pendingDeleteBoardId;
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
        _pendingDeleteBoardId = null;
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
      _pendingDeleteBoardId = null;
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
                        setState(() {
                          _validationMessage = null;
                          _pendingDeleteBoardId = null;
                        });
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      itemCount: boards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 3),
      itemBuilder: (context, index) {
        final board = boards[index];
        if (_pendingDeleteBoardId == board.id) {
          return _DeleteConfirmation(
            board: board,
            onKeep: () => setState(() => _pendingDeleteBoardId = null),
            onDelete: () {
              setState(() => _pendingDeleteBoardId = null);
              widget.onDeleteBoard(board.id);
            },
          );
        }
        return _ManagedBoardRow(
          key: ValueKey<String>('sticky-board-${board.id}'),
          board: board,
          todoCount: widget.controller.todoCountForBoard(board.id),
          isEditing: _editingBoardId == board.id,
          onOpen: () => widget.onOpenBoard(board.id),
          onEdit: () => _beginEditing(board),
          onTogglePin: () => widget.onTogglePin(board.id),
          onDelete: () {
            setState(() => _pendingDeleteBoardId = board.id);
          },
        );
      },
    );
  }
}

class StickyBoardDetailDrawer extends StatelessWidget {
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
    required this.onOpenDetails,
    required this.onEditTodo,
    required this.onOpenTagManagement,
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
  final ValueChanged<String> onOpenDetails;
  final ValueChanged<String> onEditTodo;
  final VoidCallback onOpenTagManagement;
  final FocusNode closeFocusNode;

  @override
  Widget build(BuildContext context) {
    final boardTodoIds = boardController.todoIdsForBoard(board.id);
    final items = boardTodoIds
        .map(todoController.itemById)
        .whereType<TodoItem>()
        .where((item) => !item.isArchived)
        .toList(growable: false);
    return _StickyBoardDrawerSurface(
      key: const Key('sticky-board-detail-drawer'),
      borderOnLeft: borderOnLeft,
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
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(board.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        board.name,
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
                IconButton(
                  key: const Key('sticky-board-pin'),
                  tooltip: board.isPinned
                      ? context.l10n.unpinStickyBoardTooltip
                      : context.l10n.pinStickyBoardTooltip,
                  onPressed: onTogglePin,
                  icon: Icon(
                    board.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 18,
                    color: board.isPinned
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                IconButton(
                  focusNode: closeFocusNode,
                  tooltip: context.l10n.closeStickyBoardsTooltip,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
          const _DrawerDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('sticky-board-add-existing'),
                    onPressed: onAddExisting,
                    icon: const Icon(Icons.playlist_add_rounded, size: 17),
                    label: Text(context.l10n.addExistingTodoAction),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: const Key('sticky-board-new-todo'),
                    onPressed: onCreateTodo,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(context.l10n.newTodoInStickyBoardAction),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _EmptyBoardTodos(onCreateTodo: onCreateTodo)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return TodoListRow(
                        key: ValueKey<String>('sticky-board-todo-${item.id}'),
                        item: item,
                        archivedScope: false,
                        onToggle: () =>
                            unawaited(todoController.toggleCompletion(item.id)),
                        onOpenDetails: () => onOpenDetails(item.id),
                        onEdit: () => onEditTodo(item.id),
                        onArchive: () =>
                            unawaited(todoController.archive(item.id)),
                        onRestore: () =>
                            unawaited(todoController.restore(item.id)),
                        tags: todoController.tags,
                        assignedTagIds: todoController.tagIdsForTodo(item.id),
                        onToggleTag: (tagId) => todoController.toggleTagForTodo(
                          todoId: item.id,
                          tagId: tagId,
                        ),
                        onOpenTagManagement: onOpenTagManagement,
                        onRemoveFromStickyBoard: () => unawaited(
                          boardController.removeTodo(
                            boardId: board.id,
                            todoId: item.id,
                          ),
                        ),
                        compact: true,
                      );
                    },
                  ),
          ),
        ],
      ),
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
    final query = _searchController.text.trim().toLowerCase();
    final items = widget.todoController.items
        .where(
          (item) =>
              !item.isArchived &&
              (query.isEmpty ||
                  item.title.toLowerCase().contains(query) ||
                  item.content.toLowerCase().contains(query)),
        )
        .toList(growable: false);
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
                      return Material(
                        type: MaterialType.transparency,
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
                          title: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}

class _ManagedBoardRow extends StatefulWidget {
  const _ManagedBoardRow({
    required this.board,
    required this.todoCount,
    required this.isEditing,
    required this.onOpen,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
    super.key,
  });

  final StickyBoard board;
  final int todoCount;
  final bool isEditing;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  @override
  State<_ManagedBoardRow> createState() => _ManagedBoardRowState();
}

class _ManagedBoardRowState extends State<_ManagedBoardRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showActions = _hovered || widget.isEditing;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onOpen,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 5, 8),
          decoration: BoxDecoration(
            color: _hovered || widget.isEditing
                ? theme.colorScheme.onSurface.withValues(alpha: 0.045)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Color(widget.board.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.board.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.l10n.stickyBoardTodoCount(widget.todoCount),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.42,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.board.isPinned)
                Tooltip(
                  message: context.l10n.stickyBoardPinnedLabel,
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              AnimatedOpacity(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 140),
                opacity: showActions ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showActions,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: context.l10n.renameStickyBoardTooltip,
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                      ),
                      IconButton(
                        tooltip: widget.board.isPinned
                            ? context.l10n.unpinStickyBoardTooltip
                            : context.l10n.pinStickyBoardTooltip,
                        onPressed: widget.onTogglePin,
                        icon: Icon(
                          widget.board.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          size: 16,
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.deleteStickyBoardTooltip,
                        onPressed: widget.onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmation extends StatelessWidget {
  const _DeleteConfirmation({
    required this.board,
    required this.onKeep,
    required this.onDelete,
  });

  final StickyBoard board;
  final VoidCallback onKeep;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.deleteStickyBoardTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.deleteStickyBoardMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: onKeep,
                child: Text(context.l10n.keepStickyBoardAction),
              ),
              const SizedBox(width: 5),
              FilledButton(
                onPressed: onDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: Text(context.l10n.confirmDeleteStickyBoardAction),
              ),
            ],
          ),
        ],
      ),
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
