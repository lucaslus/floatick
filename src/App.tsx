import React, { useEffect, useState } from "react";
import { Header } from "@/components/layout/Header";
import { TodoPanel } from "@/components/todos/TodoPanel";
import { NotePanel } from "@/components/notes/NotePanel";
import { SettingsDrawer } from "@/components/settings/SettingsDrawer";
import { TagManagerDrawer } from "@/components/tags/TagManagerDrawer";
import { useSettingsStore } from "@/stores/useSettingsStore";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { useNoteStore } from "@/stores/useNoteStore";
import { api } from "@/lib/api";

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<"todos" | "notes">("todos");
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isTagManagerOpen, setIsTagManagerOpen] = useState(false);

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
  }, [loadSettings, loadTodos, loadTags, loadNotes]);

  // Global Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Esc closes drawers first, then window
      if (e.key === "Escape") {
        if (isSettingsOpen) {
          setIsSettingsOpen(false);
          return;
        }
        if (isTagManagerOpen) {
          setIsTagManagerOpen(false);
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
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isSettingsOpen, isTagManagerOpen]);

  return (
    <div className="w-full h-full p-2 flex flex-col items-center justify-center select-none bg-transparent">
      {/* Main Floating Popover Window */}
      <div className="w-full h-full flex flex-col rounded-2xl overflow-hidden bg-white/85 dark:bg-zinc-900/90 backdrop-blur-2xl border border-black/10 dark:border-white/10 shadow-2xl relative">
        {/* Navigation Header */}
        <Header
          activeTab={activeTab}
          onTabChange={setActiveTab}
          onOpenSettings={() => setIsSettingsOpen(true)}
          onOpenTagManager={() => setIsTagManagerOpen(true)}
        />

        {/* Content Panels */}
        {activeTab === "todos" ? <TodoPanel /> : <NotePanel />}

        {/* Settings Drawer */}
        {isSettingsOpen && (
          <SettingsDrawer onClose={() => setIsSettingsOpen(false)} />
        )}

        {/* Tag Manager Drawer */}
        {isTagManagerOpen && (
          <TagManagerDrawer onClose={() => setIsTagManagerOpen(false)} />
        )}
      </div>
    </div>
  );
};
