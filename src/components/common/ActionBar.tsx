import React from "react";
import { MagnifyingGlass, X, Tag, Plus } from "@phosphor-icons/react";
import { useTranslation } from "react-i18next";

interface ActionBarProps {
  query: string;
  onQueryChange: (query: string) => void;
  selectedTagCount?: number;
  onOpenTagFilter: () => void;
  onAddNew: () => void;
  placeholder?: string;
  addTooltip?: string;
}

export const ActionBar: React.FC<ActionBarProps> = ({
  query,
  onQueryChange,
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
          className="w-full h-full pl-9 pr-12 text-[13.5px] font-medium rounded-[8px] bg-[var(--color-bg-elevated)] text-[var(--color-text-primary)] placeholder:text-[var(--color-text-subtle)] focus:outline-none focus:bg-[var(--color-bg-elevated-hover)] focus:placeholder-transparent transition-colors"
        />
        <MagnifyingGlass size={16} weight="bold" className="absolute left-3 text-[var(--color-text-subtle)] pointer-events-none" />

        {/* Clear Button */}
        {query && (
          <button
            type="button"
            onClick={() => onQueryChange("")}
            title={t("clearSearch")}
            className="w-5 h-5 absolute right-3 rounded-full flex items-center justify-center text-[var(--color-text-subtle)] hover:text-[var(--color-text-primary)] tactile-btn cursor-pointer"
          >
            <X size={13} weight="bold" />
          </button>
        )}
      </div>

      {/* Tag Filter Button (42x42) - Clean Icon Button without selected background */}
      <button
        type="button"
        onClick={onOpenTagFilter}
        title={t("filterByTagTitle")}
        className={`w-[42px] h-[42px] shrink-0 rounded-[8px] flex items-center justify-center relative tactile-btn cursor-pointer transition-colors ${
          selectedTagCount > 0
            ? "text-[var(--color-teal-primary)] hover:bg-[var(--color-hover-overlay)]"
            : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
        }`}
      >
        <Tag size={20} weight={selectedTagCount > 0 ? "fill" : "regular"} />
        {selectedTagCount > 0 && (
          <span className="absolute top-1 right-1 w-4 h-4 rounded-full bg-[var(--color-teal-primary)] text-white text-[10px] font-bold flex items-center justify-center">
            {selectedTagCount}
          </span>
        )}
      </button>

      {/* Add Button (42x42) - Clean Icon Button */}
      <button
        type="button"
        onClick={onAddNew}
        title={addTooltip || t("createTodoAction")}
        className="w-[42px] h-[42px] shrink-0 rounded-[8px] flex items-center justify-center text-[var(--color-teal-primary)] hover:bg-[var(--color-teal-tint)] tactile-btn cursor-pointer"
      >
        <Plus size={22} weight="bold" />
      </button>
    </div>
  );
};
