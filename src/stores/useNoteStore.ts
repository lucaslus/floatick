import { create } from "zustand";
import type { NoteItem } from "@/types";
import { api } from "@/lib/api";

interface NoteState {
  notes: NoteItem[];
  isLoaded: boolean;
  searchQuery: string;
  editingNoteId: string | null;

  setSearchQuery: (query: string) => void;
  setEditingNoteId: (id: string | null) => void;

  loadNotes: () => Promise<void>;
  addNote: (title?: string, content?: string, tagIds?: string[]) => Promise<NoteItem>;
  updateNote: (id: string, updates: Partial<NoteItem>) => Promise<void>;
  deleteNote: (id: string) => Promise<void>;
  togglePin: (id: string) => Promise<void>;
  toggleArchive: (id: string) => Promise<void>;
  removeTagFromNotes: (tagId: string) => Promise<void>;
}

export const useNoteStore = create<NoteState>((set, get) => ({
  notes: [],
  isLoaded: false,
  searchQuery: "",
  editingNoteId: null,

  setSearchQuery: (query) => set({ searchQuery: query }),
  setEditingNoteId: (id) => set({ editingNoteId: id }),

  loadNotes: async () => {
    try {
      const data = await api.getNotes();
      set({ notes: data, isLoaded: true });
    } catch {
      set({ isLoaded: true });
    }
  },

  addNote: async (title = "", content = "", tagIds = []) => {
    const now = new Date().toISOString();
    const newNote: NoteItem = {
      id: crypto.randomUUID(),
      title: title.trim(),
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
      tagIds,
      pinnedAt: null,
      archivedAt: null,
    };

    const nextNotes = [newNote, ...get().notes];
    set({ notes: nextNotes, editingNoteId: newNote.id });
    await api.saveNotes(nextNotes);
    return newNote;
  },

  updateNote: async (id: string, updates: Partial<NoteItem>) => {
    const now = new Date().toISOString();
    const nextNotes = get().notes.map((item) =>
      item.id === id ? { ...item, ...updates, updatedAt: now } : item
    );
    set({ notes: nextNotes });
    await api.saveNotes(nextNotes);
  },

  deleteNote: async (id: string) => {
    const nextNotes = get().notes.filter((item) => item.id !== id);
    set({
      notes: nextNotes,
      editingNoteId: get().editingNoteId === id ? null : get().editingNoteId,
    });
    await api.saveNotes(nextNotes);
  },

  togglePin: async (id: string) => {
    const now = new Date().toISOString();
    const nextNotes = get().notes.map((item) => {
      if (item.id !== id) return item;
      return {
        ...item,
        pinnedAt: item.pinnedAt ? null : now,
        updatedAt: now,
      };
    });
    set({ notes: nextNotes });
    await api.saveNotes(nextNotes);
  },

  toggleArchive: async (id: string) => {
    const now = new Date().toISOString();
    const nextNotes = get().notes.map((item) => {
      if (item.id !== id) return item;
      return {
        ...item,
        archivedAt: item.archivedAt ? null : now,
        pinnedAt: item.archivedAt ? item.pinnedAt : null, // unpin when archiving
        updatedAt: now,
      };
    });
    set({ notes: nextNotes });
    await api.saveNotes(nextNotes);
  },

  removeTagFromNotes: async (tagId: string) => {
    const hasTag = get().notes.some((n) => n.tagIds.includes(tagId));
    if (!hasTag) return;
    const nextNotes = get().notes.map((n) => ({
      ...n,
      tagIds: n.tagIds.filter((tId) => tId !== tagId),
    }));
    set({ notes: nextNotes });
    await api.saveNotes(nextNotes);
  },
}));
