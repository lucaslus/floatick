import React from "react";
import { useTranslation } from "react-i18next";
import { Pin, Archive, Trash2 } from "lucide-react";
import type { NoteItem } from "@/types";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import { formatTime } from "@/lib/dateUtils";

interface NoteItemRowProps {
  note: NoteItem;
  onOpen: (note: NoteItem) => void;
}

export const NoteItemRow: React.FC<NoteItemRowProps> = ({ note, onOpen }) => {
  const { t } = useTranslation();
  const togglePin = useNoteStore((s) => s.togglePin);
  const toggleArchive = useNoteStore((s) => s.toggleArchive);
  const deleteNote = useNoteStore((s) => s.deleteNote);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const tags = tagsWorkspace.tags.filter((t) => note.tagIds.includes(t.id));

  const isPinned = !!note.pinnedAt;
  const isArchived = !!note.archivedAt;

  return (
    <div
      onClick={() => onOpen(note)}
      className={`group relative p-3 rounded-xl transition-all duration-150 border cursor-pointer select-none ${
        isPinned
          ? "bg-teal-500/[0.08] dark:bg-[#22B8A7]/[0.09] border-teal-500/25 dark:border-[#22B8A7]/30 shadow-xs"
          : "bg-white/70 dark:bg-[#1D2529] border-black/[0.04] dark:border-white/[0.06] hover:border-black/[0.1] dark:hover:border-white/[0.1] shadow-xs"
      }`}
    >
      {/* Top row: Title & Actions */}
      <div className="flex items-center justify-between space-x-2">
        <h4 className="text-xs font-semibold text-zinc-900 dark:text-[#EEF2F1] truncate flex items-center space-x-1.5 tracking-tight">
          {isPinned && <Pin className="w-3 h-3 text-teal-600 dark:text-[#22B8A7] fill-current shrink-0" />}
          <span>{note.title || t("newNote")}</span>
        </h4>

        {/* Hover action icons */}
        <div
          className="flex items-center space-x-0.5 opacity-0 group-hover:opacity-100 transition-opacity"
          onClick={(e) => e.stopPropagation()}
        >
          <button
            type="button"
            onClick={() => togglePin(note.id)}
            title={isPinned ? t("unpin") : t("pin")}
            className={`w-6 h-6 rounded-md flex items-center justify-center transition-colors mui-ripple cursor-pointer ${
              isPinned
                ? "text-teal-600 dark:text-[#22B8A7] bg-teal-500/15"
                : "text-zinc-400 hover:text-zinc-800 dark:hover:text-white"
            }`}
          >
            <Pin className="w-3 h-3" />
          </button>
          <button
            type="button"
            onClick={() => toggleArchive(note.id)}
            title={isArchived ? t("restore") : t("archive")}
            className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white mui-ripple cursor-pointer"
          >
            <Archive className="w-3 h-3" />
          </button>
          <button
            type="button"
            onClick={() => deleteNote(note.id)}
            title={t("delete")}
            className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-red-500 mui-ripple cursor-pointer"
          >
            <Trash2 className="w-3 h-3" />
          </button>
        </div>
      </div>

      {/* Snippet */}
      {note.content && (
        <p className="mt-1 text-[11px] text-zinc-500 dark:text-[#8E9599] line-clamp-2 leading-relaxed font-sans">
          {note.content}
        </p>
      )}

      {/* Bottom meta: tags and updated time */}
      <div className="mt-2.5 flex items-center justify-between text-[10.5px] text-zinc-400 dark:text-[#8E9599]">
        <div className="flex items-center space-x-1.5 overflow-hidden">
          {tags.slice(0, 3).map((tag) => (
            <span
              key={tag.id}
              className="inline-flex items-center space-x-1 px-2 py-0.2 rounded-full text-[9.5px] font-medium truncate"
              style={{
                backgroundColor: `${tag.colorHex}22`,
                color: tag.colorHex,
                border: `1px solid ${tag.colorHex}44`,
              }}
            >
              <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: tag.colorHex }} />
              <span>{tag.name}</span>
            </span>
          ))}
          {tags.length > 3 && <span>+{tags.length - 3}</span>}
        </div>
        <span>{formatTime(note.updatedAt)}</span>
      </div>
    </div>
  );
};
