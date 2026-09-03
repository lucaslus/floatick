import React from "react";
import { useTranslation } from "react-i18next";
import { CheckSquare, FileText } from "lucide-react";
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
    <div className="px-5 mb-3 select-none">
      <div className="h-[38px] flex items-center bg-black/[0.04] dark:bg-black/30 p-1 rounded-xl border border-black/[0.05] dark:border-white/[0.07] shadow-inner">
        {/* Todos Tab */}
        <button
          type="button"
          onClick={() => onSelected("todos")}
          className={`flex-1 h-full flex items-center justify-center space-x-1.5 text-xs font-semibold rounded-lg tactile-btn cursor-pointer ${
            selected === "todos"
              ? "bg-white dark:bg-[#1C252B] text-zinc-900 dark:text-[#F1F5F9] shadow-[0_2px_8px_rgba(0,0,0,0.25),inset_0_1px_0_rgba(255,255,255,0.1)] border border-black/[0.04] dark:border-white/[0.08]"
              : "text-zinc-500 dark:text-[#94A3B8] hover:text-zinc-800 dark:hover:text-[#F1F5F9]"
          }`}
        >
          <CheckSquare className={`w-3.5 h-3.5 ${selected === "todos" ? "text-teal-500 dark:text-[#2DD4BF]" : ""}`} />
          <span>{t("todos")}</span>
          {activeTodoCount > 0 && (
            <span
              className={`text-[10px] px-1.5 py-0.2 rounded-full font-mono font-medium ${
                selected === "todos"
                  ? "bg-teal-500/15 text-teal-600 dark:text-[#2DD4BF]"
                  : "bg-black/[0.05] dark:bg-white/[0.08] text-zinc-400 dark:text-[#94A3B8]"
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
          className={`flex-1 h-full flex items-center justify-center space-x-1.5 text-xs font-semibold rounded-lg tactile-btn cursor-pointer ${
            selected === "notes"
              ? "bg-white dark:bg-[#1C252B] text-zinc-900 dark:text-[#F1F5F9] shadow-[0_2px_8px_rgba(0,0,0,0.25),inset_0_1px_0_rgba(255,255,255,0.1)] border border-black/[0.04] dark:border-white/[0.08]"
              : "text-zinc-500 dark:text-[#94A3B8] hover:text-zinc-800 dark:hover:text-[#F1F5F9]"
          }`}
        >
          <FileText className={`w-3.5 h-3.5 ${selected === "notes" ? "text-teal-500 dark:text-[#2DD4BF]" : ""}`} />
          <span>{t("notes")}</span>
          {activeNoteCount > 0 && (
            <span
              className={`text-[10px] px-1.5 py-0.2 rounded-full font-mono font-medium ${
                selected === "notes"
                  ? "bg-teal-500/15 text-teal-600 dark:text-[#2DD4BF]"
                  : "bg-black/[0.05] dark:bg-white/[0.08] text-zinc-400 dark:text-[#94A3B8]"
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
