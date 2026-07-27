import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _FloatickShellState extends State<_FloatickShell>
    with SingleTickerProviderStateMixin {
  static const _expandedPanelSize = Size(440, 700);
  static const _expandDuration = Duration(milliseconds: 180);
  static const _collapseDuration = Duration(milliseconds: 150);

  bool _isExpanded = false;
  bool _isChangingWindow = false;
  bool _isPanelPrepared = false;
  bool _panelTooltipsEnabled = false;
  bool _hasSyncedPreferredLanguage = false;
  bool _hasSyncedAlwaysOnTop = false;
  String? _lastSyncedLanguageCode;
  bool? _lastSyncedAlwaysOnTop;
  WindowExpansionAnchor _expansionAnchor = WindowExpansionAnchor.topRight;
  StickyBoardMainWindowRequest? _stickyBoardRequest;
  int _stickyBoardRequestSerial = 0;
  Future<void>? _rendererWarmUpFuture;
  Future<void>? _panelPreparationFuture;
  late final AnimationController _panelAnimationController;
  late final Animation<double> _panelOpacity;
  late final Animation<double> _panelScale;

  @override
  void initState() {
    super.initState();
    _panelAnimationController = AnimationController(
      vsync: this,
      duration: _expandDuration,
      reverseDuration: _collapseDuration,
    );
    final panelCurve = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _panelOpacity = panelCurve;
    _panelScale = Tween<double>(begin: 0.97, end: 1).animate(panelCurve);
    widget.windowBridge.setExpandRequestHandler(_handleNativeExpandRequest);
    widget.settingsController.addListener(_handleSettingsChanged);
    widget.stickyBoardWindowCoordinator.setMainWindowRequestHandler(
      _handleStickyBoardWindowRequest,
    );
    unawaited(_syncPreferredLanguage());
    unawaited(_syncAlwaysOnTop());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_preparePanelAndRestorePinnedBoards());
    });
  }

  @override
  void didUpdateWidget(covariant _FloatickShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.windowBridge != widget.windowBridge) {
      oldWidget.windowBridge.setExpandRequestHandler(null);
      widget.windowBridge.setExpandRequestHandler(_handleNativeExpandRequest);
      _hasSyncedPreferredLanguage = false;
      _hasSyncedAlwaysOnTop = false;
    }
    if (oldWidget.settingsController != widget.settingsController) {
      oldWidget.settingsController.removeListener(_handleSettingsChanged);
      widget.settingsController.addListener(_handleSettingsChanged);
      _hasSyncedPreferredLanguage = false;
      _hasSyncedAlwaysOnTop = false;
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
    if (!_hasSyncedAlwaysOnTop) {
      unawaited(_syncAlwaysOnTop());
    }
  }

  @override
  void dispose() {
    widget.windowBridge.setExpandRequestHandler(null);
    widget.settingsController.removeListener(_handleSettingsChanged);
    widget.stickyBoardWindowCoordinator.setMainWindowRequestHandler(null);
    _panelAnimationController.dispose();
    super.dispose();
  }

  void _handleStickyBoardWindowRequest(StickyBoardMainWindowRequest request) {
    setState(() {
      _stickyBoardRequest = request;
      _stickyBoardRequestSerial += 1;
    });
    unawaited(_setExpanded(true));
  }

  void _handleSettingsChanged() {
    unawaited(_syncPreferredLanguage());
    unawaited(_syncAlwaysOnTop());
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

  Future<void> _preparePanelAndRestorePinnedBoards() async {
    await _ensurePanelPrepared();
    if (!mounted) {
      return;
    }
    await widget.stickyBoardWindowCoordinator.restorePinnedBoards();
  }

  Future<void> _ensurePanelPrepared() {
    return _panelPreparationFuture ??= _preparePanel();
  }

  Future<void> _preparePanel() async {
    if (!_isPanelPrepared && mounted) {
      setState(() => _isPanelPrepared = true);
      await WidgetsBinding.instance.endOfFrame;
    }
    _startRendererWarmUp();
    await _rendererWarmUpFuture;
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

  Future<void> _syncAlwaysOnTop() async {
    final alwaysOnTop = widget.settingsController.alwaysOnTop;
    if (_hasSyncedAlwaysOnTop && alwaysOnTop == _lastSyncedAlwaysOnTop) {
      return;
    }

    _hasSyncedAlwaysOnTop = true;
    _lastSyncedAlwaysOnTop = alwaysOnTop;
    try {
      await widget.windowBridge.setAlwaysOnTop(alwaysOnTop);
    } on Object catch (error, stackTrace) {
      if (_lastSyncedAlwaysOnTop == alwaysOnTop) {
        _hasSyncedAlwaysOnTop = false;
      }
      debugPrint('Floatick could not update the window level: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleNativeExpandRequest(WindowExpansionAnchor expansionAnchor) {
    unawaited(_setExpanded(true, requestedAnchor: expansionAnchor));
  }

  void _enablePanelTooltips() {
    if (!_isExpanded || _panelTooltipsEnabled) {
      return;
    }
    setState(() => _panelTooltipsEnabled = true);
  }

  KeyEventResult _handlePanelKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent) {
      _enablePanelTooltips();
    }
    return KeyEventResult.ignored;
  }

  Future<void> _setExpanded(
    bool expanded, {
    WindowExpansionAnchor? requestedAnchor,
  }) async {
    if (_isChangingWindow) {
      return;
    }
    if (_isExpanded == expanded) {
      if (expanded) {
        try {
          await widget.windowBridge.setExpanded(true);
        } on Object catch (error, stackTrace) {
          debugPrint('Floatick could not focus the native window: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      return;
    }

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final previousExpanded = _isExpanded;
    setState(() {
      _isChangingWindow = true;
      _panelTooltipsEnabled = false;
    });

    try {
      if (expanded) {
        await _ensurePanelPrepared();
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
        if (!mounted) {
          return;
        }
        setState(() => _isExpanded = true);
        if (reduceMotion) {
          _panelAnimationController.value = 1;
        } else {
          await _panelAnimationController.forward().orCancel;
        }
      } else {
        setState(() => _isExpanded = false);
        if (reduceMotion) {
          _panelAnimationController.value = 0;
        } else {
          await _panelAnimationController.reverse().orCancel;
        }
        await widget.windowBridge.setExpanded(false);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Floatick could not change the native window: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isExpanded = previousExpanded);
        _panelAnimationController.value = previousExpanded ? 1 : 0;
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingWindow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expansionAlignment = switch (_expansionAnchor) {
      WindowExpansionAnchor.topLeft => Alignment.topLeft,
      WindowExpansionAnchor.topRight => Alignment.topRight,
      WindowExpansionAnchor.bottomLeft => Alignment.bottomLeft,
      WindowExpansionAnchor.bottomRight => Alignment.bottomRight,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelSize = Size(
            constraints.maxWidth < _expandedPanelSize.width
                ? _expandedPanelSize.width
                : constraints.maxWidth,
            constraints.maxHeight < _expandedPanelSize.height
                ? _expandedPanelSize.height
                : constraints.maxHeight,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Align(
                alignment: expansionAlignment,
                child: FadeTransition(
                  opacity: ReverseAnimation(_panelOpacity),
                  child: IgnorePointer(
                    ignoring: _isExpanded || _isChangingWindow,
                    child: FloatingTodoIcon(
                      key: const ValueKey('floating-todo-icon'),
                      activeCount: widget.controller.activeCount,
                      onOpen: () => unawaited(_setExpanded(true)),
                    ),
                  ),
                ),
              ),
              if (_isPanelPrepared)
                Positioned.fill(
                  child: OverflowBox(
                    alignment: expansionAlignment,
                    minWidth: panelSize.width,
                    maxWidth: panelSize.width,
                    minHeight: panelSize.height,
                    maxHeight: panelSize.height,
                    child: SizedBox.fromSize(
                      size: panelSize,
                      child: IgnorePointer(
                        ignoring: !_isExpanded,
                        child: TickerMode(
                          enabled: _isExpanded,
                          child: FadeTransition(
                            opacity: _panelOpacity,
                            child: ScaleTransition(
                              scale: _panelScale,
                              alignment: expansionAlignment,
                              child: RepaintBoundary(
                                key: const ValueKey('todo-panel'),
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: _handlePanelKeyEvent,
                                  child: Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerHover: (event) {
                                      if (event.delta.distanceSquared > 0) {
                                        _enablePanelTooltips();
                                      }
                                    },
                                    onPointerDown: (_) =>
                                        _enablePanelTooltips(),
                                    child: TooltipVisibility(
                                      key: const Key(
                                        'panel-tooltip-visibility',
                                      ),
                                      visible: _panelTooltipsEnabled,
                                      child: TodoPanel(
                                        controller: widget.controller,
                                        settingsController:
                                            widget.settingsController,
                                        updateController:
                                            widget.updateController,
                                        stickyBoardController:
                                            widget.stickyBoardController,
                                        stickyBoardWindowCoordinator:
                                            widget.stickyBoardWindowCoordinator,
                                        windowBridge: widget.windowBridge,
                                        expansionAnchor: _expansionAnchor,
                                        stickyBoardRequest: _stickyBoardRequest,
                                        stickyBoardRequestSerial:
                                            _stickyBoardRequestSerial,
                                        onCollapse: () =>
                                            unawaited(_setExpanded(false)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
