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
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <div
      className={`group relative px-3 py-2.5 rounded-2xl transition-all duration-200 select-none ${
        isDoing
          ? "doing-glow"
          : "hover:bg-white/[0.045] dark:hover:bg-white/[0.045] border border-transparent hover:border-black/[0.04] dark:hover:border-white/[0.06]"
      }`}
    >
      {/* Top Row: Checkbox + Title + Hover Dock Actions */}
      <div className="flex items-center space-x-3">
        {/* Checkbox: Custom tactile squircle */}
        <button
          type="button"
          onClick={() => toggleComplete(todo.id)}
          className={`w-[20px] h-[20px] shrink-0 rounded-[6px] flex items-center justify-center border transition-all tactile-btn cursor-pointer ${
            isCompleted
              ? "bg-teal-500 dark:bg-[#2DD4BF] border-teal-500 dark:border-[#2DD4BF] text-white dark:text-zinc-950 shadow-[0_2px_8px_rgba(45,212,191,0.35)]"
              : "border-zinc-300 dark:border-white/20 hover:border-teal-500 dark:hover:border-[#2DD4BF] bg-transparent"
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
            className={`text-[13px] leading-5 block truncate tracking-tight transition-colors ${
              isCompleted
                ? "line-through text-zinc-400 dark:text-[#64748B]"
                : isDoing
                ? "font-semibold text-zinc-900 dark:text-[#F1F5F9]"
                : "font-medium text-zinc-800 dark:text-[#E2E8F0] group-hover:text-zinc-950 dark:group-hover:text-white"
            }`}
          >
            {todo.title}
          </span>
        </div>

        {/* Right Hover Actions: Sleek Capsule Toolbar */}
        <div className="flex items-center space-x-0.5 opacity-0 group-hover:opacity-100 transition-opacity bg-white/80 dark:bg-[#1E272E]/90 backdrop-blur-md px-1 py-0.5 rounded-xl border border-black/[0.06] dark:border-white/[0.08] shadow-xs">
          {/* Doing Play/Pause button */}
          {!isCompleted && !isArchived && (
            <button
              type="button"
              onClick={() => toggleDoing(todo.id)}
              title={isDoing ? t("stopDoing") : t("startDoing")}
              className={`w-6 h-6 rounded-lg flex items-center justify-center tactile-btn cursor-pointer ${
                isDoing
                  ? "text-teal-500 dark:text-[#2DD4BF] bg-teal-500/15"
                  : "text-zinc-400 hover:text-zinc-800 dark:hover:text-[#F1F5F9] hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
              }`}
            >
              {isDoing ? (
                <Pause className="w-3 h-3 fill-current" />
              ) : (
                <Play className="w-3 h-3 fill-current" />
              )}
            </button>
          )}

          {/* Deadline Button */}
          {!isArchived && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              title={todo.dueAt ? t("editDeadline") : t("setDeadline")}
              className={`w-6 h-6 rounded-lg flex items-center justify-center tactile-btn cursor-pointer ${
                todo.dueAt
                  ? "text-teal-500 dark:text-[#2DD4BF]"
                  : "text-zinc-400 hover:text-zinc-800 dark:hover:text-[#F1F5F9] hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
              }`}
            >
              <Clock className="w-3 h-3" />
            </button>
          )}

          {/* Copy as Markdown Button */}
          <button
            type="button"
            onClick={handleCopyMarkdown}
            title={copied ? t("copied") : t("copyMarkdown")}
            className="w-6 h-6 rounded-lg flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-[#F1F5F9] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] tactile-btn cursor-pointer"
          >
            {copied ? (
              <Check className="w-3 h-3 text-teal-500 dark:text-[#2DD4BF]" />
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
              className="w-6 h-6 rounded-lg flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-[#F1F5F9] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] tactile-btn cursor-pointer"
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
                <div className="absolute right-0 top-7 z-50 w-28 bg-white dark:bg-[#1E272E] rounded-xl shadow-2xl border border-black/[0.08] dark:border-white/[0.1] py-1 text-xs animate-in fade-in zoom-in-95 duration-100">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowMenu(false);
                      onEdit(todo);
                    }}
                    className="w-full px-3 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-[#E2E8F0] hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600 dark:hover:text-[#2DD4BF]"
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
                      className="w-full px-3 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-[#E2E8F0] hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600 dark:hover:text-[#2DD4BF]"
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
                      className="w-full px-3 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-[#E2E8F0] hover:bg-amber-50 dark:hover:bg-amber-950/40 hover:text-amber-500"
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
                    className="w-full px-3 py-1.5 flex items-center space-x-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40"
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

      {/* Sub-row: Tags & Deadline badges (Indented) */}
      {(assignedTags.length > 0 || deadlineInfo || isDoing) && (
        <div className="pl-[32px] pt-1.5 flex flex-wrap items-center gap-1.5">
          {/* Doing Status Pill */}
          {isDoing && (
            <span className="inline-flex items-center space-x-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-teal-500/15 text-teal-600 dark:text-[#2DD4BF] border border-teal-500/30">
              <span className="w-1.5 h-1.5 rounded-full bg-[#2DD4BF] shadow-[0_0_6px_#2DD4BF] animate-pulse" />
              <span>{t("doing")}</span>
            </span>
          )}

          {/* Assigned Tag Chips with Gemstone dot */}
          {assignedTags.map((tag) => (
            <button
              key={tag.id}
              type="button"
              onClick={() => onOpenTagAssignment(todo)}
              className="inline-flex items-center space-x-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-medium transition-all hover:scale-105 tactile-btn cursor-pointer"
              style={{
                backgroundColor: `${tag.colorHex}18`,
                color: tag.colorHex,
                border: `1px solid ${tag.colorHex}35`,
              }}
            >
              <span
                className="w-1.5 h-1.5 rounded-full"
                style={{
                  backgroundColor: tag.colorHex,
                  boxShadow: `0 0 6px ${tag.colorHex}88`,
                }}
              />
              <span>{tag.name}</span>
            </button>
          ))}

          {/* Deadline Chip */}
          {deadlineInfo && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              className={`inline-flex items-center space-x-1 text-[10px] px-2.5 py-0.5 rounded-full transition-all hover:scale-105 tactile-btn cursor-pointer ${
                deadlineInfo.isOverdue && !isCompleted
                  ? "bg-red-500/15 text-red-500 dark:text-red-400 border border-red-500/30 font-semibold shadow-[0_0_8px_rgba(239,68,68,0.25)]"
                  : "bg-white/[0.04] text-zinc-600 dark:text-[#94A3B8] border border-black/[0.05] dark:border-white/[0.07]"
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
