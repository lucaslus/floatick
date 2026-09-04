import { invoke } from "@tauri-apps/api/core";
import type { TodoItem, TagWorkspace, NoteItem, AppSettings } from "@/types";

const isMock = typeof window !== "undefined" && (
  window.location.search.includes("mock") || !("__TAURI_INTERNALS__" in window)
);

const nowIso = new Date().toISOString();
const todayDueIso = new Date(Date.now() + 3600 * 1000 * 4).toISOString();
const tomorrowDueIso = new Date(Date.now() + 3600 * 1000 * 24).toISOString();

const MOCK_TAGS: TagWorkspace = {
  version: 1,
  tags: [
    { id: "tag-1", name: "Design", colorHex: "#6366F1", createdAt: nowIso },
    { id: "tag-2", name: "Engineering", colorHex: "#14B8A6", createdAt: nowIso },
    { id: "tag-3", name: "Product", colorHex: "#F59E0B", createdAt: nowIso },
    { id: "tag-4", name: "Launch", colorHex: "#EC4899", createdAt: nowIso },
  ],
  assignments: {
    "mock-todo-1": ["tag-1"],
    "mock-todo-2": ["tag-3"],
    "mock-todo-3": ["tag-2"],
    "mock-todo-4": ["tag-4"],
  },
};

const MOCK_TODOS: TodoItem[] = [
  {
    id: "mock-todo-1",
    title: "Align design system tokens & frosted blur glass",
    content: "Ensure backdrop blur and border contrast adapt gracefully across light and dark macOS themes.\n\n### Sprint Milestones\n- [x] Integrate Tauri v2 AppKit native tray\n- [x] Support TipTap markdown slash commands\n- [ ] Polish product showcase & documentation\n\n```bash\npnpm tauri:build\n```\n\n> Fast, distraction-free, and local-first for macOS.",
    createdAt: nowIso,
    startedAt: null,
    completedAt: null,
    archivedAt: null,
    dueAt: todayDueIso,
    reminderAt: null,
  },
  {
    id: "mock-todo-2",
    title: "Review Q4 product roadmap & release checklist",
    content: "Review open PRs, verify universal dmg packaging, and update changelog documentation.",
    createdAt: nowIso,
    startedAt: null,
    completedAt: null,
    archivedAt: null,
    dueAt: tomorrowDueIso,
    reminderAt: null,
  },
  {
    id: "mock-todo-3",
    title: "Implement TipTap slash commands & micro-toolbars",
    content: "Interactive task items, heading levels, quotes, code fences, and keyboard shortcuts.",
    createdAt: nowIso,
    startedAt: null,
    completedAt: null,
    archivedAt: null,
    dueAt: null,
    reminderAt: null,
  },
  {
    id: "mock-todo-4",
    title: "Draft launch communication and release notes",
    content: "Highlight local-first architecture and native macOS menu bar status extra.",
    createdAt: nowIso,
    startedAt: null,
    completedAt: null,
    archivedAt: null,
    dueAt: null,
    reminderAt: null,
  },
  {
    id: "mock-todo-5",
    title: "Migrate core framework to Tauri v2 and React 19",
    content: "Achieved sub-30MB idle footprint and 120Hz smooth rendering.",
    createdAt: new Date(Date.now() - 3600 * 1000 * 8).toISOString(),
    startedAt: null,
    completedAt: new Date(Date.now() - 3600 * 1000 * 2).toISOString(),
    archivedAt: null,
    dueAt: null,
    reminderAt: null,
  },
  {
    id: "mock-todo-6",
    title: "Add macOS native Menu Bar template status icon",
    content: "Dynamic badge counter showing remaining pending items.",
    createdAt: new Date(Date.now() - 3600 * 1000 * 12).toISOString(),
    startedAt: null,
    completedAt: new Date(Date.now() - 3600 * 1000 * 4).toISOString(),
    archivedAt: null,
    dueAt: null,
    reminderAt: null,
  },
];

