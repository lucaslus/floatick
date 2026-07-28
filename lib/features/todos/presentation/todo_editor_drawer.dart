import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/floatick_hover_motion.dart';
import '../../../l10n/l10n.dart';
import '../domain/todo_item.dart';
import '../domain/todo_tag.dart';
import 'widgets/floatick_tag_chip.dart';
import 'widgets/todo_markdown.dart';

enum TodoEditorDrawerMode { create, details, edit }

class TodoEditorDrawer extends StatefulWidget {
  const TodoEditorDrawer({
    required this.mode,
    required this.item,
    required this.availableTags,
    required this.originalAssignedTagIds,
    required this.assignedTagIds,
    required this.isOpen,
    required this.onClose,
    required this.onEdit,
    required this.onOpenTagAssignment,
    required this.onSave,
    required this.onSaved,
    required this.closeFocusNode,
    this.canEdit = true,
    super.key,
  });

  final TodoEditorDrawerMode mode;
  final TodoItem? item;
  final List<TodoTag> availableTags;
  final List<String> originalAssignedTagIds;
  final List<String> assignedTagIds;
  final bool isOpen;
  final bool canEdit;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onOpenTagAssignment;
  final Future<bool> Function(String title, String content, List<String> tagIds)
  onSave;
  final VoidCallback onSaved;
  final FocusNode closeFocusNode;

  @override
  State<TodoEditorDrawer> createState() => _TodoEditorDrawerState();
}

