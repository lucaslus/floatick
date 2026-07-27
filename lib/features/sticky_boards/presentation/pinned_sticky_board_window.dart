import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

import '../../../app/theme/floatick_theme.dart';
import '../../../l10n/l10n.dart';
import '../../todos/domain/todo_item.dart';
import '../../todos/presentation/todo_view_model.dart';
import '../../todos/presentation/widgets/todo_list_row.dart';
import '../domain/sticky_board.dart';
import 'sticky_board_frame_save_scheduler.dart';
import 'sticky_board_view_model.dart';
import 'sticky_board_window_coordinator.dart';
import 'widgets/sticky_board_todo_details.dart';

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
  final StickyBoardFrameSaveScheduler _frameSaveScheduler =
      StickyBoardFrameSaveScheduler();
  bool _isUnpinning = false;
  String? _detailsTodoId;

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
    _frameSaveScheduler.cancel();
    widget.boardController.removeListener(_handleModelChanged);
    widget.todoController.removeListener(_handleModelChanged);
    widget.coordinator.forgetWindow(
      boardId: widget.boardId,
      viewId: widget.viewId,
    );
    super.dispose();
  }

  void _handleModelChanged() {
    if (!mounted) {
      return;
    }
    final detailsTodoId = _detailsTodoId;
    if (detailsTodoId != null) {
      final item = widget.todoController.itemById(detailsTodoId);
      final belongsToBoard = widget.boardController
          .todoIdsForBoard(widget.boardId)
          .contains(detailsTodoId);
      if (item == null || item.isArchived || !belongsToBoard) {
        _detailsTodoId = null;
      }
    }
    setState(() {});
  }

  @override
  void onWindowClose() {
    if (!_isUnpinning) {
      _frameSaveScheduler.cancel();
      unawaited(_persistBoundsAndUnpin());
    }
  }

  @override
  void onWindowMoved() {
    _scheduleBoundsSave();
  }

  @override
  void onWindowResized() {
    _scheduleBoundsSave();
  }

  void _scheduleBoundsSave() {
    _frameSaveScheduler.schedule(() => unawaited(_persistBounds()));
  }

  Future<void> _persistBounds({bool allowClosing = false}) async {
    if (!mounted || (_isUnpinning && !allowClosing)) {
      return;
    }
    try {
      final bounds = await MultiViewDesktop.of(context).getBounds();
      await widget.coordinator.saveWindowFrame(
        boardId: widget.boardId,
        bounds: bounds,
      );
    } on Object catch (error, stackTrace) {
      debugPrint(
        'Floatick could not save sticky board ${widget.boardId} bounds: '
        '$error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _unpin() async {
    if (_isUnpinning) {
      return;
    }
    _frameSaveScheduler.cancel();
    _isUnpinning = true;
    try {
      await widget.coordinator.unpin(widget.boardId);
    } finally {
      _isUnpinning = false;
    }
  }

  Future<void> _persistBoundsAndUnpin() async {
    if (_isUnpinning) {
      return;
    }
    _isUnpinning = true;
    try {
      await _persistBounds(allowClosing: true);
      await widget.coordinator.unpin(widget.boardId);
    } finally {
      _isUnpinning = false;
    }
  }

  void _openMain({
    required StickyBoardMainWindowDestination destination,
    String? todoId,
  }) {
    widget.coordinator.requestMainWindow(
      StickyBoardMainWindowRequest(
        boardId: widget.boardId,
        destination: destination,
        todoId: todoId,
      ),
    );
  }

  void _showTodoDetails(String todoId) {
    setState(() => _detailsTodoId = todoId);
  }

  void _closeTodoDetails() {
    setState(() => _detailsTodoId = null);
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

    final detailsItem = _detailsTodoId == null
        ? null
        : widget.todoController.itemById(_detailsTodoId!);

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? FloatickColors.darkGlassSurface
              : FloatickColors.lightGlassSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.90),
          ),
        ),
        child: Column(
          children: <Widget>[
            _PinnedHeader(board: board, onUnpin: () => unawaited(_unpin())),
            Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: detailsItem == null
                    ? _buildTodoList(board)
                    : StickyBoardTodoDetails(
                        key: ValueKey<String>(
                          'sticky-board-details-${detailsItem.id}',
                        ),
                        item: detailsItem,
                        tags: widget.todoController.tags
                            .where(
                              (tag) => widget.todoController
                                  .tagIdsForTodo(detailsItem.id)
                                  .contains(tag.id),
                            )
                            .toList(growable: false),
                        onBack: _closeTodoDetails,
                        onEdit: () => _openMain(
                          destination:
                              StickyBoardMainWindowDestination.todoEdit,
                          todoId: detailsItem.id,
                        ),
                      ),
              ),
            ),
          ],
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            key: const Key('pinned-sticky-board-empty'),
            context.l10n.emptyPinnedStickyBoardMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.52),
            ),
          ),
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
          onOpenDetails: () => _showTodoDetails(item.id),
          onEdit: () => _openMain(
            destination: StickyBoardMainWindowDestination.todoEdit,
            todoId: item.id,
          ),
          onArchive: () => unawaited(widget.todoController.archive(item.id)),
          onRestore: () => unawaited(widget.todoController.restore(item.id)),
          tags: widget.todoController.tags,
          assignedTagIds: widget.todoController.tagIdsForTodo(item.id),
          onOpenTagAssignment: () => _openMain(
            destination: StickyBoardMainWindowDestination.todoEdit,
            todoId: item.id,
          ),
          showArchiveAction: false,
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