const MOCK_NOTES: NoteItem[] = [
  {
    id: "mock-note-1",
    title: "Architecture & Intentional Simplicity",
    content: "Floatick is designed for intentional simplicity. Instead of unbounded task hierarchies, it honors lightweight task management, TipTap Markdown writing, and unobtrusive macOS menu bar integration.\n\n- Local-first in ~/.floatick\n- 120Hz ProMotion fluidity\n- Native NSStatusBar status extra",
    tagIds: ["tag-1", "tag-2"],
    createdAt: nowIso,
    updatedAt: nowIso,
    pinnedAt: nowIso,
    archivedAt: null,
  },
  {
    id: "mock-note-2",
    title: "Keyboard-First Workflows & Shortcuts",
    content: "⌘N to capture instantly, ⌘⏎ to save and confirm, Esc to dismiss, / in editor for rich blocks. Fast capture without context switching.",
    tagIds: ["tag-3"],
    createdAt: new Date(Date.now() - 3600 * 1000 * 6).toISOString(),
    updatedAt: new Date(Date.now() - 3600 * 1000 * 6).toISOString(),
    pinnedAt: null,
    archivedAt: null,
  },
  {
    id: "mock-note-3",
    title: "Release v0.4.0 Highlights",
    content: "Full-width title layout, secondary row frosted action capsules, and modular cross-tab colored tags.",
    tagIds: ["tag-4"],
    createdAt: new Date(Date.now() - 3600 * 1000 * 24).toISOString(),
    updatedAt: new Date(Date.now() - 3600 * 1000 * 24).toISOString(),
    pinnedAt: null,
    archivedAt: null,
  },
];

const MOCK_SETTINGS: AppSettings = {
  theme: "dark",
  language: "en",
  alwaysOnTop: true,
  collapseWhenClickingOutside: true,
};

export const api = {
  // Todos
  getTodos: async (): Promise<TodoItem[]> => {
    if (isMock) return MOCK_TODOS;
    return await invoke<TodoItem[]>("get_todos");
  },
  saveTodos: async (todos: TodoItem[]): Promise<void> => {
    if (isMock) return;
    await invoke("save_todos", { todos });
  },

  // Tags
  getTags: async (): Promise<TagWorkspace> => {
    if (isMock) return MOCK_TAGS;
    return await invoke<TagWorkspace>("get_tags");
  },
  saveTags: async (workspace: TagWorkspace): Promise<void> => {
    if (isMock) return;
    await invoke("save_tags", { workspace });
  },

  // Notes
  getNotes: async (): Promise<NoteItem[]> => {
    if (isMock) return MOCK_NOTES;
    return await invoke<NoteItem[]>("get_notes");
  },
  saveNotes: async (notes: NoteItem[]): Promise<void> => {
    if (isMock) return;
    await invoke("save_notes", { notes });
  },

  // Settings
  getSettings: async (): Promise<AppSettings> => {
    if (isMock) return MOCK_SETTINGS;
    return await invoke<AppSettings>("get_settings");
  },
  saveSettings: async (settings: AppSettings): Promise<void> => {
    if (isMock) return;
    await invoke("save_settings", { settings });
  },

  // Window actions
  hideWindow: async (): Promise<void> => {
    if (isMock) return;
    await invoke("hide_window");
  },
  toggleWindow: async (): Promise<void> => {
    if (isMock) return;
    await invoke("toggle_window");
  },
  setAlwaysOnTop: async (alwaysOnTop: boolean): Promise<void> => {
    if (isMock) return;
    await invoke("set_always_on_top", { alwaysOnTop });
  },
  updateTrayCount: async (count: number): Promise<void> => {
    if (isMock) return;
    await invoke("update_tray_count", { count });
  },

  // Autostart
  isAutostartEnabled: async (): Promise<boolean> => {
    if (isMock) return false;
    return await invoke<boolean>("is_autostart_enabled");
  },
  setAutostartEnabled: async (enabled: boolean): Promise<void> => {
    if (isMock) return;
    await invoke("set_autostart_enabled", { enabled });
  },
  quitApp: async (): Promise<void> => {
    if (isMock) return;
    await invoke("quit_app");
  },
};
