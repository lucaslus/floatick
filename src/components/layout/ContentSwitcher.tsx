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
          className={`flex-1 h-full rounded-[8px] flex items-center justify-center text-[13px] transition-colors tactile-btn cursor-pointer ${
            selected === "todos"
              ? "text-[#22B8A7] font-semibold bg-[#22B8A7]/[0.055]"
              : "text-[#EEF2F1]/62 font-medium hover:bg-white/[0.055] hover:text-[#EEF2F1]/85"
          }`}
        >
          {t("todos")}
        </button>

        {/* Notes Tab Button */}
        <button
          type="button"
          onClick={() => onSelected("notes")}
          className={`flex-1 h-full rounded-[8px] flex items-center justify-center text-[13px] transition-colors tactile-btn cursor-pointer ${
            selected === "notes"
              ? "text-[#22B8A7] font-semibold bg-[#22B8A7]/[0.055]"
              : "text-[#EEF2F1]/62 font-medium hover:bg-white/[0.055] hover:text-[#EEF2F1]/85"
          }`}
        >
          {t("notes")}
        </button>
      </div>
    </div>
  );
};
