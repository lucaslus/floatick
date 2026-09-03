import React, { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { X, Calendar, Tag as TagIcon, Check } from "lucide-react";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface TodoEditDrawerProps {
  todoId: string | null;
  onClose: () => void;
}

export const TodoEditDrawer: React.FC<TodoEditDrawerProps> = ({
  todoId,
  onClose,
}) => {
  const { t } = useTranslation();
  const todos = useTodoStore((s) => s.todos);
  const updateTodo = useTodoStore((s) => s.updateTodo);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const setTodoTags = useTagStore((s) => s.setTodoTags);

  const todo = todos.find((t) => t.id === todoId);

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [dueAt, setDueAt] = useState<string>("");
  const [selectedTagIds, setSelectedTagIds] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<"edit" | "preview">("edit");

  useEffect(() => {
    if (todo) {
      setTitle(todo.title);
      setContent(todo.content || "");
      setDueAt(todo.dueAt ? todo.dueAt.substring(0, 16) : "");
      setSelectedTagIds(tagsWorkspace.assignments[todo.id] || []);
    }
  }, [todo, tagsWorkspace]);

  if (!todo) return null;

  const handleSave = async () => {
    const trimmedTitle = title.trim();
    if (!trimmedTitle) return;

    await updateTodo(todo.id, {
      title: trimmedTitle,
      content: content.trim(),
      dueAt: dueAt ? new Date(dueAt).toISOString() : null,
    });
    await setTodoTags(todo.id, selectedTagIds);
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
        <span className="text-xs font-semibold text-zinc-800 dark:text-zinc-200">
          {t("edit")}
        </span>
        <button
          onClick={onClose}
          className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.05] dark:hover:bg-white/[0.08]"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 text-xs">
        {/* Title Input */}
        <div>
          <label className="block text-[11px] font-medium text-zinc-500 mb-1">
            {t("title")}
          </label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-2.5 py-1.5 rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-teal-500/30"
          />
        </div>

        {/* Tags Selector */}
        <div>
          <label className="block text-[11px] font-medium text-zinc-500 mb-1 flex items-center space-x-1">
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
                  className={`inline-flex items-center space-x-1 px-2 py-0.8 rounded-full text-[11px] transition-all cursor-pointer ${
                    isSelected ? "font-medium ring-2 ring-teal-500/50" : "opacity-70 hover:opacity-100"
                  }`}
                  style={{
                    backgroundColor: `${tag.colorHex}20`,
                    color: tag.colorHex,
                    border: `1px solid ${tag.colorHex}66`,
                  }}
                >
                  {isSelected && <Check className="w-2.5 h-2.5" />}
                  <span>{tag.name}</span>
                </button>
              );
            })}
            {tagsWorkspace.tags.length === 0 && (
              <span className="text-[11px] text-zinc-400">暂无标签，可在设置或顶部添加</span>
            )}
          </div>
        </div>

        {/* Deadline Picker */}
        <div>
          <label className="block text-[11px] font-medium text-zinc-500 mb-1 flex items-center space-x-1">
            <Calendar className="w-3 h-3" />
            <span>{t("deadline")}</span>
          </label>
          <div className="flex items-center space-x-2">
            <input
              type="datetime-local"
              value={dueAt}
              onChange={(e) => setDueAt(e.target.value)}
              className="flex-1 px-2.5 py-1.5 rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-teal-500/30"
            />
            {dueAt && (
              <button
                type="button"
                onClick={() => setDueAt("")}
                className="px-2 py-1.5 text-zinc-400 hover:text-red-500 hover:bg-black/[0.04] rounded-lg"
              >
                {t("clearDeadline")}
              </button>
            )}
          </div>
        </div>

        {/* Content (Markdown) */}
        <div>
          <div className="flex items-center justify-between mb-1">
            <label className="text-[11px] font-medium text-zinc-500">
              {t("content")} (Markdown)
            </label>
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
          </div>

          {activeTab === "edit" ? (
            <textarea
              rows={6}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="添加详细 Markdown 说明…"
              className="w-full p-2.5 rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-teal-500/30 font-mono text-[11px] resize-none"
            />
          ) : (
            <div className="w-full min-h-[120px] p-2.5 rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.02] dark:bg-white/[0.02] prose prose-zinc dark:prose-invert prose-xs max-w-none">
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
      <div className="h-12 px-4 border-t border-black/[0.06] dark:border-white/[0.08] flex items-center justify-end space-x-2">
        <button
          onClick={onClose}
          className="px-3 py-1.5 rounded-lg text-zinc-600 dark:text-zinc-300 hover:bg-black/[0.05] dark:hover:bg-white/[0.08] text-xs transition-colors"
        >
          {t("cancel")}
        </button>
        <button
          onClick={handleSave}
          className="px-4 py-1.5 rounded-lg bg-teal-600 hover:bg-teal-700 text-white font-medium text-xs shadow-xs transition-all cursor-pointer"
        >
          {t("save")}
        </button>
      </div>
    </div>
  );
};
