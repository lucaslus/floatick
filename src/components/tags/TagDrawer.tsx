import React, { useState, useEffect, useMemo } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  Check,
  CaretLeft,
  Stack,
  PencilSimple,
  Trash,
  Plus,
} from "@phosphor-icons/react";
import { useTagStore } from "@/stores/useTagStore";
import { useTodoStore } from "@/stores/useTodoStore";
import { useNoteStore } from "@/stores/useNoteStore";

// Exact TagPalette colors from legacy/flutter/lib/features/todos/presentation/widgets/tag_palette.dart
const TAG_PALETTE = [
  "#20B8A8", // Teal
  "#4C8FF5", // Blue
  "#6F73E8", // Indigo
  "#A46BE0", // Purple
  "#E36F9F", // Pink
  "#F18A45", // Orange
  "#E0B83F", // Yellow
  "#E15F5F", // Red
];

interface TagDrawerProps {
  isOpen: boolean;
  initialMode?: "filter" | "assignment" | "manage";
  targetTodoId?: string | null;
  onClose: () => void;
}

export const TagDrawer: React.FC<TagDrawerProps> = ({
  isOpen,
  initialMode = "filter",
  targetTodoId = null,
  onClose,
}) => {
  const { t } = useTranslation();

  const workspace = useTagStore((s) => s.workspace);
  const selectedTagIds = useTagStore((s) => s.selectedTagIds);
  const toggleTagFilter = useTagStore((s) => s.toggleTagFilter);
  const clearTagFilter = useTagStore((s) => s.clearTagFilter);
  const toggleTodoTag = useTagStore((s) => s.toggleTodoTag);
  const createTag = useTagStore((s) => s.createTag);
  const updateTag = useTagStore((s) => s.updateTag);
  const deleteTag = useTagStore((s) => s.deleteTag);

  const todos = useTodoStore((s) => s.todos);
  const notes = useNoteStore((s) => s.notes);

  const [mode, setMode] = useState<"filter" | "assignment" | "manage">(initialMode);
  const [returnMode, setReturnMode] = useState<"filter" | "assignment">("filter");

  const [tagNameInput, setTagNameInput] = useState("");
  const [selectedColor, setSelectedColor] = useState(TAG_PALETTE[0]);
  const [editingTagId, setEditingTagId] = useState<string | null>(null);
  const [confirmDeleteTagId, setConfirmDeleteTagId] = useState<string | null>(null);
  const [validationError, setValidationError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setMode(initialMode);
      setReturnMode(initialMode === "manage" ? "filter" : initialMode);
      setTagNameInput("");
      setSelectedColor(TAG_PALETTE[0]);
      setEditingTagId(null);
      setConfirmDeleteTagId(null);
      setValidationError(null);
    }
  }, [isOpen, initialMode, targetTodoId]);

  // Compute accurate active usage counts (Active Todos + Active Notes)
  const usageCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const tag of workspace.tags) {
      counts[tag.id] = 0;
    }

    // Active todos
    for (const todo of todos) {
      if (todo.archivedAt) continue;
      const assigned = workspace.assignments[todo.id] || [];
      for (const tagId of assigned) {
        if (counts[tagId] !== undefined) {
          counts[tagId]++;
        }
      }
    }

    // Active notes
    for (const note of notes) {
      if (note.archivedAt) continue;
      for (const tagId of note.tagIds) {
        if (counts[tagId] !== undefined) {
          counts[tagId]++;
        }
      }
    }

    return counts;
  }, [workspace.tags, workspace.assignments, todos, notes]);

  if (!isOpen) return null;

  const targetAssignedTagIds = targetTodoId
    ? workspace.assignments[targetTodoId] || []
    : [];

  const handleOpenManage = () => {
    setReturnMode(mode === "manage" ? "filter" : mode);
    setMode("manage");
    handleCancelEdit();
  };

  const handleBackFromManage = () => {
    setMode(returnMode);
    handleCancelEdit();
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const name = tagNameInput.trim();
    if (!name) return;

    try {
      if (editingTagId) {
        await updateTag(editingTagId, name, selectedColor);
        setEditingTagId(null);
      } else {
        await createTag(name, selectedColor);
      }
      setTagNameInput("");
      setSelectedColor(TAG_PALETTE[0]);
      setValidationError(null);
    } catch (err: unknown) {
      if (err instanceof Error && err.message === "Tag name already exists") {
        setValidationError(t("tagNameAlreadyExistsMessage") || "标签名称已存在");
      } else {
        setValidationError(String(err));
      }
    }
  };

  const handleStartEdit = (tag: { id: string; name: string; colorHex: string }) => {
    setEditingTagId(tag.id);
    setTagNameInput(tag.name);
    setSelectedColor(tag.colorHex);
    setConfirmDeleteTagId(null);
    setValidationError(null);
  };

  const handleCancelEdit = () => {
    setEditingTagId(null);
    setTagNameInput("");
    setSelectedColor(TAG_PALETTE[0]);
    setValidationError(null);
  };

  const handleDelete = async (tagId: string) => {
    await deleteTag(tagId);
    setConfirmDeleteTagId(null);
    if (editingTagId === tagId) {
      handleCancelEdit();
    }
  };

  return (
    <>
      {/* Scrim Overlay */}
      <div
        className="absolute inset-0 z-40 bg-black/50 backdrop-blur-xs transition-opacity"
        onClick={onClose}
      />

      {/* Surface: 292px width, sliding from right */}
      <div className="absolute top-0 right-0 bottom-0 z-50 w-[292px] bg-[var(--color-bg-drawer)] text-[var(--color-text-primary)] border-l border-[var(--color-border-drawer)] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-right duration-200 select-none">
        {/* Header */}
        <div className="px-4.5 py-3 border-b border-[var(--color-border-drawer)] flex items-center justify-between shrink-0">
          <div className="flex items-center space-x-1.5 min-w-0">
            {mode === "manage" && (
              <button
                type="button"
                onClick={handleBackFromManage}
                title={returnMode === "assignment" ? t("assignTagsTitle") || "分配标签" : t("filterByTagTitle")}
                className="w-7 h-7 rounded-lg flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] transition-colors tactile-btn cursor-pointer -ml-1.5"
              >
                <CaretLeft size={16} weight="bold" />
              </button>
            )}
            <span className="text-[15px] font-semibold text-[var(--color-text-primary)] tracking-tight truncate">
              {mode === "filter"
                ? t("filterByTagTitle")
                : mode === "assignment"
                ? t("assignTagsTitle") || "分配标签"
                : t("manageTags")}
            </span>
          </div>

          <div className="flex items-center space-x-1 shrink-0">
            {mode !== "manage" && (
              <button
                type="button"
                onClick={handleOpenManage}
                className="text-[12.5px] font-semibold text-[var(--color-teal-primary)] hover:underline px-2 py-1 rounded transition-colors tactile-btn cursor-pointer"
              >
                {t("manageTags")}
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              className="w-7 h-7 rounded-lg flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] transition-colors tactile-btn cursor-pointer"
            >
              <X size={16} weight="bold" />
            </button>
          </div>
        </div>

        {/* View 1: Filter Mode (TagFilterDrawer - Multi-Select Filter) */}
        {mode === "filter" && (
          <div className="flex-1 overflow-y-auto p-2.5 space-y-1 smooth-scroll">
            {/* All Items Row (Clears multi-selection) */}
            <button
              type="button"
              onClick={clearTagFilter}
              className={`w-full h-11 px-3 rounded-[8px] flex items-center justify-between transition-colors tactile-btn cursor-pointer ${
                selectedTagIds.length === 0
                  ? "text-[var(--color-teal-primary)] font-medium hover:bg-[var(--color-hover-overlay)]"
                  : "text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
              }`}
            >
              <div className="flex items-center space-x-2.5">
                <Stack size={17} weight={selectedTagIds.length === 0 ? "fill" : "regular"} className="opacity-75" />
                <span className="text-[13.5px] font-medium tracking-tight">
                  {t("allTagsFilterLabel")}
                </span>
              </div>
              {selectedTagIds.length === 0 && (
                <Check size={16} weight="bold" className="text-[var(--color-teal-primary)]" />
              )}
            </button>

            {/* Tags List */}
            {workspace.tags.length === 0 ? (
              <div className="py-12 text-center text-[12.5px] text-[var(--color-text-subtle)] px-4">
                {t("noTagsYetMessage")}
              </div>
            ) : (
              workspace.tags.map((tag) => {
                const isSelected = selectedTagIds.includes(tag.id);
                const count = usageCounts[tag.id] ?? 0;
                return (
                  <button
                    key={tag.id}
                    type="button"
                    onClick={() => toggleTagFilter(tag.id)}
                    className={`w-full h-11 px-3 rounded-[8px] flex items-center justify-between transition-colors tactile-btn cursor-pointer ${
                      isSelected
                        ? "text-[var(--color-teal-primary)] font-medium hover:bg-[var(--color-hover-overlay)]"
                        : "text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
                    }`}
                  >
                    <div className="flex items-center space-x-2.5 min-w-0 flex-1 mr-2">
                      <span
                        className="w-2 h-2 rounded-full shrink-0"
                        style={{ backgroundColor: tag.colorHex }}
                      />
                      <span className="text-[13.5px] font-medium tracking-tight truncate">
                        {tag.name}
                      </span>
                    </div>

                    <div className="flex items-center space-x-2 shrink-0">
                      <span className="text-[11.5px] text-[var(--color-text-subtle)] font-mono">
                        {count}
                      </span>
                      {isSelected && (
                        <Check size={16} weight="bold" className="text-[var(--color-teal-primary)]" />
                      )}
                    </div>
                  </button>
                );
              })
            )}
          </div>
        )}

        {/* View 2: Assignment Mode (TagFilterDrawer.assignment - Assign to specific item) */}
        {mode === "assignment" && targetTodoId && (
          <div className="flex-1 overflow-y-auto p-2.5 space-y-1 smooth-scroll">
            {workspace.tags.length === 0 ? (
              <div className="py-12 text-center text-xs text-[var(--color-text-subtle)] px-4">
                {t("noTagsYetMessage")}
              </div>
            ) : (
              workspace.tags.map((tag) => {
                const isAssigned = targetAssignedTagIds.includes(tag.id);
                const count = usageCounts[tag.id] ?? 0;
                return (
                  <button
                    key={tag.id}
                    type="button"
                    onClick={() => toggleTodoTag(targetTodoId, tag.id)}
                    className={`w-full h-11 px-3 rounded-[8px] flex items-center justify-between transition-colors tactile-btn cursor-pointer ${
                      isAssigned
                        ? "text-[var(--color-teal-primary)] font-medium hover:bg-[var(--color-hover-overlay)]"
                        : "text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
                    }`}
                  >
                    <div className="flex items-center space-x-2.5 min-w-0 flex-1 mr-2">
                      <span
                        className="w-2 h-2 rounded-full shrink-0"
                        style={{ backgroundColor: tag.colorHex }}
                      />
                      <span className="text-[13.5px] font-medium tracking-tight truncate">
                        {tag.name}
                      </span>
                    </div>

                    <div className="flex items-center space-x-2 shrink-0">
                      <span className="text-[11.5px] text-[var(--color-text-subtle)] font-mono">
                        {count}
                      </span>
                      {isAssigned && (
                        <Check size={16} weight="bold" className="text-[var(--color-teal-primary)]" />
                      )}
                    </div>
                  </button>
                );
              })
            )}
          </div>
        )}

        {/* View 3: Management Mode (TagManagementDrawer) */}
        {mode === "manage" && (
          <div className="flex-1 flex flex-col min-h-0">
            {/* Top Create / Edit Section */}
            <form onSubmit={handleSubmit} className="p-4 border-b border-[var(--color-border-drawer)] space-y-3 shrink-0">
              <div className="relative flex items-center">
                <input
                  type="text"
                  maxLength={30}
                  value={tagNameInput}
                  onChange={(e) => {
                    setTagNameInput(e.target.value);
                    if (validationError) setValidationError(null);
                  }}
                  placeholder={editingTagId ? t("tagName") : t("searchOrCreateTagHint") || "搜索或创建标签…"}
                  className="w-full h-9.5 pl-3 pr-16 rounded-[8px] bg-[var(--color-bg-elevated)] text-[13px] font-medium text-[var(--color-text-primary)] placeholder:text-[var(--color-text-subtle)] focus:outline-none focus:bg-[var(--color-bg-elevated-hover)] transition-colors"
                />

                <div className="absolute right-1.5 flex items-center space-x-1">
                  {editingTagId && (
                    <button
                      type="button"
                      onClick={handleCancelEdit}
                      className="w-6 h-6 rounded-md flex items-center justify-center text-[var(--color-text-subtle)] hover:text-[var(--color-text-primary)] cursor-pointer"
                    >
                      <X size={13} weight="bold" />
                    </button>
                  )}
                  <button
                    type="submit"
                    disabled={!tagNameInput.trim()}
                    className="w-7 h-7 rounded-lg flex items-center justify-center text-[var(--color-teal-primary)] hover:bg-[var(--color-teal-tint)] transition-colors tactile-btn cursor-pointer disabled:opacity-30 disabled:pointer-events-none"
                  >
                    {editingTagId ? (
                      <Check size={16} weight="bold" />
                    ) : (
                      <Plus size={16} weight="bold" />
                    )}
                  </button>
                </div>
              </div>

              {/* Character limit and validation message */}
              <div className="flex items-center justify-between text-[11px] px-1">
                <span className={validationError ? "text-red-400 font-medium" : "text-[var(--color-text-subtle)]"}>
                  {validationError || (editingTagId ? "编辑标签模式" : "创建标签模式")}
                </span>
                <span className="text-[var(--color-text-subtle)] font-mono">
                  {tagNameInput.length}/30
                </span>
              </div>

              {/* TagPalette: 8 Circular Colors */}
              <div className="flex items-center justify-between px-0.5 pt-0.5">
                {TAG_PALETTE.map((color) => {
                  const isSelected = selectedColor === color;
                  return (
                    <button
                      key={color}
                      type="button"
                      onClick={() => setSelectedColor(color)}
                      className={`w-6 h-6 rounded-full transition-transform cursor-pointer flex items-center justify-center tactile-btn ${
                        isSelected ? "scale-115 ring-2 ring-[var(--color-teal-primary)] shadow-xs" : "hover:scale-105"
                      }`}
                      style={{ backgroundColor: color }}
                    >
                      {isSelected && <Check className="w-3 h-3 text-white stroke-[3]" />}
                    </button>
                  );
                })}
              </div>
            </form>

            {/* Managed Tags List */}
            <div className="flex-1 overflow-y-auto p-2.5 space-y-1 smooth-scroll">
              {workspace.tags.length === 0 ? (
                <div className="py-12 text-center text-xs text-[var(--color-text-subtle)] px-4">
                  {t("noTagsYetMessage")}
                </div>
              ) : (
                workspace.tags.map((tag) => {
                  const isEditing = editingTagId === tag.id;
                  const isConfirming = confirmDeleteTagId === tag.id;
                  const count = usageCounts[tag.id] ?? 0;

                  return (
                    <div
                      key={tag.id}
                      className={`group h-11 px-3 rounded-[8px] flex items-center justify-between transition-colors ${
                        isEditing
                          ? "bg-[var(--color-teal-tint)]"
                          : "hover:bg-[var(--color-hover-overlay)]"
                      }`}
                    >
                      {/* Left: Tag Chip */}
                      <div
                        className="inline-flex items-center space-x-1.5 px-2 py-0.5 rounded-md text-[11px] font-medium shrink-0"
                        style={{
                          backgroundColor: `${tag.colorHex}22`,
                          border: `1px solid ${tag.colorHex}44`,
                          color: tag.colorHex,
                        }}
                      >
                        <span
                          className="w-1.5 h-1.5 rounded-full shrink-0"
                          style={{ backgroundColor: tag.colorHex }}
                        />
                        <span className="truncate max-w-[110px]">{tag.name}</span>
                      </div>

                      {/* Right: Usage count + Actions */}
                      <div className="flex items-center space-x-1.5 shrink-0">
                        {!isConfirming && (
                          <span className="text-[11px] text-[var(--color-text-subtle)] mr-1 font-mono">
                            {count}
                          </span>
                        )}

                        {isConfirming ? (
                          <div className="flex items-center space-x-1">
                            <button
                              type="button"
                              onClick={() => setConfirmDeleteTagId(null)}
                              className="w-6 h-6 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] cursor-pointer"
                            >
                              <X size={13} weight="bold" />
                            </button>
                            <button
                              type="button"
                              onClick={() => handleDelete(tag.id)}
                              className="w-6 h-6 rounded flex items-center justify-center text-[#E15F5F] hover:bg-[#E15F5F]/15 cursor-pointer"
                            >
                              <Check size={14} weight="bold" />
                            </button>
                          </div>
                        ) : (
                          <div className="flex items-center space-x-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button
                              type="button"
                              onClick={() => handleStartEdit(tag)}
                              title={t("edit")}
                              className="w-6.5 h-6.5 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] cursor-pointer"
                            >
                              <PencilSimple size={14} />
                            </button>
                            <button
                              type="button"
                              onClick={() => setConfirmDeleteTagId(tag.id)}
                              title={t("delete")}
                              className="w-6.5 h-6.5 rounded flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[#E15F5F] hover:bg-[var(--color-hover-overlay)] cursor-pointer"
                            >
                              <Trash size={14} />
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        )}
      </div>
    </>
  );
};
