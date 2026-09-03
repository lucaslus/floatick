import React from "react";
import { MagnifyingGlass, X, Tag, Plus, Clock } from "@phosphor-icons/react";
import { useTranslation } from "react-i18next";

interface ActionBarProps {
  query: string;
  onQueryChange: (query: string) => void;
  showDoingFilter?: boolean;
  isDoingSelected?: boolean;
  onToggleDoingFilter?: () => void;
  selectedTagCount?: number;
  onOpenTagFilter: () => void;
  onAddNew: () => void;
  placeholder?: string;
  addTooltip?: string;
}

export const ActionBar: React.FC<ActionBarProps> = ({
  query,
  onQueryChange,
  showDoingFilter = true,
  isDoingSelected = false,
  onToggleDoingFilter,
  selectedTagCount = 0,
  onOpenTagFilter,
  onAddNew,
  placeholder,
  addTooltip,
}) => {
  const { t } = useTranslation();

  return (
    <div className="px-5 mb-3 flex items-center space-x-2 select-none">
      {/* 42px Search Bar - Borderless & Clean */}
      <div className="flex-1 h-[42px] relative flex items-center">
        <input
          type="text"
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
          placeholder={placeholder || t("search")}
          className="w-full h-full pl-9 pr-12 text-[13px] rounded-[8px] bg-[#1D2529] text-[#EEF2F1] placeholder:text-[#EEF2F1]/50 focus:outline-none focus:bg-[#222B30] transition-colors"
        />
        <MagnifyingGlass size={16} weight="bold" className="absolute left-3 text-[#EEF2F1]/50 pointer-events-none" />

        {/* Clear Button */}
        {query && (
          <button
            type="button"
            onClick={() => onQueryChange("")}
            title={t("clearSearch")}
            className="w-5 h-5 absolute right-3 rounded-full flex items-center justify-center text-[#EEF2F1]/50 hover:text-[#EEF2F1] tactile-btn cursor-pointer"
          >
            <X size={13} weight="bold" />
          </button>
        )}
      </div>

      {/* Doing Filter Button (42x42) - Borderless */}
      {showDoingFilter && onToggleDoingFilter && (
        <button
          type="button"
          onClick={onToggleDoingFilter}
          title={isDoingSelected ? t("clearDoingFilterTooltip") : t("filterDoingTooltip")}
          className={`w-[42px] h-[42px] shrink-0 rounded-[8px] flex items-center justify-center transition-colors tactile-btn cursor-pointer ${
            isDoingSelected
              ? "bg-[#22B8A7]/[0.18] text-[#22B8A7]"
              : "bg-[#1D2529] text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-[#252F34]"
          }`}
        >
          <Clock size={19} weight={isDoingSelected ? "fill" : "regular"} />
        </button>
      )}

      {/* Tag Filter Button (42x42) - Borderless */}
      <button
        type="button"
        onClick={onOpenTagFilter}
        title={t("filterByTagTitle")}
        className={`w-[42px] h-[42px] shrink-0 rounded-[8px] flex items-center justify-center transition-colors relative tactile-btn cursor-pointer ${
          selectedTagCount > 0
            ? "bg-[#22B8A7]/[0.18] text-[#22B8A7]"
            : "bg-[#1D2529] text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-[#252F34]"
        }`}
      >
        <Tag size={19} weight={selectedTagCount > 0 ? "fill" : "regular"} />
        {selectedTagCount > 0 && (
          <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-[#22B8A7] text-zinc-950 text-[9px] font-bold flex items-center justify-center">
            {selectedTagCount}
          </span>
        )}
      </button>

      {/* Add Button (42x42) - Borderless, Crisp 8px radius */}
      <button
        type="button"
        onClick={onAddNew}
        title={addTooltip || t("createTodoAction")}
        className="w-[42px] h-[42px] shrink-0 rounded-[8px] flex items-center justify-center bg-[#22B8A7] hover:bg-[#1DB3A8] text-[#151B1E] font-semibold tactile-btn cursor-pointer"
      >
        <Plus size={20} weight="bold" />
      </button>
    </div>
  );
};
