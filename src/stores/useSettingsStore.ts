import { create } from "zustand";
import type { AppSettings, ThemePreference, LanguagePreference } from "@/types";
import { api } from "@/lib/api";
import i18n from "@/i18n";
import { applyOmarchyPalette, type OmarchyTheme } from "@/lib/omarchyTheme";

let omarchyTheme: OmarchyTheme | null = null;
let refreshingTheme = false;

interface SettingsState {
  settings: AppSettings;
  isLoaded: boolean;
  hasOmarchyTheme: boolean;
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
  root.classList.add("disable-transitions");
  const omarchyDark = applyOmarchyPalette(theme === "system" ? omarchyTheme : null);
  const isDark = omarchyDark ?? (
    theme === "dark" ||
    (theme === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches));

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
  hasOmarchyTheme: false,

  loadSettings: async () => {
    try {
      const [data, palette] = await Promise.all([api.getSettings(), api.getOmarchyTheme().catch(() => null)]);
      omarchyTheme = palette;
      set({ hasOmarchyTheme: palette !== null });
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

// Re-read the active path (Omarchy replaces it on theme changes). No desktop
// hooks or extra daemon are needed. Read only while following system colors.
async function refreshOmarchyTheme() {
  const state = useSettingsStore.getState();
  if (refreshingTheme || !state.isLoaded || state.settings.theme !== "system") return;
  refreshingTheme = true;
  try {
    const next = await api.getOmarchyTheme();
    if (JSON.stringify(next) !== JSON.stringify(omarchyTheme)) {
      omarchyTheme = next;
      useSettingsStore.setState({ hasOmarchyTheme: next !== null });
      applyTheme(useSettingsStore.getState().settings.theme);
    }
  } catch {
    // Keep the last palette during transient IPC failures.
  } finally {
    refreshingTheme = false;
  }
}
if (typeof window !== "undefined" && /Linux/.test(navigator.platform)) {
  window.setInterval(() => { void refreshOmarchyTheme(); }, 2000);
  window.addEventListener("focus", () => { void refreshOmarchyTheme(); });
}
