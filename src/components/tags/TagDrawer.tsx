import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { X, Plus, Trash2, Edit2, Check, Tag as TagIcon, Settings2 } from "lucide-react";
import { useTagStore } from "@/stores/useTagStore";

const TAG_PALETTE = [
  "#20B8A8", // Teal
  "#4C8FF5", // Blue
  "#6F73E8", // Indigo
  "#A46BE0", // Purple
  "#E36F9F", // Pink
  "#F17842", // Orange
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
  const [newTagName, setNewTagName] = useState("");
  const [newTagColor, setNewTagColor] = useState(TAG_PALETTE[0]);

  const [editingTagId, setEditingTagId] = useState<string | null>(null);
  const [editingTagName, setEditingTagName] = useState("");
  const [editingTagColor, setEditingTagColor] = useState(TAG_PALETTE[0]);

  if (!isOpen) return null;

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTagName.trim()) return;
    await createTag(newTagName.trim(), newTagColor);
    setNewTagName("");
  };

  const startEdit = (tag: { id: string; name: string; colorHex: string }) => {
    setEditingTagId(tag.id);
    setEditingTagName(tag.name);
    setEditingTagColor(tag.colorHex);
  };

  const saveEdit = async () => {
    if (!editingTagId || !editingTagName.trim()) return;
    await updateTag(editingTagId, editingTagName.trim(), editingTagColor);
    setEditingTagId(null);
  };

  // Compute tag usage counts
  const usageCounts = workspace.tags.reduce<Record<string, number>>((acc, tag) => {
    let count = 0;
    for (const ids of Object.values(workspace.assignments)) {
      if (ids.includes(tag.id)) count++;
    }
    acc[tag.id] = count;
    return acc;
  }, {});

  return (
    <>
      {/* Scrim */}
      <div
        className="absolute inset-0 z-40 bg-black/40 backdrop-blur-[2px] transition-opacity duration-200"
        onClick={onClose}
      />

      {/* Left Slide-in Drawer */}
      <div className="absolute top-0 left-0 bottom-0 z-50 w-[292px] bg-[#F9FBFA] dark:bg-[#1D2529] text-zinc-900 dark:text-[#EEF2F1] border-r border-black/[0.08] dark:border-white/[0.1] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-left duration-220">
        {/* Header */}
        <div className="h-12 px-4 border-b border-black/[0.05] dark:border-white/[0.06] flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <TagIcon className="w-4 h-4 text-teal-600 dark:text-[#22B8A7]" />
            <span className="text-xs font-semibold">
              {mode === "filter" ? t("filterByTagTitle") : t("manageTags")}
            </span>
          </div>

          <div className="flex items-center space-x-1">
            <button
              type="button"
              onClick={() => setMode(mode === "filter" ? "manage" : "filter")}
              title={mode === "filter" ? "管理标签" : "返回筛选"}
              className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors cursor-pointer ${
                mode === "manage"
                  ? "text-teal-600 dark:text-[#22B8A7] bg-teal-500/10"
                  : "text-zinc-400 hover:text-zinc-800 dark:hover:text-white"
              }`}
            >
              <Settings2 className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={onClose}
              className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4 text-xs">
          {mode === "filter" ? (
            /* Filter Mode */
            <div className="space-y-2">
              {/* All Tags Option */}
              <button
                type="button"
                onClick={() => {
                  setSelectedTagFilter(null);
                  onClose();
                }}
                className={`w-full p-2.5 rounded-xl text-left flex items-center justify-between border transition-all cursor-pointer ${
                  selectedTagFilter === null
                    ? "bg-teal-500/15 dark:bg-[#22B8A7]/15 border-teal-500/40 text-teal-700 dark:text-[#22B8A7] font-medium"
                    : "bg-white/60 dark:bg-[#151B1E] border-black/[0.04] dark:border-white/[0.06] text-zinc-700 dark:text-[#EEF2F1] hover:border-black/[0.1]"
                }`}
              >
                <span>{t("allTagsFilterLabel")}</span>
                {selectedTagFilter === null && <Check className="w-3.5 h-3.5 stroke-[3]" />}
              </button>

              {/* Tag Items */}
              {workspace.tags.map((tag) => {
                const isSelected = selectedTagFilter === tag.id;
                const count = usageCounts[tag.id] || 0;

                return (
                  <button
                    key={tag.id}
                    type="button"
                    onClick={() => {
                      setSelectedTagFilter(isSelected ? null : tag.id);
                      onClose();
                    }}
                    className={`w-full p-2.5 rounded-xl text-left flex items-center justify-between border transition-all cursor-pointer ${
                      isSelected
                        ? "bg-teal-500/15 dark:bg-[#22B8A7]/15 border-teal-500/40 text-teal-700 dark:text-[#22B8A7] font-medium"
                        : "bg-white/60 dark:bg-[#151B1E] border-black/[0.04] dark:border-white/[0.06] text-zinc-700 dark:text-[#EEF2F1] hover:border-black/[0.1]"
                    }`}
                  >
                    <div className="flex items-center space-x-2 truncate mr-2">
                      <span
                        className="w-2.5 h-2.5 rounded-full shrink-0"
                        style={{ backgroundColor: tag.colorHex }}
                      />
                      <span className="truncate">{tag.name}</span>
                    </div>

                    <div className="flex items-center space-x-1.5 shrink-0">
                      <span className="text-[10px] text-zinc-400">{count} 项</span>
                      {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                    </div>
                  </button>
                );
              })}

              {workspace.tags.length === 0 && (
                <div className="text-center py-8 text-zinc-400 space-y-2">
                  <p>{t("noTagsYetMessage")}</p>
                  <button
                    type="button"
                    onClick={() => setMode("manage")}
                    className="text-xs text-teal-600 dark:text-[#22B8A7] underline cursor-pointer"
                  >
                    前往创建标签
                  </button>
                </div>
              )}
            </div>
          ) : (
            /* Management Mode */
            <div className="space-y-4">
              {/* Create Tag Form */}
              <form onSubmit={handleCreate} className="p-3 bg-white dark:bg-[#151B1E] rounded-xl border border-black/[0.06] dark:border-white/[0.08] space-y-2.5">
                <span className="text-[11px] font-medium text-zinc-500 dark:text-[#8E9599] block">
                  {t("newTag")}
                </span>
                <div className="flex items-center space-x-2">
                  <input
                    type="text"
                    value={newTagName}
                    onChange={(e) => setNewTagName(e.target.value)}
                    placeholder={t("tagName")}
                    className="flex-1 px-2.5 py-1.5 rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.02] dark:bg-white/[0.05] text-xs focus:outline-none focus:border-teal-500"
                  />
                  <button
                    type="submit"
                    className="px-3 py-1.5 bg-teal-600 dark:bg-[#22B8A7] hover:bg-teal-700 text-white rounded-lg font-medium cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                </div>

                {/* Color Palette */}
                <div className="flex items-center space-x-1.5 pt-1">
                  {TAG_PALETTE.map((color) => (
                    <button
                      key={color}
                      type="button"
                      onClick={() => setNewTagColor(color)}
                      className={`w-4 h-4 rounded-full transition-transform cursor-pointer flex items-center justify-center ${
                        newTagColor === color ? "scale-125 ring-2 ring-white/40" : "hover:scale-110"
                      }`}
                      style={{ backgroundColor: color }}
                    >
                      {newTagColor === color && <Check className="w-2.5 h-2.5 text-white stroke-[3]" />}
                    </button>
                  ))}
                </div>
              </form>

              {/* Tag List */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-medium text-zinc-500 dark:text-[#8E9599] block px-1">
                  已创建的标签
                </span>

                {workspace.tags.map((tag) => {
                  const isEditing = editingTagId === tag.id;

                  return (
                    <div
                      key={tag.id}
                      className="p-2.5 bg-white dark:bg-[#151B1E] rounded-xl border border-black/[0.04] dark:border-white/[0.06] flex items-center justify-between"
                    >
                      {isEditing ? (
                        <div className="flex-1 flex items-center space-x-1.5">
                          <input
                            type="text"
                            value={editingTagName}
                            onChange={(e) => setEditingTagName(e.target.value)}
                            className="flex-1 px-2 py-1 rounded border border-teal-500 bg-transparent text-xs"
                          />
                          <button
                            type="button"
                            onClick={saveEdit}
                            className="px-2 py-1 bg-teal-600 text-white rounded text-[10px]"
                          >
                            保存
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center space-x-2 truncate mr-2">
                          <span
                            className="w-2.5 h-2.5 rounded-full shrink-0"
                            style={{ backgroundColor: tag.colorHex }}
                          />
                          <span className="truncate">{tag.name}</span>
                        </div>
                      )}

                      {!isEditing && (
                        <div className="flex items-center space-x-1">
                          <button
                            type="button"
                            onClick={() => startEdit(tag)}
                            className="w-6 h-6 flex items-center justify-center text-zinc-400 hover:text-zinc-700 dark:hover:text-white"
                          >
                            <Edit2 className="w-3 h-3" />
                          </button>
                          <button
                            type="button"
                            onClick={() => deleteTag(tag.id)}
                            className="w-6 h-6 flex items-center justify-center text-zinc-400 hover:text-red-500"
                          >
                            <Trash2 className="w-3 h-3" />
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
};
