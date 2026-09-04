import React, { useMemo, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { Note, PushPin } from "@phosphor-icons/react";
import type { NoteItem } from "@/types";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import { ActionBar } from "@/components/common/ActionBar";
import { NoteItemRow } from "./NoteItemRow";
import { getGroupLabel } from "@/lib/dateUtils";

interface NotePanelProps {
  onOpenTagFilter: () => void;
}

export const NotePanel: React.FC<NotePanelProps> = ({ onOpenTagFilter }) => {
  const { t, i18n } = useTranslation();

  const notes = useNoteStore((s) => s.notes);
  const searchQuery = useNoteStore((s) => s.searchQuery);
  const setSearchQuery = useNoteStore((s) => s.setSearchQuery);

  const selectedTagIds = useTagStore((s) => s.selectedTagIds);

  const setIsEditorOpen = useNoteStore((s) => s.setIsEditorOpen);
  const setEditingNoteId = useNoteStore((s) => s.setEditingNoteId);

  const handleOpenCreate = () => {
    setEditingNoteId(null);
    setIsEditorOpen(true);
  };

  useEffect(() => {
    const handler = () => handleOpenCreate();
    window.addEventListener("floatick:new-item", handler);
    return () => window.removeEventListener("floatick:new-item", handler);
  }, []);

  const handleOpenEdit = (note: NoteItem) => {
    setEditingNoteId(note.id);
    setIsEditorOpen(true);
  };

  // Filter notes
  const filteredNotes = useMemo(() => {
    return notes.filter((item) => {
      if (item.archivedAt) return false;

      if (selectedTagIds.length > 0) {
        const matchesTag = selectedTagIds.some((id) => item.tagIds.includes(id));
        if (!matchesTag) return false;
      }

      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchTitle = item.title.toLowerCase().includes(q);
        const matchContent = item.content.toLowerCase().includes(q);
        if (!matchTitle && !matchContent) return false;
      }

      return true;
    });
  }, [notes, selectedTagIds, searchQuery]);

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
        selectedTagCount={selectedTagIds.length}
        onOpenTagFilter={onOpenTagFilter}
        onAddNew={handleOpenCreate}
        addTooltip={t("newNote")}
      />

      {/* Notes List */}
      <div className="flex-1 overflow-y-auto px-4 pb-3 space-y-3 smooth-scroll">
        {filteredNotes.length === 0 ? (
          <div className="h-full min-h-[300px] flex flex-col items-center justify-center text-center p-6 space-y-2">
            <Note size={42} weight="duotone" className="text-[var(--color-teal-primary)]/50" />
            <p className="text-[13.5px] font-semibold text-[var(--color-text-primary)]">
              {t("noNotes")}
            </p>
            <p className="text-[12px] font-medium text-[var(--color-text-subtle)]">
              {t("noNotesSub")}
            </p>
          </div>
        ) : (
          <>
            {/* Pinned Section */}
            {pinnedNotes.length > 0 && (
              <div className="space-y-0.5">
                <div className="px-2.5 pt-1 text-[11.5px] font-semibold text-[var(--color-teal-primary)] uppercase tracking-wider flex items-center space-x-1">
                  <PushPin size={12} weight="fill" />
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
                <div className="px-2.5 pt-1 text-[11.5px] font-semibold text-[var(--color-text-subtle)] uppercase tracking-wider">
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
    </div>
  );
};
