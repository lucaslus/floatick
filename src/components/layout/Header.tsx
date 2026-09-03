import React from "react";
import { useTranslation } from "react-i18next";
import { CheckSquare, FileText, Settings, Tag, X, Flame } from "lucide-react";
import { useTodoStore } from "@/stores/useTodoStore";
import { api } from "@/lib/api";

interface HeaderProps {
  activeTab: "todos" | "notes";
  onTabChange: (tab: "todos" | "notes") => void;
  onOpenSettings: () => void;
  onOpenTagManager: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  activeTab,
  onTabChange,
  onOpenSettings,
  onOpenTagManager,
}) => {
  const { t } = useTranslation();
  const todos = useTodoStore((state) => state.todos);

  // Count doing items
  const doingCount = todos.filter(
    (item) => item.startedAt && !item.completedAt && !item.archivedAt
  ).length;

  const handleClose = async () => {
    await api.hideWindow();
  };

  return (
    <header className="h-12 px-3 border-b border-black/[0.06] dark:border-white/[0.08] flex items-center justify-between select-none bg-white/40 dark:bg-zinc-900/40 backdrop-blur-md">
      {/* Brand & Tabs */}
      <div className="flex items-center space-x-2">
        {/* Floatick Icon Badge */}
        <div className="flex items-center space-x-1.5 font-semibold text-xs text-teal-700 dark:text-teal-400">
          <div className="w-5 h-5 rounded-md bg-teal-600 flex items-center justify-center text-white font-bold text-xs shadow-sm">
            F
          </div>
          <span className="hidden sm:inline font-medium tracking-tight">Floatick</span>
        </div>

        {/* Doing Pulse Badge */}
        {doingCount > 0 && (
          <div className="flex items-center space-x-1 px-1.5 py-0.5 rounded-full bg-orange-500/10 text-orange-600 dark:text-orange-400 text-[11px] font-medium border border-orange-500/20 animate-pulse">
            <Flame className="w-3 h-3 text-orange-500" />
            <span>{doingCount}</span>
          </div>
        )}

        {/* Tabs Switcher */}
        <div className="flex items-center bg-black/[0.04] dark:bg-white/[0.06] p-0.5 rounded-lg ml-2">
          <button
            onClick={() => onTabChange("todos")}
            className={`flex items-center space-x-1 px-2.5 py-1 text-xs font-medium rounded-md transition-all ${
              activeTab === "todos"
                ? "bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white shadow-xs"
                : "text-zinc-500 hover:text-zinc-800 dark:text-zinc-400 dark:hover:text-zinc-200"
            }`}
          >
            <CheckSquare className="w-3.5 h-3.5" />
            <span>{t("todos")}</span>
          </button>
          <button
            onClick={() => onTabChange("notes")}
            className={`flex items-center space-x-1 px-2.5 py-1 text-xs font-medium rounded-md transition-all ${
              activeTab === "notes"
                ? "bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white shadow-xs"
                : "text-zinc-500 hover:text-zinc-800 dark:text-zinc-400 dark:hover:text-zinc-200"
            }`}
          >
            <FileText className="w-3.5 h-3.5" />
            <span>{t("notes")}</span>
          </button>
        </div>
      </div>

      {/* Action Icons */}
      <div className="flex items-center space-x-1">
        <button
          onClick={onOpenTagManager}
          title={t("manageTags")}
          className="w-7 h-7 flex items-center justify-center rounded-md text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] transition-colors"
        >
          <Tag className="w-3.5 h-3.5" />
        </button>

        <button
          onClick={onOpenSettings}
          title={t("settings")}
          className="w-7 h-7 flex items-center justify-center rounded-md text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] transition-colors"
        >
          <Settings className="w-3.5 h-3.5" />
        </button>

        <button
          onClick={handleClose}
          title={t("escToClose")}
          className="w-7 h-7 flex items-center justify-center rounded-md text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] transition-colors ml-0.5"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
};
