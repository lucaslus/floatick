import React from "react";
import { useTranslation } from "react-i18next";
import { PushPin, Archive, Trash, PencilSimple } from "@phosphor-icons/react";
import type { NoteItem } from "@/types";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import { formatTime } from "@/lib/dateUtils";

interface NoteItemRowProps {
  note: NoteItem;
  onView: (note: NoteItem) => void;
  onEdit: (note: NoteItem) => void;
}

export const NoteItemRow: React.FC<NoteItemRowProps> = ({ note, onView, onEdit }) => {
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
      onClick={() => onView(note)}
      className={`group relative p-2.5 rounded-[8px] transition-colors cursor-pointer select-none ${
        isPinned
          ? "bg-[var(--color-teal-tint)] hover:bg-[var(--color-teal-tint-active)]"
          : "hover:bg-[var(--color-row-hover)]"
      }`}
    >
      {/* Top row: Title (Unobstructed full width) */}
      <div className="flex items-center min-h-[26px]">
        <h4 className="text-[13.5px] font-semibold text-[var(--color-text-primary)] truncate flex items-center space-x-1.5 tracking-tight flex-1 min-w-0">
          {isPinned && <PushPin size={13} weight="fill" className="text-[var(--color-teal-primary)] shrink-0" />}
          <span className="truncate">{note.title || t("newNote")}</span>
        </h4>
      </div>

      {/* Snippet */}
      {note.content && (
        <p className="mt-1 text-[12.5px] text-[var(--color-text-secondary)] line-clamp-2 leading-normal font-sans">
          {note.content}
        </p>
      )}

      {/* Bottom meta & Floating Actions */}
      <div className="mt-2 relative flex items-center justify-between min-h-[24px] text-[11px] font-medium text-[var(--color-text-subtle)]">
        <div className="flex items-center space-x-1.5 overflow-hidden flex-1 min-w-0 mr-2">
          {tags.slice(0, 3).map((tag) => (
            <span
              key={tag.id}
              className="inline-flex items-center space-x-1 px-1 py-0.5 rounded text-[11px] font-medium truncate"
              style={{
                color: tag.colorHex,
              }}
            >
              <span className="w-1.5 h-1.5 rounded-full shrink-0" style={{ backgroundColor: tag.colorHex }} />
              <span>{tag.name}</span>
            </span>
          ))}
          {tags.length > 3 && <span>+{tags.length - 3}</span>}
        </div>
        <span className="font-mono text-[11px] shrink-0 group-hover:opacity-0 transition-opacity duration-150">
          {formatTime(note.updatedAt)}
        </span>

        {/* Floating Hover action icons with Frosted Blur Backdrop on bottom line */}
        <div
          className="absolute right-0 top-1/2 -translate-y-1/2 flex items-center opacity-0 group-hover:opacity-100 transition-opacity duration-150 pointer-events-none group-hover:pointer-events-auto z-10"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="flex items-center space-x-0.5 px-1 py-0.5 rounded-lg bg-[var(--color-bg-drawer)]/92 dark:bg-[var(--color-bg-drawer)]/92 backdrop-blur-md border border-[var(--color-border-drawer)]/70 shadow-sm">
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                onEdit(note);
              }}
              title={t("edit")}
              className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
            >
              <PencilSimple size={14} />
            </button>
            <button
              type="button"
              onClick={() => togglePin(note.id)}
              title={isPinned ? t("unpin") : t("pin")}
              className={`w-6 h-6 rounded flex items-center justify-center transition-colors tactile-btn cursor-pointer ${
                isPinned
                  ? "text-[var(--color-teal-primary)] bg-[var(--color-teal-tint-active)]"
                  : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
              }`}
            >
              <PushPin size={14} weight={isPinned ? "fill" : "regular"} />
            </button>
            <button
              type="button"
              onClick={() => toggleArchive(note.id)}
              title={isArchived ? t("restore") : t("archive")}
              className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
            >
              <Archive size={14} weight={isArchived ? "fill" : "regular"} />
            </button>
            <button
              type="button"
              onClick={() => deleteNote(note.id)}
              title={t("delete")}
              className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-red-400 hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
            >
              <Trash size={14} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
