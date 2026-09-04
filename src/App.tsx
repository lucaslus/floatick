import React, { useEffect, useState } from "react";
import { Header } from "@/components/layout/Header";
import { ContentSwitcher } from "@/components/layout/ContentSwitcher";
import { TodoPanel } from "@/components/todos/TodoPanel";
import { NotePanel } from "@/components/notes/NotePanel";
import { SettingsDrawer } from "@/components/settings/SettingsDrawer";
import { TagDrawer } from "@/components/tags/TagDrawer";
import { TodoEditorDrawer } from "@/components/todos/TodoEditorDrawer";
import { NoteEditorDrawer } from "@/components/notes/NoteEditorDrawer";
import { useSettingsStore } from "@/stores/useSettingsStore";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { useNoteStore } from "@/stores/useNoteStore";
import { api } from "@/lib/api";

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<"todos" | "notes">("todos");
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isTagDrawerOpen, setIsTagDrawerOpen] = useState(false);
  const [tagDrawerMode, setTagDrawerMode] = useState<"filter" | "assignment" | "manage">("filter");
  const [tagDrawerTargetTodoId, setTagDrawerTargetTodoId] = useState<string | null>(null);

  const handleOpenTagFilter = () => {
    setTagDrawerMode("filter");
    setTagDrawerTargetTodoId(null);
    setIsTagDrawerOpen(true);
  };

  const handleOpenTagAssignment = (todoId: string) => {
    setTagDrawerMode("assignment");
    setTagDrawerTargetTodoId(todoId);
    setIsTagDrawerOpen(true);
  };

  const isTodoEditorOpen = useTodoStore((s) => s.isEditorOpen);
  const setIsTodoEditorOpen = useTodoStore((s) => s.setIsEditorOpen);
  const editingTodoId = useTodoStore((s) => s.editingTodoId);

  const isNoteEditorOpen = useNoteStore((s) => s.isEditorOpen);
  const setIsNoteEditorOpen = useNoteStore((s) => s.setIsEditorOpen);
  const editingNoteId = useNoteStore((s) => s.editingNoteId);

  const loadSettings = useSettingsStore((s) => s.loadSettings);
  const loadTodos = useTodoStore((s) => s.loadTodos);
  const loadTags = useTagStore((s) => s.loadTags);
  const loadNotes = useNoteStore((s) => s.loadNotes);

  useEffect(() => {
    // Initial data hydration from ~/.floatick
    loadSettings();
    loadTodos();
    loadTags();
    loadNotes();

    const params = new URLSearchParams(window.location.search);
    if (params.get("tab") === "notes") {
      setActiveTab("notes");
    }
    if (params.get("mock") === "editor") {
      setTimeout(() => {
        useTodoStore.getState().setEditingTodoId("mock-todo-1");
        useTodoStore.getState().setIsEditorOpen(true);
      }, 150);
    }
    if (params.get("mock") === "settings") {
      setTimeout(() => {
        setIsSettingsOpen(true);
      }, 150);
    }
    if (params.get("mock") === "tags") {
      setTimeout(() => {
        setTagDrawerMode("manage");
        setIsTagDrawerOpen(true);
      }, 150);
    }
  }, [loadSettings, loadTodos, loadTags, loadNotes]);

  // Global Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Esc closes drawers first, then hides window
      if (e.key === "Escape") {
        if (isSettingsOpen) {
          setIsSettingsOpen(false);
          return;
        }
        if (isTagDrawerOpen) {
          setIsTagDrawerOpen(false);
          return;
        }
        if (isTodoEditorOpen) {
          setIsTodoEditorOpen(false);
          return;
        }
        if (isNoteEditorOpen) {
          setIsNoteEditorOpen(false);
          return;
        }
        api.hideWindow();
      }

      // Cmd+1 -> Todos, Cmd+2 -> Notes
      if ((e.metaKey || e.ctrlKey) && e.key === "1") {
        e.preventDefault();
        setActiveTab("todos");
      }
      if ((e.metaKey || e.ctrlKey) && e.key === "2") {
        e.preventDefault();
        setActiveTab("notes");
      }

      // Cmd+, -> Settings
      if ((e.metaKey || e.ctrlKey) && e.key === ",") {
        e.preventDefault();
        setIsSettingsOpen(true);
      }

      // Cmd+F -> Focus Search input
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "f") {
        e.preventDefault();
        const searchInput = document.querySelector('input[type="text"]') as HTMLInputElement | null;
        searchInput?.focus();
      }

      // Cmd+N -> New Item
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "n") {
        e.preventDefault();
        if (isSettingsOpen || isTagDrawerOpen || isTodoEditorOpen || isNoteEditorOpen) return;
        window.dispatchEvent(new CustomEvent("floatick:new-item"));
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isSettingsOpen, isTagDrawerOpen, isTodoEditorOpen, isNoteEditorOpen]);

  const isScreenshotMode =
    typeof window !== "undefined" &&
    window.location.search.includes("screenshot");

  return (
    <div
      className={`w-full h-full ${
        isScreenshotMode ? "p-0" : "p-2"
      } flex flex-col items-center justify-center select-none bg-transparent font-sans`}
    >
      {/* Refined Floatick Panel Surface */}
      <div
        className={`w-full h-full flex flex-col ${
          isScreenshotMode ? "rounded-[16px]" : "rounded-[14px]"
        } overflow-hidden floatick-panel relative`}
      >
        {/* Panel Header */}
        <Header
          activeTab={activeTab}
          onOpenSettings={() => setIsSettingsOpen(true)}
        />

        {/* Content Switcher Tabs */}
        <ContentSwitcher
          selected={activeTab}
          onSelected={setActiveTab}
        />

        {/* Main Content Panels */}
        {activeTab === "todos" ? (
          <TodoPanel
            onOpenTagFilter={handleOpenTagFilter}
            onOpenTagAssignment={handleOpenTagAssignment}
          />
        ) : (
          <NotePanel onOpenTagFilter={handleOpenTagFilter} />
        )}

        {/* Settings Drawer */}
        <SettingsDrawer
          isOpen={isSettingsOpen}
          onClose={() => setIsSettingsOpen(false)}
        />

        {/* Todo Editor Full Subview */}
        <TodoEditorDrawer
          todoId={editingTodoId}
          isOpen={isTodoEditorOpen}
          onClose={() => setIsTodoEditorOpen(false)}
        />

        {/* Note Editor Full Subview */}
        <NoteEditorDrawer
          noteId={editingNoteId}
          isOpen={isNoteEditorOpen}
          onClose={() => setIsNoteEditorOpen(false)}
        />

        {/* Tag Drawer */}
        <TagDrawer
          isOpen={isTagDrawerOpen}
          initialMode={tagDrawerMode}
          targetTodoId={tagDrawerTargetTodoId}
          onClose={() => setIsTagDrawerOpen(false)}
        />
      </div>
    </div>
  );
};
