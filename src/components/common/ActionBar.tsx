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
      {/* Sleek Search Bar */}
      <div className="flex-1 h-[40px] relative flex items-center">
        <input
          type="text"
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
          placeholder={placeholder || t("searchTodos")}
          className="w-full h-full pl-9 pr-14 text-xs rounded-xl bg-black/[0.03] dark:bg-black/25 border border-black/[0.06] dark:border-white/[0.08] text-zinc-900 dark:text-[#F1F5F9] placeholder:text-zinc-400 dark:placeholder:text-[#64748B] focus:outline-none focus:ring-2 focus:ring-teal-500/30 focus:border-teal-500 dark:focus:border-[#2DD4BF] transition-all shadow-inner"
        />
        <Search className="w-4 h-4 absolute left-3 text-zinc-400 dark:text-[#64748B] pointer-events-none" />
        
        {/* Right shortcut or Clear */}
        <div className="absolute right-2.5 flex items-center space-x-1">
          {query ? (
            <button
              type="button"
              onClick={() => onQueryChange("")}
              title={t("clearSearch")}
              className="w-5 h-5 rounded-full flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-[#F1F5F9] tactile-btn"
            >
              <X className="w-3.5 h-3.5" />
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
          className={`w-[40px] h-[40px] shrink-0 rounded-xl flex items-center justify-center border transition-all tactile-btn cursor-pointer ${
            isDoingSelected
              ? "bg-teal-500/15 dark:bg-[#14B8A6]/20 border-teal-500/50 dark:border-[#2DD4BF]/50 text-teal-600 dark:text-[#2DD4BF] shadow-[0_0_12px_rgba(45,212,191,0.2)]"
              : "bg-black/[0.03] dark:bg-black/25 border-black/[0.06] dark:border-white/[0.08] text-zinc-500 dark:text-[#94A3B8] hover:text-zinc-800 dark:hover:text-[#F1F5F9] hover:bg-black/[0.05] dark:hover:bg-white/[0.04]"
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
        className={`w-[40px] h-[40px] shrink-0 rounded-xl flex items-center justify-center border transition-all relative tactile-btn cursor-pointer ${
          selectedTagCount > 0
            ? "bg-teal-500/15 dark:bg-[#14B8A6]/20 border-teal-500/50 dark:border-[#2DD4BF]/50 text-teal-600 dark:text-[#2DD4BF] shadow-[0_0_12px_rgba(45,212,191,0.2)]"
            : "bg-black/[0.03] dark:bg-black/25 border-black/[0.06] dark:border-white/[0.08] text-zinc-500 dark:text-[#94A3B8] hover:text-zinc-800 dark:hover:text-[#F1F5F9] hover:bg-black/[0.05] dark:hover:bg-white/[0.04]"
        }`}
      >
        <Tag className="w-3.5 h-3.5" />
        {selectedTagCount > 0 && (
          <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-teal-500 text-white text-[9px] font-bold flex items-center justify-center shadow-xs">
            {selectedTagCount}
          </span>
        )}
      </button>

      {/* Primary Add Button (Linear style luminous button) */}
      <button
        type="button"
        onClick={onAddNew}
        title={addTooltip || t("createTodoAction")}
        className="w-[40px] h-[40px] shrink-0 rounded-xl flex items-center justify-center bg-gradient-to-b from-teal-500/20 to-teal-600/10 dark:from-[#2DD4BF]/25 dark:to-[#14B8A6]/10 border border-teal-500/40 dark:border-[#2DD4BF]/40 text-teal-600 dark:text-[#2DD4BF] hover:from-teal-500/30 hover:to-teal-600/20 dark:hover:from-[#2DD4BF]/35 dark:hover:to-[#14B8A6]/20 shadow-[0_2px_10px_-2px_rgba(20,184,166,0.3)] tactile-btn cursor-pointer"
      >
        <Plus className="w-4 h-4 stroke-[2.5]" />
      </button>
    </div>
  );
};
