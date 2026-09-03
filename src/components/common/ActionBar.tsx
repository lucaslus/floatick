import React from "react";
import { Search, X, Play, Tag, Plus } from "lucide-react";
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
    <div className="px-5 mb-2.5 flex items-center space-x-1.5 select-none">
      {/* Clean Search Input */}
      <div className="flex-1 h-[34px] relative flex items-center">
        <input
          type="text"
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
          placeholder={placeholder || t("search")}
          className="w-full h-full pl-8 pr-12 text-xs rounded-lg bg-black/[0.03] dark:bg-black/20 border border-black/[0.05] dark:border-white/[0.07] text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 dark:placeholder:text-zinc-500 focus:outline-none focus:border-teal-500 dark:focus:border-teal-400 transition-colors"
        />
        <Search className="w-3.5 h-3.5 absolute left-2.5 text-zinc-400 dark:text-zinc-500 pointer-events-none" />
        
        {/* Clear or shortcut */}
        <div className="absolute right-2 flex items-center">
          {query ? (
            <button
              type="button"
              onClick={() => onQueryChange("")}
              title={t("clearSearch")}
              className="w-4 h-4 rounded flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 tactile-btn"
            >
              <X className="w-3 h-3" />
            </button>
          ) : (
            <span className="kbd-badge">⌘F</span>
          )}
        </div>
      </div>

      {/* Doing Filter Button */}
      {showDoingFilter && onToggleDoingFilter && (
        <button
          type="button"
          onClick={onToggleDoingFilter}
          title={isDoingSelected ? t("clearDoingFilterTooltip") : t("filterDoingTooltip")}
          className={`w-[34px] h-[34px] shrink-0 rounded-lg flex items-center justify-center border transition-colors tactile-btn cursor-pointer ${
            isDoingSelected
              ? "bg-teal-500/15 border-teal-500/40 text-teal-600 dark:text-teal-400"
              : "bg-black/[0.03] dark:bg-black/20 border-black/[0.05] dark:border-white/[0.07] text-zinc-400 dark:text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300"
          }`}
        >
          <Play className={`w-3.5 h-3.5 ${isDoingSelected ? "fill-current" : ""}`} />
        </button>
      )}

      {/* Tag Filter Button */}
      <button
        type="button"
        onClick={onOpenTagFilter}
        title={t("filterByTagTitle")}
        className={`w-[34px] h-[34px] shrink-0 rounded-lg flex items-center justify-center border transition-colors relative tactile-btn cursor-pointer ${
          selectedTagCount > 0
            ? "bg-teal-500/15 border-teal-500/40 text-teal-600 dark:text-teal-400"
            : "bg-black/[0.03] dark:bg-black/20 border-black/[0.05] dark:border-white/[0.07] text-zinc-400 dark:text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300"
        }`}
      >
        <Tag className="w-3.5 h-3.5" />
        {selectedTagCount > 0 && (
          <span className="absolute -top-1 -right-1 w-3.5 h-3.5 rounded-full bg-teal-500 text-white text-[8.5px] font-bold flex items-center justify-center">
            {selectedTagCount}
          </span>
        )}
      </button>

      {/* Add Button */}
      <button
        type="button"
        onClick={onAddNew}
        title={addTooltip || t("createTodoAction")}
        className="w-[34px] h-[34px] shrink-0 rounded-lg flex items-center justify-center bg-teal-600 dark:bg-teal-500 hover:bg-teal-500 dark:hover:bg-teal-400 text-white dark:text-zinc-950 font-medium tactile-btn cursor-pointer shadow-xs"
      >
        <Plus className="w-4 h-4 stroke-[2.5]" />
      </button>
    </div>
  );
};
