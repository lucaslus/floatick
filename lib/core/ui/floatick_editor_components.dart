import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'floatick_hover_motion.dart';

const _editorDrawerRadius = Radius.circular(22);

abstract final class FloatickEditorMetrics {
  static const bodyPadding = EdgeInsets.fromLTRB(20, 16, 20, 12);
  static const double sectionGap = 12;
}

class FloatickEditorDrawerSurface extends StatelessWidget {
  const FloatickEditorDrawerSurface({
    required this.title,
    required this.closeTooltip,
    required this.onClose,
    required this.closeFocusNode,
    required this.child,
    this.headerActions = const <Widget>[],
    this.closeButtonKey,
    super.key,
  });

  final String title;
  final String closeTooltip;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;
  final List<Widget> headerActions;
  final Key? closeButtonKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202A2E) : const Color(0xFFF9FBFA),
        borderRadius: const BorderRadius.vertical(top: _editorDrawerRadius),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.11)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: _editorDrawerRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FloatickEditorDrawerHeader(
              title: title,
              closeTooltip: closeTooltip,
              onClose: onClose,
              closeFocusNode: closeFocusNode,
              actions: headerActions,
              closeButtonKey: closeButtonKey,
            ),
            const FloatickEditorDivider(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class FloatickEditorDrawerHeader extends StatelessWidget {
  const FloatickEditorDrawerHeader({
    required this.title,
    required this.closeTooltip,
    required this.onClose,
    required this.closeFocusNode,
    this.actions = const <Widget>[],
    this.closeButtonKey,
    super.key,
  });

  final String title;
  final String closeTooltip;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;
  final List<Widget> actions;
  final Key? closeButtonKey;

  @override
  Widget build(BuildContext context) {
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
          ...actions,
          IconButton(
            key: closeButtonKey ?? const Key('editor-drawer-close'),
            focusNode: closeFocusNode,
            tooltip: closeTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class FloatickEditorSectionLabel extends StatelessWidget {
  const FloatickEditorSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class FloatickDocumentEditor extends StatelessWidget {
  const FloatickDocumentEditor({
    required this.titleController,
    required this.contentController,
    required this.titleFocusNode,
    required this.contentFocusNode,
    required this.titleHint,
    required this.contentHint,
    required this.titleSemanticsLabel,
    required this.contentSemanticsLabel,
    required this.showPreview,
    required this.preview,
    required this.onPreviewChanged,
    this.toolbarLeading,
    this.enabled = true,
    this.onTitleChanged,
    this.onContentChanged,
    this.editorSurfaceKey = const Key('floatick-document-editor'),
    this.titleFieldKey = const Key('floatick-document-title-field'),
    this.contentFieldKey = const Key('floatick-document-content-field'),
    this.modeSwitchKey = const Key('floatick-document-mode-switch'),
    this.writeTabKey = const Key('floatick-document-write-tab'),
    this.previewTabKey = const Key('floatick-document-preview-tab'),
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final FocusNode titleFocusNode;
  final FocusNode contentFocusNode;
  final String titleHint;
  final String contentHint;
  final String titleSemanticsLabel;
  final String contentSemanticsLabel;
  final bool showPreview;
  final Widget preview;
  final ValueChanged<bool> onPreviewChanged;
  final Widget? toolbarLeading;
  final bool enabled;
  final ValueChanged<String>? onTitleChanged;
  final ValueChanged<String>? onContentChanged;
  final Key editorSurfaceKey;
  final Key titleFieldKey;
  final Key contentFieldKey;
  final Key modeSwitchKey;
  final Key writeTabKey;
  final Key previewTabKey;

  void _focusContent() {
    if (!enabled) {
      return;
    }
    contentFocusNode.requestFocus();
  }

  void _handlePreviewChanged(BuildContext context, bool showPreview) {
    if (showPreview) {
      contentFocusNode.unfocus();
    }
    onPreviewChanged(showPreview);
    if (!showPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && enabled) {
          contentFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecorationTheme = theme.inputDecorationTheme;
    final focusListenable = Listenable.merge(<Listenable>[
      titleFocusNode,
      contentFocusNode,
    ]);
    final fieldDecoration = InputDecoration(
      hintText: titleHint,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (toolbarLeading case final leading?)
              Expanded(child: leading)
            else
              const Spacer(),
            const SizedBox(width: 8),
            FloatickEditorModeSwitch(
              showPreview: showPreview,
              controlKey: modeSwitchKey,
              writeTabKey: writeTabKey,
              previewTabKey: previewTabKey,
              onChanged: (value) => _handlePreviewChanged(context, value),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Expanded(
          child: ListenableBuilder(
            listenable: focusListenable,
            builder: (context, _) {
              final hasFocus =
                  titleFocusNode.hasFocus || contentFocusNode.hasFocus;
              final borderColor = hasFocus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.08 : 0.06,
                    );
              return AnimatedContainer(
                key: editorSurfaceKey,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: hasFocus ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      label: titleSemanticsLabel,
                      textField: true,
                      child: TextField(
                        key: titleFieldKey,
                        controller: titleController,
                        focusNode: titleFocusNode,
                        enabled: enabled,
                        maxLines: 1,
                        textInputAction: TextInputAction.next,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: onTitleChanged,
                        onSubmitted: (_) => _focusContent(),
                        decoration: fieldDecoration.copyWith(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            15,
                            16,
                            13,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      key: const Key('floatick-document-title-divider'),
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    Expanded(
                      child: showPreview
                          ? preview
                          : Semantics(
                              label: contentSemanticsLabel,
                              textField: true,
                              child: TextField(
                                key: contentFieldKey,
                                controller: contentController,
                                focusNode: contentFocusNode,
                                enabled: enabled,
                                expands: true,
                                minLines: null,
                                maxLines: null,
                                textAlignVertical: TextAlignVertical.top,
                                keyboardType: TextInputType.multiline,
                                onChanged: onContentChanged,
                                decoration: fieldDecoration.copyWith(
                                  hintText: contentHint,
                                  alignLabelWithHint: true,
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    16,
                                    13,
                                    16,
                                    16,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FloatickEditorModeSwitch extends StatelessWidget {
  const FloatickEditorModeSwitch({
    required this.showPreview,
    required this.onChanged,
    this.controlKey = const Key('floatick-editor-mode-switch'),
    this.writeTabKey = const Key('markdown-write-tab'),
    this.previewTabKey = const Key('markdown-preview-tab'),
    super.key,
  });

  final bool showPreview;
  final ValueChanged<bool> onChanged;
  final Key controlKey;
  final Key writeTabKey;
  final Key previewTabKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: controlKey,
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
            key: writeTabKey,
            label: context.l10n.markdownWriteLabel,
            selected: !showPreview,
            onPressed: () => onChanged(false),
          ),
          _EditorModeButton(
            key: previewTabKey,
            label: context.l10n.markdownPreviewLabel,
            selected: showPreview,
            onPressed: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class FloatickEditorDivider extends StatelessWidget {
  const FloatickEditorDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }
}

class FloatickEditorFooter extends StatelessWidget {
  const FloatickEditorFooter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const FloatickEditorDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: child,
        ),
      ],
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
