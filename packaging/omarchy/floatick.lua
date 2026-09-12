-- Omarchy / Hyprland >= 0.55. Load after Omarchy defaults.
-- The XWayland class is set by GTK to the application executable name.
o.window({ class = "^(floatick|Floatick|io.github.lucaslushuo.floatick)$" }, {
  float = true,
  -- Pinned XWayland windows cover Fcitx candidate popups on Hyprland.
  pin = false,
  -- Inherit Omarchy border colors, width, rounding, opacity and shadow.
  center = true,
})
