import React, { useState, useEffect, useRef } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  Tag,
  CalendarBlank,
  Check,
  Eye,
  PencilSimple,
  Clock,
} from "@phosphor-icons/react";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { TodoDeadlinePicker } from "./TodoDeadlinePicker";
import { FloatickTiptapEditor, FloatickEditorHandle } from "@/components/common/FloatickTiptapEditor";
import { FloatickMarkdown } from "@/components/common/FloatickMarkdown";
import { formatDeadline } from "@/lib/dateUtils";

interface TodoEditorDrawerProps {
  todoId: string | null;
  isOpen: boolean;
  onClose: () => void;
}

export const TodoEditorDrawer: React.FC<TodoEditorDrawerProps> = ({
  todoId,
  isOpen,
  onClose,
}) => {
  const { t, i18n } = useTranslation();
  const todos = useTodoStore((s) => s.todos);
  const addTodo = useTodoStore((s) => s.addTodo);
  const updateTodo = useTodoStore((s) => s.updateTodo);
  const storeEditorMode = useTodoStore((s) => s.editorMode);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const setTodoTags = useTagStore((s) => s.setTodoTags);

  const existingTodo = todos.find((t) => t.id === todoId);
  const isCreate = !existingTodo;

  const [mode, setMode] = useState<"view" | "edit">("view");
  const [title, setTitle] = useState(existingTodo?.title || "");
  const [content, setContent] = useState(existingTodo?.content || "");
  const [dueAt, setDueAt] = useState<string | null>(existingTodo?.dueAt || null);
  const [reminderAt, setReminderAt] = useState<string | null>(existingTodo?.reminderAt || null);
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>(
    (existingTodo && tagsWorkspace.assignments[existingTodo.id]) || []
  );
  const [showDeadlinePicker, setShowDeadlinePicker] = useState(false);
  const [showTagMenu, setShowTagMenu] = useState(false);

  const titleInputRef = useRef<HTMLInputElement>(null);
  const editorHandleRef = useRef<FloatickEditorHandle | null>(null);
  const isSavingRef = useRef(false);

  const existingTodoId = existingTodo?.id;

  useEffect(() => {
    if (isOpen) {
      if (existingTodo) {
        setTitle(existingTodo.title);
        setContent(existingTodo.content || "");
        setDueAt(existingTodo.dueAt || null);
        setReminderAt(existingTodo.reminderAt || null);
        setSelectedTagIds(tagsWorkspace.assignments[existingTodo.id] || []);
        setMode(storeEditorMode || "view");
      } else {
        setTitle("");
        setContent("");
        setDueAt(null);
        setReminderAt(null);
        setSelectedTagIds([]);
        setMode("edit");
      }
      setShowDeadlinePicker(false);
      setShowTagMenu(false);

      if (!existingTodo) {
        setTimeout(() => {
          titleInputRef.current?.focus();
        }, 60);
      }
    }
  }, [existingTodoId, isOpen, storeEditorMode]);

  // Global keyboard shortcuts
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.isComposing || (e as any).keyCode === 229) return;

      // In view mode: pressing 'e' or 'E' (not typing in an input) switches to edit
      if (mode === "view") {
        const activeTag = document.activeElement?.tagName?.toLowerCase();
        if (activeTag !== "input" && activeTag !== "textarea") {
          if (e.key.toLowerCase() === "e") {
            e.preventDefault();
            setMode("edit");
            return;
          }
        }
      }

      // In edit mode: Cmd+Enter to save
      if (mode === "edit" && (e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault();
        handleSave();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, mode, title, content, dueAt, reminderAt, selectedTagIds]);

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

    const finalTitle = trimmedTitle || t("untitledTodo");

    isSavingRef.current = true;
    try {
      if (isCreate) {
        const newTodo = await addTodo(finalTitle, trimmedContent);
        if (dueAt) {
          await updateTodo(newTodo.id, { dueAt, reminderAt });
        }
        if (selectedTagIds.length > 0) {
          await setTodoTags(newTodo.id, selectedTagIds);
        }
      } else {
        await updateTodo(existingTodo.id, {
          title: finalTitle,
          content: trimmedContent,
          dueAt,
          reminderAt,
        });
        await setTodoTags(existingTodo.id, selectedTagIds);
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

  const deadlineInfo = dueAt ? formatDeadline(dueAt, i18n.language) : null;
  const canSave = title.trim().length > 0 || content.trim().length > 0;

  return (
    <div className="absolute inset-0 z-50 bg-[var(--color-bg-panel)] text-[var(--color-text-primary)] flex flex-col select-none animate-in fade-in duration-150">
      {/* Top Header Bar */}
      <div className="h-12 px-5 border-b border-[var(--color-border-panel)] flex items-center justify-between shrink-0 bg-[var(--color-bg-panel)]">
        <div className="flex items-center space-x-2">
          <span className="text-[14px] font-semibold text-[var(--color-text-primary)] tracking-tight">
            {isCreate
              ? t("newTodoDrawerTitle")
              : mode === "view"
              ? t("todoDetailsDrawerTitle")
              : t("editTodoDrawerTitle")}
          </span>

          {/* View / Edit Mode Switcher (only for existing todos) */}
          {!isCreate && (
            <div className="flex items-center p-0.5 rounded-lg bg-[var(--color-hover-overlay)] border border-[var(--color-border-panel)] text-[11.5px] select-none ml-2">
              <button
                type="button"
                onClick={() => setMode("view")}
                className={`px-2 py-0.5 rounded-md font-medium transition-all flex items-center space-x-1 cursor-pointer tactile-btn ${
                  mode === "view"
                    ? "bg-[var(--color-bg-panel)] text-[var(--color-teal-primary)] shadow-xs font-semibold"
                    : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]"
                }`}
              >
                <Eye size={13} weight={mode === "view" ? "fill" : "regular"} />
                <span>{t("viewMode")}</span>
              </button>
              <button
                type="button"
                onClick={() => setMode("edit")}
                className={`px-2 py-0.5 rounded-md font-medium transition-all flex items-center space-x-1 cursor-pointer tactile-btn ${
                  mode === "edit"
                    ? "bg-[var(--color-bg-panel)] text-[var(--color-teal-primary)] shadow-xs font-semibold"
                    : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]"
                }`}
              >
                <PencilSimple size={13} weight={mode === "edit" ? "fill" : "regular"} />
                <span>{t("editMode")}</span>
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

      {/* Main Content Area */}
      {mode === "view" ? (
        /* ==================== VIEW MODE ==================== */
        <div className="flex-1 flex flex-col min-h-0 overflow-hidden">
          {/* Title as Crisp Typography Heading */}
          <div
            onDoubleClick={() => setMode("edit")}
            className="px-5 pt-4 pb-2 shrink-0 select-text cursor-text"
            title={t("doubleClickToEdit")}
          >
            <h1 className="text-[17px] font-bold text-[var(--color-text-primary)] tracking-tight leading-snug break-words">
              {title || t("untitledTodo")}
            </h1>
          </div>

          {/* Properties: Deadline + Tags */}
          {(deadlineInfo || selectedTagIds.length > 0) && (
            <div className="px-5 pb-3 flex items-center flex-wrap gap-1.5 shrink-0">
              {/* Deadline Badge */}
              {deadlineInfo && (
                <span
                  className={`inline-flex items-center space-x-1 text-[11px] font-medium px-2 py-0.5 rounded-md ${
                    deadlineInfo.isOverdue
                      ? "text-[#F18A45] bg-[#F18A45]/10 border border-[#F18A45]/30"
                      : "text-[var(--color-text-secondary)] bg-[var(--color-hover-overlay)] border border-[var(--color-border-panel)]"
                  }`}
                >
                  <Clock className="w-3 h-3 shrink-0" />
                  <span>{deadlineInfo.label}</span>
                </span>
              )}

              {/* Tag Badges */}
              {selectedTagIds.map((tagId) => {
                const tag = tagsWorkspace.tags.find((t) => t.id === tagId);
                if (!tag) return null;
                return (
                  <span
                    key={tag.id}
                    className="inline-flex items-center space-x-1.5 h-[24px] px-2 rounded-md text-[11px] font-medium shrink-0"
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
                    <span className="truncate max-w-[120px]">{tag.name}</span>
                  </span>
                );
              })}
            </div>
          )}

          {/* Clean Hairline Divider */}
          <div className="mx-5 border-b border-[var(--color-border-panel)] shrink-0" />

          {/* View Mode Markdown Content */}
          <div
            onDoubleClick={() => setMode("edit")}
            className="flex-1 flex flex-col min-h-0 px-5 pt-3 pb-2 overflow-y-auto smooth-scroll select-text"
          >
            {content.trim() ? (
              <FloatickMarkdown content={content} />
            ) : (
              <div
                onClick={() => setMode("edit")}
                className="h-full min-h-[140px] flex flex-col items-center justify-center text-[var(--color-text-subtle)] text-xs cursor-pointer hover:text-[var(--color-teal-primary)] transition-colors select-none"
              >
                <span>{t("clickToAddContent")}</span>
              </div>
            )}
          </div>

          {/* View Mode Footer */}
          <div className="h-11 px-5 border-t border-[var(--color-border-panel)] flex items-center justify-between shrink-0 bg-[var(--color-bg-panel)]">
            <span className="text-[11.5px] text-[var(--color-text-subtle)]">
              {t("viewModeHint")}
            </span>

            <div className="flex items-center space-x-2">
              <button
                type="button"
                onClick={onClose}
                className="px-3 py-1 text-[12px] font-medium text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] rounded-md transition-colors cursor-pointer tactile-btn"
              >
                {t("close")}
              </button>
              <button
                type="button"
                onClick={() => setMode("edit")}
                className="px-3.5 py-1 text-[12px] font-medium bg-[var(--color-teal-primary)] hover:bg-[var(--color-teal-primary)]/90 text-white rounded-md transition-colors cursor-pointer tactile-btn shadow-xs flex items-center space-x-1.5"
              >
                <PencilSimple size={14} weight="bold" />
                <span>{t("edit")}</span>
              </button>
            </div>
          </div>
        </div>
      ) : (
        /* ==================== EDIT MODE ==================== */
        <div className="flex-1 flex flex-col min-h-0 overflow-hidden">
          {/* Title Input (No blue text selection!) */}
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
              placeholder={t("todoTitleFieldHint")}
              className="w-full text-[17px] font-semibold bg-transparent text-[var(--color-text-primary)] placeholder:text-[var(--color-text-subtle)] focus:outline-none focus:placeholder-transparent transition-colors tracking-tight"
            />
          </div>

          {/* Metadata Properties Row: Tags + Deadline directly beneath Title */}
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

            {/* Selected Tag Pills */}
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

            {/* Deadline Trigger Button */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setShowDeadlinePicker(!showDeadlinePicker)}
                title={dueAt ? t("editDeadline") : t("setDeadline")}
                className={`h-[26px] px-2.5 rounded-md flex items-center space-x-1.5 text-[11.5px] font-medium transition-colors tactile-btn cursor-pointer ${
                  dueAt
                    ? deadlineInfo?.isOverdue
                      ? "text-[#F18A45] bg-[#F18A45]/15 border border-[#F18A45]/30 font-medium"
                      : "text-[var(--color-teal-primary)] bg-[var(--color-teal-tint-active)]"
                    : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] bg-[var(--color-hover-overlay)] hover:bg-[var(--color-hover-overlay)]/80"
                }`}
              >
                <CalendarBlank size={13} weight={dueAt ? "fill" : "regular"} />
                <span>
                  {dueAt ? deadlineInfo?.label : t("deadline")}
                </span>
                {dueAt && (
                  <span
                    onClick={(e) => {
                      e.stopPropagation();
                      setDueAt(null);
                      setReminderAt(null);
                    }}
                    className="ml-1 opacity-60 hover:opacity-100 cursor-pointer"
                    title={t("clearDeadline")}
                  >
                    <X size={10} weight="bold" />
                  </span>
                )}
              </button>
            </div>
          </div>

          {/* Clean Hairline Divider */}
          <div className="mx-5 border-b border-[var(--color-border-panel)] shrink-0" />

          {/* Tiptap Editor Canvas */}
          <div className="flex-1 flex flex-col min-h-0 px-5 pt-2.5 pb-2 overflow-hidden">
            <FloatickTiptapEditor
              key={existingTodoId || "new"}
              initialContent={content}
              editorRef={editorHandleRef}
              onChange={(md) => setContent(md)}
              onCmdEnter={handleSave}
            />
          </div>

          {/* Deadline Picker Popover Dialog */}
          {showDeadlinePicker && (
            <TodoDeadlinePicker
              initialDueAt={dueAt}
              initialReminderAt={reminderAt}
              onSave={(d, r) => {
                setDueAt(d);
                setReminderAt(r);
                setShowDeadlinePicker(false);
              }}
              onClose={() => setShowDeadlinePicker(false)}
            />
          )}

          {/* Edit Mode Footer Bar */}
          <div className="h-11 px-5 border-t border-[var(--color-border-panel)] flex items-center justify-between shrink-0 bg-[var(--color-bg-panel)]">
            <span className="text-[11.5px] text-[var(--color-text-subtle)]">
              {t("shortcutHint")}
            </span>

            <div className="flex items-center space-x-2">
              <button
                type="button"
                onClick={() => {
                  if (!isCreate) {
                    setMode("view");
                  } else {
                    onClose();
                  }
                }}
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
      )}
    </div>
  );
};
