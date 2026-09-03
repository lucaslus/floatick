import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { X, Sun, Moon, Monitor, Globe, LogOut, Folder } from "lucide-react";
import { useSettingsStore } from "@/stores/useSettingsStore";
import { api } from "@/lib/api";
import type { ThemePreference, LanguagePreference } from "@/types";

interface SettingsDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export const SettingsDrawer: React.FC<SettingsDrawerProps> = ({
  isOpen,
  onClose,
}) => {
  const { t } = useTranslation();
  const settings = useSettingsStore((s) => s.settings);
  const updateTheme = useSettingsStore((s) => s.updateTheme);
  const updateLanguage = useSettingsStore((s) => s.updateLanguage);
  const updateAlwaysOnTop = useSettingsStore((s) => s.updateAlwaysOnTop);
  const updateCollapseOnBlur = useSettingsStore((s) => s.updateCollapseOnBlur);

  const [autostart, setAutostart] = useState(false);

  useEffect(() => {
    if (isOpen) {
      api.isAutostartEnabled().then(setAutostart).catch(() => {});
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleToggleAutostart = async () => {
    const next = !autostart;
    try {
      await api.setAutostartEnabled(next);
      setAutostart(next);
    } catch (err) {
      console.error("Failed to update autostart:", err);
    }
  };

  const handleQuit = async () => {
    await api.quitApp();
  };

  return (
    <>
      {/* Scrim */}
      <div
        className="absolute inset-0 z-40 bg-black/40 backdrop-blur-[2px] transition-opacity duration-200"
        onClick={onClose}
      />

      {/* Right Slide-in Drawer */}
      <div className="absolute top-0 right-0 bottom-0 z-50 w-[276px] bg-[#F9FBFA] dark:bg-[#1D2529] text-zinc-900 dark:text-[#EEF2F1] border-l border-black/[0.08] dark:border-white/[0.1] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-right duration-220">
        {/* Header */}
        <div className="h-12 px-4 border-b border-black/[0.05] dark:border-white/[0.06] flex items-center justify-between">
          <span className="text-xs font-semibold text-zinc-800 dark:text-[#EEF2F1]">
            {t("settingsTitle")}
          </span>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded-lg flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4 text-xs">
          {/* Appearance Section */}
          <div className="space-y-1.5">
            <span className="text-[11px] font-semibold text-zinc-400 dark:text-[#8E9599] uppercase tracking-wider block">
              {t("appearanceSectionTitle")}
            </span>
            <div className="grid grid-cols-3 gap-1.5">
              {[
                { id: "system" as ThemePreference, label: t("themeSystemTooltip"), icon: Monitor },
                { id: "light" as ThemePreference, label: t("themeLightTooltip"), icon: Sun },
                { id: "dark" as ThemePreference, label: t("themeDarkTooltip"), icon: Moon },
              ].map(({ id, label, icon: Icon }) => (
                <button
                  key={id}
                  type="button"
                  onClick={() => updateTheme(id)}
                  className={`p-2 rounded-xl flex flex-col items-center space-y-1 border transition-all cursor-pointer ${
                    settings.theme === id
                      ? "bg-teal-500/15 dark:bg-[#22B8A7]/15 border-teal-500/50 dark:border-[#22B8A7]/50 text-teal-700 dark:text-[#22B8A7] font-medium"
                      : "bg-white dark:bg-[#151B1E] border-black/[0.04] dark:border-white/[0.06] text-zinc-600 dark:text-[#8E9599] hover:border-black/[0.1]"
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  <span className="text-[10px]">{label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Language Section */}
          <div className="space-y-1.5">
            <span className="text-[11px] font-semibold text-zinc-400 dark:text-[#8E9599] uppercase tracking-wider block">
              {t("languageSectionTitle")}
            </span>
            <div className="grid grid-cols-3 gap-1.5">
              {[
                { id: "system" as LanguagePreference, label: t("languageSystemTooltip") },
                { id: "zh" as LanguagePreference, label: t("languageSimplifiedChineseTooltip") },
                { id: "en" as LanguagePreference, label: t("languageEnglishTooltip") },
              ].map(({ id, label }) => (
                <button
                  key={id}
                  type="button"
                  onClick={() => updateLanguage(id)}
                  className={`p-1.5 rounded-xl flex items-center justify-center space-x-1 border transition-all cursor-pointer ${
                    settings.language === id
                      ? "bg-teal-500/15 dark:bg-[#22B8A7]/15 border-teal-500/50 dark:border-[#22B8A7]/50 text-teal-700 dark:text-[#22B8A7] font-medium"
                      : "bg-white dark:bg-[#151B1E] border-black/[0.04] dark:border-white/[0.06] text-zinc-600 dark:text-[#8E9599] hover:border-black/[0.1]"
                  }`}
                >
                  <Globe className="w-3 h-3" />
                  <span className="text-[10px]">{label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Window Behavior */}
          <div className="space-y-1.5">
            <span className="text-[11px] font-semibold text-zinc-400 dark:text-[#8E9599] uppercase tracking-wider block">
              {t("windowSectionTitle")}
            </span>
            <div className="bg-white dark:bg-[#151B1E] rounded-xl border border-black/[0.04] dark:border-white/[0.06] divide-y divide-black/[0.04] dark:divide-white/[0.04]">
              <div className="p-2.5 flex items-center justify-between">
                <span className="text-zinc-700 dark:text-[#EEF2F1] text-[11px]">{t("alwaysOnTopLabel")}</span>
                <button
                  type="button"
                  onClick={() => updateAlwaysOnTop(!settings.alwaysOnTop)}
                  className={`w-8 h-4.5 rounded-full transition-colors relative cursor-pointer ${
                    settings.alwaysOnTop ? "bg-teal-600 dark:bg-[#22B8A7]" : "bg-zinc-300 dark:bg-zinc-700"
                  }`}
                >
                  <div
                    className={`w-3.5 h-3.5 rounded-full bg-white transition-transform absolute top-0.5 ${
                      settings.alwaysOnTop ? "translate-x-4" : "translate-x-0.5"
                    }`}
                  />
                </button>
              </div>

              <div className="p-2.5 flex items-center justify-between">
                <span className="text-zinc-700 dark:text-[#EEF2F1] text-[11px]">{t("collapseWhenClickingOutsideLabel")}</span>
                <button
                  type="button"
                  onClick={() => updateCollapseOnBlur(!settings.collapseWhenClickingOutside)}
                  className={`w-8 h-4.5 rounded-full transition-colors relative cursor-pointer ${
                    settings.collapseWhenClickingOutside ? "bg-teal-600 dark:bg-[#22B8A7]" : "bg-zinc-300 dark:bg-zinc-700"
                  }`}
                >
                  <div
                    className={`w-3.5 h-3.5 rounded-full bg-white transition-transform absolute top-0.5 ${
                      settings.collapseWhenClickingOutside ? "translate-x-4" : "translate-x-0.5"
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>

          {/* Startup Section */}
          <div className="space-y-1.5">
            <span className="text-[11px] font-semibold text-zinc-400 dark:text-[#8E9599] uppercase tracking-wider block">
              {t("startupSectionTitle")}
            </span>
            <div className="bg-white dark:bg-[#151B1E] rounded-xl border border-black/[0.04] dark:border-white/[0.06] p-2.5 flex items-center justify-between">
              <span className="text-zinc-700 dark:text-[#EEF2F1] text-[11px]">{t("openAtLoginLabel")}</span>
              <button
                type="button"
                onClick={handleToggleAutostart}
                className={`w-8 h-4.5 rounded-full transition-colors relative cursor-pointer ${
                  autostart ? "bg-teal-600 dark:bg-[#22B8A7]" : "bg-zinc-300 dark:bg-zinc-700"
                }`}
              >
                <div
                  className={`w-3.5 h-3.5 rounded-full bg-white transition-transform absolute top-0.5 ${
                    autostart ? "translate-x-4" : "translate-x-0.5"
                  }`}
                />
              </button>
            </div>
          </div>

          {/* Working Directory Section */}
          <div className="space-y-1.5">
            <span className="text-[11px] font-semibold text-zinc-400 dark:text-[#8E9599] uppercase tracking-wider block">
              {t("workingDirectorySectionTitle")}
            </span>
            <div className="p-2.5 bg-white dark:bg-[#151B1E] rounded-xl border border-black/[0.04] dark:border-white/[0.06] flex items-center space-x-2 text-[11px] text-zinc-500 dark:text-[#8E9599]">
              <Folder className="w-3.5 h-3.5 text-teal-600 dark:text-[#22B8A7]" />
              <span className="font-mono">~/.floatick</span>
            </div>
          </div>

          {/* Quit Button */}
          <div className="pt-2">
            <button
              type="button"
              onClick={handleQuit}
              className="w-full p-2.5 rounded-xl border border-red-200 dark:border-red-900/40 text-red-600 dark:text-red-400 bg-red-50/50 dark:bg-red-950/20 hover:bg-red-100 dark:hover:bg-red-950/40 font-medium flex items-center justify-center space-x-1.5 transition-colors cursor-pointer"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span>{t("quit")}</span>
            </button>
          </div>

          {/* Version Info */}
          <div className="text-center pt-1 text-[10px] text-zinc-400 dark:text-[#8E9599]">
            Floatick v0.4.0 (macOS)
          </div>
        </div>
      </div>
    </>
  );
};
