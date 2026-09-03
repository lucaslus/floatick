import { create } from "zustand";
import type { AppSettings, ThemePreference, LanguagePreference } from "@/types";
import { api } from "@/lib/api";
import i18n from "@/i18n";

interface SettingsState {
  settings: AppSettings;
  isLoaded: boolean;
  loadSettings: () => Promise<void>;
  updateTheme: (theme: ThemePreference) => Promise<void>;
  updateLanguage: (language: LanguagePreference) => Promise<void>;
  updateAlwaysOnTop: (alwaysOnTop: boolean) => Promise<void>;
  updateCollapseOnBlur: (collapse: boolean) => Promise<void>;
}

const defaultSettings: AppSettings = {
  theme: "system",
  language: "system",
  alwaysOnTop: true,
  collapseWhenClickingOutside: true,
};

function applyTheme(theme: ThemePreference) {
  const root = document.documentElement;
  if (theme === "dark") {
    root.classList.add("dark");
  } else if (theme === "light") {
    root.classList.remove("dark");
  } else {
    const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    if (isDark) {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
  }
}

function applyLanguage(lang: LanguagePreference) {
  if (lang === "system") {
    const sysLang = navigator.language.toLowerCase().startsWith("zh") ? "zh" : "en";
    i18n.changeLanguage(sysLang);
  } else {
    i18n.changeLanguage(lang);
  }
}

export const useSettingsStore = create<SettingsState>((set, get) => ({
  settings: defaultSettings,
  isLoaded: false,

  loadSettings: async () => {
    try {
      const data = await api.getSettings();
      const current = { ...defaultSettings, ...data };
      set({ settings: current, isLoaded: true });
      applyTheme(current.theme);
      applyLanguage(current.language);
      await api.setAlwaysOnTop(current.alwaysOnTop);
    } catch {
      set({ isLoaded: true });
      applyTheme(defaultSettings.theme);
      applyLanguage(defaultSettings.language);
    }
  },

  updateTheme: async (theme: ThemePreference) => {
    const next = { ...get().settings, theme };
    set({ settings: next });
    applyTheme(theme);
    await api.saveSettings(next);
  },

  updateLanguage: async (language: LanguagePreference) => {
    const next = { ...get().settings, language };
    set({ settings: next });
    applyLanguage(language);
    await api.saveSettings(next);
  },

  updateAlwaysOnTop: async (alwaysOnTop: boolean) => {
    const next = { ...get().settings, alwaysOnTop };
    set({ settings: next });
    await api.setAlwaysOnTop(alwaysOnTop);
    await api.saveSettings(next);
  },

  updateCollapseOnBlur: async (collapseWhenClickingOutside: boolean) => {
    const next = { ...get().settings, collapseWhenClickingOutside };
    set({ settings: next });
    await api.saveSettings(next);
  },
}));
