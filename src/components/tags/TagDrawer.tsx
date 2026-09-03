import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  Check,
  ChevronLeft,
  Layers,
  Edit2,
  Trash2,
  Plus,
} from "lucide-react";
import { useTagStore } from "@/stores/useTagStore";

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
  onClose: () => void;
}

export const TagDrawer: React.FC<TagDrawerProps> = ({ isOpen, onClose }) => {
  const { t } = useTranslation();
  const workspace = useTagStore((s) => s.workspace);
  const selectedTagFilter = useTagStore((s) => s.selectedTagFilter);
  const setSelectedTagFilter = useTagStore((s) => s.setSelectedTagFilter);
  const createTag = useTagStore((s) => s.createTag);
  const updateTag = useTagStore((s) => s.updateTag);
  const deleteTag = useTagStore((s) => s.deleteTag);

  const [mode, setMode] = useState<"filter" | "manage">("filter");
  const [tagNameInput, setTagNameInput] = useState("");
  const [selectedColor, setSelectedColor] = useState(TAG_PALETTE[0]);
  const [editingTagId, setEditingTagId] = useState<string | null>(null);
  const [confirmDeleteTagId, setConfirmDeleteTagId] = useState<string | null>(null);

  if (!isOpen) return null;

  // Compute tag usage counts
  const usageCounts = workspace.tags.reduce<Record<string, number>>((acc, tag) => {
    let count = 0;
    for (const ids of Object.values(workspace.assignments)) {
      if (ids.includes(tag.id)) count++;
    }
    acc[tag.id] = count;
    return acc;
  }, {});

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const name = tagNameInput.trim();
    if (!name) return;

    if (editingTagId) {
      await updateTag(editingTagId, name, selectedColor);
      setEditingTagId(null);
    } else {
      await createTag(name, selectedColor);
    }
    setTagNameInput("");
    setSelectedColor(TAG_PALETTE[0]);
  };

  const handleStartEdit = (tag: { id: string; name: string; colorHex: string }) => {
    setEditingTagId(tag.id);
    setTagNameInput(tag.name);
    setSelectedColor(tag.colorHex);
    setConfirmDeleteTagId(null);
  };

  const handleCancelEdit = () => {
    setEditingTagId(null);
    setTagNameInput("");
    setSelectedColor(TAG_PALETTE[0]);
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

      {/* Flutter Original Side Drawer (Width: 292px, #202A2E, slide from right) */}
      <div className="absolute top-0 right-0 bottom-0 z-50 w-[292px] bg-[#202A2E] text-[#EEF2F1] border-l border-white/[0.10] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-right duration-200 select-none">
        {/* Header */}
        <div className="px-4.5 py-3 border-b border-white/[0.08] flex items-center justify-between shrink-0">
          <div className="flex items-center space-x-1.5 min-w-0">
            {mode === "manage" && (
              <button
                type="button"
                onClick={() => {
                  setMode("filter");
                  handleCancelEdit();
                }}
                title={t("filterByTagTitle")}
                className="w-7 h-7 rounded-lg flex items-center justify-center text-[#EEF2F1]/58 hover:text-[#EEF2F1] hover:bg-white/[0.06] transition-colors tactile-btn cursor-pointer -ml-1.5"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
            )}
            <span className="text-[14px] font-semibold text-[#EEF2F1] tracking-tight truncate">
              {mode === "filter" ? t("filterByTagTitle") : t("manageTags")}
            </span>
          </div>

          <div className="flex items-center space-x-1 shrink-0">
            {mode === "filter" && (
              <button
                type="button"
                onClick={() => setMode("manage")}
                className="text-[12px] font-semibold text-[#22B8A7] hover:underline px-2 py-1 rounded transition-colors tactile-btn cursor-pointer"
              >
                {t("manageTags")}
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              className="w-7 h-7 rounded-lg flex items-center justify-center text-[#EEF2F1]/58 hover:text-[#EEF2F1] hover:bg-white/[0.06] transition-colors tactile-btn cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* View 1: Filter Mode (TagSelectionRow) */}
        {mode === "filter" && (
          <div className="flex-1 overflow-y-auto p-2.5 space-y-1 smooth-scroll">
            {/* All Items Row */}
            <button
              type="button"
              onClick={() => {
                setSelectedTagFilter(null);
                onClose();
              }}
              className={`w-full h-11 px-3 rounded-xl flex items-center justify-between transition-colors tactile-btn cursor-pointer ${
                selectedTagFilter === null
                  ? "bg-[#22B8A7]/[0.12] text-[#22B8A7]"
                  : "text-[#EEF2F1]/85 hover:bg-white/[0.055]"
              }`}
            >
              <div className="flex items-center space-x-2.5">
                <Layers className="w-4 h-4 opacity-50" />
                <span className="text-[13px] font-medium tracking-tight">
                  {t("allTagsFilterLabel")}
                </span>
              </div>
              {selectedTagFilter === null && (
                <Check className="w-4 h-4 text-[#22B8A7] stroke-[2.5]" />
              )}
            </button>

            {/* Tags List */}
            {workspace.tags.length === 0 ? (
              <div className="py-12 text-center text-xs text-[#EEF2F1]/40 px-4">
                {t("noTagsYetMessage")}
              </div>
            ) : (
              workspace.tags.map((tag) => {
                const isSelected = selectedTagFilter === tag.id;
                const count = usageCounts[tag.id] ?? 0;
                return (
                  <button
                    key={tag.id}
                    type="button"
                    onClick={() => {
                      setSelectedTagFilter(isSelected ? null : tag.id);
                      onClose();
                    }}
                    className={`w-full h-11 px-3 rounded-xl flex items-center justify-between transition-colors tactile-btn cursor-pointer ${
                      isSelected
                        ? "bg-[#22B8A7]/[0.12] text-[#22B8A7]"
                        : "text-[#EEF2F1]/85 hover:bg-white/[0.055]"
                    }`}
                  >
                    <div className="flex items-center space-x-2.5 min-w-0 flex-1 mr-2">
                      <span
                        className="w-2 h-2 rounded-full shrink-0"
                        style={{ backgroundColor: tag.colorHex }}
                      />
                      <span className="text-[13px] font-medium tracking-tight truncate">
                        {tag.name}
                      </span>
                    </div>

                    <div className="flex items-center space-x-2 shrink-0">
                      <span className="text-[11.5px] text-[#EEF2F1]/38">
                        {count}
                      </span>
                      {isSelected && (
                        <Check className="w-4 h-4 text-[#22B8A7] stroke-[2.5]" />
                      )}
                    </div>
                  </button>
                );
              })
            )}
          </div>
        )}

        {/* View 2: Management Mode (Search / Create & Edit) */}
        {mode === "manage" && (
          <div className="flex-1 flex flex-col min-h-0">
            {/* Top Create / Edit Section */}
            <form onSubmit={handleSubmit} className="p-4 border-b border-white/[0.06] space-y-3 shrink-0">
              <div className="relative flex items-center">
                <input
                  type="text"
                  maxLength={30}
                  value={tagNameInput}
                  onChange={(e) => setTagNameInput(e.target.value)}
                  placeholder={editingTagId ? t("tagName") : "搜索或创建标签…"}
                  className="w-full h-9.5 pl-3 pr-16 rounded-xl bg-[#1D2529] border border-white/[0.08] text-xs text-[#EEF2F1] placeholder:text-[#EEF2F1]/38 focus:outline-none focus:border-[#22B8A7] transition-colors"
                />

                <div className="absolute right-1.5 flex items-center space-x-1">
                  {editingTagId && (
                    <button
                      type="button"
                      onClick={handleCancelEdit}
                      className="w-6 h-6 rounded-md flex items-center justify-center text-[#EEF2F1]/50 hover:text-[#EEF2F1] cursor-pointer"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                  <button
                    type="submit"
                    disabled={!tagNameInput.trim()}
                    className="w-6.5 h-6.5 rounded-lg flex items-center justify-center bg-[#22B8A7] text-[#151B1E] font-semibold tactile-btn cursor-pointer disabled:opacity-30 disabled:pointer-events-none shadow-xs"
                  >
                    {editingTagId ? (
                      <Check className="w-3.5 h-3.5 stroke-[2.5]" />
                    ) : (
                      <Plus className="w-3.5 h-3.5 stroke-[2.5]" />
                    )}
                  </button>
                </div>
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
                        isSelected ? "scale-115 ring-2 ring-[#22B8A7] shadow-xs" : "hover:scale-105"
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
                <div className="py-12 text-center text-xs text-[#EEF2F1]/40 px-4">
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
                      className={`group h-11 px-3 rounded-xl flex items-center justify-between transition-colors ${
                        isEditing
                          ? "bg-[#22B8A7]/10"
                          : "hover:bg-white/[0.055]"
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
                          <span className="text-[11px] text-[#EEF2F1]/38 mr-1">
                            {count}
                          </span>
                        )}

                        {isConfirming ? (
                          <div className="flex items-center space-x-1">
                            <button
                              type="button"
                              onClick={() => setConfirmDeleteTagId(null)}
                              className="w-6 h-6 rounded flex items-center justify-center text-[#EEF2F1]/60 hover:text-[#EEF2F1] cursor-pointer"
                            >
                              <X className="w-3.5 h-3.5" />
                            </button>
                            <button
                              type="button"
                              onClick={() => handleDelete(tag.id)}
                              className="w-6 h-6 rounded flex items-center justify-center text-[#E15F5F] hover:bg-[#E15F5F]/15 cursor-pointer"
                            >
                              <Check className="w-3.5 h-3.5 stroke-[2.5]" />
                            </button>
                          </div>
                        ) : (
                          <div className="flex items-center space-x-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button
                              type="button"
                              onClick={() => handleStartEdit(tag)}
                              title={t("edit")}
                              className="w-6.5 h-6.5 rounded flex items-center justify-center text-[#EEF2F1]/50 hover:text-[#EEF2F1] hover:bg-white/[0.06] cursor-pointer"
                            >
                              <Edit2 className="w-3.5 h-3.5" />
                            </button>
                            <button
                              type="button"
                              onClick={() => setConfirmDeleteTagId(tag.id)}
                              title={t("delete")}
                              className="w-6.5 h-6.5 rounded flex items-center justify-center text-[#EEF2F1]/50 hover:text-[#E15F5F] hover:bg-white/[0.06] cursor-pointer"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
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
