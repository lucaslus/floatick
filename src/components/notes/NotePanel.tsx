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
      <div className="flex-1 overflow-y-auto px-4 pb-4 space-y-4">
        {filteredNotes.length === 0 ? (
          <div className="h-full min-h-[340px] flex flex-col items-center justify-center text-center p-6 space-y-3">
            <div className="w-14 h-14 rounded-2xl bg-teal-500/10 dark:bg-teal-500/15 border border-teal-500/20 flex items-center justify-center text-teal-500 dark:text-[#2DD4BF] shadow-[0_0_24px_rgba(45,212,191,0.15)]">
              <FileText className="w-7 h-7" />
            </div>
            <div>
              <p className="text-xs font-semibold text-zinc-800 dark:text-[#F1F5F9] tracking-tight">
                {t("noNotes")}
              </p>
              <p className="text-[11px] text-zinc-400 dark:text-[#94A3B8] max-w-[240px] mt-1 leading-relaxed">
                {t("noNotesSub")}
              </p>
            </div>
          </div>
        ) : (
          <>
            {/* Pinned Section */}
            {pinnedNotes.length > 0 && (
              <div className="space-y-1.5">
                <div className="px-3 pt-1 flex items-center space-x-2">
                  <span className="text-[10px] font-semibold text-teal-500 dark:text-[#2DD4BF] uppercase tracking-[0.14em] flex items-center space-x-1">
                    <Pin className="w-3 h-3 fill-current" />
                    <span>{t("pinnedNotes")}</span>
                  </span>
                  <div className="flex-1 h-[1px] bg-teal-500/20 dark:bg-teal-500/25" />
                  <span className="text-[9.5px] font-mono text-teal-500 dark:text-[#2DD4BF]">
                    {pinnedNotes.length}
                  </span>
                </div>
                <div className="space-y-1.5">
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
              <div key={group.label} className="space-y-1.5">
                <div className="px-3 pt-1 flex items-center space-x-2">
                  <span className="text-[10px] font-semibold text-zinc-400 dark:text-[#64748B] uppercase tracking-[0.14em]">
                    {group.label}
                  </span>
                  <div className="flex-1 h-[1px] bg-black/[0.04] dark:bg-white/[0.06]" />
                  <span className="text-[9.5px] font-mono text-zinc-400 dark:text-[#64748B]">
                    {group.items.length}
                  </span>
                </div>
                <div className="space-y-1.5">
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

      {/* Slide-up Note Editor Drawer */}
      <NoteEditorDrawer
        noteId={editingNoteId}
        isOpen={isEditorOpen}
        onClose={() => setIsEditorOpen(false)}
      />
    </div>
  );
};
