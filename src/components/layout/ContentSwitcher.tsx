import React from "react";
import { useTranslation } from "react-i18next";

interface ContentSwitcherProps {
  selected: "todos" | "notes";
  onSelected: (tab: "todos" | "notes") => void;
}

export const ContentSwitcher: React.FC<ContentSwitcherProps> = ({
  selected,
  onSelected,
}) => {
  const { t } = useTranslation();

  return (
    <div className="px-5 mb-3 select-none">
      <div className="h-10 flex items-center bg-black/[0.03] dark:bg-white/[0.04] p-1 rounded-xl border border-black/[0.04] dark:border-white/[0.05]">
        <button
          type="button"
          onClick={() => onSelected("todos")}
          className={`flex-1 h-full flex items-center justify-center text-xs font-semibold rounded-lg transition-all cursor-pointer ${
            selected === "todos"
              ? "bg-white dark:bg-[#1D2529] text-zinc-900 dark:text-[#EEF2F1] shadow-xs"
              : "text-zinc-500 dark:text-[#8E9599] hover:text-zinc-800 dark:hover:text-[#EEF2F1]"
          }`}
        >
          {t("todos")}
        </button>
        <button
          type="button"
          onClick={() => onSelected("notes")}
          className={`flex-1 h-full flex items-center justify-center text-xs font-semibold rounded-lg transition-all cursor-pointer ${
            selected === "notes"
              ? "bg-white dark:bg-[#1D2529] text-zinc-900 dark:text-[#EEF2F1] shadow-xs"
              : "text-zinc-500 dark:text-[#8E9599] hover:text-zinc-800 dark:hover:text-[#EEF2F1]"
          }`}
        >
          {t("notes")}
        </button>
      </div>
    </div>
  );
};
