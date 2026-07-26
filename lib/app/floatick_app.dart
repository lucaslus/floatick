import 'dart:async';

import 'package:flutter/material.dart';

import '../core/platform/window_bridge.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_view_model.dart';
import '../features/sticky_boards/presentation/sticky_board_view_model.dart';
import '../features/sticky_boards/presentation/sticky_board_window_coordinator.dart';
import '../features/todos/presentation/todo_panel.dart';
import '../features/todos/presentation/todo_view_model.dart';
import '../features/todos/presentation/widgets/floating_todo_icon.dart';
import '../features/updates/presentation/update_view_model.dart';
import '../l10n/app_localizations.dart';
import 'theme/floatick_theme.dart';

class FloatickApp extends StatelessWidget {
  const FloatickApp({
    required this.controller,
    required this.settingsController,
    required this.updateController,
    required this.stickyBoardController,
    required this.stickyBoardWindowCoordinator,
    required this.windowBridge,
    this.locale,
    super.key,
  });

  final TodoViewModel controller;
  final SettingsViewModel settingsController;
  final UpdateViewModel updateController;
  final StickyBoardViewModel stickyBoardController;
  final StickyBoardWindowCoordinator stickyBoardWindowCoordinator;
  final WindowBridge windowBridge;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        final settingsLocale = switch (settingsController.languagePreference) {
          AppLanguagePreference.system => null,
          AppLanguagePreference.simplifiedChinese => const Locale('zh'),
          AppLanguagePreference.english => const Locale('en'),
        };
        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context).applicationTitle,
          debugShowCheckedModeBanner: false,
          locale: locale ?? settingsLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFloatickTheme(Brightness.light),
          darkTheme: buildFloatickTheme(Brightness.dark),
          themeMode: switch (settingsController.themePreference) {
            AppThemePreference.system => ThemeMode.system,
            AppThemePreference.light => ThemeMode.light,
            AppThemePreference.dark => ThemeMode.dark,
          },
          home: _FloatickShell(
            controller: controller,
            settingsController: settingsController,
            updateController: updateController,
            stickyBoardController: stickyBoardController,
            stickyBoardWindowCoordinator: stickyBoardWindowCoordinator,
            windowBridge: windowBridge,
          ),
        );
      },
    );
  }
}

class _FloatickShell extends StatefulWidget {
  const _FloatickShell({
    required this.controller,
    required this.settingsController,
    required this.updateController,
    required this.stickyBoardController,
    required this.stickyBoardWindowCoordinator,
    required this.windowBridge,
  });

  final TodoViewModel controller;
  final SettingsViewModel settingsController;
  final UpdateViewModel updateController;
  final StickyBoardViewModel stickyBoardController;
  final StickyBoardWindowCoordinator stickyBoardWindowCoordinator;
  final WindowBridge windowBridge;

  @override
  State<_FloatickShell> createState() => _FloatickShellState();
}

class _FloatickShellState extends State<_FloatickShell> {
  static const _motionDuration = Duration(milliseconds: 220);

  bool _isExpanded = false;
  bool _isChangingWindow = false;
  bool _hasSyncedPreferredLanguage = false;
  String? _lastSyncedLanguageCode;
  WindowExpansionAnchor _expansionAnchor = WindowExpansionAnchor.topRight;
  String? _requestedStickyBoardId;
  int _stickyBoardRequestSerial = 0;
  Future<void>? _rendererWarmUpFuture;

