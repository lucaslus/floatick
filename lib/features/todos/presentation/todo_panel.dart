import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

import '../../../app/theme/floatick_theme.dart';
import '../../../core/platform/window_bridge.dart';
import '../../../core/ui/floatick_brand_mark.dart';
import '../../../core/ui/floatick_surface_metrics.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/storage_failure_localizations.dart';
import '../../notes/presentation/note_editor_drawer.dart';
import '../../notes/presentation/note_panel_content.dart';
import '../../notes/presentation/note_view_model.dart';
import '../../settings/presentation/settings_drawer.dart';
import '../../settings/presentation/settings_view_model.dart';
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
const double _editorDrawerHeight = 590;
const Duration _drawerSlideDuration = Duration(milliseconds: 220);
const Duration _drawerScrimDuration = Duration(milliseconds: 160);
const Duration _scrollHoverResumeDelay = Duration(milliseconds: 120);
const double _todoListCacheExtentViewportFraction = 0.75;

enum TodoListScope { active, archived }

enum _PanelContentKind { todos, notes }

enum _TodoPanelDrawerMode {
  none,
  settings,
  tagFilter,
  tagAssignment,
  tagManagement,
  createTodo,
  todoDetails,
  editTodo,
  createNote,
  editNote,
}

enum _TodoPanelDrawerFamily { settings, tags, todoEditor, noteEditor }

class TodoPanel extends StatefulWidget {
  const TodoPanel({
    required this.controller,
    this.noteController,
    required this.settingsController,
    required this.updateController,
    required this.windowBridge,
    required this.expansionAnchor,
    required this.onCollapse,
    super.key,
  });

  final TodoViewModel controller;
  final NoteViewModel? noteController;
  final SettingsViewModel settingsController;
  final UpdateViewModel updateController;
  final WindowBridge windowBridge;
  final WindowExpansionAnchor expansionAnchor;
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
  final _todoDrawerCloseFocusNode = FocusNode();
  final _noteDrawerCloseFocusNode = FocusNode();
  GlobalKey<NoteEditorDrawerState> _noteEditorKey =
      GlobalKey<NoteEditorDrawerState>();

