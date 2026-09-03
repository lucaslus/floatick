import { create } from "zustand";
import type { TagWorkspace, TodoTag } from "@/types";
import { api } from "@/lib/api";
import { useNoteStore } from "./useNoteStore";

interface TagState {
  workspace: TagWorkspace;
  isLoaded: boolean;
  selectedTagIds: string[];

  toggleTagFilter: (tagId: string) => void;
  clearTagFilter: () => void;
  setSelectedTagIds: (tagIds: string[]) => void;

  loadTags: () => Promise<void>;
  createTag: (name: string, colorHex: string) => Promise<TodoTag>;
  updateTag: (id: string, name: string, colorHex: string) => Promise<void>;
  deleteTag: (id: string) => Promise<void>;
  setTodoTags: (todoId: string, tagIds: string[]) => Promise<void>;
  toggleTodoTag: (todoId: string, tagId: string) => Promise<void>;
  removeAssignmentForTodo: (todoId: string) => Promise<void>;
}

const defaultWorkspace: TagWorkspace = {
  version: 1,
  tags: [],
  assignments: {},
};

export const useTagStore = create<TagState>((set, get) => ({
  workspace: defaultWorkspace,
  isLoaded: false,
  selectedTagIds: [],

  toggleTagFilter: (tagId: string) => {
    const current = get().selectedTagIds;
    if (current.includes(tagId)) {
      set({ selectedTagIds: current.filter((id) => id !== tagId) });
    } else {
      set({ selectedTagIds: [...current, tagId] });
    }
  },

  clearTagFilter: () => {
    set({ selectedTagIds: [] });
  },

  setSelectedTagIds: (tagIds: string[]) => {
    set({ selectedTagIds: tagIds });
  },

  loadTags: async () => {
    try {
      const data = await api.getTags();
      set({ workspace: data, isLoaded: true });
    } catch {
      set({ isLoaded: true });
    }
  },

  createTag: async (name: string, colorHex: string) => {
    const trimmed = name.trim();
    if (!trimmed) {
      throw new Error("Tag name cannot be empty");
    }
    if (trimmed.length > 30) {
      throw new Error("Tag name exceeds 30 characters");
    }
    const lower = trimmed.toLowerCase();
    if (get().workspace.tags.some((t) => t.name.toLowerCase() === lower)) {
      throw new Error("Tag name already exists");
    }

    const newTag: TodoTag = {
      id: crypto.randomUUID(),
      name: trimmed,
      colorHex,
    };
    const nextWorkspace: TagWorkspace = {
      ...get().workspace,
      tags: [...get().workspace.tags, newTag],
    };
    set({ workspace: nextWorkspace });
    await api.saveTags(nextWorkspace);
    return newTag;
  },

  updateTag: async (id: string, name: string, colorHex: string) => {
    const trimmed = name.trim();
    if (!trimmed) {
      throw new Error("Tag name cannot be empty");
    }
    if (trimmed.length > 30) {
      throw new Error("Tag name exceeds 30 characters");
    }
    const lower = trimmed.toLowerCase();
    if (
      get().workspace.tags.some(
        (t) => t.id !== id && t.name.toLowerCase() === lower
      )
    ) {
      throw new Error("Tag name already exists");
    }

    const nextWorkspace: TagWorkspace = {
      ...get().workspace,
      tags: get().workspace.tags.map((t) =>
        t.id === id ? { ...t, name: trimmed, colorHex } : t
      ),
    };
    set({ workspace: nextWorkspace });
    await api.saveTags(nextWorkspace);
  },

  deleteTag: async (id: string) => {
    // 1. Clean up assignments for todos
    const nextAssignments = { ...get().workspace.assignments };
    for (const key of Object.keys(nextAssignments)) {
      nextAssignments[key] = nextAssignments[key].filter((tId) => tId !== id);
    }
    const nextWorkspace: TagWorkspace = {
      version: 1,
      tags: get().workspace.tags.filter((t) => t.id !== id),
      assignments: nextAssignments,
    };

    // 2. Remove from active filter
    set({
      workspace: nextWorkspace,
      selectedTagIds: get().selectedTagIds.filter((tId) => tId !== id),
    });

    // 3. Save tags workspace
    await api.saveTags(nextWorkspace);

    // 4. Clean up tag from all notes
    await useNoteStore.getState().removeTagFromNotes(id);
  },

  setTodoTags: async (todoId: string, tagIds: string[]) => {
    const nextAssignments = {
      ...get().workspace.assignments,
      [todoId]: Array.from(new Set(tagIds)),
    };
    const nextWorkspace: TagWorkspace = {
      ...get().workspace,
      assignments: nextAssignments,
    };
    set({ workspace: nextWorkspace });
    await api.saveTags(nextWorkspace);
  },

  toggleTodoTag: async (todoId: string, tagId: string) => {
    const current = get().workspace.assignments[todoId] || [];
    const nextTagIds = current.includes(tagId)
      ? current.filter((id) => id !== tagId)
      : [...current, tagId];

    await get().setTodoTags(todoId, nextTagIds);
  },

  removeAssignmentForTodo: async (todoId: string) => {
    if (!get().workspace.assignments[todoId]) return;
    const nextAssignments = { ...get().workspace.assignments };
    delete nextAssignments[todoId];
    const nextWorkspace: TagWorkspace = {
      ...get().workspace,
      assignments: nextAssignments,
    };
    set({ workspace: nextWorkspace });
    await api.saveTags(nextWorkspace);
  },
}));
