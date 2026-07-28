import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

import '../../../app/theme/floatick_theme.dart';
import '../../../core/ui/floatick_hover_motion.dart';
import '../../../l10n/l10n.dart';
import '../../todos/domain/todo_item.dart';
import '../../todos/presentation/todo_view_model.dart';
import '../domain/sticky_board.dart';
import 'sticky_board_frame_save_scheduler.dart';
import 'sticky_board_palette.dart';
import 'sticky_board_view_model.dart';
import 'sticky_board_window_coordinator.dart';
import 'widgets/sticky_board_read_only_todo_row.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boardColor = StickyBoardPalette.color(board.colorValue);
    final surfaceColor = StickyBoardPalette.surfaceColor(
      value: board.colorValue,
      baseColor: isDark
          ? FloatickColors.darkSurface
          : FloatickColors.lightSurface,
      brightness: theme.brightness,
    );

    final detailsItem = _detailsTodoId == null
        ? null
        : widget.todoController.itemById(_detailsTodoId!);

    const borderRadius = BorderRadius.all(Radius.circular(22));
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: boardColor.withValues(alpha: isDark ? 0.44 : 0.34),
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
                        ),
                ),
              ),
            ],
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
        return StickyBoardReadOnlyTodoRow(
          key: ValueKey<String>('pinned-sticky-board-todo-${item.id}'),
          item: item,
          onToggleCompletion: () =>
              unawaited(widget.todoController.toggleCompletion(item.id)),
          onOpenDetails: () => _showTodoDetails(item.id),
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
            FloatickHoverMotion(
              hoverScale: FloatickMotion.emphasisHoverScale,
              pressedScale: FloatickMotion.emphasisPressedScale,
              hoverTurns: FloatickMotion.emphasisHoverTurns,
              child: IconButton(
                key: const Key('pinned-sticky-board-unpin'),
                tooltip: context.l10n.unpinStickyBoardTooltip,
                onPressed: onUnpin,
                style: const ButtonStyle(
                  foregroundBuilder:
                      FloatickMotion.passthroughForegroundBuilder,
                ),
                icon: Icon(
                  Icons.push_pin_rounded,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