  @override
  void initState() {
    super.initState();
    widget.windowBridge.setExpandRequestHandler(_handleNativeExpandRequest);
    widget.settingsController.addListener(_handleSettingsChanged);
    widget.stickyBoardWindowCoordinator.setMainWindowRequestHandler(
      _handleStickyBoardWindowRequest,
    );
    unawaited(_syncPreferredLanguage());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRendererWarmUp();
      unawaited(_restorePinnedBoardsAfterWarmUp());
    });
  }

  @override
  void didUpdateWidget(covariant _FloatickShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.windowBridge != widget.windowBridge) {
      oldWidget.windowBridge.setExpandRequestHandler(null);
      widget.windowBridge.setExpandRequestHandler(_handleNativeExpandRequest);
      _hasSyncedPreferredLanguage = false;
    }
    if (oldWidget.settingsController != widget.settingsController) {
      oldWidget.settingsController.removeListener(_handleSettingsChanged);
      widget.settingsController.addListener(_handleSettingsChanged);
      _hasSyncedPreferredLanguage = false;
    }
    if (oldWidget.stickyBoardWindowCoordinator !=
        widget.stickyBoardWindowCoordinator) {
      oldWidget.stickyBoardWindowCoordinator.setMainWindowRequestHandler(null);
      widget.stickyBoardWindowCoordinator.setMainWindowRequestHandler(
        _handleStickyBoardWindowRequest,
      );
    }
    if (!_hasSyncedPreferredLanguage) {
      unawaited(_syncPreferredLanguage());
    }
  }

  @override
  void dispose() {
    widget.windowBridge.setExpandRequestHandler(null);
    widget.settingsController.removeListener(_handleSettingsChanged);
    widget.stickyBoardWindowCoordinator.setMainWindowRequestHandler(null);
    super.dispose();
  }

  void _handleStickyBoardWindowRequest(String boardId) {
    setState(() {
      _requestedStickyBoardId = boardId;
      _stickyBoardRequestSerial += 1;
    });
    unawaited(_setExpanded(true));
  }

  void _handleSettingsChanged() {
    unawaited(_syncPreferredLanguage());
  }

  void _startRendererWarmUp() {
    _rendererWarmUpFuture ??= _warmUpRenderer();
  }

  Future<void> _warmUpRenderer() async {
    try {
      await const _FloatickShaderWarmUp().execute();
    } on Object catch (error, stackTrace) {
      debugPrint('Floatick could not warm up the renderer: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _restorePinnedBoardsAfterWarmUp() async {
    _startRendererWarmUp();
    await _rendererWarmUpFuture;
    if (!mounted) {
      return;
    }
    await widget.stickyBoardWindowCoordinator.restorePinnedBoards();
  }

  Future<void> _syncPreferredLanguage() async {
    final languageCode = switch (widget.settingsController.languagePreference) {
      AppLanguagePreference.system => null,
      AppLanguagePreference.simplifiedChinese => 'zh',
      AppLanguagePreference.english => 'en',
    };
    if (_hasSyncedPreferredLanguage &&
        languageCode == _lastSyncedLanguageCode) {
      return;
    }

    _hasSyncedPreferredLanguage = true;
    _lastSyncedLanguageCode = languageCode;
    try {
      await widget.windowBridge.setPreferredLanguage(languageCode);
    } on Object catch (error, stackTrace) {
      if (_lastSyncedLanguageCode == languageCode) {
        _hasSyncedPreferredLanguage = false;
      }
      debugPrint('Floatick could not update the native language: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleNativeExpandRequest(WindowExpansionAnchor expansionAnchor) {
    unawaited(_setExpanded(true, requestedAnchor: expansionAnchor));
  }

  Future<void> _setExpanded(
    bool expanded, {
    WindowExpansionAnchor? requestedAnchor,
  }) async {
    if (_isChangingWindow || _isExpanded == expanded) {
      return;
    }

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final motionDuration = reduceMotion ? Duration.zero : _motionDuration;
    setState(() => _isChangingWindow = true);

    try {
      if (expanded) {
        _startRendererWarmUp();
        await _rendererWarmUpFuture;
        if (!mounted) {
          return;
        }
        final expansionAnchor =
            requestedAnchor ??
            await widget.windowBridge.preferredExpansionAnchor();
        if (!mounted) {
          return;
        }
        setState(() => _expansionAnchor = expansionAnchor);
        await WidgetsBinding.instance.endOfFrame;
        await widget.windowBridge.setExpanded(true);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) {
          return;
        }
        setState(() => _isExpanded = true);
      } else {
        setState(() => _isExpanded = false);
        await WidgetsBinding.instance.endOfFrame;
        if (motionDuration > Duration.zero) {
          await Future<void>.delayed(motionDuration);
        }
        await widget.windowBridge.setExpanded(false);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Floatick could not change the native window: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isExpanded = !expanded);
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingWindow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final transitionDuration = reduceMotion ? Duration.zero : _motionDuration;
    final expansionAlignment = switch (_expansionAnchor) {
      WindowExpansionAnchor.topLeft => Alignment.topLeft,
      WindowExpansionAnchor.topRight => Alignment.topRight,
      WindowExpansionAnchor.bottomLeft => Alignment.bottomLeft,
      WindowExpansionAnchor.bottomRight => Alignment.bottomRight,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: AnimatedSwitcher(
          duration: transitionDuration,
          reverseDuration: transitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final isPanel = child.key == const ValueKey('todo-panel');
            final scaleAnimation = Tween<double>(
              begin: isPanel ? 0.95 : 0.92,
              end: 1,
            ).animate(curvedAnimation);
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                alignment: expansionAlignment,
                child: child,
              ),
            );
          },
          child: _isExpanded
              ? RepaintBoundary(
                  key: const ValueKey('todo-panel'),
                  child: TodoPanel(
                    controller: widget.controller,
                    settingsController: widget.settingsController,
                    updateController: widget.updateController,
                    stickyBoardController: widget.stickyBoardController,
                    stickyBoardWindowCoordinator:
                        widget.stickyBoardWindowCoordinator,
                    windowBridge: widget.windowBridge,
                    expansionAnchor: _expansionAnchor,
                    requestedStickyBoardId: _requestedStickyBoardId,
                    stickyBoardRequestSerial: _stickyBoardRequestSerial,
                    onCollapse: () => unawaited(_setExpanded(false)),
                  ),
                )
              : Align(
                  key: const ValueKey('collapsed-icon-alignment'),
                  alignment: expansionAlignment,
                  child: FloatingTodoIcon(
                    key: const ValueKey('floating-todo-icon'),
                    activeCount: widget.controller.activeCount,
                    onOpen: () => unawaited(_setExpanded(true)),
                  ),
                ),
        ),
      ),
    );
  }
}

class _FloatickShaderWarmUp extends ShaderWarmUp {
  const _FloatickShaderWarmUp();

  @override
  Size get size => const Size.square(120);

  @override
  Future<void> warmUpOnCanvas(Canvas canvas) {
    final panelBounds = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final panelShape = RRect.fromRectAndRadius(
      panelBounds,
      const Radius.circular(26),
    );
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF24383C), Color(0xFF172326)],
      ).createShader(panelBounds);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(0.95);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRRect(panelShape, gradientPaint);
    canvas.restore();

    final shadowPath = Path()..addRRect(panelShape);
    canvas.drawShadow(shadowPath, Colors.black, 6, false);
    canvas.drawCircle(
      const Offset(34, 34),
      16,
      Paint()..color = const Color(0xFF20BFB2),
    );

    final checkPaint = Paint()
      ..color = const Color(0xFF2CCCBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(22, 34)
      ..lineTo(31, 43)
      ..lineTo(48, 25);
    canvas.drawPath(checkPath, checkPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Floatick 0123456789 待办归档',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 100);
    textPainter.paint(canvas, const Offset(10, 78));
    textPainter.dispose();

    return Future<void>.value();
  }
}
