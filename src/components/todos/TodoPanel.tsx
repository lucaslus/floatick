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
          <div className="h-full min-h-[300px] flex flex-col items-center justify-center text-center p-6 space-y-2.5">
            <CheckCircle2 className="w-12 h-12 text-teal-600/30 dark:text-[#22B8A7]/30" />
            <p className="text-xs font-semibold text-zinc-700 dark:text-[#EEF2F1]">
              {t("allClear")}
            </p>
            <p className="text-[11px] text-zinc-400 dark:text-[#8E9599] max-w-[220px]">
              {t("allClearSub")}
            </p>
          </div>
        ) : (
          groupedTodos.map((group) => (
            <div key={group.label} className="space-y-1">
              <div className="px-2.5 text-[10.5px] font-semibold text-zinc-400 dark:text-[#8E9599] uppercase tracking-wider">
                {group.label}
              </div>
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
