import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/floatick_hover_motion.dart';
import '../../../l10n/l10n.dart';
import '../domain/todo_tag.dart';
import 'todo_view_model.dart';
import 'widgets/floatick_tag_chip.dart';
import 'widgets/tag_palette.dart';

const double _managedTagRowExtent = 44;

class TagManagementDrawer extends StatefulWidget {
  const TagManagementDrawer({
    required this.controller,
    required this.isOpen,
    required this.borderOnLeft,
    required this.onClose,
    required this.closeFocusNode,
    super.key,
  });

  final TodoViewModel controller;
  final bool isOpen;
  final bool borderOnLeft;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;

  @override
  State<TagManagementDrawer> createState() => _TagManagementDrawerState();
}

class _TagManagementDrawerState extends State<TagManagementDrawer> {
  final _queryController = TextEditingController();
  final _queryFocusNode = FocusNode();

  String? _editingTagId;
  String? _pendingDeleteTagId;
  String? _validationMessage;
  int _selectedColorValue = TagPalette.teal;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      _requestQueryFocus();
    }
  }

  @override
  void didUpdateWidget(covariant TagManagementDrawer oldWidget) {
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
      setState(() => _validationMessage = context.l10n.tagNameRequiredMessage);
      return;
    }

    setState(() {
      _isSaving = true;
      _validationMessage = null;
    });
    final result = _editingTagId == null
        ? await widget.controller.createTag(
            name: name,
            colorValue: _selectedColorValue,
          )
        : await widget.controller.updateTag(
            id: _editingTagId!,
            name: name,
            colorValue: _selectedColorValue,
          );
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      if (result == TagMutationResult.success) {
        _editingTagId = null;
        _pendingDeleteTagId = null;
        _queryController.clear();
        _selectedColorValue = TagPalette.teal;
      } else {
        _validationMessage = _messageForResult(result);
      }
    });
    if (result == TagMutationResult.success) {
      _queryFocusNode.requestFocus();
    }
  }

  void _beginEditing(TodoTag tag) {
    setState(() {
      _editingTagId = tag.id;
      _pendingDeleteTagId = null;
      _validationMessage = null;
      _selectedColorValue = tag.colorValue;
      _queryController.text = tag.name;
      _queryController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: tag.name.length,
      );
    });
    _queryFocusNode.requestFocus();
  }

  void _cancelEditing() {
    setState(() {
      _editingTagId = null;
      _validationMessage = null;
      _queryController.clear();
      _selectedColorValue = TagPalette.teal;
    });
    _queryFocusNode.requestFocus();
  }

  Future<void> _confirmDelete(String tagId) async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    final result = await widget.controller.deleteTag(tagId);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _pendingDeleteTagId = null;
      if (_editingTagId == tagId) {
        _editingTagId = null;
        _queryController.clear();
        _selectedColorValue = TagPalette.teal;
      }
      if (result != TagMutationResult.success) {
        _validationMessage = _messageForResult(result);
      }
    });
  }

  String _messageForResult(TagMutationResult result) {
    return switch (result) {
      TagMutationResult.emptyName => context.l10n.tagNameRequiredMessage,
      TagMutationResult.nameTooLong => context.l10n.tagNameTooLongMessage(
        TodoTag.maxNameLength,
      ),
      TagMutationResult.duplicateName => context.l10n.duplicateTagNameMessage,
      TagMutationResult.notFound => context.l10n.tagNotFoundMessage,
      TagMutationResult.invalidColor => context.l10n.invalidTagColorMessage,
      TagMutationResult.storageFailure => context.l10n.tagStorageFailureMessage,
      TagMutationResult.success => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      key: const Key('tag-management-drawer'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202A2E) : const Color(0xFFF9FBFA),
        border: Border(
          left: widget.borderOnLeft
              ? BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.07),
                )
              : BorderSide.none,
          right: widget.borderOnLeft
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.07),
                ),
        ),
      ),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final query = _queryController.text.trim().toLowerCase();
          final filteredTags = widget.controller.tags
              .where((tag) {
                return query.isEmpty || tag.name.toLowerCase().contains(query);
              })
              .toList(growable: false);
          final usageCounts = widget.controller.tagUsageCountsFor(
            filteredTags.map((tag) => tag.id),
          );
          final canSubmit = !_isSaving;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.l10n.tagsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('tag-management-close'),
                      focusNode: widget.closeFocusNode,
                      tooltip: context.l10n.closeTagManagementTooltip,
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      key: const Key('tag-search-create-field'),
                      controller: _queryController,
                      focusNode: _queryFocusNode,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.done,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(TodoTag.maxNameLength),
                      ],
                      onChanged: (_) {
                        setState(() {
                          _validationMessage = null;
                          _pendingDeleteTagId = null;
                        });
                      },
                      onSubmitted: (_) {
                        if (canSubmit) {
                          unawaited(_submit());
                        }
                      },
                      decoration: InputDecoration(
                        hintText: context.l10n.searchOrCreateTagHint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (_editingTagId != null)
                              IconButton(
                                key: const Key('cancel-tag-edit'),
                                tooltip: context.l10n.cancelEditTooltip,
                                onPressed: _isSaving ? null : _cancelEditing,
                                icon: const Icon(Icons.close_rounded, size: 16),
                              ),
                            IconButton(
                              key: const Key('submit-tag'),
                              tooltip: _editingTagId == null
                                  ? context.l10n.createTagTooltip
                                  : context.l10n.saveTagTooltip,
                              onPressed: canSubmit
                                  ? () => unawaited(_submit())
                                  : null,
                              icon: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                      ),
                                    )
                                  : Icon(
                                      _editingTagId == null
                                          ? Icons.add_rounded
                                          : Icons.check_rounded,
                                      size: 18,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _editingTagId == null
                                ? context.l10n.createTagModeLabel
                                : context.l10n.editTagModeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.44,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_queryController.text.characters.length}'
                          '/${TodoTag.maxNameLength}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.36,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      key: const Key('tag-color-palette'),
                      spacing: 9,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final colorValue in TagPalette.values)
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
                      const SizedBox(height: 10),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _validationMessage!,
                          key: const Key('tag-validation-message'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              Expanded(
                child: filteredTags.isEmpty
                    ? _EmptyTagResults(hasQuery: query.isNotEmpty)
                    : ListView.builder(
                        key: const Key('tag-management-list'),
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 14),
                        itemExtent: _managedTagRowExtent,
                        itemCount: filteredTags.length,
                        itemBuilder: (context, index) {
                          final tag = filteredTags[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: _ManagedTagRow(
                              key: ValueKey<String>('managed-tag-${tag.id}'),
                              tag: tag,
                              usageCount: usageCounts[tag.id] ?? 0,
                              isEditing: _editingTagId == tag.id,
                              isConfirmingDelete: _pendingDeleteTagId == tag.id,
                              enabled: !_isSaving,
                              onEdit: () => _beginEditing(tag),
                              onRequestDelete: () {
                                setState(() => _pendingDeleteTagId = tag.id);
                              },
                              onCancelDelete: () {
                                setState(() => _pendingDeleteTagId = null);
                              },
                              onConfirmDelete: () =>
                                  unawaited(_confirmDelete(tag.id)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
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
    final color = TagPalette.color(colorValue);
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 7,
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _ManagedTagRow extends StatefulWidget {
  const _ManagedTagRow({
    required this.tag,
    required this.usageCount,
    required this.isEditing,
    required this.isConfirmingDelete,
    required this.enabled,
    required this.onEdit,
    required this.onRequestDelete,
    required this.onCancelDelete,
    required this.onConfirmDelete,
    super.key,
  });

  final TodoTag tag;
  final int usageCount;
  final bool isEditing;
  final bool isConfirmingDelete;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onRequestDelete;
  final VoidCallback onCancelDelete;
  final VoidCallback onConfirmDelete;

  @override
  State<_ManagedTagRow> createState() => _ManagedTagRowState();
}

class _ManagedTagRowState extends State<_ManagedTagRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showActions =
        _hovered || widget.isEditing || widget.isConfirmingDelete;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        decoration: BoxDecoration(
          color: widget.isEditing || _hovered
              ? theme.colorScheme.onSurface.withValues(alpha: 0.045)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FloatickTagChip(tag: widget.tag),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              context.l10n.tagUsageCount(widget.usageCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(width: 3),
            if (widget.isConfirmingDelete) ...[
              SizedBox.square(
                dimension: 30,
                child: IconButton(
                  tooltip: context.l10n.cancelDeleteTagTooltip,
                  onPressed: widget.enabled ? widget.onCancelDelete : null,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
              SizedBox.square(
                dimension: 30,
                child: IconButton(
                  key: ValueKey<String>('confirm-delete-${widget.tag.id}'),
                  tooltip: context.l10n.confirmDeleteTagTooltip,
                  onPressed: widget.enabled ? widget.onConfirmDelete : null,
                  padding: EdgeInsets.zero,
                  color: theme.colorScheme.error,
                  icon: const Icon(Icons.delete_forever_outlined, size: 17),
                ),
              ),
            ] else
              AnimatedOpacity(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 130),
                opacity: showActions ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showActions,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox.square(
                        dimension: 30,
                        child: IconButton(
                          key: ValueKey<String>('edit-tag-${widget.tag.id}'),
                          tooltip: context.l10n.editTagTooltip,
                          onPressed: widget.enabled ? widget.onEdit : null,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                        ),
                      ),
                      SizedBox.square(
                        dimension: 30,
                        child: IconButton(
                          key: ValueKey<String>('delete-tag-${widget.tag.id}'),
                          tooltip: context.l10n.deleteTagTooltip,
                          onPressed: widget.enabled
                              ? widget.onRequestDelete
                              : null,
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTagResults extends StatelessWidget {
  const _EmptyTagResults({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasQuery
              ? context.l10n.noMatchingTagsMessage
              : context.l10n.noTagsYetMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.46),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
