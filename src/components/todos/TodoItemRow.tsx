import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Check,
  Play,
  Pause,
  Clock,
  Copy,
  MoreHorizontal,
  Edit2,
  Archive,
  Undo,
  Trash2,
} from "lucide-react";
import type { TodoItem } from "@/types";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { formatDeadline } from "@/lib/dateUtils";

interface TodoItemRowProps {
  todo: TodoItem;
  onEdit: (todo: TodoItem) => void;
  onOpenDeadlinePicker: (todo: TodoItem) => void;
  onOpenTagAssignment: (todo: TodoItem) => void;
}

export const TodoItemRow: React.FC<TodoItemRowProps> = ({
  todo,
  onEdit,
  onOpenDeadlinePicker,
  onOpenTagAssignment,
}) => {
  const { t, i18n } = useTranslation();

  const toggleComplete = useTodoStore((s) => s.toggleComplete);
  const toggleDoing = useTodoStore((s) => s.toggleDoing);
  const archiveTodo = useTodoStore((s) => s.archiveTodo);
  const restoreTodo = useTodoStore((s) => s.restoreTodo);
  const deleteTodo = useTodoStore((s) => s.deleteTodo);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const [showMenu, setShowMenu] = useState(false);
  const [copied, setCopied] = useState(false);

  const isCompleted = !!todo.completedAt;
  const isArchived = !!todo.archivedAt;
  const isDoing = !!todo.startedAt && !isCompleted && !isArchived;

  const assignedTagIds = tagsWorkspace.assignments[todo.id] || [];
  const assignedTags = tagsWorkspace.tags.filter((t) => assignedTagIds.includes(t.id));

  const deadlineInfo = todo.dueAt ? formatDeadline(todo.dueAt, i18n.language) : null;

  const handleCopyMarkdown = (e: React.MouseEvent) => {
    e.stopPropagation();
    const statusMark = isCompleted ? "[x]" : "[ ]";
    const text = `- ${statusMark} ${todo.title}${todo.content ? `\n  ${todo.content}` : ""}`;
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1200);
  };

  return (
    <div
      className={`group relative px-2.5 py-1.5 rounded-xl transition-colors select-none ${
        isDoing
          ? "doing-item"
          : "hover:bg-black/[0.03] dark:hover:bg-white/[0.04]"
      }`}
    >
      {/* Main Row: Checkbox + Title + Inline Hover Actions */}
      <div className="flex items-center space-x-2.5">
        {/* Checkbox: 18x18 squircle */}
        <button
          type="button"
          onClick={() => toggleComplete(todo.id)}
          className={`w-[18px] h-[18px] shrink-0 rounded-[5px] flex items-center justify-center border transition-all tactile-btn cursor-pointer ${
            isCompleted
              ? "bg-teal-600 dark:bg-teal-500 border-teal-600 dark:border-teal-500 text-white dark:text-zinc-950 shadow-xs"
              : "border-zinc-300 dark:border-white/20 hover:border-teal-500 dark:hover:border-teal-400 bg-transparent"
          }`}
        >
          {isCompleted && <Check className="w-3 h-3 stroke-[3]" />}
        </button>

        {/* Title (click to edit) */}
        <div
          className="flex-1 min-w-0 cursor-pointer py-0.5"
          onClick={() => onEdit(todo)}
        >
          <span
            className={`text-[13px] leading-snug block truncate tracking-tight ${
              isCompleted
                ? "line-through text-zinc-400 dark:text-zinc-500"
                : isDoing
                ? "font-medium text-zinc-900 dark:text-zinc-100"
                : "text-zinc-800 dark:text-zinc-200 group-hover:text-zinc-950 dark:group-hover:text-white"
            }`}
          >
            {todo.title}
          </span>
        </div>

        {/* Inline Hover Actions (Subtle, clean, no heavy floating box) */}
        <div className="flex items-center space-x-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
          {/* Doing Play/Pause */}
          {!isCompleted && !isArchived && (
            <button
              type="button"
              onClick={() => toggleDoing(todo.id)}
              title={isDoing ? t("stopDoing") : t("startDoing")}
              className={`w-6 h-6 rounded flex items-center justify-center tactile-btn cursor-pointer ${
                isDoing
                  ? "text-teal-600 dark:text-teal-400"
                  : "text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
              }`}
            >
              {isDoing ? (
                <Pause className="w-3 h-3 fill-current" />
              ) : (
                <Play className="w-3 h-3 fill-current" />
              )}
            </button>
          )}

          {/* Deadline */}
          {!isArchived && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              title={todo.dueAt ? t("editDeadline") : t("setDeadline")}
              className={`w-6 h-6 rounded flex items-center justify-center tactile-btn cursor-pointer ${
                todo.dueAt
                  ? "text-teal-600 dark:text-teal-400"
                  : "text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
              }`}
            >
              <Clock className="w-3 h-3" />
            </button>
          )}

          {/* Copy Markdown */}
          <button
            type="button"
            onClick={handleCopyMarkdown}
            title={copied ? t("copied") : t("copyMarkdown")}
            className="w-6 h-6 rounded flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-black/[0.04] dark:hover:bg-white/[0.06] tactile-btn cursor-pointer"
          >
            {copied ? (
              <Check className="w-3 h-3 text-teal-600 dark:text-teal-400 stroke-[2.5]" />
            ) : (
              <Copy className="w-3 h-3" />
            )}
          </button>

          {/* More actions dropdown */}
          <div className="relative">
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                setShowMenu(!showMenu);
              }}
              title={t("moreActions")}
              className="w-6 h-6 rounded flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-black/[0.04] dark:hover:bg-white/[0.06] tactile-btn cursor-pointer"
            >
              <MoreHorizontal className="w-3 h-3" />
            </button>

            {showMenu && (
              <>
                <div
                  className="fixed inset-0 z-40"
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowMenu(false);
                  }}
                />
                <div className="absolute right-0 top-7 z-50 w-24 bg-white dark:bg-[#1C2328] rounded-lg shadow-xl border border-black/[0.08] dark:border-white/[0.1] py-1 text-xs animate-in fade-in zoom-in-95 duration-75">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowMenu(false);
                      onEdit(todo);
                    }}
                    className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-zinc-200 hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600 dark:hover:text-teal-400"
                  >
                    <Edit2 className="w-3 h-3" />
                    <span>{t("edit")}</span>
                  </button>

                  {isArchived ? (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setShowMenu(false);
                        restoreTodo(todo.id);
                      }}
                      className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-zinc-200 hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600 dark:hover:text-teal-400"
                    >
                      <Undo className="w-3 h-3" />
                      <span>{t("restore")}</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setShowMenu(false);
                        archiveTodo(todo.id);
                      }}
                      className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-zinc-200 hover:bg-amber-50 dark:hover:bg-amber-950/40 hover:text-amber-500"
                    >
                      <Archive className="w-3 h-3" />
                      <span>{t("archive")}</span>
                    </button>
                  )}

                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowMenu(false);
                      deleteTodo(todo.id);
                    }}
                    className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40"
                  >
                    <Trash2 className="w-3 h-3" />
                    <span>{t("delete")}</span>
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Sub-row: Tags & Deadline (Indented 28px) */}
      {(assignedTags.length > 0 || deadlineInfo || isDoing) && (
        <div className="pl-[28px] pt-1 flex flex-wrap items-center gap-1.5">
          {/* Doing Status Tag */}
          {isDoing && (
            <span className="inline-flex items-center space-x-1 px-2 py-0.2 rounded text-[10px] font-medium bg-teal-500/10 text-teal-600 dark:text-teal-400 border border-teal-500/20">
              <span className="w-1 h-1 rounded-full bg-teal-400" />
              <span>{t("doing")}</span>
            </span>
          )}

          {/* Assigned Tag Chips */}
          {assignedTags.map((tag) => (
            <button
              key={tag.id}
              type="button"
              onClick={() => onOpenTagAssignment(todo)}
              className="inline-flex items-center space-x-1 px-1.5 py-0.2 rounded text-[10px] font-medium transition-opacity hover:opacity-80 tactile-btn cursor-pointer"
              style={{
                backgroundColor: `${tag.colorHex}15`,
                color: tag.colorHex,
              }}
            >
              <span
                className="w-1.5 h-1.5 rounded-full shrink-0"
                style={{ backgroundColor: tag.colorHex }}
              />
              <span>{tag.name}</span>
            </button>
          ))}

          {/* Deadline */}
          {deadlineInfo && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              className={`inline-flex items-center space-x-1 text-[10px] px-1.5 py-0.2 rounded transition-opacity hover:opacity-80 tactile-btn cursor-pointer ${
                deadlineInfo.isOverdue && !isCompleted
                  ? "text-red-500 dark:text-red-400 font-medium"
                  : "text-zinc-500 dark:text-zinc-400"
              }`}
            >
              <Clock className="w-2.5 h-2.5" />
              <span>{deadlineInfo.label}</span>
              {deadlineInfo.isOverdue && !isCompleted && <span>· {t("overdue")}</span>}
            </button>
          )}
        </div>
      )}
    </div>
  );
};
