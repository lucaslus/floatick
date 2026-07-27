import 'package:flutter/material.dart';

const compactSettingsToggleSize = Size(32, 18);
const _compactSettingsToggleThumbSize = 14.0;
const _compactSettingsToggleDuration = Duration(milliseconds: 140);

class CompactSettingsToggle extends StatelessWidget {
  const CompactSettingsToggle({
    required this.value,
    required this.enabled,
    super.key,
  });

  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeTrack = colorScheme.primary;
    final inactiveTrack = colorScheme.onSurface.withValues(alpha: 0.18);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox.fromSize(
        size: compactSettingsToggleSize,
        child: AnimatedContainer(
          duration: _compactSettingsToggleDuration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? activeTrack : inactiveTrack,
            borderRadius: BorderRadius.circular(
              compactSettingsToggleSize.height / 2,
            ),
          ),
          child: AnimatedAlign(
            duration: _compactSettingsToggleDuration,
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: value
                    ? colorScheme.onPrimary
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(
                dimension: _compactSettingsToggleThumbSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
