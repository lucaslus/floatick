import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../l10n/l10n.dart';

class FloatickMarkdownPreview extends StatelessWidget {
  const FloatickMarkdownPreview({
    required this.content,
    this.embedded = false,
    super.key,
  });

  final String content;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = content.trim().isEmpty
        ? Center(
            child: Text(
              context.l10n.markdownPreviewEmptyMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
              ),
            ),
          )
        : FloatickMarkdownContent(content: content);
    if (embedded) {
      return child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: child,
    );
  }
}

class FloatickMarkdownContent extends StatelessWidget {
  const FloatickMarkdownContent({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: content,
      selectable: true,
      padding: const EdgeInsets.all(14),
      styleSheet: _markdownStyleSheet(context),
      imageBuilder: (uri, title, alt) {
        return _BlockedMarkdownImage(label: alt);
      },
    );
  }
}

class _BlockedMarkdownImage extends StatelessWidget {
  const _BlockedMarkdownImage({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = label?.trim();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.image_not_supported_outlined,
            size: 17,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.46),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description == null || description.isEmpty
                  ? context.l10n.markdownImageBlockedMessage
                  : description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

MarkdownStyleSheet _markdownStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  final onSurface = theme.colorScheme.onSurface;
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(
      color: onSurface.withValues(alpha: 0.88),
      height: 1.55,
    ),
    h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    a: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
    code: theme.textTheme.bodySmall?.copyWith(
      color: onSurface.withValues(alpha: 0.90),
      fontFamily: 'monospace',
    ),
    blockSpacing: 10,
    codeblockPadding: const EdgeInsets.all(11),
    codeblockDecoration: BoxDecoration(
      color: onSurface.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(9),
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
    blockquoteDecoration: BoxDecoration(
      color: theme.colorScheme.primary.withValues(alpha: 0.07),
      border: Border(
        left: BorderSide(color: theme.colorScheme.primary, width: 3),
      ),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: onSurface.withValues(alpha: 0.13))),
    ),
  );
}
