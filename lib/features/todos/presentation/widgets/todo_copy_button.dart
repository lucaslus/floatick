import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/todo_item.dart';
import '../todo_clipboard_controller.dart';

class TodoCopyButton extends StatelessWidget {
  const TodoCopyButton({
    required this.item,
    required this.controller,
    this.visible = true,
    this.dimension = 30,
    this.iconSize = 17,
    super.key,
  });

  final TodoItem item;
  final TodoClipboardController controller;
  final bool visible;
  final double dimension;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: dimension,
      child: AnimatedOpacity(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 140),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: ExcludeFocus(
            excluding: !visible,
            child: ValueListenableBuilder<TodoCopyStatus>(
              valueListenable: controller,
              builder: (context, status, _) {
                final (tooltip, icon, color) = switch (status) {
                  TodoCopyStatus.idle => (
                    context.l10n.copyTodoAsMarkdownTooltip,
                    Icons.content_copy_rounded,
                    null,
                  ),
                  TodoCopyStatus.copied => (
                    context.l10n.todoCopiedAsMarkdownMessage,
                    Icons.check_rounded,
                    Theme.of(context).colorScheme.primary,
                  ),
                  TodoCopyStatus.failed => (
                    context.l10n.todoCopyFailedMessage,
                    Icons.error_outline_rounded,
                    Theme.of(context).colorScheme.error,
                  ),
                };
                return Semantics(
                  liveRegion: status != TodoCopyStatus.idle,
                  label: tooltip,
                  button: true,
                  child: IconButton(
                    tooltip: tooltip,
                    onPressed: () => unawaited(controller.copy(item)),
                    padding: EdgeInsets.zero,
                    icon: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 140),
                      child: Icon(
                        icon,
                        key: ValueKey<TodoCopyStatus>(status),
                        size: iconSize,
                        color: color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
