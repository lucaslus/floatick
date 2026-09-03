import React, { useState, useMemo } from "react";
import { useTranslation } from "react-i18next";
import { Plus, Search, X, FileText, Tag as TagIcon, Pin } from "lucide-react";
import type { NoteItem } from "@/types";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import { NoteItemRow } from "./NoteItemRow";
import { NoteEditorDrawer } from "./NoteEditorDrawer";
import { getGroupLabel } from "@/lib/dateUtils";

export const NotePanel: React.FC = () => {
  const { t } = useTranslation();

  const notes = useNoteStore((s) => s.notes);
  const addNote = useNoteStore((s) => s.addNote);
  const searchQuery = useNoteStore((s) => s.searchQuery);
  const setSearchQuery = useNoteStore((s) => s.setSearchQuery);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const [selectedTagFilter, setSelectedTagFilter] = useState<string | null>(null);
  const [showTagMenu, setShowTagMenu] = useState(false);

  const [editingNoteId, setEditingNoteId] = useState<string | null>(null);

  const handleCreate = async () => {
    const newNote = await addNote("", "", selectedTagFilter ? [selectedTagFilter] : []);
    setEditingNoteId(newNote.id);
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
      const label = getGroupLabel(item.updatedAt);
      if (!map.has(label)) {
        map.set(label, []);
      }
      map.get(label)!.push(item);
    }

    for (const [label, items] of map.entries()) {
      groups.push({ label, items });
    }

    return groups;
  }, [regularNotes]);

  const selectedTag = tagsWorkspace.tags.find((t) => t.id === selectedTagFilter);

  return (
    <div className="flex-1 flex flex-col min-h-0 bg-zinc-50/50 dark:bg-zinc-950/40">
      {/* Top action bar */}
      <div className="p-3 pb-1 flex items-center justify-between space-x-2">
        {/* Search input */}
        <div className="relative flex-1 flex items-center">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t("searchNotes")}
            className="w-full pl-7 pr-6 py-1.5 text-xs rounded-xl bg-white/80 dark:bg-zinc-800/80 border border-black/[0.06] dark:border-white/[0.08] shadow-xs text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-teal-500/30"
          />
          <Search className="w-3.5 h-3.5 absolute left-2 text-zinc-400" />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery("")}
              className="absolute right-2 text-zinc-400 hover:text-zinc-600"
            >
              <X className="w-3 h-3" />
            </button>
          )}
        </div>

        {/* New Note Button */}
        <button
          onClick={handleCreate}
          className="px-2.5 py-1.5 bg-teal-600 hover:bg-teal-700 text-white rounded-xl text-xs font-medium flex items-center space-x-1 shadow-xs transition-colors cursor-pointer shrink-0"
        >
          <Plus className="w-3.5 h-3.5" />
          <span>{t("newNote")}</span>
        </button>
      </div>

      {/* Filter by Tag */}
      <div className="px-3 py-1 flex items-center space-x-2 text-xs">
        <div className="relative">
          <button
            type="button"
            onClick={() => setShowTagMenu(!showTagMenu)}
            className={`inline-flex items-center space-x-1 px-2 py-0.8 rounded-lg text-[11px] transition-all cursor-pointer ${
              selectedTag
                ? "bg-teal-500/15 text-teal-700 dark:text-teal-300 font-medium border border-teal-500/30"
                : "bg-black/[0.04] dark:bg-white/[0.06] text-zinc-600 dark:text-zinc-300 hover:bg-black/[0.08]"
            }`}
          >
            <TagIcon className="w-3 h-3" />
            <span>{selectedTag ? selectedTag.name : t("allTags")}</span>
          </button>

          {showTagMenu && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setShowTagMenu(false)} />
              <div className="absolute left-0 top-7 z-50 w-36 bg-white dark:bg-zinc-800 rounded-lg shadow-lg border border-black/[0.08] dark:border-white/[0.08] py-1 text-xs max-h-48 overflow-y-auto">
                <button
                  onClick={() => {
                    setSelectedTagFilter(null);
                    setShowTagMenu(false);
                  }}
                  className="w-full px-2.5 py-1.5 text-left text-zinc-700 dark:text-zinc-300 hover:bg-black/[0.04]"
                >
                  {t("allTags")}
                </button>
                {tagsWorkspace.tags.map((tag) => (
                  <button
                    key={tag.id}
                    onClick={() => {
                      setSelectedTagFilter(tag.id);
                      setShowTagMenu(false);
                    }}
                    className="w-full px-2.5 py-1.5 flex items-center space-x-1.5 text-left text-zinc-700 dark:text-zinc-300 hover:bg-black/[0.04]"
                  >
                    <span
                      className="w-2 h-2 rounded-full"
                      style={{ backgroundColor: tag.colorHex }}
                    />
                    <span className="truncate">{tag.name}</span>
                  </button>
                ))}
              </div>
            </>
          )}
        </div>
      </div>

      {/* Notes List Area */}
      <div className="flex-1 overflow-y-auto px-3 py-2 space-y-3">
        {filteredNotes.length === 0 ? (
          <div className="h-full min-h-[240px] flex flex-col items-center justify-center text-center p-6 space-y-2">
            <FileText className="w-10 h-10 text-teal-500/40" />
            <p className="text-xs font-medium text-zinc-600 dark:text-zinc-300">
              {t("noNotes")}
            </p>
            <p className="text-[11px] text-zinc-400 max-w-[200px]">
              {t("noNotesSub")}
            </p>
          </div>
        ) : (
          <>
            {/* Pinned Notes Section */}
            {pinnedNotes.length > 0 && (
              <div className="space-y-1.5">
                <div className="px-1 text-[10px] font-semibold text-teal-600 dark:text-teal-400 uppercase tracking-wider flex items-center space-x-1">
                  <Pin className="w-2.5 h-2.5" />
                  <span>置顶笔记</span>
                </div>
                <div className="space-y-1">
                  {pinnedNotes.map((note) => (
                    <NoteItemRow
                      key={note.id}
                      note={note}
                      onOpen={(n) => setEditingNoteId(n.id)}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Date Grouped Notes */}
            {groupedNotes.map((group) => (
              <div key={group.label} className="space-y-1.5">
                <div className="px-1 text-[10px] font-semibold text-zinc-400 uppercase tracking-wider">
                  {group.label}
                </div>
                <div className="space-y-1">
                  {group.items.map((note) => (
                    <NoteItemRow
                      key={note.id}
                      note={note}
                      onOpen={(n) => setEditingNoteId(n.id)}
                    />
                  ))}
                </div>
              </div>
            ))}
          </>
        )}
      </div>

      {/* Note Editor Drawer Modal */}
      {editingNoteId && (
        <NoteEditorDrawer
          noteId={editingNoteId}
          onClose={() => setEditingNoteId(null)}
        />
      )}
    </div>
  );
};
