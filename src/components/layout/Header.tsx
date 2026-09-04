import React from "react";
import { useTranslation } from "react-i18next";
import { Archive, GearSix, CaretUp } from "@phosphor-icons/react";
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

  const activeTodoCount = todos.filter((t) => !t.completedAt && !t.archivedAt).length;
  const archivedTodoCount = todos.filter((t) => !!t.archivedAt).length;

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
    <header className="px-5 pt-[18px] pb-[16px] flex items-center justify-between select-none">
      {/* Left: 38px Brand Mark + Status Text */}
      <div className="flex items-center space-x-[11px] min-w-0 flex-1 mr-2">
        <FloatickBrandMark size={38} />
        <span className="text-[13px] font-medium text-[var(--color-text-secondary)] truncate tracking-tight">
          {statusText}
        </span>
      </div>

      {/* Right: Icon Buttons */}
      <div className="flex items-center space-x-1 shrink-0 text-[var(--color-text-secondary)]">
        {/* Archive */}
        <button
          onClick={handleToggleArchive}
          title={isArchived ? t("active") : t("archive")}
          className={`w-8 h-8 rounded-lg flex items-center justify-center tactile-btn cursor-pointer ${
            isArchived
              ? "text-[var(--color-teal-primary)] bg-[var(--color-teal-tint-active)]"
              : "hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
          }`}
        >
          <Archive size={18} weight={isArchived ? "fill" : "regular"} />
        </button>

        {/* Settings */}
        <button
          onClick={onOpenSettings}
          title={t("settings")}
          className="w-8 h-8 rounded-lg flex items-center justify-center hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
        >
          <GearSix size={18} />
        </button>

        {/* Collapse */}
        <button
          onClick={handleCollapse}
          title={t("escToClose")}
          className="w-8 h-8 rounded-lg flex items-center justify-center hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] tactile-btn cursor-pointer"
        >
          <CaretUp size={18} weight="bold" />
        </button>
      </div>
    </header>
  );
};
