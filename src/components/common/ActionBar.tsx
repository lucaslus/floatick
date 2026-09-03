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
    <div className="px-5 mb-3 flex items-center space-x-2 select-none">
      {/* Search Field */}
      <div className="flex-1 h-[42px] relative flex items-center">
        <input
          type="text"
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
          placeholder={placeholder || t("searchTodos")}
          className="w-full h-full pl-9 pr-8 text-xs rounded-xl bg-[#F0F4F2] dark:bg-[#1D2529] border border-black/[0.045] dark:border-white/[0.08] text-zinc-900 dark:text-[#EEF2F1] placeholder:text-zinc-400 dark:placeholder:text-[#8E9599] focus:outline-none focus:border-teal-600 dark:focus:border-[#22B8A7] transition-all"
        />
        <Search className="w-4 h-4 absolute left-3 text-zinc-400 dark:text-[#8E9599]" />
        {query && (
          <button
            onClick={() => onQueryChange("")}
            className="w-6 h-6 absolute right-2 flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-[#EEF2F1]"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        )}
      </div>

      {/* Doing Filter Button (Only for active todos) */}
      {showDoingFilter && onToggleDoingFilter && (
        <button
          type="button"
          onClick={onToggleDoingFilter}
          title={isDoingSelected ? "清除进行中筛选" : "仅显示进行中"}
          className={`w-[42px] h-[42px] shrink-0 rounded-xl flex items-center justify-center border transition-all cursor-pointer ${
            isDoingSelected
              ? "bg-teal-500/15 dark:bg-[#22B8A7]/15 border-teal-500/50 dark:border-[#22B8A7]/50 text-teal-600 dark:text-[#22B8A7]"
              : "bg-[#F0F4F2] dark:bg-[#1D2529] border-black/[0.045] dark:border-white/[0.08] text-zinc-500 dark:text-[#8E9599] hover:text-zinc-800 dark:hover:text-[#EEF2F1]"
          }`}
        >
          <Play className={`w-4 h-4 ${isDoingSelected ? "fill-current" : ""}`} />
        </button>
      )}

      {/* Tag Filter Button */}
      <button
        type="button"
        onClick={onOpenTagFilter}
        title={t("filterByTagTitle")}
        className={`w-[42px] h-[42px] shrink-0 rounded-xl flex items-center justify-center border transition-all relative cursor-pointer ${
          selectedTagCount > 0
            ? "bg-teal-500/15 dark:bg-[#22B8A7]/15 border-teal-500/50 dark:border-[#22B8A7]/50 text-teal-600 dark:text-[#22B8A7]"
            : "bg-[#F0F4F2] dark:bg-[#1D2529] border-black/[0.045] dark:border-white/[0.08] text-zinc-500 dark:text-[#8E9599] hover:text-zinc-800 dark:hover:text-[#EEF2F1]"
        }`}
      >
        <Tag className="w-4 h-4" />
        {selectedTagCount > 0 && (
          <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-teal-600 text-white text-[9px] font-bold flex items-center justify-center shadow-xs">
            {selectedTagCount}
          </span>
        )}
      </button>

      {/* Add Button */}
      <button
        type="button"
        onClick={onAddNew}
        title={addTooltip || t("createTodoAction")}
        className="w-[42px] h-[42px] shrink-0 rounded-xl flex items-center justify-center border border-teal-500/40 dark:border-[#22B8A7]/40 bg-teal-500/5 dark:bg-[#22B8A7]/10 text-teal-600 dark:text-[#22B8A7] hover:bg-teal-500/15 dark:hover:bg-[#22B8A7]/20 transition-all cursor-pointer"
      >
        <Plus className="w-4 h-4 stroke-[2.5]" />
      </button>
    </div>
  );
};
