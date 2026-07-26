import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/window_bridge.dart';
import '../../../core/ui/floatick_brand_mark.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/storage_failure_localizations.dart';
import '../../settings/presentation/settings_drawer.dart';
import '../../settings/presentation/settings_view_model.dart';
import '../../updates/presentation/update_view_model.dart';
import '../domain/todo_item.dart';
import '../domain/todo_tag.dart';
import 'tag_filter_drawer.dart';
import 'tag_management_drawer.dart';
import 'todo_editor_drawer.dart';
import 'todo_view_model.dart';
import 'widgets/floatick_tag_chip.dart';
import 'widgets/tag_menus.dart';

const double _panelWindowInset = 8;
const double _panelOuterRadius = 26;
const double _panelContentRadius = 25;
const double _settingsDrawerWidth = 268;
const double _tagDrawerWidth = 292;
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
  createTodo,
  todoDetails,
  editTodo,
}

class TodoPanel extends StatefulWidget {
  const TodoPanel({
    required this.controller,
    required this.settingsController,
    required this.updateController,
    required this.windowBridge,
    required this.expansionAnchor,
    required this.onCollapse,
    super.key,
  });

  final TodoViewModel controller;
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

  TodoListScope _scope = TodoListScope.active;
  String _query = '';
  String? _selectedTagId;
  String? _selectedTodoId;
  _TodoPanelDrawerMode _drawerMode = _TodoPanelDrawerMode.none;
  _TodoPanelDrawerMode _lastTagDrawerMode = _TodoPanelDrawerMode.tagFilter;
  _TodoPanelDrawerMode _lastTodoDrawerMode = _TodoPanelDrawerMode.createTodo;
  _TodoPanelDrawerMode? _tagManagementReturnMode;
  _TodoPanelDrawerMode? _tagAssignmentReturnMode;
  Set<String> _todoEditorTagIds = <String>{};
  int _todoEditorSession = 0;

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
    super.dispose();
  }

  void _openSettings() {
    _showDrawer(_TodoPanelDrawerMode.settings);
  }

  void _openTagFilter() {
    _showDrawer(_TodoPanelDrawerMode.tagFilter);
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
    _todoDrawerCloseFocusNode.unfocus();
  }

  void _showDrawer(_TodoPanelDrawerMode mode) {
    if (_drawerMode == mode) {
      return;
    }

    _unfocusDrawerControls();
    setState(() {
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
    setState(() {
      if (startsNewSession) {
        _todoEditorSession += 1;
      }
      _drawerMode = mode;
      _lastTodoDrawerMode = mode;
      _selectedTodoId = todoId;
      _todoEditorTagIds = initialTagIds.toSet();
      if (mode == _TodoPanelDrawerMode.createTodo) {
        _scope = TodoListScope.active;
      }
    });
  }

  void _selectTagFilter(String? tagId) {
    _unfocusDrawerControls();
    setState(() {
      _selectedTagId = tagId;
      _drawerMode = _TodoPanelDrawerMode.none;
    });
    _restorePanelFocus();
  }

  void _closeActiveDrawer() {
    if (_drawerMode == _TodoPanelDrawerMode.none) {
      return;
    }

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
    });
    if (returnMode != null) {
      _requestDrawerFocus(returnMode);
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

  void _releaseClosedTodoDrawer(_TodoPanelDrawerMode closedMode) {
    Future<void>.delayed(_drawerSlideDuration, () {
      if (!mounted ||
          _drawerMode != _TodoPanelDrawerMode.none ||
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

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDrawerOpen = _drawerMode != _TodoPanelDrawerMode.none;
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
    final isTodoContextOverlayOpen =
        isTagAssignmentOpen ||
        (isTagManagementOpen &&
            _tagManagementReturnMode == _TodoPanelDrawerMode.tagAssignment);
    final isTodoDrawerVisible = isTodoDrawerOpen || isTodoContextOverlayOpen;
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
                padding: const EdgeInsets.all(_panelWindowInset),
                child: DecoratedBox(
                  key: const Key('todo-panel-surface'),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xF2172024)
                        : const Color(0xF7FAFCFB),
                    borderRadius: BorderRadius.circular(_panelOuterRadius),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_panelContentRadius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ExcludeFocus(
                          excluding: isDrawerOpen,
                          child: AnimatedBuilder(
                            animation: widget.controller,
                            builder: (context, _) {
                              final selectedTag = _selectedTagId == null
                                  ? null
                                  : widget.controller.tagById(_selectedTagId!);
                              final effectiveSelectedTagId = selectedTag?.id;
                              return Column(
                                children: <Widget>[
                                  _PanelHeader(
                                    activeCount: widget.controller.activeCount,
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
                                              selectedTag: selectedTag,
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
                                        if (selectedTag != null) ...[
                                          const SizedBox(height: 9),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: FloatickTagChip(
                                              key: const Key(
                                                'active-tag-filter',
                                              ),
                                              tag: selectedTag,
                                              onDeleted: () {
                                                setState(
                                                  () => _selectedTagId = null,
                                                );
                                              },
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
                                      selectedTagId: effectiveSelectedTagId,
                                      onOpenTagManagement: _openTagManagement,
                                      onOpenDetails: _openTodoDetails,
                                      onEditTodo: _openTodoEdit,
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
                                    workingDirectoryPath:
                                        widget.controller.storageDirectoryPath,
                                    onClose: _closeActiveDrawer,
                                    closeFocusNode: _settingsCloseFocusNode,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                          return widget.controller.add(
                                            title,
                                            content: content,
                                            tagIds: tagIds,
                                          );
                                        }
                                        final todoId = selectedTodo?.id;
                                        if (todoId == null) {
                                          return Future<bool>.value(false);
                                        }
                                        return widget.controller.updateDetails(
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
                                      closeFocusNode: _todoDrawerCloseFocusNode,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                        selectedTagId: _selectedTagId,
                                        borderOnLeft: !tagDrawerOnLeft,
                                        onSelected: _selectTagFilter,
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
    required this.onOpenSettings,
    required this.onCollapse,
  });

  final int activeCount;
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
    required this.selectedTagId,
    required this.onOpenTagManagement,
    required this.onOpenDetails,
    required this.onEditTodo,
  });

  final TodoViewModel controller;
  final TodoListScope scope;
  final String query;
  final String? selectedTagId;
  final VoidCallback onOpenTagManagement;
  final ValueChanged<String> onOpenDetails;
  final ValueChanged<String> onEditTodo;

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
        hasQuery: query.isNotEmpty || selectedTagId != null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          _DateEntry() => _DateDivider(label: entry.label),
          _ItemEntry() => _TodoRow(
            key: ValueKey<String>(entry.item.id),
            item: entry.item,
            archivedScope: scope == TodoListScope.archived,
            onToggle: () =>
                unawaited(controller.toggleCompletion(entry.item.id)),
            onOpenDetails: () => onOpenDetails(entry.item.id),
            onEdit: () => onEditTodo(entry.item.id),
            onArchive: () => unawaited(controller.archive(entry.item.id)),
            onRestore: () => unawaited(controller.restore(entry.item.id)),
            tags: controller.tags,
            assignedTagIds: controller.tagIdsForTodo(entry.item.id),
            onToggleTag: (tagId) => controller.toggleTagForTodo(
              todoId: entry.item.id,
              tagId: tagId,
            ),
            onOpenTagManagement: onOpenTagManagement,
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
      selectedTagId: selectedTagId,
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

class _TodoRow extends StatefulWidget {
  const _TodoRow({
    required this.item,
    required this.archivedScope,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.tags,
    required this.assignedTagIds,
    required this.onToggleTag,
    required this.onOpenTagManagement,
    super.key,
  });

  final TodoItem item;
  final bool archivedScope;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final List<TodoTag> tags;
  final List<String> assignedTagIds;
  final Future<void> Function(String tagId) onToggleTag;
  final VoidCallback onOpenTagManagement;

  @override
  State<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends State<_TodoRow> {
  final _rowFocusNode = FocusNode();

  bool _isHovered = false;
  bool _hasFocus = false;

  @override
  void dispose() {
    _rowFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final localizations = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showEditAction = _isHovered || _hasFocus;

    return Focus(
      focusNode: _rowFocusNode,
      onFocusChange: (hasFocus) {
        if (_hasFocus != hasFocus) {
          setState(() => _hasFocus = hasFocus);
        }
      },
      child: Semantics(
        container: true,
        label: item.title,
        value: item.isCompleted
            ? localizations.completedStatus
            : localizations.incompleteStatus,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.fromLTRB(7, 8, 5, 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.055)
                        : Colors.black.withValues(alpha: 0.035))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: <Widget>[
                if (!widget.archivedScope)
                  Tooltip(
                    message: item.isCompleted
                        ? localizations.markIncompleteTooltip
                        : localizations.markCompleteTooltip,
                    child: Semantics(
                      button: true,
                      checked: item.isCompleted,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onToggle,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 160),
                              width: 21,
                              height: 21,
                              decoration: BoxDecoration(
                                color: item.isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: item.isCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : onSurface.withValues(alpha: 0.28),
                                  width: 1.4,
                                ),
                              ),
                              child: item.isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 21,
                      color: onSurface.withValues(alpha: 0.28),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withValues(
                            alpha: item.isCompleted ? 0.45 : 0.91,
                          ),
                          fontSize: 13.5,
                          height: 1.3,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: onSurface.withValues(alpha: 0.42),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: TagAssignmentMenu(
                              todoId: item.id,
                              tags: widget.tags,
                              assignedTagIds: widget.assignedTagIds,
                              onToggle: widget.onToggleTag,
                              onManageTags: widget.onOpenTagManagement,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _formatTime(
                                context,
                                widget.archivedScope
                                    ? (item.archivedAt ?? item.createdAt)
                                    : item.createdAt,
                              ),
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.35),
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 96,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      SizedBox.square(
                        dimension: 32,
                        child: AnimatedOpacity(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 140),
                          opacity: showEditAction ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !showEditAction,
                            child: IconButton(
                              key: ValueKey<String>(
                                'edit-todo-${widget.item.id}',
                              ),
                              tooltip: localizations.editTooltip,
                              onPressed: widget.onEdit,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit_outlined, size: 16),
                            ),
                          ),
                        ),
                      ),
                      SizedBox.square(
                        dimension: 32,
                        child: IconButton(
                          key: ValueKey<String>('view-todo-${widget.item.id}'),
                          tooltip: localizations.viewTodoDetailsTooltip,
                          onPressed: widget.onOpenDetails,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.subject_rounded,
                            size: 17,
                            color: item.content.trim().isEmpty
                                ? onSurface.withValues(alpha: 0.42)
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox.square(
                        dimension: 32,
                        child: IconButton(
                          tooltip: widget.archivedScope
                              ? localizations.restoreTooltip
                              : localizations.archiveTooltip,
                          onPressed: widget.archivedScope
                              ? widget.onRestore
                              : widget.onArchive,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            widget.archivedScope
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.scope, required this.hasQuery});

  final TodoListScope scope;
  final bool hasQuery;

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

String _formatTime(BuildContext context, DateTime date) {
  final local = date.toLocal();
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
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
