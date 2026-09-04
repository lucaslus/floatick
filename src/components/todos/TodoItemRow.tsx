import React, { useState, useRef } from "react";
import { useTranslation } from "react-i18next";
import {
  Check,
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
  const archiveTodo = useTodoStore((s) => s.archiveTodo);
  const restoreTodo = useTodoStore((s) => s.restoreTodo);
  const deleteTodo = useTodoStore((s) => s.deleteTodo);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const [showMenu, setShowMenu] = useState(false);
  const [copied, setCopied] = useState(false);
  const [menuPlacement, setMenuPlacement] = useState<"top" | "bottom">("bottom");
  const moreButtonRef = useRef<HTMLButtonElement>(null);

  const isCompleted = !!todo.completedAt;
  const isArchived = !!todo.archivedAt;

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

  const handleToggleMenu = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!showMenu && moreButtonRef.current) {
      const rect = moreButtonRef.current.getBoundingClientRect();
      const spaceBelow = window.innerHeight - rect.bottom;
      if (spaceBelow < 140) {
        setMenuPlacement("top");
      } else {
        setMenuPlacement("bottom");
      }
    }
    setShowMenu((prev) => !prev);
  };

  const isMockHover =
    typeof window !== "undefined" &&
    window.location.search.includes("mock") &&
    window.location.search.includes("hover") &&
    todo.id === "mock-todo-2";

  return (
    <div
      className="group relative pl-[7px] pr-[5px] py-2 my-[2px] rounded-[8px] transition-colors duration-150 select-none hover:bg-[var(--color-row-hover)]"
    >
      {/* Main Row: Checkbox + Full-width Title (Completely unobstructed on hover!) */}
      <div className="flex items-center min-h-[26px]">
        {/* 16x16 Checkbox with r=4px, border=1.3px, optically centered with text */}
        <div className="shrink-0 flex items-center justify-center p-1">
          <button
            type="button"
            onClick={() => toggleComplete(todo.id)}
            className={`w-[16px] h-[16px] translate-y-[1px] rounded-[4px] flex items-center justify-center border-[1.3px] transition-all tactile-btn cursor-pointer ${
              isCompleted
                ? "bg-[var(--color-teal-primary)] border-[var(--color-teal-primary)] text-white"
                : "border-[var(--color-text-subtle)] hover:border-[var(--color-teal-primary)] bg-transparent"
            }`}
          >
            {isCompleted && <Check size={11} weight="bold" />}
          </button>
        </div>

        {/* SizedBox(width: 6) */}
        <div className="w-[6px] shrink-0" />

        {/* Title (fontSize: 13.5) - 100% full row width */}
        <div className="flex-1 min-w-0 flex items-center select-text">
          <span
            className={`text-[13.5px] leading-normal block truncate tracking-tight ${
              isCompleted
                ? "line-through text-[var(--color-text-subtle)]"
                : "font-medium text-[var(--color-text-primary)]"
            }`}
          >
            {todo.title}
          </span>
        </div>
      </div>

      {/* Sub-row: Indented 30px (Metadata Line + Floating Hover Action Capsule) */}
      <div className="relative pl-[30px] pt-1 flex items-center justify-between min-h-[26px]">
        {/* Left: Deadline status + Tags + Tag shortcut button */}
        <div className="flex items-center space-x-1.5 overflow-x-auto smooth-scroll no-scrollbar py-0.5 min-w-0 flex-1 mr-2">
          {/* Deadline */}
          {deadlineInfo && (
            <button
              type="button"
              onClick={() => onOpenDeadlinePicker(todo)}
              className={`inline-flex items-center space-x-1 text-[11px] font-medium px-2 py-0.5 rounded-md transition-opacity hover:opacity-80 tactile-btn cursor-pointer shrink-0 ${
                deadlineInfo.isOverdue && !isCompleted
                  ? "text-[#F18A45] bg-[#F18A45]/10 border border-[#F18A45]/30 font-medium"
                  : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] bg-[var(--color-hover-overlay)] border border-[var(--color-border-panel)]"
              }`}
            >
              <Clock className="w-3 h-3 shrink-0" />
              <span className="truncate max-w-[120px]">{deadlineInfo.label}</span>
              {deadlineInfo.isOverdue && !isCompleted && <span className="shrink-0">· {t("overdue")}</span>}
            </button>
          )}

          {/* FloatickTagChip without background and border */}
          {assignedTags.map((tag) => (
            <button
              key={tag.id}
              type="button"
              onClick={() => onOpenTagAssignment(todo)}
              title={tag.name}
              className="inline-flex items-center space-x-1 px-1.5 py-0.5 rounded text-[11px] font-medium shrink-0 transition-all hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
              style={{
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
              className={`w-5 h-5 rounded flex items-center justify-center shrink-0 tactile-btn cursor-pointer ${
                assignedTags.length > 0
                  ? "text-[var(--color-teal-primary)] hover:bg-[var(--color-teal-tint)]"
                  : "text-[var(--color-text-subtle)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
              }`}
            >
              <Tag size={13} weight={assignedTags.length > 0 ? "fill" : "regular"} />
            </button>
          )}
        </div>

        {/* Right: Created / Archived timestamp (Fades out when hovered or menu opened) */}
        <div
          className={`text-[11px] font-medium text-[var(--color-text-subtle)] shrink-0 font-mono transition-opacity duration-150 ${
            showMenu || isMockHover ? "opacity-0" : "group-hover:opacity-0"
          }`}
        >
          {formatTime(isArchived && todo.archivedAt ? todo.archivedAt : todo.createdAt)}
        </div>

        {/* Floating Hover Actions with Frosted Blur Backdrop on the Next Line */}
        <div
          className={`absolute right-0 top-1/2 -translate-y-1/2 flex items-center transition-all duration-150 z-20 ${
            showMenu || isMockHover
              ? "opacity-100 pointer-events-auto"
              : "opacity-0 group-hover:opacity-100 pointer-events-none group-hover:pointer-events-auto"
          }`}
        >
          {/* Frosted Glass Floating Action Pill */}
          <div className="flex items-center space-x-0.5 px-1 py-0.5 rounded-lg bg-[var(--color-bg-drawer)]/92 dark:bg-[var(--color-bg-drawer)]/92 backdrop-blur-md border border-[var(--color-border-drawer)]/70 shadow-sm">
            {/* Edit button */}
            <button
              type="button"
              onClick={() => onEdit(todo)}
              title={t("edit")}
              className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
            >
              <PencilSimple size={14} />
            </button>

            {/* Deadline */}
            {!isArchived && (
              <button
                type="button"
                onClick={() => onOpenDeadlinePicker(todo)}
                title={todo.dueAt ? t("editDeadline") : t("setDeadline")}
                className={`w-6 h-6 rounded flex items-center justify-center tactile-btn cursor-pointer ${
                  todo.dueAt
                    ? "text-[var(--color-teal-primary)]"
                    : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
                }`}
              >
                <Clock size={15} weight={todo.dueAt ? "fill" : "regular"} />
              </button>
            )}

            {/* Copy */}
            <button
              type="button"
              onClick={handleCopyMarkdown}
              title={copied ? t("copied") : t("copyMarkdown")}
              className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
            >
              {copied ? (
                <Check size={14} weight="bold" className="text-[var(--color-teal-primary)]" />
              ) : (
                <Copy size={14} />
              )}
            </button>

            {/* More actions */}
            <div className="relative">
              <button
                ref={moreButtonRef}
                type="button"
                onClick={handleToggleMenu}
                title={t("moreActions")}
                className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
              >
                <DotsThree size={18} weight="bold" />
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
                  <div
                    className={`absolute right-0 ${
                      menuPlacement === "top" ? "bottom-full mb-1.5" : "top-full mt-1.5"
                    } z-50 w-28 bg-[var(--color-bg-drawer)] rounded-[8px] shadow-2xl border border-[var(--color-border-drawer)] py-1 text-xs animate-in fade-in zoom-in-95 duration-100`}
                  >
                    {isArchived ? (
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setShowMenu(false);
                          restoreTodo(todo.id);
                        }}
                        className="w-full px-3 py-1.5 flex items-center space-x-2 text-[var(--color-text-primary)] hover:bg-[var(--color-teal-tint)] hover:text-[var(--color-teal-primary)]"
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
                        className="w-full px-3 py-1.5 flex items-center space-x-2 text-[var(--color-text-primary)] hover:bg-amber-500/15 hover:text-amber-500"
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
      </div>
    </div>
  );
};
