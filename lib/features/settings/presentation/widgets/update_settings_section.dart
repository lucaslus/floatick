import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../updates/presentation/update_view_model.dart';
import 'compact_settings_item.dart';
import 'compact_settings_toggle.dart';

class UpdateSettingsSection extends StatelessWidget {
  const UpdateSettingsSection({required this.viewModel, super.key});

  final UpdateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final localizations = context.l10n;
        final errorMessage = switch (viewModel.error) {
          UpdateFailureKind.loadSettings =>
            localizations.updateSettingsLoadError,
          UpdateFailureKind.saveSettings =>
            localizations.updateSettingsSaveError,
          UpdateFailureKind.check => localizations.updateCheckError,
          UpdateFailureKind.feedUnavailable =>
            localizations.updateFeedUnavailable,
          null => null,
        };
        final isInformational =
            viewModel.error == UpdateFailureKind.feedUnavailable;

        return Column(
          key: const Key('update-settings-section'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    localizations.updatesSectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  localizations.currentVersionLabel(viewModel.currentVersion),
                  key: const Key('current-version'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CompactSettingsItem(
              key: const Key('automatic-update-checks'),
              label: localizations.automaticUpdateChecksLabel,
              toggled: viewModel.automaticallyChecksForUpdates,
              onPressed: viewModel.isLoading || viewModel.isSaving
                  ? null
                  : () {
                      unawaited(
                        viewModel.setAutomaticallyChecksForUpdates(
                          !viewModel.automaticallyChecksForUpdates,
                        ),
                      );
                    },
              trailing: CompactSettingsToggle(
                key: const Key('automatic-update-toggle'),
                value: viewModel.automaticallyChecksForUpdates,
                enabled: !viewModel.isLoading && !viewModel.isSaving,
              ),
            ),
            const SizedBox(height: 2),
            CompactSettingsItem(
              key: const Key('check-for-updates'),
              onPressed: viewModel.isLoading || viewModel.isChecking
                  ? null
                  : () {
                      unawaited(viewModel.checkForUpdates());
                    },
              label: viewModel.isChecking
                  ? localizations.checkingForUpdatesButton
                  : localizations.checkForUpdatesButton,
              trailing: viewModel.isChecking
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      size: 17,
                      color: colorScheme.primary,
                    ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 4),
              _UpdateStatus(
                message: errorMessage,
                informational: isInformational,
                onDismiss: viewModel.dismissError,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _UpdateStatus extends StatelessWidget {
  const _UpdateStatus({
    required this.message,
    required this.informational,
    required this.onDismiss,
  });

  final String message;
  final bool informational;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = informational
        ? colorScheme.onSurface.withValues(alpha: 0.58)
        : colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: <Widget>[
          Icon(
            informational
                ? Icons.info_outline_rounded
                : Icons.error_outline_rounded,
            size: 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                height: 1.25,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.dismissErrorTooltip,
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            icon: Icon(Icons.close_rounded, size: 14, color: foregroundColor),
          ),
        ],
      ),
    );
  }
}
