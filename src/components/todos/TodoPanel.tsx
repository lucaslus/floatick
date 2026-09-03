import React, { useState, useMemo } from "react";
import { useTranslation } from "react-i18next";
import { Search, Plus, Flame, Tag as TagIcon, X, CheckCircle2, Archive } from "lucide-react";
import type { TodoItem } from "@/types";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { TodoItemRow } from "./TodoItemRow";
import { TodoEditDrawer } from "./TodoEditDrawer";
import { getGroupLabel } from "@/lib/dateUtils";

export const TodoPanel: React.FC = () => {
  const { t } = useTranslation();

  const todos = useTodoStore((s) => s.todos);
  const addTodo = useTodoStore((s) => s.addTodo);
  const searchQuery = useTodoStore((s) => s.searchQuery);
  const setSearchQuery = useTodoStore((s) => s.setSearchQuery);
  const isDoingFilter = useTodoStore((s) => s.isDoingFilter);
  const setIsDoingFilter = useTodoStore((s) => s.setIsDoingFilter);
  const activeScope = useTodoStore((s) => s.activeScope);
  const setActiveScope = useTodoStore((s) => s.setActiveScope);

  const tagsWorkspace = useTagStore((s) => s.workspace);
  const selectedTagFilter = useTagStore((s) => s.selectedTagFilter);
  const setSelectedTagFilter = useTagStore((s) => s.setSelectedTagFilter);

  const [newTitle, setNewTitle] = useState("");
  const [editingTodo, setEditingTodo] = useState<TodoItem | null>(null);
  const [showTagMenu, setShowTagMenu] = useState(false);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;
    await addTodo(newTitle.trim());
    setNewTitle("");
  };

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

  // Grouping
  const groupedTodos = useMemo(() => {
    const groups: { label: string; items: TodoItem[] }[] = [];
    const map = new Map<string, TodoItem[]>();

    for (const item of filteredTodos) {
      const label = getGroupLabel(item.createdAt);
      if (!map.has(label)) {
        map.set(label, []);
      }
      map.get(label)!.push(item);
    }

    for (const [label, items] of map.entries()) {
      groups.push({ label, items });
    }

    return groups;
  }, [filteredTodos]);

  const selectedTag = tagsWorkspace.tags.find((t) => t.id === selectedTagFilter);

  return (
    <div className="flex-1 flex flex-col min-h-0 bg-zinc-50/50 dark:bg-zinc-950/40">
      {/* Quick Add Bar */}
      {activeScope === "active" && (
        <form onSubmit={handleCreate} className="p-3 pb-2">
          <div className="relative flex items-center">
            <input
              type="text"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder={t("addTodoPlaceholder")}
              className="w-full pl-8 pr-3 py-2 text-xs rounded-xl bg-white/80 dark:bg-zinc-800/80 border border-black/[0.06] dark:border-white/[0.08] shadow-xs text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-teal-500/30 transition-all"
            />
            <Plus className="w-3.5 h-3.5 absolute left-2.5 text-teal-600 dark:text-teal-400 stroke-[2.5]" />
          </div>
        </form>
      )}

      {/* Filter & Search Bar */}
      <div className="px-3 py-1 flex items-center justify-between space-x-2 text-xs">
        {/* Left Filter Chips */}
        <div className="flex items-center space-x-1.5 flex-wrap">
          {/* Doing Filter Chip */}
          <button
            type="button"
            onClick={() => setIsDoingFilter(!isDoingFilter)}
            className={`inline-flex items-center space-x-1 px-2 py-1 rounded-lg text-[11px] font-medium transition-all cursor-pointer ${
              isDoingFilter
                ? "bg-orange-500 text-white shadow-xs"
                : "bg-black/[0.04] dark:bg-white/[0.06] text-zinc-600 dark:text-zinc-300 hover:bg-black/[0.08]"
            }`}
          >
            <Flame className="w-3 h-3" />
            <span>{t("doingOnly")}</span>
          </button>

          {/* Tag Filter Dropdown */}
          <div className="relative">
            <button
              type="button"
              onClick={() => setShowTagMenu(!showTagMenu)}
              className={`inline-flex items-center space-x-1 px-2 py-1 rounded-lg text-[11px] transition-all cursor-pointer ${
                selectedTag
                  ? "bg-teal-500/15 text-teal-700 dark:text-teal-300 font-medium border border-teal-500/30"
                  : "bg-black/[0.04] dark:bg-white/[0.06] text-zinc-600 dark:text-zinc-300 hover:bg-black/[0.08]"
              }`}
            >
              <TagIcon className="w-3 h-3" />
              <span>{selectedTag ? selectedTag.name : t("allTags")}</span>
            </button>

            {showTagMenu && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowTagMenu(false)} />
                <div className="absolute left-0 top-7 z-50 w-36 bg-white dark:bg-zinc-800 rounded-lg shadow-lg border border-black/[0.08] dark:border-white/[0.08] py-1 text-xs max-h-48 overflow-y-auto">
                  <button
                    onClick={() => {
                      setSelectedTagFilter(null);
                      setShowTagMenu(false);
                    }}
                    className="w-full px-2.5 py-1.5 text-left text-zinc-700 dark:text-zinc-300 hover:bg-black/[0.04]"
                  >
                    {t("allTags")}
                  </button>
                  {tagsWorkspace.tags.map((tag) => (
                    <button
                      key={tag.id}
                      onClick={() => {
                        setSelectedTagFilter(tag.id);
                        setShowTagMenu(false);
                      }}
                      className="w-full px-2.5 py-1.5 flex items-center space-x-1.5 text-left text-zinc-700 dark:text-zinc-300 hover:bg-black/[0.04]"
                    >
                      <span
                        className="w-2 h-2 rounded-full"
                        style={{ backgroundColor: tag.colorHex }}
                      />
                      <span className="truncate">{tag.name}</span>
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>
        </div>

        {/* Right: Active vs Archive toggle */}
        <button
          onClick={() => setActiveScope(activeScope === "active" ? "archived" : "active")}
          className={`flex items-center space-x-1 px-2 py-1 rounded-lg text-[11px] transition-colors ${
            activeScope === "archived"
              ? "bg-amber-500 text-white font-medium"
              : "text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200"
          }`}
          title={activeScope === "active" ? "查看归档" : "返回待办"}
        >
          <Archive className="w-3 h-3" />
          <span>{activeScope === "archived" ? t("archived") : ""}</span>
        </button>
      </div>

      {/* Search Bar (if searching or active) */}
      <div className="px-3 py-1">
        <div className="relative flex items-center">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t("searchTodos")}
            className="w-full pl-7 pr-6 py-1 text-[11px] rounded-lg bg-black/[0.03] dark:bg-white/[0.04] text-zinc-800 dark:text-zinc-200 placeholder:text-zinc-400 focus:outline-none focus:bg-white dark:focus:bg-zinc-800 transition-colors"
          />
          <Search className="w-3 h-3 absolute left-2 text-zinc-400" />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery("")}
              className="absolute right-2 text-zinc-400 hover:text-zinc-600"
            >
              <X className="w-3 h-3" />
            </button>
          )}
        </div>
      </div>

      {/* Todo List Area */}
      <div className="flex-1 overflow-y-auto px-3 py-2 space-y-3">
        {groupedTodos.length === 0 ? (
          <div className="h-full min-h-[240px] flex flex-col items-center justify-center text-center p-6 space-y-2">
            <CheckCircle2 className="w-10 h-10 text-teal-500/40" />
            <p className="text-xs font-medium text-zinc-600 dark:text-zinc-300">
              {t("allClear")}
            </p>
            <p className="text-[11px] text-zinc-400 max-w-[200px]">
              {t("allClearSub")}
            </p>
          </div>
        ) : (
          groupedTodos.map((group) => (
            <div key={group.label} className="space-y-1.5">
              <div className="px-1 text-[10px] font-semibold text-zinc-400 uppercase tracking-wider">
                {group.label}
              </div>
              <div className="space-y-1">
                {group.items.map((todo) => (
                  <TodoItemRow
                    key={todo.id}
                    todo={todo}
                    onEdit={(t) => setEditingTodo(t)}
                  />
                ))}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Edit Drawer Modal */}
      {editingTodo && (
        <TodoEditDrawer
          todoId={editingTodo.id}
          onClose={() => setEditingTodo(null)}
        />
      )}
    </div>
  );
};
