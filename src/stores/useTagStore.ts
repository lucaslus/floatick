import { create } from "zustand";
import type { TagWorkspace, TodoTag } from "@/types";
import { api } from "@/lib/api";

interface TagState {
  workspace: TagWorkspace;
  isLoaded: boolean;
  selectedTagFilter: string | null;
  setSelectedTagFilter: (tagId: string | null) => void;
  loadTags: () => Promise<void>;
  createTag: (name: string, colorHex: string) => Promise<TodoTag>;
  updateTag: (id: string, name: string, colorHex: string) => Promise<void>;
  deleteTag: (id: string) => Promise<void>;
  setTodoTags: (todoId: string, tagIds: string[]) => Promise<void>;
}

const defaultWorkspace: TagWorkspace = {
  version: 1,
  tags: [],
  assignments: {},
};

export const useTagStore = create<TagState>((set, get) => ({
  workspace: defaultWorkspace,
  isLoaded: false,
  selectedTagFilter: null,

  setSelectedTagFilter: (tagId: string | null) => {
    set({ selectedTagFilter: tagId });
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
    const newTag: TodoTag = {
      id: crypto.randomUUID(),
      name: name.trim(),
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
    const nextWorkspace: TagWorkspace = {
      ...get().workspace,
      tags: get().workspace.tags.map((t) =>
        t.id === id ? { ...t, name: name.trim(), colorHex } : t
      ),
    };
    set({ workspace: nextWorkspace });
    await api.saveTags(nextWorkspace);
  },

  deleteTag: async (id: string) => {
    const nextAssignments = { ...get().workspace.assignments };
    for (const key of Object.keys(nextAssignments)) {
      nextAssignments[key] = nextAssignments[key].filter((tId) => tId !== id);
    }
    const nextWorkspace: TagWorkspace = {
      version: 1,
      tags: get().workspace.tags.filter((t) => t.id !== id),
      assignments: nextAssignments,
    };
    if (get().selectedTagFilter === id) {
      set({ selectedTagFilter: null });
    }
    set({ workspace: nextWorkspace });
    await api.saveTags(nextWorkspace);
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
}));
