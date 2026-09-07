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
      <div className="h-[40px] flex items-center space-x-[3px]">
        {/* Todos Tab Button */}
        <button
          type="button"
          onClick={() => onSelected("todos")}
          className={`flex-1 h-full rounded-[8px] flex items-center justify-center text-[13.5px] tactile-btn cursor-pointer ${
            selected === "todos"
              ? "text-[var(--color-teal-primary)] font-semibold bg-[var(--color-teal-tint)]"
              : "text-[var(--color-text-secondary)] font-medium hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-primary)]"
          }`}
        >
          {t("todos")}
        </button>

        {/* Notes Tab Button */}
        <button
          type="button"
          onClick={() => onSelected("notes")}
          className={`flex-1 h-full rounded-[8px] flex items-center justify-center text-[13.5px] tactile-btn cursor-pointer ${
            selected === "notes"
              ? "text-[var(--color-teal-primary)] font-semibold bg-[var(--color-teal-tint)]"
              : "text-[var(--color-text-secondary)] font-medium hover:bg-[var(--color-hover-overlay)] hover:text-[var(--color-text-primary)]"
          }`}
        >
          {t("notes")}
        </button>
      </div>
    </div>
  );
};
