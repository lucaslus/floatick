import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/floatick_theme.dart';
import '../../../core/platform/window_bridge.dart';
import '../../../core/ui/floatick_brand_mark.dart';
import '../../../core/ui/floatick_surface_metrics.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/storage_failure_localizations.dart';
import '../../settings/presentation/settings_drawer.dart';
import '../../settings/presentation/settings_view_model.dart';
import '../../sticky_boards/presentation/sticky_board_drawers.dart';
import '../../sticky_boards/presentation/sticky_board_view_model.dart';
import '../../sticky_boards/presentation/sticky_board_window_coordinator.dart';
import '../../updates/presentation/update_view_model.dart';
import '../domain/todo_item.dart';
import 'tag_filter_drawer.dart';
import 'tag_management_drawer.dart';
import 'todo_editor_drawer.dart';
import 'todo_view_model.dart';
import 'widgets/tag_menus.dart';
import 'widgets/todo_list_row.dart';

const double _settingsDrawerWidth = 268;
const double _tagDrawerWidth = 292;
const double _stickyBoardDrawerWidth = 336;
const double _todoDrawerHeight = 520;
const Duration _drawerSlideDuration = Duration(milliseconds: 220);
const Duration _drawerScrimDuration = Duration(milliseconds: 160);

enum TodoListScope { active, archived }

enum _TodoPanelDrawerMode {
  none,
  settings,
  tagFilter,
  tagAssignment,
  tagManagement,
  stickyBoardManagement,
  stickyBoardDetail,
  stickyBoardTodoPicker,
  createTodo,
  todoDetails,
  editTodo,
}

enum _TodoPanelDrawerFamily { settings, tags, stickyBoards, todoEditor }

class TodoPanel extends StatefulWidget {
  const TodoPanel({
    required this.controller,
    required this.settingsController,
    required this.updateController,
    required this.stickyBoardController,
    required this.stickyBoardWindowCoordinator,
    required this.windowBridge,
    required this.expansionAnchor,
    required this.stickyBoardRequest,
    required this.stickyBoardRequestSerial,
    required this.onCollapse,
    super.key,
  });

  final TodoViewModel controller;
  final SettingsViewModel settingsController;
  final UpdateViewModel updateController;
  final StickyBoardViewModel stickyBoardController;
  final StickyBoardWindowCoordinator stickyBoardWindowCoordinator;
  final WindowBridge windowBridge;
  final WindowExpansionAnchor expansionAnchor;
  final StickyBoardMainWindowRequest? stickyBoardRequest;
  final int stickyBoardRequestSerial;
  final VoidCallback onCollapse;

  @override
  State<TodoPanel> createState() => _TodoPanelState();
}

class _TodoPanelState extends State<TodoPanel> {
  final _searchController = TextEditingController();
  final _panelFocusNode = FocusNode();
  final _searchFocusNode = FocusNode();
  final _settingsCloseFocusNode = FocusNode();
  final _tagFilterCloseFocusNode = FocusNode();
  final _tagAssignmentCloseFocusNode = FocusNode();
  final _tagManagementCloseFocusNode = FocusNode();
  final _stickyBoardCloseFocusNode = FocusNode();
  final _todoDrawerCloseFocusNode = FocusNode();

  TodoListScope _scope = TodoListScope.active;
  String _query = '';
  final Set<String> _selectedTagIds = <String>{};
  String? _selectedTodoId;
  _TodoPanelDrawerMode _drawerMode = _TodoPanelDrawerMode.none;
  _TodoPanelDrawerMode? _pendingDrawerMode;
  _TodoPanelDrawerMode _lastTagDrawerMode = _TodoPanelDrawerMode.tagFilter;
  _TodoPanelDrawerMode _lastTodoDrawerMode = _TodoPanelDrawerMode.createTodo;
  _TodoPanelDrawerMode? _tagManagementReturnMode;
  _TodoPanelDrawerMode? _tagAssignmentReturnMode;
  _TodoPanelDrawerMode? _todoDrawerReturnMode;
  Set<String> _todoEditorTagIds = <String>{};
  final Set<_TodoPanelDrawerFamily> _mountedDrawerFamilies =
      <_TodoPanelDrawerFamily>{};
  String? _selectedStickyBoardId;
  String? _todoCreationBoardId;
  String? _pendingCreatedTodoId;
  int _todoEditorSession = 0;
  int _lastHandledStickyBoardRequestSerial = -1;
  int _drawerRequestSerial = 0;

  @override
  void initState() {
    super.initState();
    _handleRequestedStickyBoard();
  }

  @override
  void didUpdateWidget(covariant TodoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stickyBoardRequestSerial != widget.stickyBoardRequestSerial) {
      _handleRequestedStickyBoard();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _panelFocusNode.dispose();
    _searchFocusNode.dispose();
    _settingsCloseFocusNode.dispose();
    _tagFilterCloseFocusNode.dispose();
    _tagAssignmentCloseFocusNode.dispose();
    _tagManagementCloseFocusNode.dispose();
    _stickyBoardCloseFocusNode.dispose();
    _todoDrawerCloseFocusNode.dispose();
    super.dispose();
  }

  void _openSettings() {
    _showDrawer(_TodoPanelDrawerMode.settings);
  }

