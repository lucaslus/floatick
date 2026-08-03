import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../todos/domain/todo_tag.dart';
import '../../todos/presentation/widgets/floatick_tag_chip.dart';
import '../domain/note_item.dart';
import 'note_view_model.dart';

class NotePanelContent extends StatelessWidget {
  const NotePanelContent({
    required this.controller,
    required this.archived,
    required this.query,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onOpen,
    super.key,
  });

  final NoteViewModel controller;
  final bool archived;
  final String query;
  final List<TodoTag> availableTags;
  final Set<String> selectedTagIds;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final items = controller.itemsForView(
      archived: archived,
      query: query,
      selectedTagIds: selectedTagIds,
    );
    if (items.isEmpty) {
      return _EmptyNotes(
        archived: archived,
        hasQuery: query.isNotEmpty || selectedTagIds.isNotEmpty,
      );
    }

    final pinned = archived
        ? const <NoteItem>[]
        : items.where((item) => item.isPinned).toList(growable: false);
    final regular = archived
        ? items
        : items.where((item) => !item.isPinned).toList(growable: false);
    return ListView(
      key: const Key('note-list'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      children: <Widget>[
        if (pinned.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.push_pin_outlined,
            label: context.l10n.pinnedNotesLabel,
          ),
          ...pinned.map(
            (item) => _NoteListRow(
              item: item,
              archived: false,
              controller: controller,
              availableTags: availableTags,
              onOpen: () => onOpen(item.id),
            ),
          ),
          const SizedBox(height: 7),
        ],
        if (regular.isNotEmpty) ...[
          _SectionLabel(
            icon: archived
                ? Icons.inventory_2_outlined
                : Icons.schedule_rounded,
            label: archived
                ? context.l10n.archiveScopeLabel
                : context.l10n.recentNotesLabel,
          ),
          ...regular.map(
            (item) => _NoteListRow(
              item: item,
              archived: archived,
              controller: controller,
              availableTags: availableTags,
              onOpen: () => onOpen(item.id),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.48);
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteListRow extends StatefulWidget {
  const _NoteListRow({
    required this.item,
    required this.archived,
    required this.controller,
    required this.availableTags,
    required this.onOpen,
  });

  final NoteItem item;
  final bool archived;
  final NoteViewModel controller;
  final List<TodoTag> availableTags;
  final VoidCallback onOpen;

  @override
  State<_NoteListRow> createState() => _NoteListRowState();
}

class _NoteListRowState extends State<_NoteListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final preview = _previewFor(widget.item.content);
    final assignedTagIds = widget.item.tagIds.toSet();
    final assignedTags = widget.availableTags
        .where((tag) => assignedTagIds.contains(tag.id))
        .toList(growable: false);
    return Semantics(
      button: true,
      label: widget.item.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          key: ValueKey<String>('note-row-${widget.item.id}'),
          onTap: widget.onOpen,
          borderRadius: BorderRadius.circular(12),
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(11, 9, 5, 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: onSurface.withValues(alpha: 0.065)),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 17,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.item.isPinned && !_hovered)
                            Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              preview.isEmpty
                                  ? context.l10n.noteWithoutContent
                                  : preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurface.withValues(alpha: 0.46),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatUpdatedTime(context, widget.item.updatedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: onSurface.withValues(alpha: 0.36),
                            ),
                          ),
                        ],
                      ),
                      if (assignedTags.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 3,
                          children: <Widget>[
                            for (final tag in assignedTags)
                              FloatickTagChip(
                                key: ValueKey<String>(
                                  'note-tag-${widget.item.id}-${tag.id}',
                                ),
                                tag: tag,
                                compact: true,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  child: _hovered
                      ? _NoteRowActions(
                          key: const ValueKey<String>('actions'),
                          item: widget.item,
                          archived: widget.archived,
                          controller: widget.controller,
                        )
                      : const SizedBox(
                          key: ValueKey<String>('spacing'),
                          width: 8,
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

class _NoteRowActions extends StatelessWidget {
  const _NoteRowActions({
    required this.item,
    required this.archived,
    required this.controller,
    super.key,
  });

  final NoteItem item;
  final bool archived;
  final NoteViewModel controller;

  @override
  Widget build(BuildContext context) {
    if (archived) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            key: ValueKey<String>('restore-note-${item.id}'),
            tooltip: context.l10n.restoreNoteTooltip,
            onPressed: () => controller.restore(item.id),
            icon: const Icon(Icons.unarchive_outlined, size: 17),
          ),
          IconButton(
            key: ValueKey<String>('delete-note-${item.id}'),
            tooltip: context.l10n.deleteNoteTooltip,
            onPressed: () => controller.deletePermanently(item.id),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: ValueKey<String>('pin-note-${item.id}'),
          tooltip: item.isPinned
              ? context.l10n.unpinNoteTooltip
              : context.l10n.pinNoteTooltip,
          onPressed: () => controller.togglePin(item.id),
          icon: Icon(
            item.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            size: 17,
          ),
        ),
        IconButton(
          key: ValueKey<String>('archive-note-${item.id}'),
          tooltip: context.l10n.archiveNoteTooltip,
          onPressed: () => controller.archive(item.id),
          icon: const Icon(Icons.archive_outlined, size: 17),
        ),
      ],
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.archived, required this.hasQuery});

  final bool archived;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : archived
                    ? Icons.inventory_2_outlined
                    : Icons.edit_note_rounded,
                size: 26,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery
                  ? context.l10n.noSearchResultsTitle
                  : archived
                  ? context.l10n.emptyNoteArchiveTitle
                  : context.l10n.emptyNotesTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              hasQuery
                  ? context.l10n.noSearchResultsMessage
                  : archived
                  ? context.l10n.emptyNoteArchiveMessage
                  : context.l10n.emptyNotesMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _previewFor(String content) {
  return content
      .replaceAll(RegExp(r'[#>*_`~\[\]()]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _formatUpdatedTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: true,
    );
  }
  return '${local.month}/${local.day}';
}
