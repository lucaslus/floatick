import React, { useState } from "react";
import { Play, Square, Check, MoreHorizontal, Calendar, Trash2, Archive, Undo, Edit2 } from "lucide-react";
import type { TodoItem } from "@/types";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { formatDeadline } from "@/lib/dateUtils";

interface TodoItemRowProps {
  todo: TodoItem;
  onEdit: (todo: TodoItem) => void;
}

export const TodoItemRow: React.FC<TodoItemRowProps> = ({ todo, onEdit }) => {
  const toggleComplete = useTodoStore((s) => s.toggleComplete);
  const toggleDoing = useTodoStore((s) => s.toggleDoing);
  const archiveTodo = useTodoStore((s) => s.archiveTodo);
  const restoreTodo = useTodoStore((s) => s.restoreTodo);
  const deleteTodo = useTodoStore((s) => s.deleteTodo);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const [showMenu, setShowMenu] = useState(false);

  const isCompleted = !!todo.completedAt;
  const isArchived = !!todo.archivedAt;
  const isDoing = !!todo.startedAt && !isCompleted && !isArchived;

  const assignedTagIds = tagsWorkspace.assignments[todo.id] || [];
  const assignedTags = tagsWorkspace.tags.filter((t) => assignedTagIds.includes(t.id));

  const deadlineInfo = todo.dueAt ? formatDeadline(todo.dueAt) : null;

  return (
    <div
      className={`group relative flex items-start space-x-2.5 px-3 py-2 rounded-xl transition-all duration-150 border ${
        isDoing
          ? "bg-orange-50/70 dark:bg-orange-950/20 border-orange-200 dark:border-orange-900/40 shadow-xs"
          : isCompleted
          ? "opacity-60 bg-transparent border-transparent hover:bg-black/[0.02] dark:hover:bg-white/[0.02]"
          : "bg-white/60 dark:bg-zinc-800/60 border-black/[0.04] dark:border-white/[0.04] hover:border-black/[0.08] dark:hover:border-white/[0.08] shadow-xs"
      }`}
    >
      {/* Complete Checkbox */}
      <button
        onClick={() => toggleComplete(todo.id)}
        className={`mt-0.5 w-4 h-4 rounded-full flex items-center justify-center border transition-all cursor-pointer ${
          isCompleted
            ? "bg-teal-600 border-teal-600 text-white"
            : "border-zinc-300 dark:border-zinc-600 hover:border-teal-500 text-transparent"
        }`}
      >
        <Check className="w-2.5 h-2.5 stroke-[3]" />
      </button>

      {/* Main Content Area */}
      <div className="flex-1 min-w-0" onClick={() => onEdit(todo)}>
        <div className="flex items-center space-x-2">
          <p
            className={`text-xs leading-snug cursor-pointer select-text truncate ${
              isCompleted
                ? "line-through text-zinc-400 dark:text-zinc-500"
                : isDoing
                ? "font-medium text-orange-950 dark:text-orange-200"
                : "text-zinc-800 dark:text-zinc-200"
            }`}
          >
            {todo.title}
          </p>
        </div>

        {/* Tags & Deadline row */}
        <div className="flex flex-wrap items-center gap-1.5 mt-1">
          {/* Tags */}
          {assignedTags.map((tag) => (
            <span
              key={tag.id}
              className="inline-flex items-center px-1.5 py-0.2 rounded-full text-[10px] font-medium"
              style={{
                backgroundColor: `${tag.colorHex}22`,
                color: tag.colorHex,
                border: `1px solid ${tag.colorHex}44`,
              }}
            >
              {tag.name}
            </span>
          ))}

          {/* Deadline */}
          {deadlineInfo && (
            <span
              className={`inline-flex items-center space-x-1 text-[10px] px-1.5 py-0.2 rounded-md ${
                deadlineInfo.isOverdue && !isCompleted
                  ? "bg-red-500/10 text-red-600 dark:text-red-400 border border-red-500/20 font-medium"
                  : "bg-zinc-100 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-400"
              }`}
            >
              <Calendar className="w-2.5 h-2.5" />
              <span>{deadlineInfo.label}</span>
            </span>
          )}
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
        {/* Doing Action Button */}
        {!isCompleted && !isArchived && (
          <button
            onClick={() => toggleDoing(todo.id)}
            title={isDoing ? "停止进行中" : "设为进行中"}
            className={`w-6 h-6 rounded-md flex items-center justify-center transition-colors cursor-pointer ${
              isDoing
                ? "text-orange-600 dark:text-orange-400 bg-orange-100 dark:bg-orange-900/40"
                : "text-zinc-400 hover:text-orange-600 dark:hover:text-orange-400 hover:bg-black/[0.05] dark:hover:bg-white/[0.08]"
            }`}
          >
            {isDoing ? <Square className="w-2.5 h-2.5 fill-current" /> : <Play className="w-2.5 h-2.5 fill-current" />}
          </button>
        )}

        {/* More Actions Dropdown */}
        <div className="relative">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setShowMenu(!showMenu);
            }}
            className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.05] dark:hover:bg-white/[0.08] cursor-pointer"
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
              <div className="absolute right-0 top-7 z-50 w-28 bg-white dark:bg-zinc-800 rounded-lg shadow-lg border border-black/[0.08] dark:border-white/[0.08] py-1 text-xs">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowMenu(false);
                    onEdit(todo);
                  }}
                  className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-zinc-300 hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600"
                >
                  <Edit2 className="w-3 h-3" />
                  <span>编辑</span>
                </button>

                {isArchived ? (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowMenu(false);
                      restoreTodo(todo.id);
                    }}
                    className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-zinc-300 hover:bg-teal-50 dark:hover:bg-teal-950/40 hover:text-teal-600"
                  >
                    <Undo className="w-3 h-3" />
                    <span>恢复</span>
                  </button>
                ) : (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setShowMenu(false);
                      archiveTodo(todo.id);
                    }}
                    className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-zinc-700 dark:text-zinc-300 hover:bg-amber-50 dark:hover:bg-amber-950/40 hover:text-amber-600"
                  >
                    <Archive className="w-3 h-3" />
                    <span>归档</span>
                  </button>
                )}

                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowMenu(false);
                    deleteTodo(todo.id);
                  }}
                  className="w-full px-2.5 py-1.5 flex items-center space-x-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40"
                >
                  <Trash2 className="w-3 h-3" />
                  <span>删除</span>
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
