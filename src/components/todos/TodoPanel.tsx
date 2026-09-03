import React, { useState, useMemo } from "react";
import { useTranslation } from "react-i18next";
import { CheckCircle2 } from "lucide-react";
import type { TodoItem } from "@/types";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { ActionBar } from "@/components/common/ActionBar";
import { TodoItemRow } from "./TodoItemRow";
import { TodoEditorDrawer } from "./TodoEditorDrawer";
import { TodoDeadlinePicker } from "./TodoDeadlinePicker";
import { getGroupLabel } from "@/lib/dateUtils";

interface TodoPanelProps {
  onOpenTagFilter: () => void;
}

export const TodoPanel: React.FC<TodoPanelProps> = ({ onOpenTagFilter }) => {
  const { t, i18n } = useTranslation();

  const todos = useTodoStore((s) => s.todos);
  const updateTodo = useTodoStore((s) => s.updateTodo);
  const searchQuery = useTodoStore((s) => s.searchQuery);
  const setSearchQuery = useTodoStore((s) => s.setSearchQuery);
  const isDoingFilter = useTodoStore((s) => s.isDoingFilter);
  const setIsDoingFilter = useTodoStore((s) => s.setIsDoingFilter);
  const activeScope = useTodoStore((s) => s.activeScope);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const selectedTagFilter = useTagStore((s) => s.selectedTagFilter);

  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [editingTodoId, setEditingTodoId] = useState<string | null>(null);

  // Standalone Deadline Picker on row
  const [deadliningTodo, setDeadliningTodo] = useState<TodoItem | null>(null);

  // Filter todos
  const filteredTodos = useMemo(() => {
    return todos.filter((item) => {
      // Scope filter
      const isArchived = !!item.archivedAt;
      if (activeScope === "active" && isArchived) return false;
      if (activeScope === "archived" && !isArchived) return false;

      // Doing filter
      if (isDoingFilter) {
        const isDoing = !!item.startedAt && !item.completedAt && !item.archivedAt;
        if (!isDoing) return false;
      }

      // Tag filter
      if (selectedTagFilter) {
        const assigned = tagsWorkspace.assignments[item.id] || [];
        if (!assigned.includes(selectedTagFilter)) return false;
      }

      // Search query filter
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchTitle = item.title.toLowerCase().includes(q);
        const matchContent = (item.content || "").toLowerCase().includes(q);
        if (!matchTitle && !matchContent) return false;
      }

      return true;
    });
  }, [todos, activeScope, isDoingFilter, selectedTagFilter, searchQuery, tagsWorkspace]);

  // Grouping by Date
  const groupedTodos = useMemo(() => {
    const groups: { label: string; items: TodoItem[] }[] = [];
    const map = new Map<string, TodoItem[]>();

    for (const item of filteredTodos) {
      const label = getGroupLabel(item.createdAt, i18n.language);
      if (!map.has(label)) {
        map.set(label, []);
      }
      map.get(label)!.push(item);
    }

    for (const [label, items] of map.entries()) {
      groups.push({ label, items });
    }

    return groups;
  }, [filteredTodos, i18n.language]);

  const handleOpenCreate = () => {
    setEditingTodoId(null);
    setIsEditorOpen(true);
  };

  const handleOpenEdit = (todo: TodoItem) => {
    setEditingTodoId(todo.id);
    setIsEditorOpen(true);
  };

  const handleSaveDeadline = async (dueAt: string | null, reminderAt: string | null) => {
    if (deadliningTodo) {
      await updateTodo(deadliningTodo.id, { dueAt, reminderAt });
      setDeadliningTodo(null);
    }
  };

  return (
    <div className="flex-1 flex flex-col min-h-0">
      {/* Action Bar (Search + Doing + Tag + Add) */}
      <ActionBar
        query={searchQuery}
        onQueryChange={setSearchQuery}
        showDoingFilter={activeScope === "active"}
        isDoingSelected={isDoingFilter}
        onToggleDoingFilter={() => setIsDoingFilter(!isDoingFilter)}
        selectedTagCount={selectedTagFilter ? 1 : 0}
        onOpenTagFilter={onOpenTagFilter}
        onAddNew={handleOpenCreate}
      />

      {/* Todo List Area */}
      <div className="flex-1 overflow-y-auto px-4 pb-4 space-y-4">
        {groupedTodos.length === 0 ? (
          <div className="h-full min-h-[340px] flex flex-col items-center justify-center text-center p-6 space-y-3">
            <div className="w-14 h-14 rounded-2xl bg-teal-500/10 dark:bg-teal-500/15 border border-teal-500/20 flex items-center justify-center text-teal-500 dark:text-[#2DD4BF] shadow-[0_0_24px_rgba(45,212,191,0.15)]">
              <CheckCircle2 className="w-7 h-7" />
            </div>
            <div>
              <p className="text-xs font-semibold text-zinc-800 dark:text-[#F1F5F9] tracking-tight">
                {t("allClear")}
              </p>
              <p className="text-[11px] text-zinc-400 dark:text-[#94A3B8] max-w-[240px] mt-1 leading-relaxed">
                {t("allClearSub")}
              </p>
            </div>
          </div>
        ) : (
          groupedTodos.map((group) => (
            <div key={group.label} className="space-y-1.5">
              {/* Category Divider Header */}
              <div className="px-3 pt-1 flex items-center space-x-2">
                <span className="text-[10px] font-semibold text-zinc-400 dark:text-[#64748B] uppercase tracking-[0.14em]">
                  {group.label}
                </span>
                <div className="flex-1 h-[1px] bg-black/[0.04] dark:bg-white/[0.06]" />
                <span className="text-[9.5px] font-mono text-zinc-400 dark:text-[#64748B]">
                  {group.items.length}
                </span>
              </div>

              {/* Items List */}
              <div className="space-y-0.5">
                {group.items.map((todo) => (
                  <TodoItemRow
                    key={todo.id}
                    todo={todo}
                    onEdit={handleOpenEdit}
                    onOpenDeadlinePicker={(t) => setDeadliningTodo(t)}
                    onOpenTagAssignment={handleOpenEdit}
                  />
                ))}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Slide-up Todo Editor Drawer */}
      <TodoEditorDrawer
        todoId={editingTodoId}
        isOpen={isEditorOpen}
        onClose={() => setIsEditorOpen(false)}
      />

      {/* Standalone Deadline Picker Modal */}
      {deadliningTodo && (
        <TodoDeadlinePicker
          initialDueAt={deadliningTodo.dueAt}
          initialReminderAt={deadliningTodo.reminderAt}
          onSave={handleSaveDeadline}
          onClose={() => setDeadliningTodo(null)}
        />
      )}
    </div>
  );
};
