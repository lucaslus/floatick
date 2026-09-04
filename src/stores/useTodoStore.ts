import { create } from "zustand";
import type { TodoItem } from "@/types";
import { api } from "@/lib/api";
import { useTagStore } from "./useTagStore";

interface TodoState {
  todos: TodoItem[];
  isLoaded: boolean;
  searchQuery: string;
  activeScope: "active" | "archived";
  editingTodoId: string | null;
  isEditorOpen: boolean;

  setSearchQuery: (query: string) => void;
  setActiveScope: (scope: "active" | "archived") => void;
  setEditingTodoId: (id: string | null) => void;
  setIsEditorOpen: (val: boolean) => void;

  loadTodos: () => Promise<void>;
  addTodo: (title: string, content?: string, tagId?: string) => Promise<TodoItem>;
  toggleComplete: (id: string) => Promise<void>;
  updateTodo: (id: string, updates: Partial<TodoItem>) => Promise<void>;
  deleteTodo: (id: string) => Promise<void>;
  archiveTodo: (id: string) => Promise<void>;
  restoreTodo: (id: string) => Promise<void>;
}

export const useTodoStore = create<TodoState>((set, get) => ({
  todos: [],
  isLoaded: false,
  searchQuery: "",
  activeScope: "active",
  editingTodoId: null,
  isEditorOpen: false,

  setSearchQuery: (query) => set({ searchQuery: query }),
  setActiveScope: (scope) => set({ activeScope: scope }),
  setEditingTodoId: (id) => set({ editingTodoId: id }),
  setIsEditorOpen: (val) => set({ isEditorOpen: val }),

  loadTodos: async () => {
    try {
      const data = await api.getTodos();
      set({ todos: data, isLoaded: true });
    } catch {
      set({ isLoaded: true });
    }
  },

  addTodo: async (title: string, content: string = "") => {
    const trimmed = title.trim();
    if (!trimmed) throw new Error("Title cannot be empty");

    const newTodo: TodoItem = {
      id: crypto.randomUUID(),
      title: trimmed,
      content: content.trim(),
      createdAt: new Date().toISOString(),
      startedAt: null,
      completedAt: null,
      archivedAt: null,
      dueAt: null,
      reminderAt: null,
      notifyAtDeadline: true,
    };

    const nextTodos = [newTodo, ...get().todos];
    set({ todos: nextTodos });
    await api.saveTodos(nextTodos);
    return newTodo;
  },

  toggleComplete: async (id: string) => {
    const now = new Date().toISOString();
    const nextTodos = get().todos.map((item) => {
      if (item.id !== id) return item;
      const isCompleted = !!item.completedAt;
      return {
        ...item,
        completedAt: isCompleted ? null : now,
      };
    });
    set({ todos: nextTodos });
    await api.saveTodos(nextTodos);
  },

  updateTodo: async (id: string, updates: Partial<TodoItem>) => {
    const nextTodos = get().todos.map((item) =>
      item.id === id ? { ...item, ...updates } : item
    );
    set({ todos: nextTodos });
    await api.saveTodos(nextTodos);
  },

  deleteTodo: async (id: string) => {
    const nextTodos = get().todos.filter((item) => item.id !== id);
    set({ todos: nextTodos });
    await api.saveTodos(nextTodos);
    // Clean up tag assignments for this deleted todo
    await useTagStore.getState().removeAssignmentForTodo(id);
  },

  archiveTodo: async (id: string) => {
    const now = new Date().toISOString();
    const nextTodos = get().todos.map((item) =>
      item.id === id ? { ...item, archivedAt: now, startedAt: null } : item
    );
    set({ todos: nextTodos });
    await api.saveTodos(nextTodos);
  },

  restoreTodo: async (id: string) => {
    const nextTodos = get().todos.map((item) =>
      item.id === id ? { ...item, archivedAt: null } : item
    );
    set({ todos: nextTodos });
    await api.saveTodos(nextTodos);
  },
}));