class _TodoEditorDrawerState extends State<TodoEditorDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  bool _showPreview = false;
  bool _isSaving = false;
  bool _saveFailed = false;

  bool get _isEditing =>
      widget.mode == TodoEditorDrawerMode.create ||
      widget.mode == TodoEditorDrawerMode.edit;

  @override
  void initState() {
    super.initState();
    _syncControllers();
    if (widget.isOpen) {
      _requestInitialFocus();
    }
  }

  @override
  void didUpdateWidget(covariant TodoEditorDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedContext =
        oldWidget.mode != widget.mode ||
        oldWidget.item?.id != widget.item?.id ||
        oldWidget.item?.title != widget.item?.title ||
        oldWidget.item?.content != widget.item?.content;
    final didOpen = !oldWidget.isOpen && widget.isOpen;
    if (changedContext) {
      _formKey.currentState?.reset();
      _syncControllers();
      _showPreview = false;
      _isSaving = false;
      _saveFailed = false;
    }
    if (widget.isOpen && (changedContext || didOpen)) {
      _requestInitialFocus();
    }
    if (oldWidget.isOpen && !widget.isOpen) {
      _titleFocusNode.unfocus();
      _contentFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _titleController.text = widget.item?.title ?? '';
    _contentController.text = widget.item?.content ?? '';
  }

  void _requestInitialFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isOpen) {
        return;
      }
      if (_isEditing) {
        _titleFocusNode.requestFocus();
        _titleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _titleController.text.length,
        );
      } else {
        widget.closeFocusNode.requestFocus();
      }
    });
  }

  bool get _canSave {
    if (_isSaving || _titleController.text.trim().isEmpty) {
      return false;
    }
    if (widget.mode == TodoEditorDrawerMode.create) {
      return true;
    }
    final item = widget.item;
    return item != null &&
        (item.title != _titleController.text.trim() ||
            item.content != _contentController.text ||
            !setEquals(
              widget.originalAssignedTagIds.toSet(),
              widget.assignedTagIds.toSet(),
            ));
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (!_isEditing || _isSaving || form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    final didSave = await widget.onSave(
      _titleController.text.trim(),
      _contentController.text,
      widget.availableTags
          .where((tag) => widget.assignedTagIds.contains(tag.id))
          .map((tag) => tag.id)
          .toList(growable: false),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _saveFailed = !didSave;
    });
    if (didSave) {
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final availableTags = widget.availableTags;
    return DecoratedBox(
      key: const Key('todo-editor-drawer'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202A2E) : const Color(0xFFF9FBFA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.11)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _DrawerHeader(
              mode: widget.mode,
              canEdit: widget.canEdit,
              onEdit: widget.onEdit,
              onClose: widget.onClose,
              closeFocusNode: widget.closeFocusNode,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: widget.mode == TodoEditorDrawerMode.details
                    ? _TodoDetails(
                        key: ValueKey<String>(
                          'details-${widget.item?.id ?? 'missing'}',
                        ),
                        item: widget.item,
                        canEdit: widget.canEdit,
                        tags: availableTags
                            .where(
                              (tag) => widget.assignedTagIds.contains(tag.id),
                            )
                            .toList(growable: false),
                      )
                    : _TodoEditor(
                        key: const ValueKey<String>('todo-editor'),
                        formKey: _formKey,
                        titleController: _titleController,
                        contentController: _contentController,
                        titleFocusNode: _titleFocusNode,
                        contentFocusNode: _contentFocusNode,
                        availableTags: availableTags,
                        selectedTagIds: widget.assignedTagIds.toSet(),
                        showPreview: _showPreview,
                        isSaving: _isSaving,
                        saveFailed: _saveFailed,
                        canSave: _canSave,
                        mode: widget.mode,
                        onChanged: () {
                          setState(() {
                            _saveFailed = false;
                          });
                        },
                        onPreviewChanged: (showPreview) {
                          setState(() => _showPreview = showPreview);
                        },
                        onOpenTagAssignment: widget.onOpenTagAssignment,
                        onSubmit: () => unawaited(_submit()),
                        onCancel: widget.onClose,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.mode,
    required this.canEdit,
    required this.onEdit,
    required this.onClose,
    required this.closeFocusNode,
  });

  final TodoEditorDrawerMode mode;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;

  @override
  Widget build(BuildContext context) {
    final title = switch (mode) {
      TodoEditorDrawerMode.create => context.l10n.newTodoDrawerTitle,
      TodoEditorDrawerMode.details => context.l10n.todoDetailsDrawerTitle,
      TodoEditorDrawerMode.edit => context.l10n.editTodoDrawerTitle,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 11),
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
          if (mode == TodoEditorDrawerMode.details && canEdit)
            IconButton(
              key: const Key('todo-details-edit'),
              onPressed: onEdit,
              tooltip: context.l10n.editTodoAction,
              icon: const Icon(Icons.edit_outlined, size: 19),
            ),
          IconButton(
            key: const Key('todo-drawer-close'),
            focusNode: closeFocusNode,
            tooltip: context.l10n.closeTodoDrawerTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _TodoEditor extends StatelessWidget {
  const _TodoEditor({
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.titleFocusNode,
    required this.contentFocusNode,
    required this.availableTags,
    required this.selectedTagIds,
    required this.showPreview,
    required this.isSaving,
    required this.saveFailed,
    required this.canSave,
    required this.mode,
    required this.onChanged,
    required this.onPreviewChanged,
    required this.onOpenTagAssignment,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final FocusNode titleFocusNode;
  final FocusNode contentFocusNode;
  final List<TodoTag> availableTags;
  final Set<String> selectedTagIds;
  final bool showPreview;
  final bool isSaving;
  final bool saveFailed;
  final bool canSave;
  final TodoEditorDrawerMode mode;
  final VoidCallback onChanged;
  final ValueChanged<bool> onPreviewChanged;
  final VoidCallback onOpenTagAssignment;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _SaveTodoIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CloseTodoDrawerIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SaveTodoIntent: CallbackAction<_SaveTodoIntent>(
            onInvoke: (_) {
              if (canSave) {
                onSubmit();
              }
              return null;
            },
          ),
          _CloseTodoDrawerIntent: CallbackAction<_CloseTodoDrawerIntent>(
            onInvoke: (_) {
              onCancel();
              return null;
            },
          ),
        },
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        context.l10n.todoTitleLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        key: const Key('todo-title-field'),
                        controller: titleController,
                        focusNode: titleFocusNode,
                        enabled: !isSaving,
                        maxLines: 1,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => onChanged(),
                        onFieldSubmitted: (_) =>
                            contentFocusNode.requestFocus(),
                        validator: (value) {
                          return value == null || value.trim().isEmpty
                              ? context.l10n.todoTitleRequiredHint
                              : null;
                        },
                        decoration: InputDecoration(
                          hintText: context.l10n.todoTitleFieldHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            context.l10n.assignTagsTitle,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 5,
                              runSpacing: 5,
                              children: <Widget>[
                                for (final tag in availableTags)
                                  if (selectedTagIds.contains(tag.id))
                                    FloatickTagChip(
                                      key: ValueKey<String>(
                                        'todo-editor-tag-${tag.id}',
                                      ),
                                      tag: tag,
                                      compact: true,
                                    ),
                                IconButton(
                                  key: const Key('todo-editor-tag-button'),
                                  tooltip: context.l10n.assignTagsTooltip,
                                  onPressed: isSaving
                                      ? null
                                      : onOpenTagAssignment,
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size.square(30),
                                    maximumSize: const Size.square(30),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: selectedTagIds.isEmpty
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.56)
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                  icon: Icon(
                                    selectedTagIds.isEmpty
                                        ? Icons.sell_outlined
                                        : Icons.sell_rounded,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              context.l10n.todoContentLabel,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _EditorModeSwitch(
                            showPreview: showPreview,
                            onChanged: onPreviewChanged,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 140),
                          child: showPreview
                              ? TodoMarkdownPreview(
                                  key: const Key('todo-content-preview'),
                                  content: contentController.text,
                                )
                              : TextFormField(
                                  key: const Key('todo-content-field'),
                                  controller: contentController,
                                  focusNode: contentFocusNode,
                                  enabled: !isSaving,
                                  expands: true,
                                  minLines: null,
                                  maxLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  keyboardType: TextInputType.multiline,
                                  onChanged: (_) => onChanged(),
                                  decoration: InputDecoration(
                                    hintText: context.l10n.todoContentFieldHint,
                                    alignLabelWithHint: true,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        context.l10n.markdownSupportedHint,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (saveFailed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    context.l10n.saveTodoFailedMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: isSaving ? null : onCancel,
                      child: Text(context.l10n.cancelAction),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const Key('save-todo-details'),
                      onPressed: canSave ? onSubmit : null,
                      icon: isSaving
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 17),
                      label: Text(
                        mode == TodoEditorDrawerMode.create
                            ? context.l10n.createTodoAction
                            : context.l10n.saveChangesAction,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorModeSwitch extends StatelessWidget {
  const _EditorModeSwitch({required this.showPreview, required this.onChanged});

  final bool showPreview;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _EditorModeButton(
            key: const Key('markdown-write-tab'),
            label: context.l10n.markdownWriteLabel,
            selected: !showPreview,
            onPressed: () => onChanged(false),
          ),
          _EditorModeButton(
            key: const Key('markdown-preview-tab'),
            label: context.l10n.markdownPreviewLabel,
            selected: showPreview,
            onPressed: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _EditorModeButton extends StatelessWidget {
  const _EditorModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: FloatickHoverMotion(
        hoverScale: FloatickMotion.controlHoverScale,
        pressedScale: FloatickMotion.controlPressedScale,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 140),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.surface.withValues(alpha: 0.92)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.52),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoDetails extends StatelessWidget {
  const _TodoDetails({
    required this.item,
    required this.tags,
    required this.canEdit,
    super.key,
  });

  final TodoItem? item;
  final List<TodoTag> tags;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item == null) {
      return Center(child: Text(context.l10n.todoNotFoundMessage));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            item.title,
            key: const Key('todo-details-title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              key: const Key('todo-details-tags'),
              spacing: 6,
              runSpacing: 5,
              children: <Widget>[
                for (final tag in tags)
                  FloatickTagChip(
                    key: ValueKey<String>('todo-details-tag-${tag.id}'),
                    tag: tag,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: item.content.trim().isEmpty
                ? _EmptyTodoContent(canEdit: canEdit)
                : TodoMarkdownContent(
                    key: const Key('todo-details-markdown'),
                    content: item.content,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTodoContent extends StatelessWidget {
  const _EmptyTodoContent({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.notes_rounded,
              size: 30,
              color: onSurface.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.noTodoContentTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              canEdit
                  ? context.l10n.noTodoContentMessage
                  : context.l10n.archivedTodoNoContentMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveTodoIntent extends Intent {
  const _SaveTodoIntent();
}

class _CloseTodoDrawerIntent extends Intent {
  const _CloseTodoDrawerIntent();
}
