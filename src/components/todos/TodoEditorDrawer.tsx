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

  const deadlineInfo = dueAt ? formatDeadline(dueAt, i18n.language) : null;

  return (
    <>
      {/* Scrim Overlay */}
      <div
        className="absolute inset-0 z-40 bg-black/50 backdrop-blur-xs transition-opacity duration-200"
        onClick={onClose}
      />

      {/* Slide-up Luxury Bottom Sheet */}
      <div className="absolute inset-x-0 bottom-0 z-50 h-[590px] rounded-t-[26px] bg-[#141A1E] text-[#F1F5F9] border-t border-white/[0.12] shadow-[0_-20px_50px_rgba(0,0,0,0.6)] flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-220">
        {/* Grab Handle */}
        <div className="w-10 h-1 rounded-full bg-white/20 mx-auto mt-2.5 mb-0.5 pointer-events-none" />

        {/* Header */}
        <div className="h-11 px-5 border-b border-white/[0.07] flex items-center justify-between">
          <span className="text-xs font-semibold tracking-tight text-[#F1F5F9]">
            {isCreate ? t("newTodoDrawerTitle") : t("editTodoDrawerTitle")}
          </span>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded-full flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/[0.08] transition-colors tactile-btn cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Form Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-4 text-xs">
          {/* Title Field */}
          <div>
            <label className="block text-[10.5px] font-semibold text-[#94A3B8] uppercase tracking-[0.14em] mb-1.5">
              {t("todoTitleLabel")}
            </label>
            <input
              type="text"
              autoFocus
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={t("todoTitleFieldHint")}
              className="w-full px-3.5 py-2.5 rounded-xl border border-white/[0.08] bg-black/25 text-[#F1F5F9] placeholder:text-[#64748B] focus:outline-none focus:ring-2 focus:ring-teal-500/30 focus:border-[#2DD4BF] text-xs transition-all shadow-inner"
            />
          </div>

          {/* Tags Assignment Row */}
          <div>
            <label className="block text-[10.5px] font-semibold text-[#94A3B8] uppercase tracking-[0.14em] mb-1.5 flex items-center space-x-1">
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
              {tagsWorkspace.tags.length === 0 && (
                <span className="text-[11px] text-zinc-500 italic">
                  {t("noTagsYetMessage")}
                </span>
              )}
            </div>
          </div>

          {/* Deadline Trigger Row */}
          <div>
            <label className="block text-[10.5px] font-semibold text-[#94A3B8] uppercase tracking-[0.14em] mb-1.5 flex items-center space-x-1">
              <Clock className="w-3 h-3" />
              <span>{t("deadline")}</span>
            </label>
            <button
              type="button"
              onClick={() => setShowDeadlinePicker(true)}
              className="inline-flex items-center space-x-2 px-3.5 py-2 rounded-xl border border-white/[0.08] bg-black/25 text-[#F1F5F9] hover:border-[#2DD4BF] transition-colors tactile-btn cursor-pointer shadow-inner"
            >
              <Clock className="w-3.5 h-3.5 text-[#2DD4BF]" />
              <span className="font-medium">{deadlineInfo ? deadlineInfo.label : t("setDeadline")}</span>
            </button>
          </div>

          {/* Content / Markdown Note */}
          <div className="flex-1 flex flex-col">
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-[10.5px] font-semibold text-[#94A3B8] uppercase tracking-[0.14em]">
                {t("todoContentLabel")} (Markdown)
              </label>

              {/* Write / Preview Tab Switcher */}
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
            </div>

            {activeTab === "edit" ? (
              <div className="space-y-1">
                {/* Markdown Quick Toolbar */}
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
                  id="todo-content-textarea"
                  rows={6}
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder={t("todoContentFieldHint")}
                  className="w-full p-3.5 rounded-b-xl border border-white/[0.08] bg-black/25 text-[#F1F5F9] focus:outline-none focus:ring-2 focus:ring-teal-500/30 focus:border-[#2DD4BF] font-mono text-[11.5px] leading-relaxed resize-none select-text shadow-inner"
                />
              </div>
            ) : (
              <div className="w-full min-h-[160px] max-h-[220px] overflow-y-auto p-4 rounded-xl border border-white/[0.08] bg-black/25 shadow-inner">
                <FloatickMarkdown
                  content={content}
                  emptyMessage={t("markdownPreviewEmptyMessage")}
                />
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="h-14 px-5 border-t border-white/[0.07] flex items-center justify-end space-x-2.5 bg-black/15">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-zinc-400 hover:text-white hover:bg-white/[0.08] text-xs font-medium transition-colors tactile-btn cursor-pointer"
          >
            {t("cancel")}
          </button>
          <button
            type="button"
            onClick={handleSave}
            className="px-6 py-2 rounded-full bg-gradient-to-r from-teal-500 to-teal-400 text-zinc-950 font-semibold text-xs shadow-[0_4px_16px_rgba(20,184,166,0.35)] tactile-btn transition-all cursor-pointer"
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
