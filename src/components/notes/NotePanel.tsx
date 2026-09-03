import React, { useState, useMemo } from "react";
import { useTranslation } from "react-i18next";
import { FileText, Pin } from "lucide-react";
import type { NoteItem } from "@/types";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import { ActionBar } from "@/components/common/ActionBar";
import { NoteItemRow } from "./NoteItemRow";
import { NoteEditorDrawer } from "./NoteEditorDrawer";
import { getGroupLabel } from "@/lib/dateUtils";

interface NotePanelProps {
  onOpenTagFilter: () => void;
}

export const NotePanel: React.FC<NotePanelProps> = ({ onOpenTagFilter }) => {
  const { t, i18n } = useTranslation();

  const notes = useNoteStore((s) => s.notes);
  const searchQuery = useNoteStore((s) => s.searchQuery);
  const setSearchQuery = useNoteStore((s) => s.setSearchQuery);

  const selectedTagFilter = useTagStore((s) => s.selectedTagFilter);

  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [editingNoteId, setEditingNoteId] = useState<string | null>(null);

  const handleOpenCreate = () => {
    setEditingNoteId(null);
    setIsEditorOpen(true);
  };

  const handleOpenEdit = (note: NoteItem) => {
    setEditingNoteId(note.id);
    setIsEditorOpen(true);
  };

  // Filter notes
  const filteredNotes = useMemo(() => {
    return notes.filter((item) => {
      if (item.archivedAt) return false;

      if (selectedTagFilter && !item.tagIds.includes(selectedTagFilter)) {
        return false;
      }

      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchTitle = item.title.toLowerCase().includes(q);
        const matchContent = item.content.toLowerCase().includes(q);
        if (!matchTitle && !matchContent) return false;
      }

      return true;
    });
  }, [notes, selectedTagFilter, searchQuery]);

  // Separate pinned and unpinned
  const pinnedNotes = useMemo(() => {
    return filteredNotes.filter((n) => !!n.pinnedAt);
  }, [filteredNotes]);

  const regularNotes = useMemo(() => {
    return filteredNotes.filter((n) => !n.pinnedAt);
  }, [filteredNotes]);

  // Group regular notes by date
  const groupedNotes = useMemo(() => {
    const groups: { label: string; items: NoteItem[] }[] = [];
    const map = new Map<string, NoteItem[]>();

    for (const item of regularNotes) {
      const label = getGroupLabel(item.updatedAt, i18n.language);
      if (!map.has(label)) {
        map.set(label, []);
      }
      map.get(label)!.push(item);
    }

    for (const [label, items] of map.entries()) {
      groups.push({ label, items });
    }

    return groups;
  }, [regularNotes, i18n.language]);

  return (
    <div className="flex-1 flex flex-col min-h-0">
      {/* Action Bar */}
      <ActionBar
        query={searchQuery}
        onQueryChange={setSearchQuery}
        showDoingFilter={false}
        selectedTagCount={selectedTagFilter ? 1 : 0}
        onOpenTagFilter={onOpenTagFilter}
        onAddNew={handleOpenCreate}
        placeholder={t("searchNotes")}
        addTooltip={t("newNote")}
      />

      {/* Notes List */}
      <div className="flex-1 overflow-y-auto px-4 pb-3 space-y-3">
        {filteredNotes.length === 0 ? (
          <div className="h-full min-h-[300px] flex flex-col items-center justify-center text-center p-6 space-y-2">
            <FileText className="w-9 h-9 text-teal-500/40" />
            <p className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              {t("noNotes")}
            </p>
            <p className="text-[11px] text-zinc-400 dark:text-zinc-500">
              {t("noNotesSub")}
            </p>
          </div>
        ) : (
          <>
            {/* Pinned Section */}
            {pinnedNotes.length > 0 && (
              <div className="space-y-0.5">
                <div className="px-2.5 pt-1 text-[11px] font-medium text-teal-600 dark:text-teal-400 flex items-center space-x-1">
                  <Pin className="w-3 h-3 fill-current" />
                  <span>{t("pinnedNotes")}</span>
                </div>
                <div className="space-y-0.5">
                  {pinnedNotes.map((note) => (
                    <NoteItemRow
                      key={note.id}
                      note={note}
                      onOpen={handleOpenEdit}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Date Grouped Regular Notes */}
            {groupedNotes.map((group) => (
              <div key={group.label} className="space-y-0.5">
                <div className="px-2.5 pt-1 text-[11px] font-medium text-zinc-400 dark:text-zinc-500">
                  {group.label}
                </div>
                <div className="space-y-0.5">
                  {group.items.map((note) => (
                    <NoteItemRow
                      key={note.id}
                      note={note}
                      onOpen={handleOpenEdit}
                    />
                  ))}
                </div>
              </div>
            ))}
          </>
        )}
      </div>

      {/* Note Editor Drawer */}
      <NoteEditorDrawer
        noteId={editingNoteId}
        isOpen={isEditorOpen}
        onClose={() => setIsEditorOpen(false)}
      />
    </div>
  );
};
