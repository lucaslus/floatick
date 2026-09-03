import React, { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  Clock,
  Tag as TagIcon,
  Check,
  Bold,
  Italic,
  List,
  CheckSquare,
  Code,
  Link,
} from "lucide-react";
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
  const { t } = useTranslation();
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
  const [activeTab, setActiveTab] = useState<"edit" | "preview">("edit");
  const [showDeadlinePicker, setShowDeadlinePicker] = useState(false);

  useEffect(() => {
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
  }, [existingTodo, tagsWorkspace, isOpen]);

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

  const insertMarkdown = (before: string, after: string = "") => {
    const textarea = document.getElementById("todo-content-textarea") as HTMLTextAreaElement | null;
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

  const deadlineInfo = dueAt ? formatDeadline(dueAt) : null;

  return (
    <>
      {/* Scrim Overlay */}
      <div
        className="absolute inset-0 z-40 bg-black/40 backdrop-blur-[2px] transition-opacity duration-200"
        onClick={onClose}
      />

      {/* Slide-up Bottom Drawer */}
      <div className="absolute inset-x-0 bottom-0 z-50 h-[590px] rounded-t-[22px] bg-[#F9FBFA] dark:bg-[#1D2529] text-zinc-900 dark:text-[#EEF2F1] border-t border-black/[0.08] dark:border-white/[0.1] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-220">
        {/* Header */}
        <div className="h-12 px-5 border-b border-black/[0.05] dark:border-white/[0.06] flex items-center justify-between">
          <span className="text-xs font-semibold text-zinc-800 dark:text-[#EEF2F1] tracking-tight">
            {isCreate ? t("newTodoDrawerTitle") : t("editTodoDrawerTitle")}
          </span>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded-full flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] transition-colors mui-ripple cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Form Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-4 text-xs">
          {/* Title Field */}
          <div>
            <label className="block text-[11px] font-semibold text-zinc-500 dark:text-[#8E9599] uppercase tracking-wider mb-1.5">
              {t("todoTitleLabel")}
            </label>
            <input
              type="text"
              autoFocus
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={t("todoTitleFieldHint")}
              className="w-full px-3.5 py-2.5 rounded-xl border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-[#151B1E] text-zinc-900 dark:text-[#EEF2F1] placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-teal-500/30 focus:border-teal-600 dark:focus:border-[#22B8A7] text-xs transition-all shadow-xs"
            />
          </div>

          {/* Tags Assignment Row */}
          <div>
            <label className="block text-[11px] font-semibold text-zinc-500 dark:text-[#8E9599] uppercase tracking-wider mb-1.5 flex items-center space-x-1">
              <TagIcon className="w-3 h-3" />
              <span>{t("tags")}</span>
            </label>
            <div className="flex flex-wrap gap-1.5">
              {tagsWorkspace.tags.map((tag) => {
                const isSelected = selectedTagIds.includes(tag.id);
                return (
                  <button
                    key={tag.id}
                    type="button"
                    onClick={() => toggleTag(tag.id)}
                    className={`inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-[11px] font-medium transition-all mui-ripple cursor-pointer ${
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
              {tagsWorkspace.tags.length === 0 && (
                <span className="text-[11px] text-zinc-400 italic">
                  {t("noTagsYetMessage")}
                </span>
              )}
            </div>
          </div>

          {/* Deadline Trigger Row */}
          <div>
            <label className="block text-[11px] font-semibold text-zinc-500 dark:text-[#8E9599] uppercase tracking-wider mb-1.5 flex items-center space-x-1">
              <Clock className="w-3 h-3" />
              <span>{t("deadline")}</span>
            </label>
            <button
              type="button"
              onClick={() => setShowDeadlinePicker(true)}
              className="inline-flex items-center space-x-2 px-3.5 py-2 rounded-xl border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-[#151B1E] text-zinc-800 dark:text-[#EEF2F1] hover:border-teal-500 dark:hover:border-[#22B8A7] transition-colors mui-ripple cursor-pointer shadow-xs"
            >
              <Clock className="w-3.5 h-3.5 text-teal-600 dark:text-[#22B8A7]" />
              <span className="font-medium">{deadlineInfo ? deadlineInfo.label : t("setDeadline")}</span>
            </button>
          </div>

          {/* Content / Markdown Note */}
          <div className="flex-1 flex flex-col">
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-[11px] font-semibold text-zinc-500 dark:text-[#8E9599] uppercase tracking-wider">
                {t("todoContentLabel")} (Markdown)
              </label>

              {/* Write / Preview Tab Switcher */}
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
            </div>

            {activeTab === "edit" ? (
              <div className="space-y-1">
                {/* Markdown Quick Toolbar */}
                <div className="flex items-center space-x-0.5 px-1 py-1 rounded-t-xl bg-black/[0.03] dark:bg-white/[0.04] border-x border-t border-black/[0.08] dark:border-white/[0.1] text-zinc-500 dark:text-zinc-400">
                  <button
                    type="button"
                    onClick={() => insertMarkdown("**", "**")}
                    title={t("bold")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Bold className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("*", "*")}
                    title={t("italic")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Italic className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- ")}
                    title={t("bulletList")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <List className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- [ ] ")}
                    title={t("taskList")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <CheckSquare className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("`", "`")}
                    title={t("inlineCode")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Code className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("[", "](url)")}
                    title={t("link")}
                    className="w-6 h-6 rounded flex items-center justify-center hover:bg-black/[0.06] dark:hover:bg-white/[0.08] hover:text-zinc-900 dark:hover:text-white"
                  >
                    <Link className="w-3 h-3" />
                  </button>
                </div>

                <textarea
                  id="todo-content-textarea"
                  rows={6}
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder={t("todoContentFieldHint")}
                  className="w-full p-3 rounded-b-xl border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-[#151B1E] text-zinc-900 dark:text-[#EEF2F1] focus:outline-none focus:ring-2 focus:ring-teal-500/30 focus:border-teal-600 dark:focus:border-[#22B8A7] font-mono text-[11.5px] leading-relaxed resize-none select-text shadow-xs"
                />
              </div>
            ) : (
              <div className="w-full min-h-[160px] max-h-[220px] overflow-y-auto p-4 rounded-xl border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-[#151B1E] shadow-xs">
                <FloatickMarkdown
                  content={content}
                  emptyMessage={t("markdownPreviewEmptyMessage")}
                />
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="h-14 px-5 border-t border-black/[0.05] dark:border-white/[0.06] flex items-center justify-end space-x-2.5 bg-black/[0.01] dark:bg-white/[0.01]">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-zinc-600 dark:text-[#A0A6AA] hover:bg-black/[0.05] dark:hover:bg-white/[0.08] text-xs font-medium transition-colors mui-ripple cursor-pointer"
          >
            {t("cancel")}
          </button>
          <button
            type="button"
            onClick={handleSave}
            className="px-5 py-2 rounded-full bg-teal-600 hover:bg-teal-700 dark:bg-[#22B8A7] dark:hover:bg-[#1CA394] text-white font-medium text-xs shadow-md mui-ripple transition-all cursor-pointer"
          >
            {isCreate ? t("createTodoAction") : t("saveChangesAction")}
          </button>
        </div>
      </div>

      {/* Deadline Picker Modal */}
      {showDeadlinePicker && (
        <TodoDeadlinePicker
          initialDueAt={dueAt}
          initialReminderAt={reminderAt}
          onSave={(newDue, newRem) => {
            setDueAt(newDue);
            setReminderAt(newRem);
          }}
          onClose={() => setShowDeadlinePicker(false)}
        />
      )}
    </>
  );
};
