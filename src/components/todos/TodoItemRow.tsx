import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Check,
  Play,
  Pause,
  Clock,
  Copy,
  DotsThree,
  PencilSimple,
  Archive,
  ArrowUUpLeft,
  Trash,
  Tag,
} from "@phosphor-icons/react";
import type { TodoItem } from "@/types";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { formatDeadline, formatTime } from "@/lib/dateUtils";

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
      className={`group relative pl-[7px] pr-[5px] py-2 my-[2px] rounded-[8px] transition-colors duration-150 select-none ${
        isDoing
          ? "bg-[#22B8A7]/[0.08] hover:bg-[#22B8A7]/[0.11]"
          : "hover:bg-white/[0.055]"
      }`}
    >
      {/* Main Row: Checkbox + Title + Hover Actions */}
      <div className="flex items-center">
        {/* 21x21 Checkbox with r=5px, border=1.4px */}
        <div className="p-1 shrink-0">
          <button
            type="button"
            onClick={() => toggleComplete(todo.id)}
            className={`w-[21px] h-[21px] rounded-[5px] flex items-center justify-center border-[1.4px] transition-all tactile-btn cursor-pointer ${
              isCompleted
                ? "bg-[#22B8A7] border-[#22B8A7] text-white"
                : "border-[#EEF2F1]/[0.28] hover:border-[#22B8A7] bg-transparent"
            }`}
          >
            {isCompleted && <Check size={14} weight="bold" />}
          </button>
        </div>

        {/* SizedBox(width: 7) */}
        <div className="w-[7px] shrink-0" />

        {/* Title (fontSize: 13.5, color: 0.91 active / 0.45 completed) */}
        <div
          className="flex-1 min-w-0 cursor-pointer h-[30px] flex items-center"
          onClick={() => onEdit(todo)}
        >
          <span
            className={`text-[13.5px] leading-tight block truncate tracking-tight transition-colors ${
              isCompleted
                ? "line-through text-[#EEF2F1]/45"
                : "font-medium text-[#EEF2F1]/91 group-hover:text-[#EEF2F1]"
            }`}
          >
            {todo.title}
          </span>
        </div>

        {/* SizedBox(width: 3) */}
        <div className="w-[3px] shrink-0" />

        {/* Hover Actions */}
        <div className="flex items-center space-x-0.5 opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
          {/* Doing button */}
          {!isCompleted && !isArchived && (
            <button
              type="button"
              onClick={() => toggleDoing(todo.id)}
              title={isDoing ? t("stopDoing") : t("startDoing")}
              className={`w-7 h-7 rounded-md flex items-center justify-center tactile-btn cursor-pointer ${
                isDoing
                  ? "text-[#22B8A7]"
                  : "text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-white/[0.055]"
              }`}
            >
              {isDoing ? (
                <Pause size={16} weight="fill" />
              ) : (
                <Play size={16} weight="fill" />
              )}
            </button>
          )}

          {/* Deadline */}
          {!isArchived && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              title={todo.dueAt ? t("editDeadline") : t("setDeadline")}
              className={`w-7 h-7 rounded-md flex items-center justify-center tactile-btn cursor-pointer ${
                todo.dueAt
                  ? "text-[#22B8A7]"
                  : "text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-white/[0.055]"
              }`}
            >
              <Clock size={16} weight={todo.dueAt ? "fill" : "regular"} />
            </button>
          )}

          {/* Copy */}
          <button
            type="button"
            onClick={handleCopyMarkdown}
            title={copied ? t("copied") : t("copyMarkdown")}
            className="w-7 h-7 rounded-md flex items-center justify-center text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-white/[0.055] tactile-btn cursor-pointer"
          >
            {copied ? (
              <Check size={16} weight="bold" className="text-[#22B8A7]" />
            ) : (
              <Copy size={16} />
            )}
          </button>

          {/* More actions */}
          <div className="relative">
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                setShowMenu(!showMenu);
              }}
              title={t("moreActions")}
              className="w-7 h-7 rounded-md flex items-center justify-center text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-white/[0.055] tactile-btn cursor-pointer"
            >
              <DotsThree size={20} weight="bold" />
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
                <div className="absolute right-0 top-8 z-50 w-28 bg-[#1D2529] rounded-[8px] shadow-2xl border border-white/[0.08] py-1 text-xs animate-in fade-in zoom-in-95 duration-100">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowMenu(false);
                      onEdit(todo);
                    }}
                    className="w-full px-3 py-1.5 flex items-center space-x-2 text-[#EEF2F1] hover:bg-[#22B8A7]/15 hover:text-[#22B8A7]"
                  >
                    <PencilSimple size={14} />
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
                      className="w-full px-3 py-1.5 flex items-center space-x-2 text-[#EEF2F1] hover:bg-[#22B8A7]/15 hover:text-[#22B8A7]"
                    >
                      <ArrowUUpLeft size={14} weight="bold" />
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
                      className="w-full px-3 py-1.5 flex items-center space-x-2 text-[#EEF2F1] hover:bg-amber-500/15 hover:text-amber-400"
                    >
                      <Archive size={14} />
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
                    className="w-full px-3 py-1.5 flex items-center space-x-2 text-red-400 hover:bg-red-500/15 hover:text-red-300"
                  >
                    <Trash size={14} />
                    <span>{t("delete")}</span>
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Sub-row: Indented 36px (Exact Flutter TodoListRow Metadata Line) */}
      <div className="pl-[36px] pt-1 flex items-center justify-between min-h-[20px]">
        {/* Left: Doing status + Deadline status + Tags + Tag shortcut button */}
        <div className="flex items-center space-x-1.5 overflow-x-auto smooth-scroll no-scrollbar py-0.5 min-w-0 flex-1 mr-2">
          {/* Doing status badge */}
          {isDoing && (
            <span className="inline-flex items-center space-x-1 px-1.5 py-0.2 rounded-full text-[10px] font-medium bg-[#22B8A7]/15 text-[#22B8A7] border border-[#22B8A7]/30 shrink-0">
              <span className="w-1.5 h-1.5 rounded-full bg-[#22B8A7] animate-pulse" />
              <span>{t("doing") || "进行中"}</span>
            </span>
          )}

          {/* Deadline */}
          {deadlineInfo && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              className={`inline-flex items-center space-x-1 text-[10.5px] px-1.5 py-0.2 rounded-md transition-opacity hover:opacity-80 tactile-btn cursor-pointer shrink-0 ${
                deadlineInfo.isOverdue && !isCompleted
                  ? "text-[#F18A45] bg-[#F18A45]/10 border border-[#F18A45]/30 font-medium"
                  : "text-[#EEF2F1]/62 hover:text-[#EEF2F1] bg-white/[0.04] border border-white/[0.06]"
              }`}
            >
              <Clock className="w-2.5 h-2.5 shrink-0" />
              <span className="truncate max-w-[120px]">{deadlineInfo.label}</span>
              {deadlineInfo.isOverdue && !isCompleted && <span className="shrink-0">· {t("overdue")}</span>}
            </button>
          )}

          {/* FloatickTagChip (Flutter format) */}
          {assignedTags.map((tag) => (
            <button
              key={tag.id}
              type="button"
              onClick={() => onOpenTagAssignment(todo)}
              title={tag.name}
              className="inline-flex items-center space-x-1 px-1.5 py-0.2 rounded text-[10.5px] font-medium shrink-0 transition-opacity hover:opacity-80 tactile-btn cursor-pointer"
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

          {/* Tag Quick Selection Icon Button (Flutter: assign-tags-$todoId) */}
          {!isArchived && (
            <button
              type="button"
              onClick={() => onOpenTagAssignment(todo)}
              title={t("assignTagsTooltip") || "分配标签"}
              className={`w-5 h-5 rounded flex items-center justify-center shrink-0 transition-colors tactile-btn cursor-pointer ${
                assignedTags.length > 0
                  ? "text-[#22B8A7] hover:bg-[#22B8A7]/10"
                  : "text-[#EEF2F1]/35 hover:text-[#EEF2F1]/80 hover:bg-white/[0.06]"
              }`}
            >
              <Tag size={13} weight={assignedTags.length > 0 ? "fill" : "regular"} />
            </button>
          )}
        </div>

        {/* Right: Created / Archived timestamp (10.5px, opacity: 0.45) */}
        <div className="text-[10.5px] text-[#EEF2F1]/45 shrink-0 font-mono">
          {formatTime(isArchived && todo.archivedAt ? todo.archivedAt : todo.createdAt)}
        </div>
      </div>
    </div>
  );
};
