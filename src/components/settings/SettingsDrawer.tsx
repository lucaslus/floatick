import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { X, Sun, Moon, Monitor, Globe, LogOut } from "lucide-react";
import { useSettingsStore } from "@/stores/useSettingsStore";
import { api } from "@/lib/api";
import type { ThemePreference, LanguagePreference } from "@/types";

interface SettingsDrawerProps {
  onClose: () => void;
}

export const SettingsDrawer: React.FC<SettingsDrawerProps> = ({ onClose }) => {
  const { t } = useTranslation();
  const settings = useSettingsStore((s) => s.settings);
  const updateTheme = useSettingsStore((s) => s.updateTheme);
  const updateLanguage = useSettingsStore((s) => s.updateLanguage);
  const updateAlwaysOnTop = useSettingsStore((s) => s.updateAlwaysOnTop);
  const updateCollapseOnBlur = useSettingsStore((s) => s.updateCollapseOnBlur);

  const [autostart, setAutostart] = useState(false);

  useEffect(() => {
    api.isAutostartEnabled().then(setAutostart).catch(() => {});
  }, []);

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
    <div className="fixed inset-0 z-50 flex flex-col bg-white/95 dark:bg-zinc-900/95 backdrop-blur-xl animate-in fade-in duration-200 text-xs">
      {/* Header */}
      <div className="h-11 px-3 border-b border-black/[0.06] dark:border-white/[0.08] flex items-center justify-between">
        <span className="font-semibold text-zinc-800 dark:text-zinc-200">
          {t("settings")}
        </span>
        <button
          onClick={onClose}
          className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-zinc-200 hover:bg-black/[0.05] dark:hover:bg-white/[0.08]"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-y-auto p-4 space-y-5">
        {/* Appearance Section */}
        <div className="space-y-2">
          <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider block">
            {t("appearance")}
          </span>
          <div className="grid grid-cols-3 gap-2">
            {[
              { id: "system" as ThemePreference, label: t("themeSystem"), icon: Monitor },
              { id: "light" as ThemePreference, label: t("themeLight"), icon: Sun },
              { id: "dark" as ThemePreference, label: t("themeDark"), icon: Moon },
            ].map(({ id, label, icon: Icon }) => (
              <button
                key={id}
                type="button"
                onClick={() => updateTheme(id)}
                className={`p-2 rounded-xl flex flex-col items-center space-y-1 border transition-all cursor-pointer ${
                  settings.theme === id
                    ? "bg-teal-50 dark:bg-teal-950/30 border-teal-500 text-teal-700 dark:text-teal-300 font-medium"
                    : "bg-white/60 dark:bg-zinc-800/60 border-black/[0.06] dark:border-white/[0.06] text-zinc-600 dark:text-zinc-400 hover:border-black/[0.12]"
                }`}
              >
                <Icon className="w-4 h-4" />
                <span className="text-[10px]">{label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Language Section */}
        <div className="space-y-2">
          <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider block">
            {t("language")}
          </span>
          <div className="grid grid-cols-3 gap-2">
            {[
              { id: "system" as LanguagePreference, label: t("langSystem") },
              { id: "zh" as LanguagePreference, label: t("langZh") },
              { id: "en" as LanguagePreference, label: t("langEn") },
            ].map(({ id, label }) => (
              <button
                key={id}
                type="button"
                onClick={() => updateLanguage(id)}
                className={`p-2 rounded-xl flex items-center justify-center space-x-1 border transition-all cursor-pointer ${
                  settings.language === id
                    ? "bg-teal-50 dark:bg-teal-950/30 border-teal-500 text-teal-700 dark:text-teal-300 font-medium"
                    : "bg-white/60 dark:bg-zinc-800/60 border-black/[0.06] dark:border-white/[0.06] text-zinc-600 dark:text-zinc-400 hover:border-black/[0.12]"
                }`}
              >
                <Globe className="w-3 h-3" />
                <span className="text-[11px]">{label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Window Behavior Section */}
        <div className="space-y-2">
          <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider block">
            {t("window")}
          </span>
          <div className="bg-white/60 dark:bg-zinc-800/60 rounded-xl border border-black/[0.06] dark:border-white/[0.06] divide-y divide-black/[0.04] dark:divide-white/[0.04]">
            <div className="p-2.5 flex items-center justify-between">
              <span className="text-zinc-700 dark:text-zinc-300">{t("alwaysOnTop")}</span>
              <button
                type="button"
                onClick={() => updateAlwaysOnTop(!settings.alwaysOnTop)}
                className={`w-9 h-5 rounded-full transition-colors relative cursor-pointer ${
                  settings.alwaysOnTop ? "bg-teal-600" : "bg-zinc-300 dark:bg-zinc-700"
                }`}
              >
                <div
                  className={`w-3.5 h-3.5 rounded-full bg-white transition-transform absolute top-0.5 ${
                    settings.alwaysOnTop ? "translate-x-4.5" : "translate-x-1"
                  }`}
                />
              </button>
            </div>

            <div className="p-2.5 flex items-center justify-between">
              <span className="text-zinc-700 dark:text-zinc-300">{t("collapseOnBlur")}</span>
              <button
                type="button"
                onClick={() => updateCollapseOnBlur(!settings.collapseWhenClickingOutside)}
                className={`w-9 h-5 rounded-full transition-colors relative cursor-pointer ${
                  settings.collapseWhenClickingOutside ? "bg-teal-600" : "bg-zinc-300 dark:bg-zinc-700"
                }`}
              >
                <div
                  className={`w-3.5 h-3.5 rounded-full bg-white transition-transform absolute top-0.5 ${
                    settings.collapseWhenClickingOutside ? "translate-x-4.5" : "translate-x-1"
                  }`}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Startup Section */}
        <div className="space-y-2">
          <span className="text-[11px] font-semibold text-zinc-400 uppercase tracking-wider block">
            {t("startup")}
          </span>
          <div className="bg-white/60 dark:bg-zinc-800/60 rounded-xl border border-black/[0.06] dark:border-white/[0.06] p-2.5 flex items-center justify-between">
            <span className="text-zinc-700 dark:text-zinc-300">{t("openAtLogin")}</span>
            <button
              type="button"
              onClick={handleToggleAutostart}
              className={`w-9 h-5 rounded-full transition-colors relative cursor-pointer ${
                autostart ? "bg-teal-600" : "bg-zinc-300 dark:bg-zinc-700"
              }`}
            >
              <div
                className={`w-3.5 h-3.5 rounded-full bg-white transition-transform absolute top-0.5 ${
                  autostart ? "translate-x-4.5" : "translate-x-1"
                }`}
              />
            </button>
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

        {/* Version & About */}
        <div className="text-center pt-2 text-[10px] text-zinc-400 space-y-0.5">
          <p>Floatick v0.4.0 (Tauri + React)</p>
          <p>Local-first Menu Bar Todos & Notes</p>
        </div>
      </div>
    </div>
  );
};
