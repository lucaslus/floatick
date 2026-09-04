import React, { useState, useMemo, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { CheckCircle } from "@phosphor-icons/react";
import type { TodoItem } from "@/types";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { ActionBar } from "@/components/common/ActionBar";
import { TodoItemRow } from "./TodoItemRow";
import { TodoDeadlinePicker } from "./TodoDeadlinePicker";
import { getGroupLabel } from "@/lib/dateUtils";

interface TodoPanelProps {
  onOpenTagFilter: () => void;
  onOpenTagAssignment: (todoId: string) => void;
}

export const TodoPanel: React.FC<TodoPanelProps> = ({
  onOpenTagFilter,
  onOpenTagAssignment,
}) => {
  const { t, i18n } = useTranslation();

  const todos = useTodoStore((s) => s.todos);
  const updateTodo = useTodoStore((s) => s.updateTodo);
  const searchQuery = useTodoStore((s) => s.searchQuery);
  const setSearchQuery = useTodoStore((s) => s.setSearchQuery);
  const activeScope = useTodoStore((s) => s.activeScope);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const selectedTagIds = useTagStore((s) => s.selectedTagIds);

  const setIsEditorOpen = useTodoStore((s) => s.setIsEditorOpen);
  const setEditingTodoId = useTodoStore((s) => s.setEditingTodoId);

  // Standalone Deadline Picker on row
  const [deadliningTodo, setDeadliningTodo] = useState<TodoItem | null>(null);

  // Filter todos
  const filteredTodos = useMemo(() => {
    return todos.filter((item) => {
      // Scope filter
      const isArchived = !!item.archivedAt;
      if (activeScope === "active" && isArchived) return false;
      if (activeScope === "archived" && !isArchived) return false;

      // Multi-Tag filter (OR match, exact same as Flutter)
      if (selectedTagIds.length > 0) {
        const assigned = tagsWorkspace.assignments[item.id] || [];
        const matchesTag = selectedTagIds.some((id) => assigned.includes(id));
        if (!matchesTag) return false;
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
  }, [todos, activeScope, selectedTagIds, searchQuery, tagsWorkspace]);

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

  const setEditorMode = useTodoStore((s) => s.setEditorMode);

  const handleOpenCreate = () => {
    setEditingTodoId(null);
    setEditorMode("edit");
    setIsEditorOpen(true);
  };

  useEffect(() => {
    const handler = () => handleOpenCreate();
    window.addEventListener("floatick:new-item", handler);
    return () => window.removeEventListener("floatick:new-item", handler);
  }, []);

  const handleOpenView = (todo: TodoItem) => {
    setEditingTodoId(todo.id);
    setEditorMode("view");
    setIsEditorOpen(true);
  };

  const handleOpenEdit = (todo: TodoItem) => {
    setEditingTodoId(todo.id);
    setEditorMode("edit");
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
        selectedTagCount={selectedTagIds.length}
        onOpenTagFilter={onOpenTagFilter}
        onAddNew={handleOpenCreate}
      />

      {/* Todo List Area */}
      <div className="flex-1 overflow-y-auto px-4 pb-3 space-y-3 smooth-scroll">
        {groupedTodos.length === 0 ? (
          <div className="h-full min-h-[300px] flex flex-col items-center justify-center text-center p-6 space-y-2">
            <CheckCircle size={42} weight="duotone" className="text-[var(--color-teal-primary)]/50" />
            <p className="text-[13.5px] font-semibold text-[var(--color-text-primary)]">
              {t("allClear")}
            </p>
            <p className="text-[12px] font-medium text-[var(--color-text-subtle)]">
              {t("allClearSub")}
            </p>
          </div>
        ) : (
          groupedTodos.map((group) => (
            <div key={group.label} className="space-y-0.5">
              {/* Clean category header */}
              <div className="px-2.5 pt-1 text-[11.5px] font-semibold text-[var(--color-text-subtle)] uppercase tracking-wider">
                {group.label}
              </div>

              {/* Items */}
              <div className="space-y-0.5">
                {group.items.map((todo) => (
                  <TodoItemRow
                    key={todo.id}
                    todo={todo}
                    onView={handleOpenView}
                    onEdit={handleOpenEdit}
                    onOpenDeadlinePicker={(t) => setDeadliningTodo(t)}
                    onOpenTagAssignment={() => onOpenTagAssignment(todo.id)}
                  />
                ))}
              </div>
            </div>
          ))
        )}
      </div>

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
