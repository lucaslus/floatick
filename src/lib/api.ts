import { invoke } from "@tauri-apps/api/core";
import type { TodoItem, TagWorkspace, NoteItem, AppSettings } from "@/types";

export const api = {
  // Todos
  getTodos: async (): Promise<TodoItem[]> => {
    return await invoke<TodoItem[]>("get_todos");
  },
  saveTodos: async (todos: TodoItem[]): Promise<void> => {
    await invoke("save_todos", { todos });
  },

  // Tags
  getTags: async (): Promise<TagWorkspace> => {
    return await invoke<TagWorkspace>("get_tags");
  },
  saveTags: async (workspace: TagWorkspace): Promise<void> => {
    await invoke("save_tags", { workspace });
  },

  // Notes
  getNotes: async (): Promise<NoteItem[]> => {
    return await invoke<NoteItem[]>("get_notes");
  },
  saveNotes: async (notes: NoteItem[]): Promise<void> => {
    await invoke("save_notes", { notes });
  },

  // Settings
  getSettings: async (): Promise<AppSettings> => {
    return await invoke<AppSettings>("get_settings");
  },
  saveSettings: async (settings: AppSettings): Promise<void> => {
    await invoke("save_settings", { settings });
  },

  // Window actions
  hideWindow: async (): Promise<void> => {
    await invoke("hide_window");
  },
  toggleWindow: async (): Promise<void> => {
    await invoke("toggle_window");
  },
  setAlwaysOnTop: async (alwaysOnTop: boolean): Promise<void> => {
    await invoke("set_always_on_top", { alwaysOnTop });
  },
  updateTrayCount: async (count: number): Promise<void> => {
    await invoke("update_tray_count", { count });
  },

  // Autostart
  isAutostartEnabled: async (): Promise<boolean> => {
    return await invoke<boolean>("is_autostart_enabled");
  },
  setAutostartEnabled: async (enabled: boolean): Promise<void> => {
    await invoke("set_autostart_enabled", { enabled });
  },
  quitApp: async (): Promise<void> => {
    await invoke("quit_app");
  },
};
