import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/floatick_editor_components.dart';
import '../../../core/ui/floatick_markdown.dart';
import '../../../l10n/l10n.dart';
import '../../todos/domain/todo_tag.dart';
import '../../todos/presentation/widgets/editor_tag_selector.dart';
import '../domain/note_item.dart';

const Duration _autoSaveDelay = Duration(milliseconds: 450);

typedef SaveNoteDraft =
    Future<NoteItem?> Function({
      String? id,
      required String title,
      required String content,
      required List<String> tagIds,
    });

class NoteEditorDrawer extends StatefulWidget {
  const NoteEditorDrawer({
    required this.item,
    required this.availableTags,
    required this.assignedTagIds,
    required this.isOpen,
    required this.onSave,
    required this.onOpenTagAssignment,
    required this.onClose,
    required this.closeFocusNode,
    super.key,
  });

  final NoteItem? item;
  final List<TodoTag> availableTags;
  final List<String> assignedTagIds;
  final bool isOpen;
  final SaveNoteDraft onSave;
  final VoidCallback onOpenTagAssignment;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;

  @override
  State<NoteEditorDrawer> createState() => NoteEditorDrawerState();
}

class NoteEditorDrawerState extends State<NoteEditorDrawer> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  Timer? _autoSaveTimer;
  Future<bool>? _saveFuture;
  String? _noteId;
  String _lastSavedTitle = '';
  String _lastSavedContent = '';
  List<String> _lastSavedTagIds = const <String>[];
  bool _saveAgain = false;
  bool _isSaving = false;
  bool _saveFailed = false;
  bool _showPreview = false;

  bool get _isCreating => widget.item == null;
  bool get _hasUnsavedChanges =>
      _titleController.text != _lastSavedTitle ||
      _contentController.text != _lastSavedContent ||
      !listEquals(_currentTagIds, _lastSavedTagIds);
  List<String> get _currentTagIds => _effectiveTagIdsFor(
    availableTags: widget.availableTags,
    assignedTagIds: widget.assignedTagIds,
  );

  @override
  void initState() {
    super.initState();
    _loadItem(widget.item);
    _titleController.addListener(_handleInputChanged);
    _contentController.addListener(_handleInputChanged);
    if (widget.isOpen) {
      _requestInitialFocus();
    }
  }

  @override
  void didUpdateWidget(covariant NoteEditorDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousTagIds = _effectiveTagIdsFor(
      availableTags: oldWidget.availableTags,
      assignedTagIds: oldWidget.assignedTagIds,
    );
    if (!listEquals(previousTagIds, _currentTagIds)) {
      _handleInputChanged();
    }
    if (!oldWidget.isOpen && widget.isOpen) {
      _requestInitialFocus();
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _contentController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<bool> flush() async {
    _autoSaveTimer?.cancel();
    if (!_hasUnsavedChanges) {
      return !_saveFailed;
    }
    return _requestSave();
  }

  void _loadItem(NoteItem? item) {
    _noteId = item?.id;
    _lastSavedTitle = item?.title ?? '';
    _lastSavedContent = item?.content ?? '';
    _lastSavedTagIds = item?.tagIds ?? const <String>[];
    _titleController.text = _lastSavedTitle;
    _contentController.text = _lastSavedContent;
  }

  void _requestInitialFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isOpen) {
        _titleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _titleController.text.length,
        );
        _titleFocusNode.requestFocus();
      }
    });
  }

  void _handleInputChanged() {
    if (!_hasUnsavedChanges) {
      return;
    }
    if (_saveFailed) {
      setState(() => _saveFailed = false);
    }
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      unawaited(_requestSave());
    });
  }

  Future<bool> _requestSave() {
    _saveAgain = true;
    final activeSave = _saveFuture;
    if (activeSave != null) {
      return activeSave;
    }
    final save = _runSaveLoop();
    _saveFuture = save;
    unawaited(
      save.whenComplete(() {
        if (identical(_saveFuture, save)) {
          _saveFuture = null;
        }
      }),
    );
    return save;
  }

  Future<bool> _runSaveLoop() async {
    while (_saveAgain) {
      _saveAgain = false;
      final title = _titleController.text;
      final content = _contentController.text;
      final tagIds = _currentTagIds;
      if (title == _lastSavedTitle &&
          content == _lastSavedContent &&
          listEquals(tagIds, _lastSavedTagIds)) {
        continue;
      }
      if (_noteId == null && title.trim().isEmpty && content.trim().isEmpty) {
        _lastSavedTitle = title;
        _lastSavedContent = content;
        _lastSavedTagIds = tagIds;
        continue;
      }

      if (mounted) {
        setState(() {
          _isSaving = true;
          _saveFailed = false;
        });
      }
      NoteItem? saved;
      try {
        saved = await widget.onSave(
          id: _noteId,
          title: title,
          content: content,
          tagIds: tagIds,
        );
      } on Object catch (error, stackTrace) {
        debugPrint('Floatick could not autosave a note: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (saved == null) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _saveFailed = true;
          });
        }
        return false;
      }
      _noteId = saved.id;
      _lastSavedTitle = title;
      _lastSavedContent = content;
      _lastSavedTagIds = tagIds;
      if (_titleController.text != title ||
          _contentController.text != content ||
          !listEquals(_currentTagIds, tagIds)) {
        _saveAgain = true;
      }
    }
    if (mounted) {
      setState(() {
        _isSaving = false;
        _saveFailed = false;
      });
    }
    return true;
  }

  Future<void> _closeAfterFlush() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (await flush() && mounted) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return FloatickEditorDrawerSurface(
      key: const Key('note-editor-drawer'),
      title: _isCreating
          ? context.l10n.newNoteDrawerTitle
          : context.l10n.editNoteDrawerTitle,
      closeTooltip: context.l10n.closeNoteDrawerTooltip,
      closeButtonKey: const Key('close-note-editor'),
      onClose: () => unawaited(_closeAfterFlush()),
      closeFocusNode: widget.closeFocusNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: FloatickEditorMetrics.bodyPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: FloatickDocumentEditor(
                      editorSurfaceKey: const Key('note-document-editor'),
                      titleFieldKey: const Key('note-title-field'),
                      contentFieldKey: const Key('note-content-field'),
                      modeSwitchKey: const Key('note-editor-mode-switch'),
                      writeTabKey: const Key('note-markdown-write-tab'),
                      previewTabKey: const Key('note-markdown-preview-tab'),
                      titleController: _titleController,
                      contentController: _contentController,
                      titleFocusNode: _titleFocusNode,
                      contentFocusNode: _contentFocusNode,
                      titleHint: context.l10n.noteTitleHint,
                      contentHint: context.l10n.noteContentHint,
                      titleSemanticsLabel: context.l10n.noteTitleLabel,
                      contentSemanticsLabel: context.l10n.noteContentLabel,
                      toolbarLeading: EditorTagSelector(
                        availableTags: widget.availableTags,
                        selectedTagIds: widget.assignedTagIds.toSet(),
                        buttonKey: const Key('note-editor-tag-button'),
                        tagKeyPrefix: 'note-editor-tag',
                        onPressed: widget.onOpenTagAssignment,
                      ),
                      showPreview: _showPreview,
                      preview: FloatickMarkdownPreview(
                        key: const Key('note-content-preview'),
                        content: _contentController.text,
                        embedded: true,
                      ),
                      onPreviewChanged: (value) =>
                          setState(() => _showPreview = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FloatickEditorFooter(
            key: const Key('note-editor-footer'),
            child: Row(
              children: <Widget>[
                Icon(
                  _saveFailed
                      ? Icons.error_outline_rounded
                      : _isSaving
                      ? Icons.sync_rounded
                      : Icons.check_rounded,
                  size: 16,
                  color: _saveFailed
                      ? theme.colorScheme.error
                      : onSurface.withValues(alpha: 0.48),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _saveFailed
                        ? context.l10n.noteAutoSaveFailed
                        : _isSaving
                        ? context.l10n.noteAutoSaving
                        : _noteId == null
                        ? context.l10n.noteEmptyDraftHint
                        : context.l10n.noteAutoSaved,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _saveFailed
                          ? theme.colorScheme.error
                          : onSurface.withValues(alpha: 0.48),
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('finish-note-editor'),
                  onPressed: _isSaving
                      ? null
                      : () => unawaited(_closeAfterFlush()),
                  style: TextButton.styleFrom(
                    foregroundColor: onSurface.withValues(alpha: 0.68),
                  ),
                  child: Text(context.l10n.finishNoteAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _effectiveTagIdsFor({
    required List<TodoTag> availableTags,
    required List<String> assignedTagIds,
  }) {
    final selectedTagIds = assignedTagIds.toSet();
    return List<String>.unmodifiable(
      availableTags
          .where((tag) => selectedTagIds.contains(tag.id))
          .map((tag) => tag.id),
    );
  }
}
