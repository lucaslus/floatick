import React, { useEffect, useState } from "react";
import { Header } from "@/components/layout/Header";
import { ContentSwitcher } from "@/components/layout/ContentSwitcher";
import { TodoPanel } from "@/components/todos/TodoPanel";
import { NotePanel } from "@/components/notes/NotePanel";
import { SettingsDrawer } from "@/components/settings/SettingsDrawer";
import { TagDrawer } from "@/components/tags/TagDrawer";
import { useSettingsStore } from "@/stores/useSettingsStore";
import { useTodoStore } from "@/stores/useTodoStore";
import { useTagStore } from "@/stores/useTagStore";
import { useNoteStore } from "@/stores/useNoteStore";
import { api } from "@/lib/api";

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<"todos" | "notes">("todos");
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isTagDrawerOpen, setIsTagDrawerOpen] = useState(false);

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
  }, [isSettingsOpen, isTagDrawerOpen]);

  return (
    <div className="w-full h-full p-2.5 flex flex-col items-center justify-center select-none bg-transparent font-sans">
      {/* Signature Floatick 26px Rounded Panel Surface */}
      <div className="w-full h-full flex flex-col rounded-[26px] overflow-hidden bg-[#F9FBFA] dark:bg-[#151B1E] text-zinc-900 dark:text-[#EEF2F1] border border-black/[0.08] dark:border-white/[0.09] shadow-2xl relative">
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
          <TodoPanel onOpenTagFilter={() => setIsTagDrawerOpen(true)} />
        ) : (
          <NotePanel onOpenTagFilter={() => setIsTagDrawerOpen(true)} />
        )}

        {/* Right Settings Drawer */}
        <SettingsDrawer
          isOpen={isSettingsOpen}
          onClose={() => setIsSettingsOpen(false)}
        />

        {/* Left Tag Drawer */}
        <TagDrawer
          isOpen={isTagDrawerOpen}
          onClose={() => setIsTagDrawerOpen(false)}
        />
      </div>
    </div>
  );
};