  _PanelContentKind _contentKind = _PanelContentKind.todos;
  TodoListScope _scope = TodoListScope.active;
  TodoProgressFilter _progressFilter = TodoProgressFilter.all;
  bool _noteArchived = false;
  String _query = '';
  final Set<String> _selectedTagIds = <String>{};
  String? _selectedTodoId;
  _TodoPanelDrawerMode _drawerMode = _TodoPanelDrawerMode.none;
  _TodoPanelDrawerMode? _pendingDrawerMode;
  _TodoPanelDrawerMode _lastTagDrawerMode = _TodoPanelDrawerMode.tagFilter;
  _TodoPanelDrawerMode _lastTodoDrawerMode = _TodoPanelDrawerMode.createTodo;
  _TodoPanelDrawerMode? _tagManagementReturnMode;
  _TodoPanelDrawerMode? _tagAssignmentReturnMode;
  Set<String> _todoEditorTagIds = <String>{};
  Set<String> _noteEditorTagIds = <String>{};
  final Set<_TodoPanelDrawerFamily> _mountedDrawerFamilies =
      <_TodoPanelDrawerFamily>{};
  int _todoEditorSession = 0;
  String? _selectedNoteId;
  int _drawerRequestSerial = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _panelFocusNode.dispose();
    _searchFocusNode.dispose();
    _settingsCloseFocusNode.dispose();
    _tagFilterCloseFocusNode.dispose();
    _tagAssignmentCloseFocusNode.dispose();
    _tagManagementCloseFocusNode.dispose();
    _todoDrawerCloseFocusNode.dispose();
    _noteDrawerCloseFocusNode.dispose();
    super.dispose();
  }

  void _openSettings() {
    _showDrawer(_TodoPanelDrawerMode.settings);
  }

  void _toggleArchiveScope() {
    setState(() {
      _scope = _scope == TodoListScope.active
          ? TodoListScope.archived
          : TodoListScope.active;
      if (_scope == TodoListScope.archived) {
        _progressFilter = TodoProgressFilter.all;
      }
    });
  }

  void _toggleDoingFilter() {
    if (_contentKind != _PanelContentKind.todos ||
        _scope != TodoListScope.active) {
      return;
    }
    setState(() {
      _progressFilter = _progressFilter == TodoProgressFilter.doing
          ? TodoProgressFilter.all
          : TodoProgressFilter.doing;
    });
  }

  void _openTagFilter() {
    _showDrawer(_TodoPanelDrawerMode.tagFilter);
  }

  void _selectContentKind(_PanelContentKind kind) {
    if (_contentKind == kind || _drawerMode != _TodoPanelDrawerMode.none) {
      return;
    }
    _searchController.clear();
    setState(() {
      _contentKind = kind;
      _query = '';
      if (kind == _PanelContentKind.notes) {
        _progressFilter = TodoProgressFilter.all;
      }
    });
  }

  void _toggleNoteArchive() {
    setState(() => _noteArchived = !_noteArchived);
  }

  void _openNoteCreate() {
    if (widget.noteController == null) {
      return;
    }
    _showNoteDrawer(
      _TodoPanelDrawerMode.createNote,
      initialTagIds: const <String>[],
    );
  }

  void _openNote(String noteId) {
    if (widget.noteController?.itemById(noteId) == null) {
      return;
    }
    _showNoteDrawer(
      _TodoPanelDrawerMode.editNote,
      noteId: noteId,
      initialTagIds: widget.noteController!.itemById(noteId)!.tagIds,
    );
  }

  void _showNoteDrawer(
    _TodoPanelDrawerMode mode, {
    required Iterable<String> initialTagIds,
    String? noteId,
  }) {
    assert(
      mode == _TodoPanelDrawerMode.createNote ||
          mode == _TodoPanelDrawerMode.editNote,
    );
    final requestSerial = ++_drawerRequestSerial;
    _noteEditorKey = GlobalKey<NoteEditorDrawerState>();
    final needsMount = !_mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.noteEditor,
    );
    setState(() {
      _selectedNoteId = noteId;
      _noteEditorTagIds = initialTagIds.toSet();
      if (needsMount) {
        _mountedDrawerFamilies.add(_TodoPanelDrawerFamily.noteEditor);
        _pendingDrawerMode = mode;
      } else {
        _pendingDrawerMode = null;
        _drawerMode = mode;
      }
      if (mode == _TodoPanelDrawerMode.createNote) {
        _noteArchived = false;
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

  void _openTagManagement() {
    _tagManagementReturnMode = null;
    _tagAssignmentReturnMode = null;
    _showDrawer(_TodoPanelDrawerMode.tagManagement);
  }

  void _openTodoCreate() {
    _showTodoDrawer(
      _TodoPanelDrawerMode.createTodo,
      initialTagIds: const <String>[],
      startsNewSession: true,
    );
  }

  void _openTodoDetails(String todoId) {
    _showTodoDrawer(
      _TodoPanelDrawerMode.todoDetails,
      todoId: todoId,
      initialTagIds: widget.controller.tagIdsForTodo(todoId),
    );
  }

  void _openTodoEdit(String todoId) {
    _showTodoDrawer(
      _TodoPanelDrawerMode.editTodo,
      todoId: todoId,
      initialTagIds: widget.controller.tagIdsForTodo(todoId),
    );
  }

  Future<void> _deleteArchivedTodoPermanently(String todoId) async {
    final deleted = await widget.controller.deletePermanently(todoId);
    if (deleted && mounted && _selectedTodoId == todoId) {
      _closeActiveDrawer();
    }
  }

  Future<bool> _saveCreatedTodo({
    required String title,
    required String content,
    required Iterable<String> tagIds,
  }) async {
    final item = await widget.controller.create(
      title,
      content: content,
      tagIds: tagIds,
    );
    return item != null;
  }

  void _openTagAssignmentFromEditor() {
    if (_drawerMode != _TodoPanelDrawerMode.createTodo &&
        _drawerMode != _TodoPanelDrawerMode.editTodo &&
        _drawerMode != _TodoPanelDrawerMode.createNote &&
        _drawerMode != _TodoPanelDrawerMode.editNote) {
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

  void _toggleEditorTag(String tagId) {
    if (widget.controller.tagById(tagId) == null) {
      return;
    }
    setState(() {
      final isNoteAssignment =
          _tagAssignmentReturnMode == _TodoPanelDrawerMode.createNote ||
          _tagAssignmentReturnMode == _TodoPanelDrawerMode.editNote;
      final editorTagIds = isNoteAssignment
          ? _noteEditorTagIds
          : _todoEditorTagIds;
      if (!editorTagIds.add(tagId)) {
        editorTagIds.remove(tagId);
      }
    });
  }

  void _unfocusDrawerControls() {
    _settingsCloseFocusNode.unfocus();
    _tagFilterCloseFocusNode.unfocus();
    _tagAssignmentCloseFocusNode.unfocus();
    _tagManagementCloseFocusNode.unfocus();
    _todoDrawerCloseFocusNode.unfocus();
    _noteDrawerCloseFocusNode.unfocus();
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
        _TodoPanelDrawerMode.none ||
        _TodoPanelDrawerMode.tagManagement ||
        _TodoPanelDrawerMode.createTodo ||
        _TodoPanelDrawerMode.todoDetails ||
        _TodoPanelDrawerMode.editTodo ||
        _TodoPanelDrawerMode.createNote ||
        _TodoPanelDrawerMode.editNote => null,
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
      if (_isNoteDrawerMode(closedMode)) {
        _selectedNoteId = null;
        _noteEditorTagIds = <String>{};
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

  Future<void> _requestCloseActiveDrawer() async {
    if (_isNoteDrawerMode(_drawerMode)) {
      final canClose = await _noteEditorKey.currentState?.flush() ?? true;
      if (!canClose || !mounted) {
        return;
      }
    }
    _closeActiveDrawer();
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

  bool _isNoteDrawerMode(_TodoPanelDrawerMode mode) {
    return mode == _TodoPanelDrawerMode.createNote ||
        mode == _TodoPanelDrawerMode.editNote;
  }

  _TodoPanelDrawerFamily? _drawerFamilyFor(_TodoPanelDrawerMode mode) {
    return switch (mode) {
      _TodoPanelDrawerMode.settings => _TodoPanelDrawerFamily.settings,
      _TodoPanelDrawerMode.tagFilter ||
      _TodoPanelDrawerMode.tagAssignment ||
      _TodoPanelDrawerMode.tagManagement => _TodoPanelDrawerFamily.tags,
      _TodoPanelDrawerMode.createTodo ||
      _TodoPanelDrawerMode.todoDetails ||
      _TodoPanelDrawerMode.editTodo => _TodoPanelDrawerFamily.todoEditor,
      _TodoPanelDrawerMode.createNote ||
      _TodoPanelDrawerMode.editNote => _TodoPanelDrawerFamily.noteEditor,
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
    final isTodoDrawerOpen =
        _drawerMode == _TodoPanelDrawerMode.createTodo ||
        _drawerMode == _TodoPanelDrawerMode.todoDetails ||
        _drawerMode == _TodoPanelDrawerMode.editTodo;
    final isNoteDrawerOpen =
        _drawerMode == _TodoPanelDrawerMode.createNote ||
        _drawerMode == _TodoPanelDrawerMode.editNote;
    final hasSettingsDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.settings,
    );
    final hasTagDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.tags,
    );
    final hasTodoDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.todoEditor,
    );
    final hasNoteDrawer = _mountedDrawerFamilies.contains(
      _TodoPanelDrawerFamily.noteEditor,
    );
    final isEditorContextOverlayOpen =
        isTagAssignmentOpen ||
        (isTagManagementOpen &&
            _tagManagementReturnMode == _TodoPanelDrawerMode.tagAssignment);
    final tagAssignmentOwner = _tagAssignmentReturnMode;
    final isTodoTagContext =
        isEditorContextOverlayOpen &&
        (tagAssignmentOwner == _TodoPanelDrawerMode.createTodo ||
            tagAssignmentOwner == _TodoPanelDrawerMode.editTodo);
    final isNoteTagContext =
        isEditorContextOverlayOpen &&
        (tagAssignmentOwner == _TodoPanelDrawerMode.createNote ||
            tagAssignmentOwner == _TodoPanelDrawerMode.editNote);
    final isTodoDrawerVisible = isTodoDrawerOpen || isTodoTagContext;
    final isNoteDrawerVisible = isNoteDrawerOpen || isNoteTagContext;
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
    final selectedNote = _selectedNoteId == null
        ? null
        : widget.noteController?.itemById(_selectedNoteId!);
    final todoEditorTagIds = widget.controller.tags
        .where((tag) => _todoEditorTagIds.contains(tag.id))
        .map((tag) => tag.id)
        .toList(growable: false);
    final noteEditorTagIds = widget.controller.tags
        .where((tag) => _noteEditorTagIds.contains(tag.id))
        .map((tag) => tag.id)
        .toList(growable: false);
    final assignmentTagIds = isNoteTagContext
        ? _noteEditorTagIds
        : _todoEditorTagIds;
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
                unawaited(_requestCloseActiveDrawer());
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
              switch (_contentKind) {
                case _PanelContentKind.notes:
                  _openNoteCreate();
                case _PanelContentKind.todos:
                  _openTodoCreate();
              }
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
                        ? FloatickColors.darkSurface
                        : FloatickColors.lightSurface,
                    borderRadius: BorderRadius.circular(
                      FloatickSurfaceMetrics.panelRadius,
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.09)
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
                            animation: Listenable.merge(<Listenable>[
                              widget.controller,
                              if (widget.noteController != null)
                                widget.noteController!,
                            ]),
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
                                    scope: _scope,
                                    activeCount: widget.controller.activeCount,
                                    archivedCount:
                                        widget.controller.archivedCount,
                                    contentKind: _contentKind,
                                    noteArchived: _noteArchived,
                                    noteActiveCount:
                                        widget.noteController?.activeCount ?? 0,
                                    noteArchivedCount:
                                        widget.noteController?.archivedCount ??
                                        0,
                                    onToggleArchive: _toggleArchiveScope,
                                    onToggleNoteArchive: _toggleNoteArchive,
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
                                    child: _ContentSwitcher(
                                      selected: _contentKind,
                                      showNotes: widget.noteController != null,
                                      onSelected: _selectContentKind,
                                    ),
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
                                                  hintText: switch (_contentKind) {
                                                    _PanelContentKind.notes =>
                                                      _noteArchived
                                                          ? context
                                                                .l10n
                                                                .searchNoteArchiveHint
                                                          : context
                                                                .l10n
                                                                .searchNotesHint,
                                                    _PanelContentKind.todos =>
                                                      _scope ==
                                                              TodoListScope
                                                                  .active
                                                          ? context
                                                                .l10n
                                                                .searchTodosHint
                                                          : context
                                                                .l10n
                                                                .searchArchiveHint,
                                                  },
                                                  prefixIcon: const Icon(
                                                    Icons.search_rounded,
                                                    size: 17,
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
                                            if (_contentKind ==
                                                    _PanelContentKind.todos &&
                                                _scope ==
                                                    TodoListScope.active) ...[
                                              _DoingFilterButton(
                                                selected:
                                                    _progressFilter ==
                                                    TodoProgressFilter.doing,
                                                onPressed: _toggleDoingFilter,
                                              ),
                                              const SizedBox(width: 9),
                                            ],
                                            TagFilterButton(
                                              selectedCount:
                                                  effectiveSelectedTagIds
                                                      .length,
                                              onPressed: _openTagFilter,
                                            ),
                                            if ((_contentKind ==
                                                        _PanelContentKind
                                                            .todos &&
                                                    _scope ==
                                                        TodoListScope.active) ||
                                                (_contentKind ==
                                                        _PanelContentKind
                                                            .notes &&
                                                    !_noteArchived)) ...[
                                              const SizedBox(width: 9),
                                              SizedBox(
                                                height: 42,
                                                width: 42,
                                                child: IconButton(
                                                  key: Key(
                                                    switch (_contentKind) {
                                                      _PanelContentKind.notes =>
                                                        'add-note-button',
                                                      _PanelContentKind.todos =>
                                                        'add-todo-button',
                                                    },
                                                  ),
                                                  onPressed:
                                                      switch (_contentKind) {
                                                        _PanelContentKind
                                                            .notes =>
                                                          _openNoteCreate,
                                                        _PanelContentKind
                                                            .todos =>
                                                          _openTodoCreate,
                                                      },
                                                  tooltip:
                                                      switch (_contentKind) {
                                                        _PanelContentKind
                                                            .notes =>
                                                          context
                                                              .l10n
                                                              .newNoteAction,
                                                        _PanelContentKind
                                                            .todos =>
                                                          context
                                                              .l10n
                                                              .newTodoAction,
                                                      },
                                                  style: IconButton.styleFrom(
                                                    foregroundColor: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: isDark
                                                                  ? 0.025
                                                                  : 0.04,
                                                            ),
                                                    side: BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                            alpha: isDark
                                                                ? 0.42
                                                                : 0.32,
                                                          ),
                                                    ),
                                                    minimumSize:
                                                        const Size.square(42),
                                                    maximumSize:
                                                        const Size.square(42),
                                                    padding: EdgeInsets.zero,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.add_rounded,
                                                    size: 17,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_contentKind == _PanelContentKind.todos &&
                                      widget.controller.error != null)
                                    _ErrorBanner(
                                      message: context.l10n
                                          .messageForStorageFailure(
                                            widget.controller.error!,
                                          ),
                                      onDismiss: widget.controller.dismissError,
                                    ),
                                  if (_contentKind == _PanelContentKind.notes &&
                                      widget.noteController?.error != null)
                                    _ErrorBanner(
                                      message: context.l10n
                                          .messageForStorageFailure(
                                            widget.noteController!.error!,
                                          ),
                                      onDismiss:
                                          widget.noteController!.dismissError,
                                    ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.07)
                                        : Colors.black.withValues(alpha: 0.055),
                                  ),
                                  Expanded(
                                    child: switch (_contentKind) {
                                      _PanelContentKind.notes =>
                                        NotePanelContent(
                                          controller: widget.noteController!,
                                          archived: _noteArchived,
                                          query: _query,
                                          availableTags: widget.controller.tags,
                                          selectedTagIds:
                                              effectiveSelectedTagIds,
                                          onOpen: _openNote,
                                        ),
                                      _PanelContentKind.todos => _TodoList(
                                        controller: widget.controller,
                                        scope: _scope,
                                        query: _query,
                                        progressFilter: _progressFilter,
                                        selectedTagIds: effectiveSelectedTagIds,
                                        onClearDoingFilter: _toggleDoingFilter,
                                        onClearTagFilters: _clearTagFilters,
                                        onOpenTagManagement: _openTagManagement,
                                        onOpenDetails: _openTodoDetails,
                                        onEditTodo: _openTodoEdit,
                                        onDeleteTodo:
                                            _deleteArchivedTodoPermanently,
                                      ),
                                    },
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
                                  onTap: () =>
                                      unawaited(_requestCloseActiveDrawer()),
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
                        if (hasTodoDrawer)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: _editorDrawerHeight,
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
                                            _openTagAssignmentFromEditor,
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
                        if (hasNoteDrawer)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: _editorDrawerHeight,
                            child: IgnorePointer(
                              key: const Key('note-drawer-pointer'),
                              ignoring: !isNoteDrawerOpen,
                              child: ExcludeFocus(
                                excluding: !isNoteDrawerOpen,
                                child: ExcludeSemantics(
                                  excluding: !isNoteDrawerOpen,
                                  child: AnimatedSlide(
                                    key: const Key('note-drawer-slide'),
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : _drawerSlideDuration,
                                    curve: Curves.easeOutCubic,
                                    offset: isNoteDrawerVisible
                                        ? Offset.zero
                                        : const Offset(0, 1),
                                    child: FocusTraversalGroup(
                                      child: NoteEditorDrawer(
                                        key: _noteEditorKey,
                                        item: selectedNote,
                                        availableTags: widget.controller.tags,
                                        assignedTagIds: noteEditorTagIds,
                                        isOpen: isNoteDrawerOpen,
                                        onOpenTagAssignment:
                                            _openTagAssignmentFromEditor,
                                        onSave:
                                            ({
                                              id,
                                              required title,
                                              required content,
                                              required tagIds,
                                            }) {
                                              return widget.noteController!
                                                  .save(
                                                    id: id,
                                                    title: title,
                                                    content: content,
                                                    tagIds: tagIds,
                                                  );
                                            },
                                        onClose: _closeActiveDrawer,
                                        closeFocusNode:
                                            _noteDrawerCloseFocusNode,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if ((hasTodoDrawer || hasNoteDrawer) && hasTagDrawer)
                          Positioned.fill(
                            child: IgnorePointer(
                              key: const Key('todo-context-scrim-pointer'),
                              ignoring: !isEditorContextOverlayOpen,
                              child: ExcludeSemantics(
                                child: AnimatedOpacity(
                                  key: const Key('todo-context-scrim'),
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : _drawerScrimDuration,
                                  curve: Curves.easeOut,
                                  opacity: isEditorContextOverlayOpen ? 1 : 0,
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
                                            additionalUsageCounts:
                                                widget.noteController
                                                    ?.tagUsageCountsFor(
                                                      widget.controller.tags
                                                          .map((tag) => tag.id),
                                                    ) ??
                                                const <String, int>{},
                                            onTagDeleted: widget
                                                .noteController
                                                ?.removeTag,
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
                                            selectedTagIds: assignmentTagIds,
                                            borderOnLeft: !tagDrawerOnLeft,
                                            onToggled: _toggleEditorTag,
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
                                          usageCounts:
                                              _contentKind ==
                                                  _PanelContentKind.notes
                                              ? widget.noteController
                                                    ?.tagUsageCountsFor(
                                                      widget.controller.tags
                                                          .map((tag) => tag.id),
                                                    )
                                              : null,
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

class _ContentSwitcher extends StatelessWidget {
  const _ContentSwitcher({
    required this.selected,
    required this.showNotes,
    required this.onSelected,
  });

  final _PanelContentKind selected;
  final bool showNotes;
  final ValueChanged<_PanelContentKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: <Widget>[
          _ContentSwitcherButton(
            key: const Key('todo-tab'),
            label: context.l10n.todoTabLabel,
            selected: selected == _PanelContentKind.todos,
            onPressed: () => onSelected(_PanelContentKind.todos),
          ),
          if (showNotes) ...[
            const SizedBox(width: 3),
            _ContentSwitcherButton(
              key: const Key('note-tab'),
              label: context.l10n.notesTabLabel,
              selected: selected == _PanelContentKind.notes,
              onPressed: () => onSelected(_PanelContentKind.notes),
            ),
          ],
        ],
      ),
    );
  }
}

class _DoingFilterButton extends StatelessWidget {
  const _DoingFilterButton({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return Semantics(
      selected: selected,
      child: SizedBox.square(
        dimension: 42,
        child: IconButton(
          key: const Key('doing-filter-button'),
          tooltip: selected
              ? context.l10n.clearDoingFilterTooltip
              : context.l10n.filterDoingTooltip,
          isSelected: selected,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(42),
            maximumSize: const Size.square(42),
            padding: EdgeInsets.zero,
            foregroundColor: selected
                ? primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.62),
            backgroundColor: selected
                ? primary.withValues(alpha: isDark ? 0.13 : 0.10)
                : isDark
                ? theme.inputDecorationTheme.fillColor
                : const Color(0xFFF0F4F2),
            side: BorderSide(
              color: selected
                  ? primary.withValues(alpha: isDark ? 0.46 : 0.36)
                  : isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.045),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.timelapse_rounded, size: 17),
        ),
      ),
    );
  }
}

class _ContentSwitcherButton extends StatefulWidget {
  const _ContentSwitcherButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_ContentSwitcherButton> createState() => _ContentSwitcherButtonState();
}

class _ContentSwitcherButtonState extends State<_ContentSwitcherButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hoverColor = widget.selected
        ? theme.colorScheme.primary.withValues(alpha: 0.055)
        : theme.colorScheme.onSurface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.055 : 0.035,
          );
    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.selected,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              key: const Key('content-tab-hover-surface'),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: _isHovered ? hoverColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(8),
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                child: Center(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: widget.selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w500,
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
    required this.scope,
    required this.activeCount,
    required this.archivedCount,
    required this.contentKind,
    required this.noteArchived,
    required this.noteActiveCount,
    required this.noteArchivedCount,
    required this.onToggleArchive,
    required this.onToggleNoteArchive,
    required this.onOpenSettings,
    required this.onCollapse,
  });

  final TodoListScope scope;
  final int activeCount;
  final int archivedCount;
  final _PanelContentKind contentKind;
  final bool noteArchived;
  final int noteActiveCount;
  final int noteArchivedCount;
  final VoidCallback onToggleArchive;
  final VoidCallback onToggleNoteArchive;
  final VoidCallback onOpenSettings;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final localizations = context.l10n;
    final archiveSelected = switch (contentKind) {
      _PanelContentKind.notes => noteArchived,
      _PanelContentKind.todos => scope == TodoListScope.archived,
    };
    final statusText = switch (contentKind) {
      _PanelContentKind.notes =>
        noteArchived
            ? '${localizations.archiveScopeLabel} · $noteArchivedCount'
            : localizations.noteCountLabel(noteActiveCount),
      _PanelContentKind.todos =>
        scope == TodoListScope.archived
            ? '${localizations.archiveScopeLabel} · $archivedCount'
            : activeCount == 0
            ? localizations.allClearToday
            : localizations.activeTodoCount(activeCount),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      child: Row(
        children: <Widget>[
          const _MiniMark(),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.62),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Semantics(
            selected: archiveSelected,
            child: IconButton(
              key: const Key('archive-scope-button'),
              tooltip: archiveSelected
                  ? localizations.activeScopeLabel
                  : localizations.archiveScopeLabel,
              onPressed: contentKind == _PanelContentKind.notes
                  ? onToggleNoteArchive
                  : onToggleArchive,
              color: archiveSelected
                  ? Theme.of(context).colorScheme.primary
                  : null,
              icon: Icon(
                archiveSelected
                    ? Icons.archive_rounded
                    : Icons.archive_outlined,
                size: 17,
              ),
            ),
          ),
          IconButton(
            key: const Key('settings-button'),
            tooltip: localizations.settingsTooltip,
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, size: 17),
          ),
          IconButton(
            key: const Key('collapse-button'),
            tooltip: localizations.collapseTooltip,
            onPressed: onCollapse,
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
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

class _TodoList extends StatefulWidget {
  const _TodoList({
    required this.controller,
    required this.scope,
    required this.query,
    required this.progressFilter,
    required this.selectedTagIds,
    required this.onClearDoingFilter,
    required this.onClearTagFilters,
    required this.onOpenTagManagement,
    required this.onOpenDetails,
    required this.onEditTodo,
    required this.onDeleteTodo,
  });

  final TodoViewModel controller;
  final TodoListScope scope;
  final String query;
  final TodoProgressFilter progressFilter;
  final Set<String> selectedTagIds;
  final VoidCallback onClearDoingFilter;
  final VoidCallback onClearTagFilters;
  final VoidCallback onOpenTagManagement;
  final ValueChanged<String> onOpenDetails;
  final ValueChanged<String> onEditTodo;
  final ValueChanged<String> onDeleteTodo;

  @override
  State<_TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<_TodoList> {
  List<TodoItem>? _cachedItems;
  List<_ListEntry> _cachedEntries = const <_ListEntry>[];
  Locale? _cachedLocale;
  DateTime? _cachedToday;
  bool? _cachedArchived;

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading) {
      return const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final entries = _buildEntries(context);
    if (entries.isEmpty) {
      final hasSearchOrTagFilters =
          widget.query.isNotEmpty || widget.selectedTagIds.isNotEmpty;
      return _EmptyList(
        scope: widget.scope,
        hasQuery: hasSearchOrTagFilters,
        doingOnly:
            widget.progressFilter == TodoProgressFilter.doing &&
            widget.scope == TodoListScope.active,
        onClearDoingFilter: hasSearchOrTagFilters
            ? null
            : widget.onClearDoingFilter,
        onClearTagFilters: widget.selectedTagIds.isEmpty
            ? null
            : widget.onClearTagFilters,
      );
    }

    return _ScrollableTodoEntries(
      entries: entries,
      controller: widget.controller,
      scope: widget.scope,
      onOpenTagManagement: widget.onOpenTagManagement,
      onOpenDetails: widget.onOpenDetails,
      onEditTodo: widget.onEditTodo,
      onDeleteTodo: widget.onDeleteTodo,
    );
  }

  List<_ListEntry> _buildEntries(BuildContext context) {
    final archived = widget.scope == TodoListScope.archived;
    final items = widget.controller.itemsForView(
      archived: archived,
      query: widget.query,
      selectedTagIds: widget.selectedTagIds,
      progressFilter: archived ? TodoProgressFilter.all : widget.progressFilter,
    );
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (identical(items, _cachedItems) &&
        locale == _cachedLocale &&
        today == _cachedToday &&
        archived == _cachedArchived) {
      return _cachedEntries;
    }

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
    _cachedItems = items;
    _cachedEntries = List<_ListEntry>.unmodifiable(entries);
    _cachedLocale = locale;
    _cachedToday = today;
    _cachedArchived = archived;
    return _cachedEntries;
  }
}

class _ScrollableTodoEntries extends StatefulWidget {
  const _ScrollableTodoEntries({
    required this.entries,
    required this.controller,
    required this.scope,
    required this.onOpenTagManagement,
    required this.onOpenDetails,
    required this.onEditTodo,
    required this.onDeleteTodo,
  });

  final List<_ListEntry> entries;
  final TodoViewModel controller;
  final TodoListScope scope;
  final VoidCallback onOpenTagManagement;
  final ValueChanged<String> onOpenDetails;
  final ValueChanged<String> onEditTodo;
  final ValueChanged<String> onDeleteTodo;

  @override
  State<_ScrollableTodoEntries> createState() => _ScrollableTodoEntriesState();
}

class _ScrollableTodoEntriesState extends State<_ScrollableTodoEntries> {
  Timer? _hoverResumeTimer;
  bool _isScrolling = false;

  @override
  void dispose() {
    _hoverResumeTimer?.cancel();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      _hoverResumeTimer?.cancel();
      if (!_isScrolling) {
        setState(() => _isScrolling = true);
      }
    }
    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification ||
        notification is ScrollEndNotification) {
      _scheduleHoverResume();
    }
    return false;
  }

  void _scheduleHoverResume() {
    _hoverResumeTimer?.cancel();
    _hoverResumeTimer = Timer(_scrollHoverResumeDelay, () {
      if (mounted && _isScrolling) {
        setState(() => _isScrolling = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final archived = widget.scope == TodoListScope.archived;
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
        scrollCacheExtent: const ScrollCacheExtent.viewport(
          _todoListCacheExtentViewportFraction,
        ),
        itemCount: widget.entries.length,
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          return switch (entry) {
            _DateEntry() => _DateDivider(label: entry.label),
            _ItemEntry() => TodoListRow(
              key: ValueKey<String>(entry.item.id),
              item: entry.item,
              archivedScope: archived,
              hoverEnabled: !_isScrolling,
              onToggle: () =>
                  unawaited(widget.controller.toggleCompletion(entry.item.id)),
              onToggleDoing: archived
                  ? null
                  : () =>
                        unawaited(widget.controller.toggleDoing(entry.item.id)),
              onOpenDetails: () => widget.onOpenDetails(entry.item.id),
              onEdit: archived ? null : () => widget.onEditTodo(entry.item.id),
              onArchive: () =>
                  unawaited(widget.controller.archive(entry.item.id)),
              onRestore: () =>
                  unawaited(widget.controller.restore(entry.item.id)),
              tags: widget.controller.tags,
              assignedTagIds: widget.controller.tagIdsForTodo(entry.item.id),
              onToggleTag: archived
                  ? null
                  : (tagId) => widget.controller.toggleTagForTodo(
                      todoId: entry.item.id,
                      tagId: tagId,
                    ),
              onOpenTagManagement: archived ? null : widget.onOpenTagManagement,
              onDeletePermanently: archived
                  ? () => widget.onDeleteTodo(entry.item.id)
                  : null,
            ),
          };
        },
      ),
    );
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
    ).colorScheme.onSurface.withValues(alpha: 0.58);
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
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.scope,
    required this.hasQuery,
    required this.doingOnly,
    this.onClearDoingFilter,
    this.onClearTagFilters,
  });

  final TodoListScope scope;
  final bool hasQuery;
  final bool doingOnly;
  final VoidCallback? onClearDoingFilter;
  final VoidCallback? onClearTagFilters;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isArchive = scope == TodoListScope.archived;
    final showDoingEmptyState = doingOnly && !hasQuery;
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
                showDoingEmptyState
                    ? Icons.timelapse_rounded
                    : hasQuery
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
              showDoingEmptyState
                  ? localizations.emptyDoingTodosTitle
                  : hasQuery
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
              showDoingEmptyState
                  ? localizations.emptyDoingTodosMessage
                  : hasQuery
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
            if (onClearDoingFilter != null && showDoingEmptyState) ...[
              const SizedBox(height: 10),
              TextButton(
                key: const Key('clear-doing-filter'),
                onPressed: onClearDoingFilter,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(localizations.clearDoingFilterTooltip),
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
