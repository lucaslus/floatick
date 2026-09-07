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
  const isDark =
    theme === "dark" ||
    (theme === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches);

  // Disable all CSS transitions during theme switch so all elements (header, search bar, buttons, list)
  // switch 100% synchronously in a single atomic frame without any staggered delay or lag.
  root.classList.add("disable-transitions");

  if (isDark) {
    root.classList.add("dark");
    root.classList.remove("light");
  } else {
    root.classList.remove("dark");
    root.classList.add("light");
  }

  // Force reflow to immediately apply theme tokens while transitions are disabled
  void root.offsetHeight;

  // Restore micro-interactions on the next frame for hover/focus states
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      root.classList.remove("disable-transitions");
    });
  });
}

// Reactively respond to OS light/dark changes when following system theme
if (typeof window !== "undefined" && window.matchMedia) {
  const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
  const handleSystemThemeChange = () => {
    const currentTheme = useSettingsStore.getState().settings.theme;
    if (currentTheme === "system") {
      applyTheme("system");
    }
  };
  if (mediaQuery.addEventListener) {
    mediaQuery.addEventListener("change", handleSystemThemeChange);
  } else {
    // Legacy Safari/WebKit fallback
    mediaQuery.addListener(handleSystemThemeChange);
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
