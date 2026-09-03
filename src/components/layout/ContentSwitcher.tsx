import React from "react";
import { useTranslation } from "react-i18next";
import { useTodoStore } from "@/stores/useTodoStore";
import { useNoteStore } from "@/stores/useNoteStore";

interface ContentSwitcherProps {
  selected: "todos" | "notes";
  onSelected: (tab: "todos" | "notes") => void;
}

export const ContentSwitcher: React.FC<ContentSwitcherProps> = ({
  selected,
  onSelected,
}) => {
  const { t } = useTranslation();
  const todos = useTodoStore((s) => s.todos);
  const notes = useNoteStore((s) => s.notes);

  const activeTodoCount = todos.filter((item) => !item.completedAt && !item.archivedAt).length;
  const activeNoteCount = notes.filter((item) => !item.archivedAt).length;

  return (
    <div className="px-5 mb-2.5 select-none">
      <div className="h-[32px] flex items-center bg-black/[0.04] dark:bg-black/25 p-0.5 rounded-lg border border-black/[0.04] dark:border-white/[0.06]">
        {/* Todos Tab */}
        <button
          type="button"
          onClick={() => onSelected("todos")}
          className={`flex-1 h-full flex items-center justify-center space-x-1.5 text-xs font-medium rounded-md tactile-btn cursor-pointer ${
            selected === "todos"
              ? "bg-white dark:bg-[#1E252A] text-zinc-900 dark:text-zinc-100 shadow-xs"
              : "text-zinc-500 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200"
          }`}
        >
          <span>{t("todos")}</span>
          {activeTodoCount > 0 && (
            <span
              className={`text-[10px] px-1.5 py-0.2 rounded-full font-mono ${
                selected === "todos"
                  ? "bg-teal-500/15 text-teal-600 dark:text-teal-400 font-semibold"
                  : "text-zinc-400 dark:text-zinc-500"
              }`}
            >
              {activeTodoCount}
            </span>
          )}
        </button>

        {/* Notes Tab */}
        <button
          type="button"
          onClick={() => onSelected("notes")}
          className={`flex-1 h-full flex items-center justify-center space-x-1.5 text-xs font-medium rounded-md tactile-btn cursor-pointer ${
            selected === "notes"
              ? "bg-white dark:bg-[#1E252A] text-zinc-900 dark:text-zinc-100 shadow-xs"
              : "text-zinc-500 dark:text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200"
          }`}
        >
          <span>{t("notes")}</span>
          {activeNoteCount > 0 && (
            <span
              className={`text-[10px] px-1.5 py-0.2 rounded-full font-mono ${
                selected === "notes"
                  ? "bg-teal-500/15 text-teal-600 dark:text-teal-400 font-semibold"
                  : "text-zinc-400 dark:text-zinc-500"
              }`}
            >
              {activeNoteCount}
            </span>
          )}
        </button>
      </div>
    </div>
  );
};
