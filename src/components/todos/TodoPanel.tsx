import React, { useState, useMemo, useEffect } from "react";
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

  useEffect(() => {
    const handler = () => handleOpenCreate();
    window.addEventListener("floatick:new-item", handler);
    return () => window.removeEventListener("floatick:new-item", handler);
  }, []);

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
      {/* Action Bar */}
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
      <div className="flex-1 overflow-y-auto px-4 pb-3 space-y-3 smooth-scroll">
        {groupedTodos.length === 0 ? (
          <div className="h-full min-h-[300px] flex flex-col items-center justify-center text-center p-6 space-y-2">
            <CheckCircle2 className="w-9 h-9 text-teal-500/40" />
            <p className="text-xs font-medium text-zinc-700 dark:text-zinc-300">
              {t("allClear")}
            </p>
            <p className="text-[11px] text-zinc-400 dark:text-zinc-500">
              {t("allClearSub")}
            </p>
          </div>
        ) : (
          groupedTodos.map((group) => (
            <div key={group.label} className="space-y-0.5">
              {/* Clean category header */}
              <div className="px-2.5 pt-1 text-[11px] font-medium text-zinc-400 dark:text-zinc-500">
                {group.label}
              </div>

              {/* Items */}
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

      {/* Todo Editor Drawer */}
      <TodoEditorDrawer
        todoId={editingTodoId}
        isOpen={isEditorOpen}
        onClose={() => setIsEditorOpen(false)}
      />

      {/* Deadline Picker Modal */}
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
