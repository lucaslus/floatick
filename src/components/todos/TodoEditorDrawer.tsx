import React, { useState, useEffect, useRef } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  Tag,
  CalendarBlank,
  Check,
} from "@phosphor-icons/react";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { TodoDeadlinePicker } from "./TodoDeadlinePicker";
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

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const setTodoTags = useTagStore((s) => s.setTodoTags);

  const existingTodo = todos.find((t) => t.id === todoId);
  const isCreate = !existingTodo;

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [dueAt, setDueAt] = useState<string | null>(null);
  const [reminderAt, setReminderAt] = useState<string | null>(null);
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);
  const [showPreview, setShowPreview] = useState(false);
  const [showDeadlinePicker, setShowDeadlinePicker] = useState(false);
  const [showTagMenu, setShowTagMenu] = useState(false);

  const titleInputRef = useRef<HTMLInputElement>(null);
  const contentTextareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (isOpen) {
      if (existingTodo) {
        setTitle(existingTodo.title);
        setContent(existingTodo.content || "");
        setDueAt(existingTodo.dueAt || null);
        setReminderAt(existingTodo.reminderAt || null);
        setSelectedTagIds(tagsWorkspace.assignments[existingTodo.id] || []);
      } else {
        setTitle("");
        setContent("");
        setDueAt(null);
        setReminderAt(null);
        setSelectedTagIds([]);
      }
      setShowPreview(false);
      setShowDeadlinePicker(false);
      setShowTagMenu(false);

      // Focus title input on open
      setTimeout(() => {
        titleInputRef.current?.focus();
        titleInputRef.current?.select();
      }, 50);
    }
  }, [existingTodo, tagsWorkspace, isOpen]);

  // Global drawer keyboard shortcuts (Cmd+Enter to save, Esc to close)
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault();
        handleSave();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, title, content, dueAt, reminderAt, selectedTagIds]);

  if (!isOpen) return null;

  const handleSave = async () => {
    const trimmedTitle = title.trim();
    if (!trimmedTitle) return;

    if (isCreate) {
      const newTodo = await addTodo(trimmedTitle, content.trim());
      if (dueAt) {
        await updateTodo(newTodo.id, { dueAt, reminderAt });
      }
      if (selectedTagIds.length > 0) {
        await setTodoTags(newTodo.id, selectedTagIds);
      }
    } else {
      await updateTodo(existingTodo.id, {
        title: trimmedTitle,
        content: content.trim(),
        dueAt,
        reminderAt,
      });
      await setTodoTags(existingTodo.id, selectedTagIds);
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

  const deadlineInfo = dueAt ? formatDeadline(dueAt, i18n.language) : null;
  const canSave = title.trim().length > 0 || content.trim().length > 0;

  return (
    <>
      {/* Scrim Overlay */}
      <div
        className="absolute inset-0 z-40 bg-black/50 backdrop-blur-xs transition-opacity"
        onClick={onClose}
      />

      {/* FloatickEditorDrawerSurface (590px height, 22px radius, #202A2E dark surface) */}
      <div className="absolute inset-x-0 bottom-0 z-50 h-[590px] rounded-t-[22px] bg-[#202A2E] text-[#EEF2F1] border-t border-white/[0.11] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-200 sheet-slide-up select-none">
        {/* FloatickEditorDrawerHeader */}
        <div className="px-5 pt-3.5 pb-3 border-b border-white/[0.08] flex items-center justify-between shrink-0">
          <span className="text-[14.5px] font-semibold text-[#EEF2F1] tracking-tight">
            {isCreate ? t("newTodoDrawerTitle") : t("editTodoDrawerTitle")}
          </span>
          <button
            type="button"
            onClick={onClose}
            title={t("cancel")}
            className="w-7 h-7 rounded-lg flex items-center justify-center text-[#EEF2F1]/58 hover:text-[#EEF2F1] hover:bg-white/[0.06] transition-colors tactile-btn cursor-pointer"
          >
            <X size={18} weight="bold" />
          </button>
        </div>

        {/* Body (FloatickEditorMetrics.bodyPadding: 20px 16px 20px 12px) */}
        <div className="flex-1 p-5 pt-3.5 pb-2.5 flex flex-col min-h-0">
          {/* Toolbar row (EditorTagSelector + Deadline + FloatickEditorModeSwitch) */}
          <div className="flex items-center justify-between shrink-0">
            {/* Left: Tag Button + Deadline Button */}
            <div className="flex items-center space-x-1.5 min-w-0 flex-1 mr-2">
              {/* Tag Selector Button with Dropdown */}
              <div className="relative shrink-0">
                <button
                  type="button"
                  onClick={() => setShowTagMenu(!showTagMenu)}
                  title={t("tags")}
                  className={`w-[30px] h-[30px] rounded-lg flex items-center justify-center tactile-btn cursor-pointer transition-colors ${
                    selectedTagIds.length > 0
                      ? "text-[#22B8A7] bg-[#22B8A7]/[0.12]"
                      : "text-[#EEF2F1]/56 hover:text-[#EEF2F1] hover:bg-white/[0.06]"
                  }`}
                >
                  <Tag size={16} weight={selectedTagIds.length > 0 ? "fill" : "regular"} />
                </button>

                {/* Tag Dropdown Popover */}
                {showTagMenu && (
                  <>
                    <div
                      className="fixed inset-0 z-30"
                      onClick={() => setShowTagMenu(false)}
                    />
                    <div className="absolute left-0 top-9 z-40 w-48 bg-[#1D2529] rounded-xl shadow-2xl border border-white/[0.1] py-1.5 text-xs animate-in fade-in zoom-in-95 duration-100 max-h-56 overflow-y-auto smooth-scroll">
                      <div className="px-3 py-1 text-[11px] font-medium text-[#EEF2F1]/50 uppercase tracking-wider">
                        {t("tags")}
                      </div>
                      {tagsWorkspace.tags.length === 0 ? (
                        <div className="px-3 py-2 text-[11px] text-[#EEF2F1]/40">
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
                              className="w-full px-3 py-1.5 flex items-center justify-between hover:bg-white/[0.06] text-left cursor-pointer"
                            >
                              <div className="flex items-center space-x-2 truncate">
                                <span
                                  className="w-2 h-2 rounded-full shrink-0"
                                  style={{ backgroundColor: tag.colorHex }}
                                />
                                <span className="truncate text-[#EEF2F1] text-xs">
                                  {tag.name}
                                </span>
                              </div>
                              {isSelected && (
                                <Check size={14} weight="bold" className="text-[#22B8A7] shrink-0" />
                              )}
                            </button>
                          );
                        })
                      )}
                    </div>
                  </>
                )}
              </div>

              {/* Selected Tag Chips */}
              {selectedTagIds.length > 0 && (
                <div className="flex items-center space-x-1 overflow-x-auto smooth-scroll no-scrollbar py-0.5">
                  {tagsWorkspace.tags
                    .filter((t) => selectedTagIds.includes(t.id))
                    .map((tag) => (
                      <button
                        key={tag.id}
                        type="button"
                        onClick={() => toggleTag(tag.id)}
                        title={tag.name}
                        className="inline-flex items-center space-x-1 px-1.5 py-0.5 rounded text-[10.5px] font-medium shrink-0 transition-opacity hover:opacity-75 tactile-btn cursor-pointer"
                        style={{
                          backgroundColor: `${tag.colorHex}22`,
                          border: `1px solid ${tag.colorHex}44`,
                          color: tag.colorHex,
                        }}
                      >
                        <span
                          className="w-1.5 h-1.5 rounded-full shrink-0"
                          style={{ backgroundColor: tag.colorHex }}
                        />
                        <span className="truncate max-w-[90px]">{tag.name}</span>
                      </button>
                    ))}
                </div>
              )}

              {/* Deadline Button */}
              <div className="relative shrink-0 flex items-center space-x-1">
                <button
                  type="button"
                  onClick={() => setShowDeadlinePicker(true)}
                  title={dueAt ? t("editDeadline") : t("setDeadline")}
                  className={`w-[30px] h-[30px] rounded-lg flex items-center justify-center tactile-btn cursor-pointer transition-colors ${
                    dueAt
                      ? "text-[#22B8A7] bg-[#22B8A7]/[0.12]"
                      : "text-[#EEF2F1]/56 hover:text-[#EEF2F1] hover:bg-white/[0.06]"
                  }`}
                >
                  <CalendarBlank size={16} weight={dueAt ? "fill" : "regular"} />
                </button>

                {/* Deadline Chip */}
                {deadlineInfo && (
                  <div className="inline-flex items-center space-x-1 px-2 py-0.5 rounded text-[10.5px] font-medium bg-[#22B8A7]/15 text-[#22B8A7] border border-[#22B8A7]/30 shrink-0">
                    <span className="truncate max-w-[110px]">{deadlineInfo.label}</span>
                    <button
                      type="button"
                      onClick={() => {
                        setDueAt(null);
                        setReminderAt(null);
                      }}
                      className="hover:text-white ml-0.5 cursor-pointer"
                    >
                      <X size={12} weight="bold" />
                    </button>
                  </div>
                )}
              </div>
            </div>

            {/* Right: FloatickEditorModeSwitch (Write / Preview) */}
            <div className="h-[28px] flex items-center rounded-lg bg-black/25 p-0.5 border border-white/[0.06] shrink-0">
              <button
                type="button"
                onClick={() => setShowPreview(false)}
                className={`px-2.5 h-full rounded-md text-[11.5px] transition-colors tactile-btn cursor-pointer ${
                  !showPreview
                    ? "bg-[#22B8A7]/15 text-[#22B8A7] font-semibold"
                    : "text-[#EEF2F1]/58 hover:text-[#EEF2F1] font-medium"
                }`}
              >
                {t("markdownWriteLabel")}
              </button>
              <button
                type="button"
                onClick={() => setShowPreview(true)}
                className={`px-2.5 h-full rounded-md text-[11.5px] transition-colors tactile-btn cursor-pointer ${
                  showPreview
                    ? "bg-[#22B8A7]/15 text-[#22B8A7] font-semibold"
                    : "text-[#EEF2F1]/58 hover:text-[#EEF2F1] font-medium"
                }`}
              >
                {t("markdownPreviewLabel")}
              </button>
            </div>
          </div>

          {/* FloatickDocumentEditor: Single Unified Surface Card */}
          <div className="mt-2.5 flex-1 flex flex-col rounded-xl overflow-hidden bg-[#1D2529] border border-white/[0.08] focus-within:border-[#22B8A7]/40 min-h-0 transition-colors">
            {/* Title Field (Bold, 15px, clean borderless) */}
            <input
              ref={titleInputRef}
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  contentTextareaRef.current?.focus();
                }
              }}
              placeholder={t("todoTitleFieldHint")}
              className="w-full px-4 pt-3.5 pb-3 text-[15px] font-semibold bg-transparent text-[#EEF2F1] placeholder:text-[#EEF2F1]/38 focus:outline-none tracking-tight shrink-0"
            />

            {/* Title Divider */}
            <div className="mx-4 border-b border-white/[0.08] shrink-0" />

            {/* Content Area: Markdown Textarea OR Markdown Preview */}
            <div className="flex-1 flex flex-col min-h-0 relative">
              {showPreview ? (
                <div className="p-4 flex-1 overflow-y-auto smooth-scroll text-[13px] text-[#EEF2F1]">
                  {content.trim() ? (
                    <FloatickMarkdown content={content} />
                  ) : (
                    <div className="h-full flex items-center justify-center text-[#EEF2F1]/38 text-xs italic">
                      {t("markdownPreviewEmptyMessage")}
                    </div>
                  )}
                </div>
              ) : (
                <textarea
                  ref={contentTextareaRef}
                  id="todo-content-textarea"
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder={t("todoContentFieldHint")}
                  className="p-4 flex-1 w-full resize-none bg-transparent font-mono text-[13px] leading-relaxed text-[#EEF2F1] placeholder:text-[#EEF2F1]/38 focus:outline-none overflow-y-auto smooth-scroll"
                />
              )}
            </div>
          </div>
        </div>

        {/* FloatickEditorFooter */}
        <div className="border-t border-white/[0.08] px-5 py-3 flex items-center justify-end space-x-2 shrink-0">
          <button
            type="button"
            onClick={onClose}
            className="px-3.5 py-1.5 rounded-lg text-xs font-medium text-[#EEF2F1]/70 hover:text-[#EEF2F1] hover:bg-white/[0.06] transition-colors tactile-btn cursor-pointer"
          >
            {t("cancel")}
          </button>

          <button
            type="button"
            onClick={handleSave}
            disabled={!canSave}
            className="px-4.5 py-1.5 rounded-lg bg-[#22B8A7] hover:bg-[#1DB3A8] text-[#151B1E] font-semibold text-xs flex items-center space-x-1.5 transition-colors tactile-btn cursor-pointer shadow-xs disabled:opacity-40 disabled:pointer-events-none"
          >
            <Check size={16} weight="bold" />
            <span>
              {isCreate ? t("createTodoAction") : t("saveChangesAction")}
            </span>
          </button>
        </div>
      </div>

      {/* Deadline Picker Modal */}
      {showDeadlinePicker && (
        <TodoDeadlinePicker
          initialDueAt={dueAt}
          initialReminderAt={reminderAt}
          onSave={(newDue, newReminder) => {
            setDueAt(newDue);
            setReminderAt(newReminder);
            setShowDeadlinePicker(false);
          }}
          onClose={() => setShowDeadlinePicker(false)}
        />
      )}
    </>
  );
};
