import React, { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  Pin,
  Archive,
  Trash2,
  Check,
  Tag as TagIcon,
  Bold,
  Italic,
  List,
  CheckSquare,
  Code,
  Link,
} from "lucide-react";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import { FloatickMarkdown } from "@/components/common/FloatickMarkdown";

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

  const insertMarkdown = (before: string, after: string = "") => {
    const textarea = document.getElementById("note-content-textarea") as HTMLTextAreaElement | null;
    if (!textarea) {
      setContent((prev) => prev + before + after);
      return;
    }
    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const previousText = textarea.value;
    const selectedText = previousText.substring(start, end);
    const replacement = before + selectedText + after;
    const newText = previousText.substring(0, start) + replacement + previousText.substring(end);
    setContent(newText);
    setTimeout(() => {
      textarea.focus();
      textarea.setSelectionRange(start + before.length, end + before.length);
    }, 10);
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
                  className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors mui-ripple cursor-pointer ${
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
                  className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors mui-ripple cursor-pointer ${
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
                  className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-red-500 hover:bg-black/[0.04] dark:hover:bg-white/[0.06] mui-ripple cursor-pointer"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </>
            )}
            {isCreate && (
              <span className="text-xs font-semibold text-zinc-800 dark:text-[#EEF2F1] tracking-tight">
                {t("newNote")}
              </span>
            )}
          </div>

          {/* Edit / Preview Tabs + Close */}
          <div className="flex items-center space-x-2">
            <div className="flex items-center bg-black/[0.04] dark:bg-white/[0.06] rounded-lg p-0.5 border border-black/[0.03] dark:border-white/[0.04]">
              <button
                type="button"
                onClick={() => setActiveTab("edit")}
                className={`px-2.5 py-0.5 rounded-md text-[10.5px] font-medium transition-all ${
                  activeTab === "edit"
                    ? "bg-white dark:bg-[#151B1E] text-zinc-900 dark:text-white shadow-xs"
                    : "text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-300"
                }`}
              >
                {t("markdownWriteLabel")}
              </button>
              <button
                type="button"
                onClick={() => setActiveTab("preview")}
                className={`px-2.5 py-0.5 rounded-md text-[10.5px] font-medium transition-all ${
                  activeTab === "preview"
                    ? "bg-white dark:bg-[#151B1E] text-zinc-900 dark:text-white shadow-xs"
                    : "text-zinc-500 hover:text-zinc-800 dark:hover:text-zinc-300"
                }`}
              >
                {t("markdownPreviewLabel")}
              </button>
            </div>

            <button
              type="button"
              onClick={handleSaveAndClose}
              className="w-7 h-7 rounded-full flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.04] dark:hover:bg-white/[0.06] mui-ripple cursor-pointer"
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
            placeholder={t("title")}
            className="w-full text-sm font-semibold bg-transparent border-none outline-none text-zinc-900 dark:text-[#EEF2F1] placeholder:text-zinc-400 tracking-tight"
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
                  className={`inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-[10.5px] font-medium transition-all mui-ripple cursor-pointer ${
                    isSelected
                      ? "ring-2 ring-teal-500/60 shadow-xs"
                      : "opacity-60 hover:opacity-100"
                  }`}
                  style={{
                    backgroundColor: `${tag.colorHex}22`,
                    color: tag.colorHex,
                    border: `1px solid ${tag.colorHex}55`,
                  }}
                >
                  {isSelected && <Check className="w-2.5 h-2.5 stroke-[3]" />}
                  <span>{tag.name}</span>
                </button>
              );
            })}
          </div>

          {/* Content Area */}
          <div className="flex-1 overflow-y-auto">
            {activeTab === "edit" ? (
              <div className="h-full flex flex-col space-y-1">
                {/* Markdown Toolbar */}
                <div className="flex items-center space-x-0.5 px-1 py-1 rounded-t-xl bg-black/[0.03] dark:bg-white/[0.04] border-x border-t border-black/[0.08] dark:border-white/[0.1] text-zinc-500 dark:text-zinc-400">
                  <button
                    type="button"
                    onClick={() => insertMarkdown("**", "**")}
                    title="加粗"
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Bold className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("*", "*")}
                    title="斜体"
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Italic className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- ")}
                    title="无序列表"
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <List className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- [ ] ")}
                    title="任务列表"
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <CheckSquare className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("`", "`")}
                    title="行内代码"
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Code className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("[", "](url)")}
                    title="链接"
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Link className="w-3 h-3" />
                  </button>
                </div>

                <textarea
                  id="note-content-textarea"
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder={t("content")}
                  className="flex-1 w-full p-3 rounded-b-xl border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-[#151B1E] text-zinc-900 dark:text-[#EEF2F1] focus:outline-none focus:ring-2 focus:ring-teal-500/30 focus:border-teal-600 dark:focus:border-[#22B8A7] font-mono text-[11.5px] leading-relaxed resize-none select-text shadow-xs"
                />
              </div>
            ) : (
              <div className="w-full h-full overflow-y-auto p-4 rounded-xl border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-[#151B1E] shadow-xs">
                <FloatickMarkdown
                  content={content}
                  emptyMessage={t("markdownPreviewEmptyMessage")}
                />
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
            className="px-5 py-1.5 rounded-full bg-teal-600 hover:bg-teal-700 dark:bg-[#22B8A7] dark:hover:bg-[#1CA394] text-white font-medium text-xs shadow-md mui-ripple cursor-pointer transition-all"
          >
            {t("finish")}
          </button>
        </div>
      </div>
    </>
  );
};
