import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

import '../../../l10n/l10n.dart';
import '../../todos/domain/todo_item.dart';
import '../../todos/presentation/tag_filter_drawer.dart';
import '../../todos/presentation/todo_editor_drawer.dart';
import '../../todos/presentation/todo_view_model.dart';
import '../../todos/presentation/widgets/todo_list_row.dart';
import '../domain/sticky_board.dart';
import 'sticky_board_view_model.dart';
import 'sticky_board_window_coordinator.dart';

enum _PinnedDrawerMode { none, create, details, edit, tagAssignment }

class PinnedStickyBoardWindow extends StatefulWidget {
  const PinnedStickyBoardWindow({
    required this.boardId,
    required this.viewId,
    required this.boardController,
    required this.todoController,
    required this.coordinator,
    super.key,
  });

  final String boardId;
  final int viewId;
  final StickyBoardViewModel boardController;
  final TodoViewModel todoController;
  final StickyBoardWindowCoordinator coordinator;

  @override
  State<PinnedStickyBoardWindow> createState() =>
      _PinnedStickyBoardWindowState();
}

class _PinnedStickyBoardWindowState extends State<PinnedStickyBoardWindow>
    with WindowListener {
  final _todoDrawerCloseFocusNode = FocusNode();
  final _tagDrawerCloseFocusNode = FocusNode();

  _PinnedDrawerMode _drawerMode = _PinnedDrawerMode.none;
  _PinnedDrawerMode _todoDrawerMode = _PinnedDrawerMode.create;
  String? _selectedTodoId;
  Set<String> _todoEditorTagIds = <String>{};
  int _editorSession = 0;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    widget.boardController.addListener(_handleModelChanged);
    widget.todoController.addListener(_handleModelChanged);
    widget.coordinator.registerWindow(
      boardId: widget.boardId,
      viewId: widget.viewId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(MultiViewDesktop.of(context).setPreventClose(true));
    });
  }

  @override
  void dispose() {
    widget.boardController.removeListener(_handleModelChanged);
    widget.todoController.removeListener(_handleModelChanged);
    _todoDrawerCloseFocusNode.dispose();
    _tagDrawerCloseFocusNode.dispose();
    widget.coordinator.forgetWindow(widget.boardId);
    super.dispose();
  }

  void _handleModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void onWindowClose() {
    if (!_isClosing) {
      unawaited(widget.coordinator.unpin(widget.boardId));
    }
  }

  @override
  void onWindowMoved() {
    unawaited(_persistBounds());
  }

  @override
  void onWindowResized() {
    unawaited(_persistBounds());
  }

  Future<void> _persistBounds() async {
    if (!mounted || _isClosing) {
      return;
    }
    final bounds = await MultiViewDesktop.of(context).getBounds();
    await widget.coordinator.saveWindowFrame(
      boardId: widget.boardId,
      bounds: bounds,
    );
  }

  Future<void> _unpin() async {
    if (_isClosing) {
      return;
    }
    _isClosing = true;
    await widget.coordinator.unpin(widget.boardId);
  }

  void _openCreate() {
    setState(() {
      _editorSession += 1;
      _selectedTodoId = null;
      _todoEditorTagIds = <String>{};
      _todoDrawerMode = _PinnedDrawerMode.create;
      _drawerMode = _PinnedDrawerMode.create;
    });
  }

  void _openDetails(String todoId) {
    setState(() {
      _selectedTodoId = todoId;
      _todoEditorTagIds = widget.todoController.tagIdsForTodo(todoId).toSet();
      _todoDrawerMode = _PinnedDrawerMode.details;
      _drawerMode = _PinnedDrawerMode.details;
    });
  }

  void _openEdit(String todoId) {
    setState(() {
      _selectedTodoId = todoId;
      _todoEditorTagIds = widget.todoController.tagIdsForTodo(todoId).toSet();
      _todoDrawerMode = _PinnedDrawerMode.edit;
      _drawerMode = _PinnedDrawerMode.edit;
    });
  }

  void _openTagAssignment() {
    if (_drawerMode == _PinnedDrawerMode.create ||
        _drawerMode == _PinnedDrawerMode.edit) {
      setState(() => _drawerMode = _PinnedDrawerMode.tagAssignment);
    }
  }

  void _closeDrawer() {
    setState(() {
      if (_drawerMode == _PinnedDrawerMode.tagAssignment) {
        _drawerMode = _todoDrawerMode;
      } else {
        _drawerMode = _PinnedDrawerMode.none;
      }
    });
  }

  void _toggleEditorTag(String tagId) {
    setState(() {
      if (!_todoEditorTagIds.add(tagId)) {
        _todoEditorTagIds.remove(tagId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.boardController.boardById(widget.boardId);
    if (board == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_unpin());
        }
      });
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTodoDrawerOpen =
        _drawerMode == _PinnedDrawerMode.create ||
        _drawerMode == _PinnedDrawerMode.details ||
        _drawerMode == _PinnedDrawerMode.edit;
    final isTagAssignmentOpen = _drawerMode == _PinnedDrawerMode.tagAssignment;
    final selectedTodo = _selectedTodoId == null
        ? null
        : widget.todoController.itemById(_selectedTodoId!);
    final editorMode = switch (_todoDrawerMode) {
      _PinnedDrawerMode.details => TodoEditorDrawerMode.details,
      _PinnedDrawerMode.edit => TodoEditorDrawerMode.edit,
      _ => TodoEditorDrawerMode.create,
    };

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF7182226) : const Color(0xFAFAFCFB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.90),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    _PinnedHeader(
                      board: board,
                      onUnpin: () => unawaited(_unpin()),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                    Expanded(child: _buildTodoList(board)),
                    _PinnedFooter(
                      onAddTodo: _openCreate,
                      onOpenMain: () =>
                          widget.coordinator.requestMainWindow(board.id),
                    ),
                  ],
                ),
                if (_drawerMode != _PinnedDrawerMode.none)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeDrawer,
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.22 : 0.12,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isTodoDrawerOpen,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      offset: isTodoDrawerOpen
                          ? Offset.zero
                          : const Offset(0, 1),
                      child: TodoEditorDrawer(
                        key: ValueKey<int>(_editorSession),
                        mode: editorMode,
                        item: selectedTodo,
                        availableTags: widget.todoController.tags,
                        originalAssignedTagIds: selectedTodo == null
                            ? const <String>[]
                            : widget.todoController.tagIdsForTodo(
                                selectedTodo.id,
                              ),
                        assignedTagIds: widget.todoController.tags
                            .where((tag) => _todoEditorTagIds.contains(tag.id))
                            .map((tag) => tag.id)
                            .toList(growable: false),
                        isOpen: isTodoDrawerOpen,
                        onClose: _closeDrawer,
                        onEdit: () {
                          if (selectedTodo != null) {
                            _openEdit(selectedTodo.id);
                          }
                        },
                        onOpenTagAssignment: _openTagAssignment,
                        onSave: (title, content, tagIds) async {
                          if (editorMode == TodoEditorDrawerMode.create) {
                            final item = await widget.todoController.create(
                              title,
                              content: content,
                              tagIds: tagIds,
                            );
                            if (item == null) {
                              return false;
                            }
                            return widget.boardController.addTodo(
                              boardId: board.id,
                              todoId: item.id,
                            );
                          }
                          if (selectedTodo == null) {
                            return false;
                          }
                          return widget.todoController.updateDetails(
                            id: selectedTodo.id,
                            title: title,
                            content: content,
                            tagIds: tagIds,
                          );
                        },
                        onSaved: () {
                          if (editorMode == TodoEditorDrawerMode.edit &&
                              selectedTodo != null) {
                            _openDetails(selectedTodo.id);
                          } else {
                            _closeDrawer();
                          }
                        },
                        closeFocusNode: _todoDrawerCloseFocusNode,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: 292,
                  child: IgnorePointer(
                    ignoring: !isTagAssignmentOpen,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      offset: isTagAssignmentOpen
                          ? Offset.zero
                          : const Offset(1, 0),
                      child: TagFilterDrawer.assignment(
                        controller: widget.todoController,
                        selectedTagIds: _todoEditorTagIds,
                        borderOnLeft: true,
                        onToggled: _toggleEditorTag,
                        onManageTags: () {
                          widget.coordinator.requestMainWindow(board.id);
                        },
                        onClose: _closeDrawer,
                        closeFocusNode: _tagDrawerCloseFocusNode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList(StickyBoard board) {
    final items = widget.boardController
        .todoIdsForBoard(board.id)
        .map(widget.todoController.itemById)
        .whereType<TodoItem>()
        .where((item) => !item.isArchived)
        .toList(growable: false);
    if (items.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: _openCreate,
          icon: const Icon(Icons.add_rounded, size: 17),
          label: Text(context.l10n.newTodoInStickyBoardAction),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TodoListRow(
          key: ValueKey<String>('pinned-sticky-board-todo-${item.id}'),
          item: item,
          archivedScope: false,
          onToggle: () =>
              unawaited(widget.todoController.toggleCompletion(item.id)),
          onOpenDetails: () => _openDetails(item.id),
          onEdit: () => _openEdit(item.id),
          onArchive: () => unawaited(widget.todoController.archive(item.id)),
          onRestore: () => unawaited(widget.todoController.restore(item.id)),
          tags: widget.todoController.tags,
          assignedTagIds: widget.todoController.tagIdsForTodo(item.id),
          onToggleTag: (tagId) => widget.todoController.toggleTagForTodo(
            todoId: item.id,
            tagId: tagId,
          ),
          onOpenTagManagement: () {
            widget.coordinator.requestMainWindow(board.id);
          },
          onRemoveFromStickyBoard: () => unawaited(
            widget.boardController.removeTodo(
              boardId: board.id,
              todoId: item.id,
            ),
          ),
          compact: true,
        );
      },
    );
  }
}

class _PinnedHeader extends StatelessWidget {
  const _PinnedHeader({required this.board, required this.onUnpin});

  final StickyBoard board;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
        child: Row(
          children: <Widget>[
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
              child: Text(
                board.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              key: const Key('pinned-sticky-board-unpin'),
              tooltip: context.l10n.unpinStickyBoardTooltip,
              onPressed: onUnpin,
              icon: Icon(
                Icons.push_pin_rounded,
                size: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedFooter extends StatelessWidget {
  const _PinnedFooter({required this.onAddTodo, required this.onOpenMain});

  final VoidCallback onAddTodo;
  final VoidCallback onOpenMain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 11),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.tonalIcon(
              key: const Key('pinned-sticky-board-add-todo'),
              onPressed: onAddTodo,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: Text(context.l10n.newTodoInStickyBoardAction),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: context.l10n.openMainListTooltip,
            onPressed: onOpenMain,
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}
