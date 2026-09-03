import React, { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { X, Pin, Archive, Trash2, Check, Tag as TagIcon } from "lucide-react";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface NoteEditorDrawerProps {
  noteId: string | null;
  isOpen: boolean;
  onClose: () => void;
}

export const NoteEditorDrawer: React.FC<NoteEditorDrawerProps> = ({
  noteId,
  isOpen,
  onClose,
}) => {
  const { t } = useTranslation();
  const notes = useNoteStore((s) => s.notes);
  const addNote = useNoteStore((s) => s.addNote);
  const updateNote = useNoteStore((s) => s.updateNote);
  const deleteNote = useNoteStore((s) => s.deleteNote);
  const togglePin = useNoteStore((s) => s.togglePin);
  const toggleArchive = useNoteStore((s) => s.toggleArchive);

  const tagsWorkspace = useTagStore((s) => s.workspace);

  const note = notes.find((n) => n.id === noteId);
  const isCreate = !note;

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<"edit" | "preview">("edit");

  useEffect(() => {
    if (note) {
      setTitle(note.title);
      setContent(note.content);
      setSelectedTagIds(note.tagIds || []);
    } else {
      setTitle("");
      setContent("");
      setSelectedTagIds([]);
    }
  }, [note, isOpen]);

  if (!isOpen) return null;

  const handleSaveAndClose = async () => {
    if (isCreate) {
      if (title.trim() || content.trim()) {
        await addNote(title.trim(), content.trim(), selectedTagIds);
      }
    } else {
      await updateNote(note.id, {
        title: title.trim(),
        content: content.trim(),
        tagIds: selectedTagIds,
      });
    }
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
    <>
      {/* Scrim */}
      <div
        className="absolute inset-0 z-40 bg-black/40 backdrop-blur-[2px] transition-opacity duration-200"
        onClick={handleSaveAndClose}
      />

      {/* Slide-up Bottom Drawer */}
      <div className="absolute inset-x-0 bottom-0 z-50 h-[590px] rounded-t-[22px] bg-[#F9FBFA] dark:bg-[#1D2529] text-zinc-900 dark:text-[#EEF2F1] border-t border-black/[0.08] dark:border-white/[0.1] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-220">
        {/* Header */}
        <div className="h-12 px-5 border-b border-black/[0.05] dark:border-white/[0.06] flex items-center justify-between">
          <div className="flex items-center space-x-1">
            {note && (
              <>
                <button
                  type="button"
                  onClick={() => togglePin(note.id)}
                  title={note.pinnedAt ? t("unpin") : t("pin")}
                  className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors cursor-pointer ${
                    note.pinnedAt
                      ? "text-teal-600 dark:text-[#22B8A7] bg-teal-500/10"
                      : "text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
                  }`}
                >
                  <Pin className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={() => toggleArchive(note.id)}
                  title={note.archivedAt ? t("restore") : t("archive")}
                  className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors cursor-pointer ${
                    note.archivedAt
                      ? "text-amber-600 bg-amber-500/10"
                      : "text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
                  }`}
                >
                  <Archive className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={() => {
                    deleteNote(note.id);
                    onClose();
                  }}
                  title={t("delete")}
                  className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-red-500 hover:bg-black/[0.04] dark:hover:bg-white/[0.06] cursor-pointer"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </>
            )}
            {isCreate && (
              <span className="text-xs font-semibold text-zinc-800 dark:text-[#EEF2F1]">
                {t("newNote")}
              </span>
            )}
          </div>

          {/* Edit / Preview Tabs + Close */}
          <div className="flex items-center space-x-2">
            <div className="flex items-center bg-black/[0.04] dark:bg-white/[0.06] rounded-lg p-0.5">
              <button
                type="button"
                onClick={() => setActiveTab("edit")}
                className={`px-2 py-0.5 rounded text-[10px] ${
                  activeTab === "edit"
                    ? "bg-white dark:bg-[#151B1E] font-medium text-zinc-900 dark:text-white shadow-xs"
                    : "text-zinc-500"
                }`}
              >
                {t("markdownWriteLabel")}
              </button>
              <button
                type="button"
                onClick={() => setActiveTab("preview")}
                className={`px-2 py-0.5 rounded text-[10px] ${
                  activeTab === "preview"
                    ? "bg-white dark:bg-[#151B1E] font-medium text-zinc-900 dark:text-white shadow-xs"
                    : "text-zinc-500"
                }`}
              >
                {t("markdownPreviewLabel")}
              </button>
            </div>

            <button
              type="button"
              onClick={handleSaveAndClose}
              className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.04] dark:hover:bg-white/[0.06] cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Body */}
        <div className="flex-1 flex flex-col p-5 overflow-hidden space-y-3 text-xs">
          {/* Title Input */}
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="便签标题"
            className="w-full text-sm font-semibold bg-transparent border-none outline-none text-zinc-900 dark:text-[#EEF2F1] placeholder:text-zinc-400"
          />

          {/* Tags Row */}
          <div className="flex flex-wrap gap-1.5 items-center pb-2 border-b border-black/[0.04] dark:border-white/[0.06]">
            <TagIcon className="w-3 h-3 text-zinc-400 mr-1" />
            {tagsWorkspace.tags.map((tag) => {
              const isSelected = selectedTagIds.includes(tag.id);
              return (
                <button
                  key={tag.id}
                  type="button"
                  onClick={() => toggleTag(tag.id)}
                  className={`inline-flex items-center space-x-1 px-2.5 py-0.8 rounded-full text-[10px] transition-all cursor-pointer ${
                    isSelected
                      ? "font-medium ring-2 ring-teal-500/50"
                      : "opacity-60 hover:opacity-100"
                  }`}
                  style={{
                    backgroundColor: `${tag.colorHex}22`,
                    color: tag.colorHex,
                    border: `1px solid ${tag.colorHex}55`,
                  }}
                >
                  {isSelected && <Check className="w-2.5 h-2.5" />}
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
                placeholder="使用 Markdown 输入便签内容…"
                className="w-full h-full bg-transparent border-none outline-none resize-none text-xs text-zinc-800 dark:text-[#EEF2F1] placeholder:text-zinc-400 font-mono leading-relaxed select-text"
              />
            ) : (
              <div className="w-full h-full prose prose-zinc dark:prose-invert prose-xs max-w-none select-text">
                {content ? (
                  <Markdown remarkPlugins={[remarkGfm]}>{content}</Markdown>
                ) : (
                  <span className="text-zinc-400 italic">
                    {t("markdownPreviewEmptyMessage")}
                  </span>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="h-12 px-5 border-t border-black/[0.05] dark:border-white/[0.06] flex items-center justify-between text-[11px] text-zinc-400">
          <span>{content.length} 字符</span>
          <button
            type="button"
            onClick={handleSaveAndClose}
            className="px-4 py-1.5 rounded-xl bg-teal-600 hover:bg-teal-700 dark:bg-[#22B8A7] dark:hover:bg-[#1CA394] text-white font-medium text-xs shadow-xs cursor-pointer"
          >
            完成
          </button>
        </div>
      </div>
    </>
  );
};
