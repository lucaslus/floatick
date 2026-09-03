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
        className="absolute inset-0 z-40 bg-black/50 backdrop-blur-xs transition-opacity duration-200"
        onClick={handleSaveAndClose}
      />

      {/* Slide-up Luxury Bottom Sheet */}
      <div className="absolute inset-x-0 bottom-0 z-50 h-[590px] rounded-t-[26px] bg-[#141A1E] text-[#F1F5F9] border-t border-white/[0.12] shadow-[0_-20px_50px_rgba(0,0,0,0.6)] flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-220">
        {/* Grab Handle */}
        <div className="w-10 h-1 rounded-full bg-white/20 mx-auto mt-2.5 mb-0.5 pointer-events-none" />

        {/* Header */}
        <div className="h-11 px-5 border-b border-white/[0.07] flex items-center justify-between">
          <div className="flex items-center space-x-1">
            {note && (
              <>
                <button
                  type="button"
                  onClick={() => togglePin(note.id)}
                  title={note.pinnedAt ? t("unpin") : t("pin")}
                  className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors tactile-btn cursor-pointer ${
                    note.pinnedAt
                      ? "text-teal-400 bg-teal-500/15"
                      : "text-zinc-400 hover:text-white hover:bg-white/[0.06]"
                  }`}
                >
                  <Pin className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={() => toggleArchive(note.id)}
                  title={note.archivedAt ? t("restore") : t("archive")}
                  className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors tactile-btn cursor-pointer ${
                    note.archivedAt
                      ? "text-amber-400 bg-amber-500/15"
                      : "text-zinc-400 hover:text-white hover:bg-white/[0.06]"
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
                  className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-red-400 hover:bg-white/[0.06] tactile-btn cursor-pointer"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </>
            )}
            {isCreate && (
              <span className="text-xs font-semibold text-[#F1F5F9] tracking-tight">
                {t("newNote")}
              </span>
            )}
          </div>

          {/* Edit / Preview Tabs + Close */}
          <div className="flex items-center space-x-2">
            <div className="flex items-center bg-black/30 rounded-lg p-0.5 border border-white/[0.06]">
              <button
                type="button"
                onClick={() => setActiveTab("edit")}
                className={`px-2.5 py-0.5 rounded-md text-[10.5px] font-medium transition-all ${
                  activeTab === "edit"
                    ? "bg-[#1E272E] text-white shadow-xs"
                    : "text-zinc-400 hover:text-white"
                }`}
              >
                {t("markdownWriteLabel")}
              </button>
              <button
                type="button"
                onClick={() => setActiveTab("preview")}
                className={`px-2.5 py-0.5 rounded-md text-[10.5px] font-medium transition-all ${
                  activeTab === "preview"
                    ? "bg-[#1E272E] text-white shadow-xs"
                    : "text-zinc-400 hover:text-white"
                }`}
              >
                {t("markdownPreviewLabel")}
              </button>
            </div>

            <button
              type="button"
              onClick={handleSaveAndClose}
              className="w-7 h-7 rounded-full flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/[0.08] tactile-btn cursor-pointer"
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
            placeholder={t("noteTitlePlaceholder")}
            className="w-full text-sm font-semibold bg-transparent border-none outline-none text-[#F1F5F9] placeholder:text-[#64748B] tracking-tight"
          />

          {/* Tags Row */}
          <div className="flex flex-wrap gap-1.5 items-center pb-2.5 border-b border-white/[0.07]">
            <TagIcon className="w-3 h-3 text-[#64748B] mr-1" />
            {tagsWorkspace.tags.map((tag) => {
              const isSelected = selectedTagIds.includes(tag.id);
              return (
                <button
                  key={tag.id}
                  type="button"
                  onClick={() => toggleTag(tag.id)}
                  className={`inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-[10.5px] font-medium transition-all tactile-btn cursor-pointer ${
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
                <div className="flex items-center space-x-0.5 px-1.5 py-1 rounded-t-xl bg-black/30 border-x border-t border-white/[0.08] text-zinc-400">
                  <button
                    type="button"
                    onClick={() => insertMarkdown("**", "**")}
                    title={t("bold")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white tactile-btn"
                  >
                    <Bold className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("*", "*")}
                    title={t("italic")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white tactile-btn"
                  >
                    <Italic className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- ")}
                    title={t("bulletList")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white tactile-btn"
                  >
                    <List className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- [ ] ")}
                    title={t("taskList")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white tactile-btn"
                  >
                    <CheckSquare className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("`", "`")}
                    title={t("inlineCode")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white tactile-btn"
                  >
                    <Code className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("[", "](url)")}
                    title={t("link")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white tactile-btn"
                  >
                    <Link className="w-3 h-3" />
                  </button>
                </div>

                <textarea
                  id="note-content-textarea"
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder={t("noteContentPlaceholder")}
                  className="flex-1 w-full p-3.5 rounded-b-xl border border-white/[0.08] bg-black/25 text-[#F1F5F9] focus:outline-none focus:ring-2 focus:ring-teal-500/30 focus:border-[#2DD4BF] font-mono text-[11.5px] leading-relaxed resize-none select-text shadow-inner"
                />
              </div>
            ) : (
              <div className="w-full h-full overflow-y-auto p-4 rounded-xl border border-white/[0.08] bg-black/25 shadow-inner">
                <FloatickMarkdown
                  content={content}
                  emptyMessage={t("markdownPreviewEmptyMessage")}
                />
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="h-12 px-5 border-t border-white/[0.07] flex items-center justify-between text-[11px] text-[#94A3B8] bg-black/15">
          <span>{t("charactersCount", { count: content.length })}</span>
          <button
            type="button"
            onClick={handleSaveAndClose}
            className="px-6 py-1.5 rounded-full bg-gradient-to-r from-teal-500 to-teal-400 text-zinc-950 font-semibold text-xs shadow-[0_4px_16px_rgba(20,184,166,0.35)] tactile-btn cursor-pointer transition-all"
          >
            {t("finish")}
          </button>
        </div>
      </div>
    </>
  );
};
