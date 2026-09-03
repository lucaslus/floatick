import React from "react";
import { useTranslation } from "react-i18next";
import { Archive, Settings, ChevronUp } from "lucide-react";
import { FloatickBrandMark } from "@/components/common/FloatickBrandMark";
import { useTodoStore } from "@/stores/useTodoStore";
import { useNoteStore } from "@/stores/useNoteStore";
import { api } from "@/lib/api";

interface HeaderProps {
  activeTab: "todos" | "notes";
  onOpenSettings: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  activeTab,
  onOpenSettings,
}) => {
  const { t } = useTranslation();

  const todos = useTodoStore((s) => s.todos);
  const activeScope = useTodoStore((s) => s.activeScope);
  const setActiveScope = useTodoStore((s) => s.setActiveScope);

  const notes = useNoteStore((s) => s.notes);

  // Todo counts
  const activeTodoCount = todos.filter((t) => !t.completedAt && !t.archivedAt).length;
  const archivedTodoCount = todos.filter((t) => !!t.archivedAt).length;

  // Note counts
  const activeNoteCount = notes.filter((n) => !n.archivedAt).length;
  const archivedNoteCount = notes.filter((n) => !!n.archivedAt).length;

  const isArchived = activeScope === "archived";

  const statusText = (() => {
    if (activeTab === "notes") {
      return isArchived
        ? `${t("archive")} · ${archivedNoteCount}`
        : t("noteCount", { count: activeNoteCount });
    }
    if (isArchived) {
      return `${t("archive")} · ${archivedTodoCount}`;
    }
    return activeTodoCount === 0
      ? t("allClear")
      : t("tasksRemaining", { count: activeTodoCount });
  })();

  const handleToggleArchive = () => {
    setActiveScope(isArchived ? "active" : "archived");
  };

  const handleCollapse = async () => {
    await api.hideWindow();
  };

  return (
    <header className="px-5 pt-4 pb-2.5 flex items-center justify-between select-none">
      {/* Left: Brand Mark + Status Capsule */}
      <div className="flex items-center space-x-2.5">
        <FloatickBrandMark size={34} />
        
        {/* Status Capsule Badge */}
        <div className="inline-flex items-center space-x-1.5 px-2.5 py-1 rounded-full bg-white/[0.04] dark:bg-white/[0.04] border border-black/[0.06] dark:border-white/[0.08] shadow-xs">
          <span
            className={`w-1.5 h-1.5 rounded-full ${
              activeTodoCount > 0
                ? "bg-teal-400 shadow-[0_0_8px_rgba(45,212,191,0.6)] animate-pulse"
                : "bg-zinc-400"
            }`}
          />
          <span className="text-[12px] font-medium text-zinc-700 dark:text-[#CBD5E1] tracking-tight">
            {statusText}
          </span>
        </div>
      </div>

      {/* Right: Tactile Actions */}
      <div className="flex items-center space-x-1 text-zinc-400 dark:text-[#94A3B8]">
        {/* Archive Toggle */}
        <button
          onClick={handleToggleArchive}
          title={isArchived ? t("active") : t("archive")}
          className={`w-8 h-8 rounded-xl flex items-center justify-center tactile-btn cursor-pointer ${
            isArchived
              ? "text-teal-400 bg-teal-500/15 border border-teal-500/30 font-medium"
              : "hover:text-zinc-900 dark:hover:text-[#F1F5F9] hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
          }`}
        >
          <Archive className="w-4 h-4" />
        </button>

        {/* Settings */}
        <button
          onClick={onOpenSettings}
          title={t("settings")}
          className="w-8 h-8 rounded-xl flex items-center justify-center hover:text-zinc-900 dark:hover:text-[#F1F5F9] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] tactile-btn cursor-pointer"
        >
          <Settings className="w-4 h-4" />
        </button>

        {/* Collapse with Esc hint */}
        <button
          onClick={handleCollapse}
          title={t("escToClose")}
          className="h-8 px-2 rounded-xl flex items-center space-x-1 hover:text-zinc-900 dark:hover:text-[#F1F5F9] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] tactile-btn cursor-pointer"
        >
          <ChevronUp className="w-4 h-4" />
          <span className="kbd-badge hidden sm:inline-flex">Esc</span>
        </button>
      </div>
    </header>
  );
};
