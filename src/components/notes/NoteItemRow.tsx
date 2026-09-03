import React from "react";
import { useTranslation } from "react-i18next";
import { PushPin, Archive, Trash } from "@phosphor-icons/react";
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
      className={`group relative p-2.5 rounded-xl transition-colors border cursor-pointer select-none ${
        isPinned
          ? "bg-teal-500/[0.06] border-teal-500/25"
          : "bg-black/[0.02] dark:bg-white/[0.03] border-black/[0.04] dark:border-white/[0.05] hover:border-black/[0.08] dark:hover:border-white/[0.1]"
      }`}
    >
      {/* Top row: Title & Actions */}
      <div className="flex items-center justify-between space-x-2">
        <h4 className="text-xs font-medium text-zinc-900 dark:text-zinc-100 truncate flex items-center space-x-1.5 tracking-tight">
          {isPinned && <PushPin size={12} weight="fill" className="text-[#22B8A7] shrink-0" />}
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
            className={`w-6 h-6 rounded flex items-center justify-center transition-colors tactile-btn cursor-pointer ${
              isPinned
                ? "text-[#22B8A7] bg-[#22B8A7]/15"
                : "text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200"
            }`}
          >
            <PushPin size={14} weight={isPinned ? "fill" : "regular"} />
          </button>
          <button
            type="button"
            onClick={() => toggleArchive(note.id)}
            title={isArchived ? t("restore") : t("archive")}
            className="w-6 h-6 rounded flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 tactile-btn cursor-pointer"
          >
            <Archive size={14} weight={isArchived ? "fill" : "regular"} />
          </button>
          <button
            type="button"
            onClick={() => deleteNote(note.id)}
            title={t("delete")}
            className="w-6 h-6 rounded flex items-center justify-center text-zinc-400 hover:text-red-500 tactile-btn cursor-pointer"
          >
            <Trash size={14} />
          </button>
        </div>
      </div>

      {/* Snippet */}
      {note.content && (
        <p className="mt-1 text-[11px] text-zinc-500 dark:text-zinc-400 line-clamp-2 leading-relaxed font-sans">
          {note.content}
        </p>
      )}

      {/* Bottom meta */}
      <div className="mt-2 flex items-center justify-between text-[10.5px] text-zinc-400 dark:text-zinc-500">
        <div className="flex items-center space-x-1.5 overflow-hidden">
          {tags.slice(0, 3).map((tag) => (
            <span
              key={tag.id}
              className="inline-flex items-center space-x-1 px-1.5 py-0.2 rounded text-[9.5px] font-medium truncate"
              style={{
                backgroundColor: `${tag.colorHex}15`,
                color: tag.colorHex,
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
