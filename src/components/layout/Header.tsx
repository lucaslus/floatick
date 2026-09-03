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
    <header className="px-5 pt-3.5 pb-2 flex items-center justify-between select-none">
      {/* Left: Brand + Crisp Status */}
      <div className="flex items-center space-x-2.5">
        <FloatickBrandMark size={30} />
        <span className="text-[13px] font-medium text-zinc-700 dark:text-zinc-300 tracking-tight">
          {statusText}
        </span>
      </div>

      {/* Right: Minimal Actions */}
      <div className="flex items-center space-x-0.5 text-zinc-400 dark:text-zinc-500">
        {/* Archive Toggle */}
        <button
          onClick={handleToggleArchive}
          title={isArchived ? t("active") : t("archive")}
          className={`w-7 h-7 rounded-lg flex items-center justify-center tactile-btn cursor-pointer ${
            isArchived
              ? "text-teal-500 dark:text-teal-400 bg-teal-500/10 font-medium"
              : "hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.04] dark:hover:bg-white/[0.05]"
          }`}
        >
          <Archive className="w-3.5 h-3.5" />
        </button>

        {/* Settings */}
        <button
          onClick={onOpenSettings}
          title={t("settings")}
          className="w-7 h-7 rounded-lg flex items-center justify-center hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.04] dark:hover:bg-white/[0.05] tactile-btn cursor-pointer"
        >
          <Settings className="w-3.5 h-3.5" />
        </button>

        {/* Collapse */}
        <button
          onClick={handleCollapse}
          title={t("escToClose")}
          className="w-7 h-7 rounded-lg flex items-center justify-center hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.04] dark:hover:bg-white/[0.05] tactile-btn cursor-pointer"
        >
          <ChevronUp className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
};
