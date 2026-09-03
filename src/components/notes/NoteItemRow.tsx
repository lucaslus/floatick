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
      className={`group relative p-3 rounded-xl transition-all duration-150 border cursor-pointer ${
        isPinned
          ? "bg-teal-50/60 dark:bg-teal-950/20 border-teal-200/80 dark:border-teal-900/40 shadow-xs"
          : "bg-white/60 dark:bg-zinc-800/60 border-black/[0.04] dark:border-white/[0.04] hover:border-black/[0.08] dark:hover:border-white/[0.08] shadow-xs"
      }`}
    >
      {/* Top row: Title & Actions */}
      <div className="flex items-center justify-between space-x-2">
        <h4 className="text-xs font-semibold text-zinc-900 dark:text-zinc-100 truncate flex items-center space-x-1.5">
          {isPinned && <Pin className="w-3 h-3 text-teal-600 fill-teal-600 shrink-0" />}
          <span>{note.title || "无标题笔记"}</span>
        </h4>

        {/* Hover action icons */}
        <div
          className="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity"
          onClick={(e) => e.stopPropagation()}
        >
          <button
            onClick={() => togglePin(note.id)}
            title={isPinned ? "取消置顶" : "置顶笔记"}
            className={`w-5 h-5 rounded flex items-center justify-center transition-colors ${
              isPinned ? "text-teal-600" : "text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200"
            }`}
          >
            <Pin className="w-3 h-3" />
          </button>
          <button
            onClick={() => toggleArchive(note.id)}
            title={isArchived ? "恢复笔记" : "归档笔记"}
            className="w-5 h-5 rounded flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200"
          >
            <Archive className="w-3 h-3" />
          </button>
          <button
            onClick={() => deleteNote(note.id)}
            title="删除笔记"
            className="w-5 h-5 rounded flex items-center justify-center text-zinc-400 hover:text-red-600"
          >
            <Trash2 className="w-3 h-3" />
          </button>
        </div>
      </div>

      {/* Snippet */}
      {note.content && (
        <p className="mt-1 text-[11px] text-zinc-500 dark:text-zinc-400 line-clamp-2 leading-relaxed">
          {note.content}
        </p>
      )}

      {/* Bottom meta: tags and updated time */}
      <div className="mt-2 flex items-center justify-between text-[10px] text-zinc-400">
        <div className="flex items-center space-x-1 overflow-hidden">
          {tags.slice(0, 3).map((tag) => (
            <span
              key={tag.id}
              className="px-1.5 py-0.2 rounded-full text-[9px] font-medium truncate"
              style={{
                backgroundColor: `${tag.colorHex}22`,
                color: tag.colorHex,
                border: `1px solid ${tag.colorHex}44`,
              }}
            >
              {tag.name}
            </span>
          ))}
          {tags.length > 3 && <span>+{tags.length - 3}</span>}
        </div>
        <span>{formatTime(note.updatedAt)}</span>
      </div>
    </div>
  );
};