  void _handleRequestedStickyBoard() {
    if (_lastHandledStickyBoardRequestSerial ==
        widget.stickyBoardRequestSerial) {
      return;
    }
    _lastHandledStickyBoardRequestSerial = widget.stickyBoardRequestSerial;
    final request = widget.stickyBoardRequest;
    if (request == null ||
        widget.stickyBoardController.boardById(request.boardId) == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openRequestedStickyBoard(request);
    });
  }

  void _openRequestedStickyBoard(StickyBoardMainWindowRequest request) {
    final boardId = request.boardId;
    final todoId = request.todoId;
    if (widget.stickyBoardController.boardById(boardId) == null) {
      return;
    }
    if (todoId != null && widget.controller.itemById(todoId) == null) {
      return;
    }

    _selectedStickyBoardId = boardId;
    if (!_mountedDrawerFamilies.contains(_TodoPanelDrawerFamily.stickyBoards)) {
      setState(
        () => _mountedDrawerFamilies.add(_TodoPanelDrawerFamily.stickyBoards),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performStickyBoardRequest(request);
        }
      });
      return;
    }
    _performStickyBoardRequest(request);
  }

  void _performStickyBoardRequest(StickyBoardMainWindowRequest request) {
    final todoId = request.todoId;
    switch (request.destination) {
      case StickyBoardMainWindowDestination.board:
        _openStickyBoard(request.boardId);
      case StickyBoardMainWindowDestination.todoDetails:
        if (todoId == null) {
          return;
        }
        _todoDrawerReturnMode = _TodoPanelDrawerMode.stickyBoardDetail;
        _showTodoDrawer(
          _TodoPanelDrawerMode.todoDetails,
          todoId: todoId,
          initialTagIds: widget.controller.tagIdsForTodo(todoId),
        );
      case StickyBoardMainWindowDestination.todoEdit:
        if (todoId == null) {
          return;
        }
        _todoDrawerReturnMode = _TodoPanelDrawerMode.stickyBoardDetail;
        _showTodoDrawer(
          _TodoPanelDrawerMode.editTodo,
          todoId: todoId,
          initialTagIds: widget.controller.tagIdsForTodo(todoId),
        );
    }
  }

  void _openStickyBoards() {
    _selectedStickyBoardId = null;
    _showDrawer(_TodoPanelDrawerMode.stickyBoardManagement);
  }

  void _openStickyBoard(String boardId) {
    if (widget.stickyBoardController.boardById(boardId) == null) {
      return;
    }
    if (_drawerMode == _TodoPanelDrawerMode.stickyBoardDetail) {
      setState(() => _selectedStickyBoardId = boardId);
      return;
    }
    _selectedStickyBoardId = boardId;
    _showDrawer(_TodoPanelDrawerMode.stickyBoardDetail);
  }

  void _openStickyBoardTodoPicker() {
    if (_selectedStickyBoardId == null) {
      return;
    }
    _showDrawer(_TodoPanelDrawerMode.stickyBoardTodoPicker);
  }

  void _backToStickyBoardManagement() {
    _showDrawer(_TodoPanelDrawerMode.stickyBoardManagement);
  }

  void _backToStickyBoardDetail() {
    if (_selectedStickyBoardId == null) {
      _backToStickyBoardManagement();
      return;
    }
    _showDrawer(_TodoPanelDrawerMode.stickyBoardDetail);
  }

  void _toggleStickyBoardPin(String boardId) {
    unawaited(widget.stickyBoardWindowCoordinator.togglePin(boardId));
  }

  void _deleteStickyBoard(String boardId) {
    if (_selectedStickyBoardId == boardId) {
      _selectedStickyBoardId = null;
    }
    unawaited(widget.stickyBoardWindowCoordinator.deleteBoard(boardId));
  }

  void _openTagFilter() {
    _showDrawer(_TodoPanelDrawerMode.tagFilter);
  }

  void _openTagManagement() {
    _tagManagementReturnMode = null;
    _tagAssignmentReturnMode = null;
    _showDrawer(_TodoPanelDrawerMode.tagManagement);
  }

  void _openTodoCreate({String? stickyBoardId}) {
    _todoCreationBoardId = stickyBoardId;
    _pendingCreatedTodoId = null;
    _todoDrawerReturnMode = stickyBoardId == null
        ? null
        : _TodoPanelDrawerMode.stickyBoardDetail;
    _showTodoDrawer(
      _TodoPanelDrawerMode.createTodo,
      initialTagIds: const <String>[],
      startsNewSession: true,
    );
  }

  void _openTodoDetails(String todoId) {
    if (_drawerMode == _TodoPanelDrawerMode.stickyBoardDetail) {
      _todoDrawerReturnMode = _TodoPanelDrawerMode.stickyBoardDetail;
    }
    _showTodoDrawer(
      _TodoPanelDrawerMode.todoDetails,
      todoId: todoId,
      initialTagIds: widget.controller.tagIdsForTodo(todoId),
    );
  }

  void _openTodoEdit(String todoId) {
    if (_drawerMode == _TodoPanelDrawerMode.stickyBoardDetail ||
        _todoDrawerReturnMode == _TodoPanelDrawerMode.stickyBoardDetail) {
      _todoDrawerReturnMode = _TodoPanelDrawerMode.stickyBoardDetail;
    }
    _showTodoDrawer(
      _TodoPanelDrawerMode.editTodo,
      todoId: todoId,
      initialTagIds: widget.controller.tagIdsForTodo(todoId),
    );
  }

  Future<void> _deleteArchivedTodoPermanently(String todoId) async {
    final boardIds = widget.stickyBoardController.boards
        .where(
          (board) => widget.stickyBoardController
              .todoIdsForBoard(board.id)
              .contains(todoId),
        )
        .map((board) => board.id)
        .toList(growable: false);
    final removedFromBoards = await widget.stickyBoardController
        .removeTodoFromAllBoards(todoId);
    if (!removedFromBoards) {
      return;
    }
    final deleted = await widget.controller.deletePermanently(todoId);
    if (!deleted) {
      if (widget.controller.itemById(todoId) != null) {
        for (final boardId in boardIds) {
          await widget.stickyBoardController.addTodo(
            boardId: boardId,
            todoId: todoId,
          );
        }
      }
      return;
    }
    if (mounted && _selectedTodoId == todoId) {
      _closeActiveDrawer();
    }
  }

  Future<bool> _saveCreatedTodo({
    required String title,
    required String content,
    required Iterable<String> tagIds,
  }) async {
    final boardId = _todoCreationBoardId;
    var todoId = _pendingCreatedTodoId;
    if (todoId == null) {
      final todoIdsBeforeSave = widget.controller.items
          .map((item) => item.id)
          .toSet();
      final item = await widget.controller.create(
        title,
        content: content,
        tagIds: tagIds,
      );
      if (item == null) {
        final partiallySavedItems = widget.controller.items
            .where((item) => !todoIdsBeforeSave.contains(item.id))
            .toList(growable: false);
        if (partiallySavedItems.length == 1) {
          _pendingCreatedTodoId = partiallySavedItems.single.id;
        }
        return false;
      }
      todoId = item.id;
      _pendingCreatedTodoId = todoId;
    } else {
      final updated = await widget.controller.updateDetails(
        id: todoId,
        title: title,
        content: content,
        tagIds: tagIds,
      );
      if (!updated) {
        return false;
      }
    }

    if (boardId == null) {
      _pendingCreatedTodoId = null;
      return true;
    }
    final linked = await widget.stickyBoardController.addTodo(
      boardId: boardId,
      todoId: todoId,
    );
    if (linked) {
      _pendingCreatedTodoId = null;
    }
    return linked;
  }

  void _openTagAssignmentFromTodo() {
    if (_drawerMode != _TodoPanelDrawerMode.createTodo &&
        _drawerMode != _TodoPanelDrawerMode.editTodo) {
      return;
    }
    _tagAssignmentReturnMode = _drawerMode;
    _showDrawer(_TodoPanelDrawerMode.tagAssignment);
  }

  void _openTagManagementFromTagAssignment() {
    if (_drawerMode != _TodoPanelDrawerMode.tagAssignment) {
      return;
    }
    _tagManagementReturnMode = _TodoPanelDrawerMode.tagAssignment;
    _showDrawer(_TodoPanelDrawerMode.tagManagement);
  }

  void _openTagManagementFromStickyBoard() {
    _tagManagementReturnMode = _TodoPanelDrawerMode.stickyBoardDetail;
    _showDrawer(_TodoPanelDrawerMode.tagManagement);
  }

  void _toggleTodoEditorTag(String tagId) {
    if (widget.controller.tagById(tagId) == null) {
      return;
    }
    setState(() {
      if (!_todoEditorTagIds.add(tagId)) {
        _todoEditorTagIds.remove(tagId);
      }
    });
  }

  void _unfocusDrawerControls() {
    _settingsCloseFocusNode.unfocus();
    _tagFilterCloseFocusNode.unfocus();
    _tagAssignmentCloseFocusNode.unfocus();
    _tagManagementCloseFocusNode.unfocus();
    _stickyBoardCloseFocusNode.unfocus();
    _todoDrawerCloseFocusNode.unfocus();
  }

  void _showDrawer(_TodoPanelDrawerMode mode) {
    if (_drawerMode == mode) {
      return;
    }

    _unfocusDrawerControls();
    final requestSerial = ++_drawerRequestSerial;
    final family = _drawerFamilyFor(mode);
    if (family != null && !_mountedDrawerFamilies.contains(family)) {
      setState(() {
        _mountedDrawerFamilies.add(family);
        _pendingDrawerMode = mode;
        if (family == _TodoPanelDrawerFamily.tags) {
          _lastTagDrawerMode = mode;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || requestSerial != _drawerRequestSerial) {
          return;
        }
        _activateDrawer(mode);
      });
      return;
    }
    _activateDrawer(mode);
  }

  void _activateDrawer(_TodoPanelDrawerMode mode) {
    setState(() {
      _pendingDrawerMode = null;
      _drawerMode = mode;
      if (mode == _TodoPanelDrawerMode.tagFilter ||
          mode == _TodoPanelDrawerMode.tagAssignment ||
          mode == _TodoPanelDrawerMode.tagManagement) {
        _lastTagDrawerMode = mode;
      }
    });
    _requestDrawerFocus(mode);
  }

  void _requestDrawerFocus(_TodoPanelDrawerMode mode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _drawerMode != mode) {
        return;
      }
      final focusNode = switch (mode) {
        _TodoPanelDrawerMode.settings => _settingsCloseFocusNode,
        _TodoPanelDrawerMode.tagFilter => _tagFilterCloseFocusNode,
        _TodoPanelDrawerMode.tagAssignment => _tagAssignmentCloseFocusNode,
        _TodoPanelDrawerMode.stickyBoardManagement ||
        _TodoPanelDrawerMode.stickyBoardDetail ||
        _TodoPanelDrawerMode.stickyBoardTodoPicker =>
          _stickyBoardCloseFocusNode,
        _TodoPanelDrawerMode.none ||
        _TodoPanelDrawerMode.tagManagement ||
        _TodoPanelDrawerMode.createTodo ||
        _TodoPanelDrawerMode.todoDetails ||
        _TodoPanelDrawerMode.editTodo => null,
      };
      focusNode?.requestFocus();
    });
  }

  void _showTodoDrawer(
    _TodoPanelDrawerMode mode, {
    required Iterable<String> initialTagIds,
    String? todoId,
    bool startsNewSession = false,
  }) {
    assert(
      mode == _TodoPanelDrawerMode.createTodo ||
          mode == _TodoPanelDrawerMode.todoDetails ||
          mode == _TodoPanelDrawerMode.editTodo,
    );
    if (_drawerMode == mode && _selectedTodoId == todoId) {
      return;
    }

    _unfocusDrawerControls();
    final requestSerial = ++_drawerRequestSerial;
    final needsMount = !_mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.todoEditor,
    );
    setState(() {
      if (startsNewSession) {
        _todoEditorSession += 1;
      }
      if (needsMount) {
        _mountedDrawerFamilies.add(_TodoPanelDrawerFamily.todoEditor);
        _pendingDrawerMode = mode;
      } else {
        _pendingDrawerMode = null;
        _drawerMode = mode;
      }
      _lastTodoDrawerMode = mode;
      _selectedTodoId = todoId;
      _todoEditorTagIds = initialTagIds.toSet();
      if (mode == _TodoPanelDrawerMode.createTodo) {
        _scope = TodoListScope.active;
      }
    });
    if (!needsMount) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestSerial != _drawerRequestSerial) {
        return;
      }
      setState(() {
        _pendingDrawerMode = null;
        _drawerMode = mode;
      });
    });
  }

  void _toggleTagFilter(String tagId) {
    setState(() {
      if (!_selectedTagIds.add(tagId)) {
        _selectedTagIds.remove(tagId);
      }
    });
  }

  void _clearTagFilters() {
    if (_selectedTagIds.isEmpty) {
      return;
    }
    setState(_selectedTagIds.clear);
  }

  void _closeActiveDrawer() {
    if (_drawerMode == _TodoPanelDrawerMode.none) {
      if (_pendingDrawerMode == null) {
        return;
      }
      _drawerRequestSerial += 1;
      setState(() => _pendingDrawerMode = null);
      _restorePanelFocus();
      return;
    }

    _drawerRequestSerial += 1;
    final closedMode = _drawerMode;
    final returnMode = switch (closedMode) {
      _TodoPanelDrawerMode.tagManagement => _tagManagementReturnMode,
      _TodoPanelDrawerMode.tagAssignment => _tagAssignmentReturnMode,
      _TodoPanelDrawerMode.createTodo ||
      _TodoPanelDrawerMode.todoDetails ||
      _TodoPanelDrawerMode.editTodo => _todoDrawerReturnMode,
      _ => null,
    };
    _unfocusDrawerControls();
    setState(() {
      _drawerMode = returnMode ?? _TodoPanelDrawerMode.none;
      if (closedMode == _TodoPanelDrawerMode.tagManagement) {
        _tagManagementReturnMode = null;
      }
      if (closedMode == _TodoPanelDrawerMode.tagAssignment) {
        _tagAssignmentReturnMode = null;
      }
      if (_isTodoDrawerMode(closedMode)) {
        _todoDrawerReturnMode = null;
        _todoCreationBoardId = null;
        _pendingCreatedTodoId = null;
      }
    });
    if (returnMode != null) {
      _requestDrawerFocus(returnMode);
      if (_isTodoDrawerMode(closedMode)) {
        _releaseClosedTodoDrawer(closedMode, expectedMode: returnMode);
      }
      return;
    }
    _restorePanelFocus();
    if (_isTodoDrawerMode(closedMode)) {
      _releaseClosedTodoDrawer(closedMode);
    }
  }

  void _restorePanelFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _drawerMode == _TodoPanelDrawerMode.none) {
        _panelFocusNode.requestFocus();
      }
    });
  }

  void _releaseClosedTodoDrawer(
    _TodoPanelDrawerMode closedMode, {
    _TodoPanelDrawerMode expectedMode = _TodoPanelDrawerMode.none,
  }) {
    Future<void>.delayed(_drawerSlideDuration, () {
      if (!mounted ||
          _drawerMode != expectedMode ||
          _lastTodoDrawerMode != closedMode) {
        return;
      }
      setState(() {
        _lastTodoDrawerMode = _TodoPanelDrawerMode.createTodo;
        _selectedTodoId = null;
        _todoEditorTagIds = <String>{};
      });
    });
  }

  bool _isTodoDrawerMode(_TodoPanelDrawerMode mode) {
    return mode == _TodoPanelDrawerMode.createTodo ||
        mode == _TodoPanelDrawerMode.todoDetails ||
        mode == _TodoPanelDrawerMode.editTodo;
  }

  _TodoPanelDrawerFamily? _drawerFamilyFor(_TodoPanelDrawerMode mode) {
    return switch (mode) {
      _TodoPanelDrawerMode.settings => _TodoPanelDrawerFamily.settings,
      _TodoPanelDrawerMode.tagFilter ||
      _TodoPanelDrawerMode.tagAssignment ||
      _TodoPanelDrawerMode.tagManagement => _TodoPanelDrawerFamily.tags,
      _TodoPanelDrawerMode.stickyBoardManagement ||
      _TodoPanelDrawerMode.stickyBoardDetail ||
      _TodoPanelDrawerMode.stickyBoardTodoPicker =>
        _TodoPanelDrawerFamily.stickyBoards,
      _TodoPanelDrawerMode.createTodo ||
      _TodoPanelDrawerMode.todoDetails ||
      _TodoPanelDrawerMode.editTodo => _TodoPanelDrawerFamily.todoEditor,
      _TodoPanelDrawerMode.none => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDrawerOpen =
        _drawerMode != _TodoPanelDrawerMode.none || _pendingDrawerMode != null;
    final isSettingsOpen = _drawerMode == _TodoPanelDrawerMode.settings;
    final isTagFilterOpen = _drawerMode == _TodoPanelDrawerMode.tagFilter;
    final isTagAssignmentOpen =
        _drawerMode == _TodoPanelDrawerMode.tagAssignment;
    final isTagManagementOpen =
        _drawerMode == _TodoPanelDrawerMode.tagManagement;
    final isTagDrawerOpen =
        isTagFilterOpen || isTagAssignmentOpen || isTagManagementOpen;
    final isStickyBoardManagementOpen =
        _drawerMode == _TodoPanelDrawerMode.stickyBoardManagement;
    final isStickyBoardDetailOpen =
        _drawerMode == _TodoPanelDrawerMode.stickyBoardDetail;
    final isStickyBoardTodoPickerOpen =
        _drawerMode == _TodoPanelDrawerMode.stickyBoardTodoPicker;
    final isStickyBoardDrawerOpen =
        isStickyBoardManagementOpen ||
        isStickyBoardDetailOpen ||
        isStickyBoardTodoPickerOpen;
    final isTodoDrawerOpen =
        _drawerMode == _TodoPanelDrawerMode.createTodo ||
        _drawerMode == _TodoPanelDrawerMode.todoDetails ||
        _drawerMode == _TodoPanelDrawerMode.editTodo;
    final hasSettingsDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.settings,
    );
    final hasTagDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.tags,
    );
    final hasStickyBoardDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.stickyBoards,
    );
    final hasTodoDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.todoEditor,
    );
    final isTodoContextOverlayOpen =
        isTagAssignmentOpen ||
        (isTagManagementOpen &&
            _tagManagementReturnMode == _TodoPanelDrawerMode.tagAssignment);
    final isTodoDrawerVisible = isTodoDrawerOpen || isTodoContextOverlayOpen;
    final isStickyBoardContextVisible =
        (_todoDrawerReturnMode == _TodoPanelDrawerMode.stickyBoardDetail &&
            (isTodoDrawerOpen || isTodoContextOverlayOpen)) ||
        (isTagManagementOpen &&
            _tagManagementReturnMode == _TodoPanelDrawerMode.stickyBoardDetail);
    final isStickyBoardDrawerVisible =
        isStickyBoardDrawerOpen || isStickyBoardContextVisible;
    final visibleTagDrawerMode = isTagDrawerOpen
        ? _drawerMode
        : _lastTagDrawerMode;
    final visibleTodoDrawerMode = isTodoDrawerOpen
        ? _drawerMode
        : _lastTodoDrawerMode;
    final todoEditorMode = switch (visibleTodoDrawerMode) {
      _TodoPanelDrawerMode.todoDetails => TodoEditorDrawerMode.details,
      _TodoPanelDrawerMode.editTodo => TodoEditorDrawerMode.edit,
      _ => TodoEditorDrawerMode.create,
    };
    final selectedTodo = _selectedTodoId == null
        ? null
        : widget.controller.itemById(_selectedTodoId!);
    final todoEditorTagIds = widget.controller.tags
        .where((tag) => _todoEditorTagIds.contains(tag.id))
        .map((tag) => tag.id)
        .toList(growable: false);
    final originalTodoTagIds = selectedTodo == null
        ? const <String>[]
        : widget.controller.tagIdsForTodo(selectedTodo.id);
    final tagDrawerOnLeft = switch (widget.expansionAnchor) {
      WindowExpansionAnchor.topRight ||
      WindowExpansionAnchor.bottomRight => true,
      WindowExpansionAnchor.topLeft ||
      WindowExpansionAnchor.bottomLeft => false,
    };
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _CollapseIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true): _SearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true): _NewTodoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CollapseIntent: CallbackAction<_CollapseIntent>(
            onInvoke: (_) {
              if (isDrawerOpen) {
                _closeActiveDrawer();
              } else {
                widget.onCollapse();
              }
              return null;
            },
          ),
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (_) {
              _searchFocusNode.requestFocus();
              return null;
            },
          ),
          _NewTodoIntent: CallbackAction<_NewTodoIntent>(
            onInvoke: (_) {
              _openTodoCreate();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _panelFocusNode,
          autofocus: true,
          child: FocusTraversalGroup(
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: 440,
                height: 700,
                padding: const EdgeInsets.all(
                  FloatickSurfaceMetrics.windowInset,
                ),
                child: DecoratedBox(
                  key: const Key('todo-panel-surface'),
                  decoration: BoxDecoration(
                    color: isDark
                        ? FloatickColors.darkGlassSurface
                        : FloatickColors.lightGlassSurface,
                    borderRadius: BorderRadius.circular(
                      FloatickSurfaceMetrics.panelRadius,
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      FloatickSurfaceMetrics.panelContentRadius,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ExcludeFocus(
                          excluding: isDrawerOpen,
                          child: AnimatedBuilder(
                            animation: widget.controller,
                            builder: (context, _) {
                              final selectedTags = widget.controller.tags
                                  .where(
                                    (tag) => _selectedTagIds.contains(tag.id),
                                  )
                                  .toList(growable: false);
                              final effectiveSelectedTagIds = selectedTags
                                  .map((tag) => tag.id)
                                  .toSet();
                              return Column(
                                children: <Widget>[
                                  _PanelHeader(
                                    activeCount: widget.controller.activeCount,
                                    onOpenStickyBoards: _openStickyBoards,
                                    onOpenSettings: _openSettings,
                                    onCollapse: widget.onCollapse,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      12,
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        _ScopePicker(
                                          scope: _scope,
                                          activeCount:
                                              widget.controller.activeCount,
                                          archivedCount:
                                              widget.controller.archivedCount,
                                          reduceMotion: reduceMotion,
                                          onChanged: (scope) {
                                            setState(() => _scope = scope);
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: TextField(
                                                key: const Key('search-field'),
                                                controller: _searchController,
                                                focusNode: _searchFocusNode,
                                                onChanged: (value) {
                                                  setState(
                                                    () => _query = value.trim(),
                                                  );
                                                },
                                                decoration: InputDecoration(
                                                  hintText:
                                                      _scope ==
                                                          TodoListScope.active
                                                      ? context
                                                            .l10n
                                                            .searchTodosHint
                                                      : context
                                                            .l10n
                                                            .searchArchiveHint,
                                                  prefixIcon: const Icon(
                                                    Icons.search_rounded,
                                                    size: 19,
                                                  ),
                                                  suffixIcon: _query.isEmpty
                                                      ? null
                                                      : IconButton(
                                                          tooltip: context
                                                              .l10n
                                                              .clearSearchTooltip,
                                                          onPressed: () {
                                                            _searchController
                                                                .clear();
                                                            setState(
                                                              () => _query = '',
                                                            );
                                                            _searchFocusNode
                                                                .requestFocus();
                                                          },
                                                          icon: const Icon(
                                                            Icons.close_rounded,
                                                            size: 18,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 9),
                                            TagFilterButton(
                                              selectedCount:
                                                  effectiveSelectedTagIds
                                                      .length,
                                              onPressed: _openTagFilter,
                                            ),
                                          ],
                                        ),
                                        if (_scope == TodoListScope.active) ...[
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 42,
                                            child: FilledButton.tonalIcon(
                                              key: const Key('add-todo-button'),
                                              onPressed: _openTodoCreate,
                                              style: FilledButton.styleFrom(
                                                alignment: Alignment.centerLeft,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                    ),
                                              ),
                                              icon: const Icon(
                                                Icons.add_rounded,
                                                size: 18,
                                              ),
                                              label: Text(
                                                context.l10n.createTodoAction,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (widget.controller.error != null)
                                    _ErrorBanner(
                                      message: context.l10n
                                          .messageForStorageFailure(
                                            widget.controller.error!,
                                          ),
                                      onDismiss: widget.controller.dismissError,
                                    ),
                                  AnimatedBuilder(
                                    animation: widget.stickyBoardController,
                                    builder: (context, _) {
                                      final error =
                                          widget.stickyBoardController.error;
                                      if (error == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return _ErrorBanner(
                                        message: context.l10n
                                            .messageForStorageFailure(error),
                                        onDismiss: widget
                                            .stickyBoardController
                                            .dismissError,
                                      );
                                    },
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.07)
                                        : Colors.black.withValues(alpha: 0.055),
                                  ),
                                  Expanded(
                                    child: _TodoList(
                                      controller: widget.controller,
                                      scope: _scope,
                                      query: _query,
                                      selectedTagIds: effectiveSelectedTagIds,
                                      onClearTagFilters: _clearTagFilters,
                                      onOpenTagManagement: _openTagManagement,
                                      onOpenDetails: _openTodoDetails,
                                      onEditTodo: _openTodoEdit,
                                      onDeleteTodo:
                                          _deleteArchivedTodoPermanently,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !isDrawerOpen,
                            child: ExcludeSemantics(
                              excluding: !isDrawerOpen,
                              child: AnimatedOpacity(
                                key: const Key('panel-drawer-scrim'),
                                duration: reduceMotion
                                    ? Duration.zero
                                    : _drawerScrimDuration,
                                curve: Curves.easeOut,
                                opacity: isDrawerOpen ? 1 : 0,
                                child: GestureDetector(
                                  key: const Key('panel-drawer-dismiss'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _closeActiveDrawer,
                                  child: ColoredBox(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.22 : 0.12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasSettingsDrawer)
                          Positioned(
                            top: 0,
                            right: 0,
                            bottom: 0,
                            width: _settingsDrawerWidth,
                            child: IgnorePointer(
                              key: const Key('settings-drawer-pointer'),
                              ignoring: !isSettingsOpen,
                              child: ExcludeSemantics(
                                excluding: !isSettingsOpen,
                                child: AnimatedSlide(
                                  key: const Key('settings-drawer-slide'),
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : _drawerSlideDuration,
                                  curve: Curves.easeOutCubic,
                                  offset: isSettingsOpen
                                      ? Offset.zero
                                      : const Offset(1, 0),
                                  child: FocusTraversalGroup(
                                    child: SettingsDrawer(
                                      viewModel: widget.settingsController,
                                      updateViewModel: widget.updateController,
                                      workingDirectoryPath: widget
                                          .controller
                                          .storageDirectoryPath,
                                      onClose: _closeActiveDrawer,
                                      closeFocusNode: _settingsCloseFocusNode,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (hasStickyBoardDrawer)
                          Positioned(
                            top: 0,
                            left: tagDrawerOnLeft ? 0 : null,
                            right: tagDrawerOnLeft ? null : 0,
                            bottom: 0,
                            width: _stickyBoardDrawerWidth,
                            child: IgnorePointer(
                              key: const Key('sticky-board-drawer-pointer'),
                              ignoring: !isStickyBoardDrawerOpen,
                              child: ExcludeSemantics(
                                excluding: !isStickyBoardDrawerOpen,
                                child: AnimatedSlide(
                                  key: const Key('sticky-board-drawer-slide'),
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : _drawerSlideDuration,
                                  curve: Curves.easeOutCubic,
                                  offset: isStickyBoardDrawerVisible
                                      ? Offset.zero
                                      : Offset(tagDrawerOnLeft ? -1 : 1, 0),
                                  child: FocusTraversalGroup(
                                    child: AnimatedBuilder(
                                      animation: Listenable.merge(<Listenable>[
                                        widget.stickyBoardController,
                                        widget.controller,
                                      ]),
                                      builder: (context, _) {
                                        final board =
                                            _selectedStickyBoardId == null
                                            ? null
                                            : widget.stickyBoardController
                                                  .boardById(
                                                    _selectedStickyBoardId!,
                                                  );
                                        if (isStickyBoardTodoPickerOpen &&
                                            board != null) {
                                          return StickyBoardTodoPickerDrawer(
                                            board: board,
                                            todoController: widget.controller,
                                            boardController:
                                                widget.stickyBoardController,
                                            borderOnLeft: !tagDrawerOnLeft,
                                            onBack: _backToStickyBoardDetail,
                                            onClose: _closeActiveDrawer,
                                            closeFocusNode:
                                                _stickyBoardCloseFocusNode,
                                          );
                                        }
                                        if ((isStickyBoardDetailOpen ||
                                                isStickyBoardContextVisible) &&
                                            board != null) {
                                          return StickyBoardDetailDrawer(
                                            board: board,
                                            todoController: widget.controller,
                                            boardController:
                                                widget.stickyBoardController,
                                            borderOnLeft: !tagDrawerOnLeft,
                                            onBack:
                                                _backToStickyBoardManagement,
                                            onClose: _closeActiveDrawer,
                                            onTogglePin: () =>
                                                _toggleStickyBoardPin(board.id),
                                            onAddExisting:
                                                _openStickyBoardTodoPicker,
                                            onCreateTodo: () => _openTodoCreate(
                                              stickyBoardId: board.id,
                                            ),
                                            onOpenDetails: _openTodoDetails,
                                            onEditTodo: _openTodoEdit,
                                            onOpenTagManagement:
                                                _openTagManagementFromStickyBoard,
                                            closeFocusNode:
                                                _stickyBoardCloseFocusNode,
                                          );
                                        }
                                        return StickyBoardManagementDrawer(
                                          controller:
                                              widget.stickyBoardController,
                                          isOpen: isStickyBoardManagementOpen,
                                          borderOnLeft: !tagDrawerOnLeft,
                                          onClose: _closeActiveDrawer,
                                          onOpenBoard: _openStickyBoard,
                                          onTogglePin: _toggleStickyBoardPin,
                                          onDeleteBoard: _deleteStickyBoard,
                                          closeFocusNode:
                                              _stickyBoardCloseFocusNode,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (hasTodoDrawer)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: _todoDrawerHeight,
                            child: IgnorePointer(
                              key: const Key('todo-drawer-pointer'),
                              ignoring: !isTodoDrawerOpen,
                              child: ExcludeFocus(
                                excluding: !isTodoDrawerOpen,
                                child: ExcludeSemantics(
                                  excluding: !isTodoDrawerOpen,
                                  child: AnimatedSlide(
                                    key: const Key('todo-drawer-slide'),
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : _drawerSlideDuration,
                                    curve: Curves.easeOutCubic,
                                    offset: isTodoDrawerVisible
                                        ? Offset.zero
                                        : const Offset(0, 1),
                                    child: FocusTraversalGroup(
                                      child: TodoEditorDrawer(
                                        key: ValueKey<int>(_todoEditorSession),
                                        mode: todoEditorMode,
                                        item: selectedTodo,
                                        availableTags: widget.controller.tags,
                                        originalAssignedTagIds:
                                            originalTodoTagIds,
                                        assignedTagIds: todoEditorTagIds,
                                        isOpen: isTodoDrawerOpen,
                                        canEdit:
                                            selectedTodo?.isArchived != true,
                                        onClose: _closeActiveDrawer,
                                        onEdit: () {
                                          final todoId = selectedTodo?.id;
                                          if (todoId != null) {
                                            _openTodoEdit(todoId);
                                          }
                                        },
                                        onOpenTagAssignment:
                                            _openTagAssignmentFromTodo,
                                        onSave: (title, content, tagIds) {
                                          if (todoEditorMode ==
                                              TodoEditorDrawerMode.create) {
                                            return _saveCreatedTodo(
                                              title: title,
                                              content: content,
                                              tagIds: tagIds,
                                            );
                                          }
                                          final todoId = selectedTodo?.id;
                                          if (todoId == null) {
                                            return Future<bool>.value(false);
                                          }
                                          return widget.controller
                                              .updateDetails(
                                                id: todoId,
                                                title: title,
                                                content: content,
                                                tagIds: tagIds,
                                              );
                                        },
                                        onSaved: () {
                                          if (_drawerMode ==
                                              _TodoPanelDrawerMode.createTodo) {
                                            _closeActiveDrawer();
                                            return;
                                          }
                                          if (_drawerMode ==
                                              _TodoPanelDrawerMode.editTodo) {
                                            final todoId = _selectedTodoId;
                                            if (todoId != null) {
                                              _openTodoDetails(todoId);
                                            }
                                          }
                                        },
                                        closeFocusNode:
                                            _todoDrawerCloseFocusNode,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (hasTodoDrawer && hasTagDrawer)
                          Positioned.fill(
                            child: IgnorePointer(
                              key: const Key('todo-context-scrim-pointer'),
                              ignoring: !isTodoContextOverlayOpen,
                              child: ExcludeSemantics(
                                child: AnimatedOpacity(
                                  key: const Key('todo-context-scrim'),
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : _drawerScrimDuration,
                                  curve: Curves.easeOut,
                                  opacity: isTodoContextOverlayOpen ? 1 : 0,
                                  child: GestureDetector(
                                    key: const Key('todo-context-dismiss'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _closeActiveDrawer,
                                    child: ColoredBox(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.18 : 0.10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (hasTagDrawer)
                          Positioned(
                            top: 0,
                            left: tagDrawerOnLeft ? 0 : null,
                            right: tagDrawerOnLeft ? null : 0,
                            bottom: 0,
                            width: _tagDrawerWidth,
                            child: IgnorePointer(
                              key: const Key('tag-drawer-pointer'),
                              ignoring: !isTagDrawerOpen,
                              child: ExcludeSemantics(
                                excluding: !isTagDrawerOpen,
                                child: AnimatedSlide(
                                  key: const Key('tag-drawer-slide'),
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : _drawerSlideDuration,
                                  curve: Curves.easeOutCubic,
                                  offset: isTagDrawerOpen
                                      ? Offset.zero
                                      : Offset(tagDrawerOnLeft ? -1 : 1, 0),
                                  child: FocusTraversalGroup(
                                    child: AnimatedSwitcher(
                                      duration: reduceMotion
                                          ? Duration.zero
                                          : const Duration(milliseconds: 160),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      child: switch (visibleTagDrawerMode) {
                                        _TodoPanelDrawerMode.tagManagement =>
                                          TagManagementDrawer(
                                            key: const ValueKey<String>(
                                              'tag-management-drawer-content',
                                            ),
                                            controller: widget.controller,
                                            isOpen: isTagManagementOpen,
                                            borderOnLeft: !tagDrawerOnLeft,
                                            onClose: _closeActiveDrawer,
                                            closeFocusNode:
                                                _tagManagementCloseFocusNode,
                                          ),
                                        _TodoPanelDrawerMode.tagAssignment =>
                                          TagFilterDrawer.assignment(
                                            key: const ValueKey<String>(
                                              'tag-assignment-drawer-content',
                                            ),
                                            controller: widget.controller,
                                            selectedTagIds: _todoEditorTagIds,
                                            borderOnLeft: !tagDrawerOnLeft,
                                            onToggled: _toggleTodoEditorTag,
                                            onManageTags:
                                                _openTagManagementFromTagAssignment,
                                            onClose: _closeActiveDrawer,
                                            closeFocusNode:
                                                _tagAssignmentCloseFocusNode,
                                          ),
                                        _ => TagFilterDrawer.filter(
                                          key: const ValueKey<String>(
                                            'tag-filter-drawer-content',
                                          ),
                                          controller: widget.controller,
                                          selectedTagIds: _selectedTagIds,
                                          borderOnLeft: !tagDrawerOnLeft,
                                          onToggled: _toggleTagFilter,
                                          onClear: _clearTagFilters,
                                          onManageTags: _openTagManagement,
                                          onClose: _closeActiveDrawer,
                                          closeFocusNode:
                                              _tagFilterCloseFocusNode,
                                        ),
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.activeCount,
    required this.onOpenStickyBoards,
    required this.onOpenSettings,
    required this.onCollapse,
  });

  final int activeCount;
  final VoidCallback onOpenStickyBoards;
  final VoidCallback onOpenSettings;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final localizations = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      child: Row(
        children: <Widget>[
          const _MiniMark(),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              activeCount == 0
                  ? localizations.allClearToday
                  : localizations.activeTodoCount(activeCount),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.53),
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            key: const Key('sticky-boards-button'),
            tooltip: localizations.stickyBoardsTooltip,
            onPressed: onOpenStickyBoards,
            icon: const Icon(Icons.sticky_note_2_outlined, size: 19),
          ),
          IconButton(
            key: const Key('settings-button'),
            tooltip: localizations.settingsTooltip,
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, size: 19),
          ),
          IconButton(
            key: const Key('collapse-button'),
            tooltip: localizations.collapseTooltip,
            onPressed: onCollapse,
            icon: const Icon(Icons.unfold_less_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MiniMark extends StatelessWidget {
  const _MiniMark();

  @override
  Widget build(BuildContext context) {
    return const FloatickBrandMark(key: ValueKey('panel-brand-mark'), size: 38);
  }
}

class _ScopePicker extends StatelessWidget {
  const _ScopePicker({
    required this.scope,
    required this.activeCount,
    required this.archivedCount,
    required this.reduceMotion,
    required this.onChanged,
  });

  final TodoListScope scope;
  final int activeCount;
  final int archivedCount;
  final bool reduceMotion;
  final ValueChanged<TodoListScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: <Widget>[
          _ScopeButton(
            label: context.l10n.activeScopeLabel,
            count: activeCount,
            selected: scope == TodoListScope.active,
            reduceMotion: reduceMotion,
            onPressed: () => onChanged(TodoListScope.active),
          ),
          _ScopeButton(
            label: context.l10n.archiveScopeLabel,
            count: archivedCount,
            selected: scope == TodoListScope.archived,
            reduceMotion: reduceMotion,
            onPressed: () => onChanged(TodoListScope.archived),
          ),
        ],
      ),
    );
  }
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.reduceMotion,
    required this.onPressed,
  });

  final String label;
  final int count;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected && !isDark
                    ? <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$label  $count',
                style: TextStyle(
                  color: selected
                      ? onSurface
                      : onSurface.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.dismissErrorTooltip,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.controller,
    required this.scope,
    required this.query,
    required this.selectedTagIds,
    required this.onClearTagFilters,
    required this.onOpenTagManagement,
    required this.onOpenDetails,
    required this.onEditTodo,
    required this.onDeleteTodo,
  });

  final TodoViewModel controller;
  final TodoListScope scope;
  final String query;
  final Set<String> selectedTagIds;
  final VoidCallback onClearTagFilters;
  final VoidCallback onOpenTagManagement;
  final ValueChanged<String> onOpenDetails;
  final ValueChanged<String> onEditTodo;
  final ValueChanged<String> onDeleteTodo;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final entries = _buildEntries(context);
    if (entries.isEmpty) {
      return _EmptyList(
        scope: scope,
        hasQuery: query.isNotEmpty || selectedTagIds.isNotEmpty,
        onClearTagFilters: selectedTagIds.isEmpty ? null : onClearTagFilters,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          _DateEntry() => _DateDivider(label: entry.label),
          _ItemEntry() => TodoListRow(
            key: ValueKey<String>(entry.item.id),
            item: entry.item,
            archivedScope: scope == TodoListScope.archived,
            onToggle: () =>
                unawaited(controller.toggleCompletion(entry.item.id)),
            onOpenDetails: () => onOpenDetails(entry.item.id),
            onEdit: scope == TodoListScope.archived
                ? null
                : () => onEditTodo(entry.item.id),
            onArchive: () => unawaited(controller.archive(entry.item.id)),
            onRestore: () => unawaited(controller.restore(entry.item.id)),
            tags: controller.tags,
            assignedTagIds: controller.tagIdsForTodo(entry.item.id),
            onToggleTag: scope == TodoListScope.archived
                ? null
                : (tagId) => controller.toggleTagForTodo(
                    todoId: entry.item.id,
                    tagId: tagId,
                  ),
            onOpenTagManagement: scope == TodoListScope.archived
                ? null
                : onOpenTagManagement,
            onDeletePermanently: scope == TodoListScope.archived
                ? () => onDeleteTodo(entry.item.id)
                : null,
          ),
        };
      },
    );
  }

  List<_ListEntry> _buildEntries(BuildContext context) {
    final archived = scope == TodoListScope.archived;
    final items = controller.itemsForView(
      archived: archived,
      query: query,
      selectedTagIds: selectedTagIds,
    );

    DateTime relevantDate(TodoItem item) {
      if (archived) {
        return (item.archivedAt ?? item.createdAt).toLocal();
      }
      return item.createdAt.toLocal();
    }

    final entries = <_ListEntry>[];
    DateTime? previousDay;
    for (final item in items) {
      final date = relevantDate(item);
      final day = DateTime(date.year, date.month, date.day);
      if (day != previousDay) {
        entries.add(_DateEntry(_formatDay(context, day)));
        previousDay = day;
      }
      entries.add(_ItemEntry(item));
    }
    return entries;
  }
}

sealed class _ListEntry {
  const _ListEntry();
}

class _DateEntry extends _ListEntry {
  const _DateEntry(this.label);

  final String label;
}

class _ItemEntry extends _ListEntry {
  const _ItemEntry(this.item);

  final TodoItem item;
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.48);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 13, 8, 7),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(height: 1, color: color.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.scope,
    required this.hasQuery,
    this.onClearTagFilters,
  });

  final TodoListScope scope;
  final bool hasQuery;
  final VoidCallback? onClearTagFilters;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isArchive = scope == TodoListScope.archived;
    final localizations = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : (isArchive
                          ? Icons.inventory_2_outlined
                          : Icons.check_rounded),
                color: Theme.of(context).colorScheme.primary,
                size: 27,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              hasQuery
                  ? localizations.noSearchResultsTitle
                  : (isArchive
                        ? localizations.emptyArchiveTitle
                        : localizations.emptyTodosTitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              hasQuery
                  ? localizations.noSearchResultsMessage
                  : (isArchive
                        ? localizations.emptyArchiveMessage
                        : localizations.emptyTodosMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.40),
                fontSize: 12,
              ),
            ),
            if (onClearTagFilters != null) ...[
              const SizedBox(height: 10),
              TextButton(
                key: const Key('clear-active-tag-filters'),
                onPressed: onClearTagFilters,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(localizations.clearTagFilterTooltip),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDay(BuildContext context, DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) {
    return context.l10n.todayLabel;
  }
  if (difference == 1) {
    return context.l10n.yesterdayLabel;
  }

  return MaterialLocalizations.of(context).formatFullDate(day);
}

class _CollapseIntent extends Intent {
  const _CollapseIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _NewTodoIntent extends Intent {
  const _NewTodoIntent();
}
