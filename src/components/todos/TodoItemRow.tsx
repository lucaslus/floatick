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
  const { t } = useTranslation();

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

  const deadlineInfo = todo.dueAt ? formatDeadline(todo.dueAt) : null;

  const handleCopyMarkdown = (e: React.MouseEvent) => {
    e.stopPropagation();
    const statusMark = isCompleted ? "[x]" : "[ ]";
    const text = `- ${statusMark} ${todo.title}${todo.content ? `\n  ${todo.content}` : ""}`;
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <div
      className={`group relative px-2.5 py-2 rounded-xl transition-all duration-150 select-none ${
        isDoing
          ? "bg-teal-500/[0.08] dark:bg-[#22B8A7]/[0.09] border border-teal-500/25 dark:border-[#22B8A7]/30 shadow-xs"
          : "hover:bg-black/[0.035] dark:hover:bg-white/[0.045] border border-transparent"
      }`}
    >
      {/* Top Row: Checkbox + Title + Right Hover Actions */}
      <div className="flex items-center space-x-2.5">
        {/* Checkbox: 21x21 rounded square */}
        <button
          type="button"
          onClick={() => toggleComplete(todo.id)}
          className={`w-[21px] h-[21px] shrink-0 rounded-[7px] flex items-center justify-center border transition-all mui-ripple cursor-pointer ${
            isCompleted
              ? "bg-teal-600 dark:bg-[#22B8A7] border-teal-600 dark:border-[#22B8A7] text-white shadow-xs"
              : "border-zinc-300 dark:border-white/25 hover:border-teal-500 dark:hover:border-[#22B8A7] bg-transparent"
          }`}
        >
          {isCompleted && <Check className="w-3.5 h-3.5 stroke-[3]" />}
        </button>

        {/* Title (click to edit) */}
        <div
          className="flex-1 min-w-0 cursor-pointer"
          onClick={() => onEdit(todo)}
        >
          <span
            className={`text-[13.5px] leading-5 block truncate ${
              isCompleted
                ? "line-through text-zinc-400 dark:text-[#8E9599]"
                : isDoing
                ? "font-medium text-zinc-900 dark:text-[#EEF2F1]"
                : "text-zinc-800 dark:text-[#EEF2F1]"
            }`}
          >
            {todo.title}
          </span>
        </div>

        {/* Right Hover Actions (Start doing, Alarm, Copy, More) */}
        <div className="flex items-center space-x-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
          {/* Doing Play/Pause button */}
          {!isCompleted && !isArchived && (
            <button
              type="button"
              onClick={() => toggleDoing(todo.id)}
              title={isDoing ? t("stopDoing") : t("startDoing")}
              className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors mui-ripple cursor-pointer ${
                isDoing
                  ? "text-teal-600 dark:text-[#22B8A7] bg-teal-500/10"
                  : "text-zinc-400 hover:text-zinc-800 dark:hover:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
              }`}
            >
              {isDoing ? (
                <Pause className="w-3.5 h-3.5 fill-current" />
              ) : (
                <Play className="w-3.5 h-3.5 fill-current" />
              )}
            </button>
          )}

          {/* Deadline / Alarm Button */}
          {!isArchived && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              title={todo.dueAt ? t("editDeadline") : t("setDeadline")}
              className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors mui-ripple cursor-pointer ${
                todo.dueAt
                  ? "text-teal-600 dark:text-[#22B8A7]"
                  : "text-zinc-400 hover:text-zinc-800 dark:hover:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
              }`}
            >
              <Clock className="w-3.5 h-3.5" />
            </button>
          )}

          {/* Copy as Markdown Button */}
          <button
            type="button"
            onClick={handleCopyMarkdown}
            title={copied ? t("copied") : t("copyMarkdown")}
            className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] transition-colors mui-ripple cursor-pointer"
          >
            {copied ? (
              <Check className="w-3.5 h-3.5 text-teal-600 dark:text-[#22B8A7]" />
            ) : (
              <Copy className="w-3.5 h-3.5" />
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
              className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] transition-colors mui-ripple cursor-pointer"
            >
              <MoreHorizontal className="w-3.5 h-3.5" />
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
                <div className="absolute right-0 top-8 z-50 w-28 bg-white dark:bg-[#1D2529] rounded-xl shadow-xl border border-black/[0.08] dark:border-white/[0.1] py-1 text-xs">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowMenu(false);
                      onEdit(todo);
                    }}
                    className="w-full px-3 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-[#EEF2F1] hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600 dark:hover:text-[#22B8A7]"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
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
                      className="w-full px-3 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-[#EEF2F1] hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600 dark:hover:text-[#22B8A7]"
                    >
                      <Undo className="w-3.5 h-3.5" />
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
                      className="w-full px-3 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-[#EEF2F1] hover:bg-amber-50 dark:hover:bg-amber-950/40 hover:text-amber-600"
                    >
                      <Archive className="w-3.5 h-3.5" />
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
                    className="w-full px-3 py-1.5 flex items-center space-x-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>{t("delete")}</span>
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Indented Sub-row (left indent 31px): Tags & Deadline badges */}
      {(assignedTags.length > 0 || deadlineInfo || isDoing) && (
        <div className="pl-[31px] pt-1 flex flex-wrap items-center gap-1.5">
          {/* Doing Chip */}
          {isDoing && (
            <span className="inline-flex items-center space-x-1 px-2.5 py-0.5 rounded-full text-[10px] font-medium bg-teal-500/15 text-teal-700 dark:text-[#22B8A7] border border-teal-500/30">
              <span className="w-1.5 h-1.5 rounded-full bg-[#22B8A7] animate-pulse" />
              <span>{t("doing")}</span>
            </span>
          )}

          {/* Assigned Tags */}
          {assignedTags.map((tag) => (
            <button
              key={tag.id}
              type="button"
              onClick={() => onOpenTagAssignment(todo)}
              className="inline-flex items-center space-x-1.5 px-2.5 py-0.5 rounded-full text-[10.5px] font-medium transition-transform hover:scale-105 mui-ripple cursor-pointer"
              style={{
                backgroundColor: `${tag.colorHex}22`,
                color: tag.colorHex,
                border: `1px solid ${tag.colorHex}44`,
              }}
            >
              <span
                className="w-1.5 h-1.5 rounded-full"
                style={{ backgroundColor: tag.colorHex }}
              />
              <span>{tag.name}</span>
            </button>
          ))}

          {/* Deadline Badge */}
          {deadlineInfo && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              className={`inline-flex items-center space-x-1 text-[10.5px] px-2.5 py-0.5 rounded-full transition-transform hover:scale-105 mui-ripple cursor-pointer ${
                deadlineInfo.isOverdue && !isCompleted
                  ? "bg-red-500/15 text-red-500 dark:text-red-400 border border-red-500/30 font-medium"
                  : "bg-black/[0.04] dark:bg-white/[0.06] text-zinc-600 dark:text-[#A0A6AA] border border-black/[0.04] dark:border-white/[0.06]"
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
