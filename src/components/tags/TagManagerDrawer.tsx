import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { X, Plus, Trash2, Edit2, Check } from "lucide-react";
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

interface TagManagerDrawerProps {
  onClose: () => void;
}

export const TagManagerDrawer: React.FC<TagManagerDrawerProps> = ({ onClose }) => {
  const { t } = useTranslation();
  const workspace = useTagStore((s) => s.workspace);
  const createTag = useTagStore((s) => s.createTag);
  const updateTag = useTagStore((s) => s.updateTag);
  const deleteTag = useTagStore((s) => s.deleteTag);

  const [newName, setNewName] = useState("");
  const [newColor, setNewColor] = useState(TAG_PALETTE[0]);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [editingName, setEditingName] = useState("");
  const [editingColor, setEditingColor] = useState(TAG_PALETTE[0]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;
    await createTag(newName.trim(), newColor);
    setNewName("");
  };

  const startEdit = (tag: { id: string; name: string; colorHex: string }) => {
    setEditingId(tag.id);
    setEditingName(tag.name);
    setEditingColor(tag.colorHex);
  };

  const handleSaveEdit = async () => {
    if (!editingId || !editingName.trim()) return;
    await updateTag(editingId, editingName.trim(), editingColor);
    setEditingId(null);
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-white/95 dark:bg-zinc-900/95 backdrop-blur-xl animate-in fade-in duration-200 text-xs">
      {/* Header */}
      <div className="h-11 px-3 border-b border-black/[0.06] dark:border-white/[0.08] flex items-center justify-between">
        <span className="font-semibold text-zinc-800 dark:text-zinc-200">
          {t("manageTags")}
        </span>
        <button
          onClick={onClose}
          className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.05] dark:hover:bg-white/[0.08]"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {/* Create Form */}
        <form onSubmit={handleCreate} className="p-3 bg-black/[0.02] dark:bg-white/[0.03] rounded-xl border border-black/[0.06] dark:border-white/[0.06] space-y-2.5">
          <span className="text-[11px] font-medium text-zinc-500 block">
            {t("newTag")}
          </span>
          <div className="flex items-center space-x-2">
            <input
              type="text"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              placeholder={t("tagName")}
              className="flex-1 px-2.5 py-1.5 rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-teal-500/30 text-xs"
            />
            <button
              type="submit"
              className="px-3 py-1.5 bg-teal-600 hover:bg-teal-700 text-white rounded-lg font-medium flex items-center space-x-1 cursor-pointer transition-colors"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>添加</span>
            </button>
          </div>

          {/* Color palette picker */}
          <div className="flex items-center space-x-2 pt-1">
            <span className="text-[10px] text-zinc-400">颜色:</span>
            <div className="flex items-center space-x-1.5">
              {TAG_PALETTE.map((color) => (
                <button
                  key={color}
                  type="button"
                  onClick={() => setNewColor(color)}
                  className={`w-4 h-4 rounded-full transition-transform cursor-pointer flex items-center justify-center ${
                    newColor === color ? "scale-125 ring-2 ring-black/20 dark:ring-white/30" : "hover:scale-110"
                  }`}
                  style={{ backgroundColor: color }}
                >
                  {newColor === color && <Check className="w-2.5 h-2.5 text-white stroke-[3]" />}
                </button>
              ))}
            </div>
          </div>
        </form>

        {/* Existing Tags List */}
        <div className="space-y-1.5">
          <span className="text-[11px] font-medium text-zinc-500 block px-1">
            已创建的标签 ({workspace.tags.length})
          </span>

          {workspace.tags.length === 0 ? (
            <div className="text-center py-6 text-zinc-400 text-xs">
              还没有标签，可在上方添加
            </div>
          ) : (
            workspace.tags.map((tag) => {
              const isEditing = editingId === tag.id;

              return (
                <div
                  key={tag.id}
                  className="flex items-center justify-between p-2.5 rounded-xl border border-black/[0.04] dark:border-white/[0.04] bg-white/60 dark:bg-zinc-800/60 shadow-xs"
                >
                  {isEditing ? (
                    <div className="flex-1 flex items-center space-x-2 mr-2">
                      <input
                        type="text"
                        value={editingName}
                        onChange={(e) => setEditingName(e.target.value)}
                        className="flex-1 px-2 py-1 rounded border border-teal-500 bg-white dark:bg-zinc-800 text-xs"
                      />
                      <div className="flex items-center space-x-1">
                        {TAG_PALETTE.map((c) => (
                          <button
                            key={c}
                            type="button"
                            onClick={() => setEditingColor(c)}
                            className="w-3.5 h-3.5 rounded-full"
                            style={{ backgroundColor: c }}
                          />
                        ))}
                      </div>
                      <button
                        onClick={handleSaveEdit}
                        className="px-2 py-1 bg-teal-600 text-white rounded text-[10px]"
                      >
                        保存
                      </button>
                    </div>
                  ) : (
                    <div className="flex items-center space-x-2">
                      <span
                        className="w-3 h-3 rounded-full shrink-0"
                        style={{ backgroundColor: tag.colorHex }}
                      />
                      <span className="font-medium text-zinc-800 dark:text-zinc-200">
                        {tag.name}
                      </span>
                    </div>
                  )}

                  {!isEditing && (
                    <div className="flex items-center space-x-1">
                      <button
                        onClick={() => startEdit(tag)}
                        className="w-6 h-6 flex items-center justify-center rounded text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200"
                      >
                        <Edit2 className="w-3 h-3" />
                      </button>
                      <button
                        onClick={() => deleteTag(tag.id)}
                        className="w-6 h-6 flex items-center justify-center rounded text-zinc-400 hover:text-red-600"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
};
