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
        : `${activeNoteCount} 条便签`;
    }
    if (isArchived) {
      return `${t("archive")} · ${archivedTodoCount}`;
    }
    return activeTodoCount === 0
      ? t("allClear")
      : `${activeTodoCount} 项待完成`;
  })();

  const handleToggleArchive = () => {
    setActiveScope(isArchived ? "active" : "archived");
  };

  const handleCollapse = async () => {
    await api.hideWindow();
  };

  return (
    <header className="px-5 pt-4 pb-3 flex items-center justify-between select-none">
      {/* Left: Brand Mark + Status Text */}
      <div className="flex items-center space-x-3">
        <FloatickBrandMark size={36} />
        <span className="text-[13px] font-medium text-zinc-600 dark:text-[#A0A6AA] tracking-tight">
          {statusText}
        </span>
      </div>

      {/* Right: Actions */}
      <div className="flex items-center space-x-0.5 text-zinc-500 dark:text-[#8E9599]">
        {/* Archive Toggle */}
        <button
          onClick={handleToggleArchive}
          title={isArchived ? t("active") : t("archive")}
          className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors cursor-pointer ${
            isArchived
              ? "text-teal-600 dark:text-[#22B8A7] bg-teal-500/10"
              : "hover:text-zinc-900 dark:hover:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.06]"
          }`}
        >
          <Archive className="w-4 h-4" />
        </button>

        {/* Settings */}
        <button
          onClick={onOpenSettings}
          title={t("settings")}
          className="w-8 h-8 rounded-lg flex items-center justify-center hover:text-zinc-900 dark:hover:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] transition-colors cursor-pointer"
        >
          <Settings className="w-4 h-4" />
        </button>

        {/* Collapse */}
        <button
          onClick={handleCollapse}
          title={t("escToClose")}
          className="w-8 h-8 rounded-lg flex items-center justify-center hover:text-zinc-900 dark:hover:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.06] transition-colors cursor-pointer"
        >
          <ChevronUp className="w-5 h-5" />
        </button>
      </div>
    </header>
  );
};
