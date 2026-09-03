import React, { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { X, Pin, Archive, Trash2, Check } from "lucide-react";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface NoteEditorDrawerProps {
  noteId: string | null;
  onClose: () => void;
}

export const NoteEditorDrawer: React.FC<NoteEditorDrawerProps> = ({
  noteId,
  onClose,
}) => {
  const { t } = useTranslation();
  const notes = useNoteStore((s) => s.notes);
  const updateNote = useNoteStore((s) => s.updateNote);
  const deleteNote = useNoteStore((s) => s.deleteNote);
  const togglePin = useNoteStore((s) => s.togglePin);
  const toggleArchive = useNoteStore((s) => s.toggleArchive);

  const tagsWorkspace = useTagStore((s) => s.workspace);

  const note = notes.find((n) => n.id === noteId);

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<"edit" | "preview">("edit");

  useEffect(() => {
    if (note) {
      setTitle(note.title);
      setContent(note.content);
      setSelectedTagIds(note.tagIds || []);
    }
  }, [note]);

  if (!note) return null;

  const handleSaveAndClose = async () => {
    await updateNote(note.id, {
      title: title.trim(),
      content: content.trim(),
      tagIds: selectedTagIds,
    });
    onClose();
  };

  const toggleTag = (tagId: string) => {
    if (selectedTagIds.includes(tagId)) {
      setSelectedTagIds(selectedTagIds.filter((id) => id !== tagId));
    } else {
      setSelectedTagIds([...selectedTagIds, tagId]);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-white/95 dark:bg-zinc-900/95 backdrop-blur-xl animate-in fade-in duration-200">
      {/* Header */}
      <div className="h-11 px-3 border-b border-black/[0.06] dark:border-white/[0.08] flex items-center justify-between">
        <div className="flex items-center space-x-1.5">
          <button
            onClick={() => togglePin(note.id)}
            title={note.pinnedAt ? "取消置顶" : "置顶笔记"}
            className={`w-7 h-7 rounded-md flex items-center justify-center transition-colors ${
              note.pinnedAt
                ? "text-teal-600 bg-teal-50 dark:bg-teal-950/40"
                : "text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-black/[0.05]"
            }`}
          >
            <Pin className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => toggleArchive(note.id)}
            title={note.archivedAt ? "恢复笔记" : "归档笔记"}
            className={`w-7 h-7 rounded-md flex items-center justify-center transition-colors ${
              note.archivedAt
                ? "text-amber-600 bg-amber-50 dark:bg-amber-950/40"
                : "text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-black/[0.05]"
            }`}
          >
            <Archive className="w-3.5 h-3.5" />
          </button>
          <button
            onClick={() => {
              deleteNote(note.id);
              onClose();
            }}
            title="删除笔记"
            className="w-7 h-7 rounded-md flex items-center justify-center text-zinc-400 hover:text-red-600 hover:bg-black/[0.05]"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Edit / Preview Tabs */}
        <div className="flex items-center space-x-2">
          <div className="flex items-center bg-black/[0.04] dark:bg-white/[0.06] rounded-md p-0.5">
            <button
              type="button"
              onClick={() => setActiveTab("edit")}
              className={`px-2 py-0.5 rounded text-[10px] ${
                activeTab === "edit"
                  ? "bg-white dark:bg-zinc-800 font-medium text-zinc-900 dark:text-white shadow-xs"
                  : "text-zinc-500"
              }`}
            >
              {t("write")}
            </button>
            <button
              type="button"
              onClick={() => setActiveTab("preview")}
              className={`px-2 py-0.5 rounded text-[10px] ${
                activeTab === "preview"
                  ? "bg-white dark:bg-zinc-800 font-medium text-zinc-900 dark:text-white shadow-xs"
                  : "text-zinc-500"
              }`}
            >
              {t("preview")}
            </button>
          </div>

          <button
            onClick={handleSaveAndClose}
            className="w-7 h-7 rounded-md flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.05]"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Body */}
      <div className="flex-1 flex flex-col p-4 overflow-hidden space-y-3">
        {/* Title Input */}
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="笔记标题"
          className="w-full text-sm font-semibold bg-transparent border-none outline-none text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400"
        />

        {/* Tags Row */}
        <div className="flex flex-wrap gap-1 items-center pb-2 border-b border-black/[0.04] dark:border-white/[0.06]">
          {tagsWorkspace.tags.map((tag) => {
            const isSelected = selectedTagIds.includes(tag.id);
            return (
              <button
                key={tag.id}
                type="button"
                onClick={() => toggleTag(tag.id)}
                className={`inline-flex items-center space-x-1 px-2 py-0.5 rounded-full text-[10px] transition-all cursor-pointer ${
                  isSelected ? "font-medium ring-2 ring-teal-500/50" : "opacity-60 hover:opacity-100"
                }`}
                style={{
                  backgroundColor: `${tag.colorHex}20`,
                  color: tag.colorHex,
                  border: `1px solid ${tag.colorHex}55`,
                }}
              >
                {isSelected && <Check className="w-2 h-2" />}
                <span>{tag.name}</span>
              </button>
            );
          })}
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto">
          {activeTab === "edit" ? (
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="开始输入 Markdown 便签内容…"
              className="w-full h-full bg-transparent border-none outline-none resize-none text-xs text-zinc-800 dark:text-zinc-200 placeholder:text-zinc-400 font-mono leading-relaxed select-text"
            />
          ) : (
            <div className="w-full h-full prose prose-zinc dark:prose-invert prose-xs max-w-none select-text">
              {content ? (
                <Markdown remarkPlugins={[remarkGfm]}>{content}</Markdown>
              ) : (
                <span className="text-zinc-400 italic">暂无内容</span>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Footer */}
      <div className="h-10 px-4 border-t border-black/[0.06] dark:border-white/[0.08] flex items-center justify-between text-[11px] text-zinc-400">
        <span>{content.length} 字符</span>
        <button
          onClick={handleSaveAndClose}
          className="px-3 py-1 rounded-lg bg-teal-600 hover:bg-teal-700 text-white font-medium text-xs shadow-xs cursor-pointer"
        >
          完成
        </button>
      </div>
    </div>
  );
};
