import 'package:flutter/material.dart';

const _compactSettingsItemMinHeight = 34.0;
const _compactSettingsItemRadius = 8.0;
const _compactSettingsItemLabelFontSize = 11.0;

class CompactSettingsItem extends StatelessWidget {
  const CompactSettingsItem({
    required this.label,
    required this.trailing,
    required this.onPressed,
    this.toggled,
    super.key,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onPressed;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return Semantics(
      button: toggled == null,
      enabled: enabled,
      label: label,
      toggled: toggled,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_compactSettingsItemRadius),
            hoverColor: theme.colorScheme.primary.withValues(alpha: 0.06),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.10),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: _compactSettingsItemMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: enabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                          fontSize: _compactSettingsItemLabelFontSize,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
