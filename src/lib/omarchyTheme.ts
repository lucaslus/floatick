export interface OmarchyTheme {
  colors: Record<string, string>;
  mode: "dark" | "light" | null;
}

const rgb = (hex: string) => [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16));
const rgba = (hex: string, alpha: number) => `rgba(${rgb(hex).join(", ")}, ${alpha})`;
const mix = (base: string, ink: string, amount: number) => {
  const a = rgb(base), b = rgb(ink);
  return `#${a.map((v, i) => Math.round(v + (b[i] - v) * amount).toString(16).padStart(2, "0")).join("")}`;
};
const luminance = (hex: string) => rgb(hex).map(v => {
  const s = v / 255;
  return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
}).reduce((sum, v, i) => sum + v * [0.2126, 0.7152, 0.0722][i], 0);

export function omarchyTokens(theme: OmarchyTheme) {
  const { background: bg, foreground: fg, accent } = theme.colors;
  const dark = theme.mode ? theme.mode === "dark" : luminance(bg) < luminance(fg);
  const tokens: Record<string, string> = {
    "bg-panel": bg,
    "bg-drawer": mix(bg, fg, 0.035),
    "bg-elevated": mix(bg, fg, 0.07),
    "bg-elevated-hover": mix(bg, fg, 0.13),
    "border-panel": rgba(fg, 0.18),
    "border-drawer": rgba(fg, 0.18),
    "text-primary": fg,
    "text-secondary": mix(bg, fg, 0.82),
    "text-subtle": mix(bg, fg, 0.65),
    "hover-overlay": rgba(fg, 0.08),
    "row-hover": rgba(fg, 0.06),
    "scrollbar-thumb": rgba(fg, 0.25),
    "scrollbar-thumb-hover": rgba(fg, 0.4),
    "teal-primary": accent,
    "teal-tint": rgba(accent, 0.12),
    "teal-tint-active": rgba(accent, 0.22),
    // Choose the higher-contrast label for arbitrary light or dark accents.
    "on-accent": luminance(accent) > 0.179 ? "#000000" : "#ffffff",
    "selection": theme.colors.selection || mix(bg, accent, 0.25),
  };
  return { dark, tokens };
}

let appliedKeys: string[] = [];
export function applyOmarchyPalette(theme: OmarchyTheme | null): boolean | null {
  const root = document.documentElement;
  for (const key of appliedKeys) root.style.removeProperty(`--color-${key}`);
  appliedKeys = [];
  delete root.dataset.omarchyTheme;
  if (!theme) return null;
  const { dark, tokens } = omarchyTokens(theme);
  for (const [key, value] of Object.entries(tokens)) root.style.setProperty(`--color-${key}`, value);
  appliedKeys = Object.keys(tokens);
  root.dataset.omarchyTheme = "true";
  return dark;
}
