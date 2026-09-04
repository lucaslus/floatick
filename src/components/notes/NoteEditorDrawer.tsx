import React, { useState, useEffect, useRef } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  PushPin,
  Archive,
  Trash,
  Check,
  Tag,
} from "@phosphor-icons/react";
import { useNoteStore } from "@/stores/useNoteStore";
import { useTagStore } from "@/stores/useTagStore";
import { FloatickTiptapEditor, FloatickEditorHandle } from "@/components/common/FloatickTiptapEditor";

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
  const [showTagMenu, setShowTagMenu] = useState(false);

  const titleInputRef = useRef<HTMLInputElement>(null);
  const editorHandleRef = useRef<FloatickEditorHandle | null>(null);
  const isSavingRef = useRef(false);

  const existingNoteId = note?.id;

  useEffect(() => {
    if (isOpen) {
      if (note) {
        setTitle(note.title);
        setContent(note.content || "");
        setSelectedTagIds(note.tagIds || []);
      } else {
        setTitle("");
        setContent("");
        setSelectedTagIds([]);
      }
      setShowTagMenu(false);

      setTimeout(() => {
        titleInputRef.current?.focus();
        titleInputRef.current?.select();
      }, 50);
    }
  }, [existingNoteId, isOpen]);

  // Global keyboard shortcuts (Cmd+Enter to save, Esc to close)
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.isComposing || (e as any).keyCode === 229) return;
      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault();
        handleSave();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, title, content, selectedTagIds]);

  if (!isOpen) return null;

  const handleSave = async () => {
    if (isSavingRef.current) return;
    const trimmedTitle = title.trim();
    const currentMarkdown = editorHandleRef.current?.getMarkdown() ?? content;
    const trimmedContent = currentMarkdown.trim();

    if (!trimmedTitle && !trimmedContent) {
      onClose();
      return;
    }

    isSavingRef.current = true;
    try {
      if (isCreate) {
        await addNote(trimmedTitle, trimmedContent, selectedTagIds);
      } else {
        await updateNote(note.id, {
          title: trimmedTitle,
          content: trimmedContent,
          tagIds: selectedTagIds,
        });
      }
      onClose();
    } finally {
      isSavingRef.current = false;
    }
  };

  const toggleTag = (tagId: string) => {
    if (selectedTagIds.includes(tagId)) {
      setSelectedTagIds(selectedTagIds.filter((id) => id !== tagId));
    } else {
      setSelectedTagIds([...selectedTagIds, tagId]);
    }
  };

  const canSave = title.trim().length > 0 || content.trim().length > 0;

  return (
    <div className="absolute inset-0 z-50 bg-[var(--color-bg-panel)] text-[var(--color-text-primary)] flex flex-col select-none animate-in fade-in duration-150">
      {/* Top Header Bar (Consistent with Settings) */}
      <div className="h-12 px-5 border-b border-[var(--color-border-panel)] flex items-center justify-between shrink-0 bg-[var(--color-bg-panel)]">
        <div className="flex items-center space-x-2">
          <span className="text-[14px] font-semibold text-[var(--color-text-primary)] tracking-tight">
            {isCreate ? t("newNoteDrawerTitle") : t("editNoteDrawerTitle")}
          </span>
          {note && (
            <div className="flex items-center space-x-1 ml-2 border-l border-[var(--color-border-panel)] pl-2">
              <button
                type="button"
                onClick={() => togglePin(note.id)}
                title={note.pinnedAt ? t("unpin") : t("pin")}
                className={`w-6 h-6 rounded flex items-center justify-center transition-colors tactile-btn cursor-pointer ${
                  note.pinnedAt
                    ? "text-[var(--color-teal-primary)] bg-[var(--color-teal-tint-active)]"
                    : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]"
                }`}
              >
                <PushPin size={15} weight={note.pinnedAt ? "fill" : "regular"} />
              </button>
              <button
                type="button"
                onClick={() => toggleArchive(note.id)}
                title={note.archivedAt ? t("restore") : t("archive")}
                className={`w-6 h-6 rounded flex items-center justify-center transition-colors tactile-btn cursor-pointer ${
                  note.archivedAt
                    ? "text-amber-500 bg-amber-500/15"
                    : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]"
                }`}
              >
                <Archive size={15} weight={note.archivedAt ? "fill" : "regular"} />
              </button>
              <button
                type="button"
                onClick={() => {
                  deleteNote(note.id);
                  onClose();
                }}
                title={t("delete")}
                className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-red-400 tactile-btn cursor-pointer"
              >
                <Trash size={15} />
              </button>
            </div>
          )}
        </div>

        <button
          type="button"
          onClick={onClose}
          title={t("escToClose")}
          className="w-7 h-7 rounded-lg flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] transition-colors tactile-btn cursor-pointer"
        >
          <X size={16} weight="bold" />
        </button>
      </div>

      {/* Main Canvas Area */}
      <div className="flex-1 flex flex-col min-h-0 overflow-hidden">
        {/* Title Input */}
        <div className="px-5 pt-4 pb-2 shrink-0">
          <input
            ref={titleInputRef}
            type="text"
            value={title}
            onChange={(e) => {
              const val = e.target.value;
              if (!title && val === " ") return;
              setTitle(val);
            }}
            onKeyDown={(e) => {
              if (e.nativeEvent.isComposing || e.keyCode === 229) return;
              if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
                e.preventDefault();
                e.stopPropagation();
                handleSave();
                return;
              }
              if (e.key === "Enter") {
                e.preventDefault();
                editorHandleRef.current?.focus();
              }
            }}
            placeholder={t("noteTitlePlaceholder")}
            className="w-full text-[17px] font-semibold bg-transparent text-[var(--color-text-primary)] placeholder:text-[var(--color-text-subtle)] focus:outline-none focus:placeholder-transparent transition-colors tracking-tight"
          />
        </div>

        {/* Metadata Properties Row: Tags directly beneath Title */}
        <div className="px-5 pb-3 flex items-center flex-wrap gap-1.5 shrink-0">
          {/* Tag Selector Trigger Button */}
          <div className="relative">
            <button
              type="button"
              onClick={() => setShowTagMenu(!showTagMenu)}
              title={t("tags")}
              className={`h-[26px] px-2.5 rounded-md flex items-center space-x-1.5 text-[11.5px] font-medium transition-colors tactile-btn cursor-pointer ${
                selectedTagIds.length > 0
                  ? "text-[var(--color-teal-primary)] bg-[var(--color-teal-tint-active)]"
                  : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] bg-[var(--color-hover-overlay)] hover:bg-[var(--color-hover-overlay)]/80"
              }`}
            >
              <Tag size={13} weight={selectedTagIds.length > 0 ? "fill" : "regular"} />
              <span>{t("tags")}</span>
            </button>

            {/* Tag Dropdown Popover */}
            {showTagMenu && (
              <>
                <div
                  className="fixed inset-0 z-30"
                  onClick={() => setShowTagMenu(false)}
                />
                <div className="absolute left-0 top-7.5 z-40 w-48 bg-[var(--color-bg-drawer)] rounded-xl shadow-2xl border border-[var(--color-border-drawer)] py-1.5 text-xs animate-in fade-in zoom-in-95 duration-100 max-h-56 overflow-y-auto smooth-scroll">
                  <div className="px-3 py-1 text-[11px] font-semibold text-[var(--color-text-subtle)] uppercase tracking-wider">
                    {t("tags")}
                  </div>
                  {tagsWorkspace.tags.length === 0 ? (
                    <div className="px-3 py-2 text-[12px] text-[var(--color-text-subtle)]">
                      {t("noTagsYetMessage")}
                    </div>
                  ) : (
                    tagsWorkspace.tags.map((tag) => {
                      const isSelected = selectedTagIds.includes(tag.id);
                      return (
                        <button
                          key={tag.id}
                          type="button"
                          onClick={() => toggleTag(tag.id)}
                          className="w-full px-3 py-1.5 flex items-center justify-between hover:bg-[var(--color-hover-overlay)] text-left cursor-pointer"
                        >
                          <div className="flex items-center space-x-2 truncate">
                            <span
                              className="w-2 h-2 rounded-full shrink-0"
                              style={{ backgroundColor: tag.colorHex }}
                            />
                            <span className="truncate text-[var(--color-text-primary)] text-[12.5px] font-medium">
                              {tag.name}
                            </span>
                          </div>
                          {isSelected && (
                            <Check size={14} weight="bold" className="text-[var(--color-teal-primary)] shrink-0" />
                          )}
                        </button>
                      );
                    })
                  )}
                </div>
              </>
            )}
          </div>

          {/* Selected Tag Pills (displayed right next to Tag button) */}
          {selectedTagIds.map((tagId) => {
            const tag = tagsWorkspace.tags.find((t) => t.id === tagId);
            if (!tag) return null;
            return (
              <button
                key={tag.id}
                type="button"
                onClick={() => toggleTag(tag.id)}
                title={tag.name}
                className="inline-flex items-center space-x-1.5 h-[26px] px-2 rounded-md text-[11px] font-medium shrink-0 transition-opacity hover:opacity-80 tactile-btn cursor-pointer"
                style={{
                  backgroundColor: `${tag.colorHex}18`,
                  border: `1px solid ${tag.colorHex}35`,
                  color: tag.colorHex,
                }}
              >
                <span
                  className="w-1.5 h-1.5 rounded-full shrink-0"
                  style={{ backgroundColor: tag.colorHex }}
                />
                <span className="truncate max-w-[90px]">{tag.name}</span>
                <X size={10} weight="bold" className="ml-0.5 opacity-60 hover:opacity-100" />
              </button>
            );
          })}
        </div>

        {/* Clean Hairline Divider */}
        <div className="mx-5 border-b border-[var(--color-border-panel)] shrink-0" />

        {/* Tiptap Editor Canvas */}
        <div className="flex-1 flex flex-col min-h-0 px-5 pt-2.5 pb-2 overflow-hidden">
          <FloatickTiptapEditor
            key={existingNoteId || "new"}
            initialContent={content}
            editorRef={editorHandleRef}
            onChange={(md) => setContent(md)}
            onCmdEnter={handleSave}
          />
        </div>
      </div>

      {/* Bottom Footer Bar */}
      <div className="h-11 px-5 border-t border-[var(--color-border-panel)] flex items-center justify-between shrink-0 bg-[var(--color-bg-panel)]">
        <span className="text-[11.5px] text-[var(--color-text-subtle)]">
          {t("shortcutHint")}
        </span>

        <div className="flex items-center space-x-2">
          <button
            type="button"
            onClick={onClose}
            className="px-3 py-1 text-[12px] font-medium text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] rounded-md transition-colors cursor-pointer tactile-btn"
          >
            {t("cancel")}
          </button>
          <button
            type="button"
            onClick={handleSave}
            disabled={!canSave}
            className="px-3.5 py-1 text-[12px] font-medium bg-[var(--color-teal-primary)] hover:bg-[var(--color-teal-primary)]/90 text-white rounded-md transition-colors cursor-pointer tactile-btn disabled:opacity-40 disabled:pointer-events-none shadow-xs flex items-center space-x-1.5"
          >
            <Check size={14} weight="bold" />
            <span>{t("save")}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
