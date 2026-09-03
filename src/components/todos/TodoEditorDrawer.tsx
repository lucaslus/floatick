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
      {/* Scrim */}
      <div
        className="absolute inset-0 z-40 bg-black/40 backdrop-blur-xs transition-opacity"
        onClick={onClose}
      />

      {/* Clean Bottom Sheet */}
      <div className="absolute inset-x-0 bottom-0 z-50 h-[580px] rounded-t-2xl bg-[#161B1F] text-zinc-100 border-t border-white/[0.1] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-200">
        {/* Header */}
        <div className="h-11 px-4.5 border-b border-white/[0.06] flex items-center justify-between">
          <span className="text-xs font-semibold text-zinc-200 tracking-tight">
            {isCreate ? t("newTodoDrawerTitle") : t("editTodoDrawerTitle")}
          </span>
          <button
            onClick={onClose}
            className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/[0.06] transition-colors tactile-btn cursor-pointer"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-4.5 space-y-3.5 text-xs">
          {/* Title Field */}
          <div>
            <input
              type="text"
              autoFocus
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={t("todoTitleFieldHint")}
              className="w-full px-3 py-2 rounded-lg border border-white/[0.08] bg-black/20 text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:border-teal-500 text-xs transition-colors"
            />
          </div>

          {/* Tags */}
          <div>
            <div className="text-[11px] text-zinc-400 mb-1.5 flex items-center space-x-1">
              <TagIcon className="w-3 h-3" />
              <span>{t("tags")}</span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {tagsWorkspace.tags.map((tag) => {
                const isSelected = selectedTagIds.includes(tag.id);
                return (
                  <button
                    key={tag.id}
                    type="button"
                    onClick={() => toggleTag(tag.id)}
                    className={`inline-flex items-center space-x-1 px-2.5 py-0.5 rounded text-[10.5px] font-medium transition-all tactile-btn cursor-pointer ${
                      isSelected
                        ? "ring-1 ring-teal-500"
                        : "opacity-60 hover:opacity-100"
                    }`}
                    style={{
                      backgroundColor: `${tag.colorHex}18`,
                      color: tag.colorHex,
                    }}
                  >
                    {isSelected && <Check className="w-2.5 h-2.5 stroke-[3]" />}
                    <span>{tag.name}</span>
                  </button>
                );
              })}
              {tagsWorkspace.tags.length === 0 && (
                <span className="text-[11px] text-zinc-500">{t("noTagsYetMessage")}</span>
              )}
            </div>
          </div>

          {/* Deadline */}
          <div>
            <div className="text-[11px] text-zinc-400 mb-1.5 flex items-center space-x-1">
              <Clock className="w-3 h-3" />
              <span>{t("deadline")}</span>
            </div>
            <button
              type="button"
              onClick={() => setShowDeadlinePicker(true)}
              className="inline-flex items-center space-x-2 px-3 py-1.5 rounded-lg border border-white/[0.08] bg-black/20 text-zinc-200 hover:border-teal-500 transition-colors tactile-btn cursor-pointer"
            >
              <Clock className="w-3.5 h-3.5 text-teal-400" />
              <span>{deadlineInfo ? deadlineInfo.label : t("setDeadline")}</span>
            </button>
          </div>

          {/* Markdown Content */}
          <div className="flex-1 flex flex-col">
            <div className="flex items-center justify-between mb-1.5">
              <span className="text-[11px] text-zinc-400">{t("todoContentLabel")}</span>

              {/* Tabs */}
              <div className="flex items-center bg-black/25 rounded p-0.5 border border-white/[0.06]">
                <button
                  type="button"
                  onClick={() => setActiveTab("edit")}
                  className={`px-2 py-0.2 rounded text-[10px] font-medium ${
                    activeTab === "edit" ? "bg-white/10 text-white" : "text-zinc-400"
                  }`}
                >
                  {t("markdownWriteLabel")}
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab("preview")}
                  className={`px-2 py-0.2 rounded text-[10px] font-medium ${
                    activeTab === "preview" ? "bg-white/10 text-white" : "text-zinc-400"
                  }`}
                >
                  {t("markdownPreviewLabel")}
                </button>
              </div>
            </div>

            {activeTab === "edit" ? (
              <div className="space-y-1">
                {/* Clean Toolbar */}
                <div className="flex items-center space-x-0.5 px-1 py-1 rounded-t-lg bg-black/20 border-x border-t border-white/[0.08] text-zinc-400">
                  <button
                    type="button"
                    onClick={() => insertMarkdown("**", "**")}
                    title={t("bold")}
                    className="w-5 h-5 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white"
                  >
                    <Bold className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("*", "*")}
                    title={t("italic")}
                    className="w-5 h-5 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white"
                  >
                    <Italic className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- ")}
                    title={t("bulletList")}
                    className="w-5 h-5 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white"
                  >
                    <List className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("- [ ] ")}
                    title={t("taskList")}
                    className="w-5 h-5 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white"
                  >
                    <CheckSquare className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("`", "`")}
                    title={t("inlineCode")}
                    className="w-5 h-5 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white"
                  >
                    <Code className="w-3 h-3" />
                  </button>
                  <button
                    type="button"
                    onClick={() => insertMarkdown("[", "](url)")}
                    title={t("link")}
                    className="w-5 h-5 rounded flex items-center justify-center hover:bg-white/[0.08] hover:text-white"
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
                  className="w-full p-3 rounded-b-lg border border-white/[0.08] bg-black/20 text-zinc-100 focus:outline-none focus:border-teal-500 font-mono text-[11.5px] leading-relaxed resize-none select-text"
                />
              </div>
            ) : (
              <div className="w-full min-h-[160px] max-h-[220px] overflow-y-auto p-3.5 rounded-lg border border-white/[0.08] bg-black/20">
                <FloatickMarkdown
                  content={content}
                  emptyMessage={t("markdownPreviewEmptyMessage")}
                />
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="h-12 px-4.5 border-t border-white/[0.06] flex items-center justify-end space-x-2 bg-black/10">
          <button
            type="button"
            onClick={onClose}
            className="px-3.5 py-1.5 rounded-lg text-zinc-400 hover:text-white text-xs transition-colors tactile-btn cursor-pointer"
          >
            {t("cancel")}
          </button>
          <button
            type="button"
            onClick={handleSave}
            className="px-4.5 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-500 text-white font-medium text-xs tactile-btn transition-colors cursor-pointer shadow-xs"
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
