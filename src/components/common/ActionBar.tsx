import React from "react";
import { Search, X, Tag, Plus, Clock } from "lucide-react";
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
      {/* 42px Search Bar */}
      <div className="flex-1 h-[42px] relative flex items-center">
        <input
          type="text"
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
          placeholder={placeholder || t("search")}
          className="w-full h-full pl-9 pr-12 text-[13px] rounded-xl bg-[#1D2529] border border-white/[0.08] text-[#EEF2F1] placeholder:text-[#EEF2F1]/58 focus:outline-none focus:border-[#22B8A7] transition-colors"
        />
        <Search className="w-4 h-4 absolute left-3 text-[#EEF2F1]/58 pointer-events-none" />

        {/* Clear Button */}
        {query && (
          <button
            type="button"
            onClick={() => onQueryChange("")}
            title={t("clearSearch")}
            className="w-5 h-5 absolute right-3 rounded-full flex items-center justify-center text-[#EEF2F1]/58 hover:text-[#EEF2F1] tactile-btn cursor-pointer"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        )}
      </div>

      {/* Doing Filter Button (42x42) */}
      {showDoingFilter && onToggleDoingFilter && (
        <button
          type="button"
          onClick={onToggleDoingFilter}
          title={isDoingSelected ? t("clearDoingFilterTooltip") : t("filterDoingTooltip")}
          className={`w-[42px] h-[42px] shrink-0 rounded-xl flex items-center justify-center border transition-colors tactile-btn cursor-pointer ${
            isDoingSelected
              ? "bg-[#22B8A7]/[0.13] border-[#22B8A7]/[0.46] text-[#22B8A7]"
              : "bg-[#1D2529] border-white/[0.08] text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-white/[0.055]"
          }`}
        >
          <Clock className="w-[17px] h-[17px]" />
        </button>
      )}

      {/* Tag Filter Button (42x42) */}
      <button
        type="button"
        onClick={onOpenTagFilter}
        title={t("filterByTagTitle")}
        className={`w-[42px] h-[42px] shrink-0 rounded-xl flex items-center justify-center border transition-colors relative tactile-btn cursor-pointer ${
          selectedTagCount > 0
            ? "bg-[#22B8A7]/[0.13] border-[#22B8A7]/[0.46] text-[#22B8A7]"
            : "bg-[#1D2529] border-white/[0.08] text-[#EEF2F1]/62 hover:text-[#EEF2F1] hover:bg-white/[0.055]"
        }`}
      >
        <Tag className="w-[17px] h-[17px]" />
        {selectedTagCount > 0 && (
          <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-[#22B8A7] text-zinc-950 text-[9px] font-bold flex items-center justify-center">
            {selectedTagCount}
          </span>
        )}
      </button>

      {/* Add Button (42x42) */}
      <button
        type="button"
        onClick={onAddNew}
        title={addTooltip || t("createTodoAction")}
        className="w-[42px] h-[42px] shrink-0 rounded-xl flex items-center justify-center bg-[#22B8A7] hover:bg-[#1DB3A8] text-[#151B1E] font-semibold tactile-btn cursor-pointer shadow-xs"
      >
        <Plus className="w-5 h-5 stroke-[2.4]" />
      </button>
    </div>
  );
};
