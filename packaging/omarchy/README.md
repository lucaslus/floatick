# Omarchy / Arch Linux

Floatick supports a Linux tray menu and uses XWayland by default on Hyprland
when `DISPLAY` is available. This overrides Omarchy’s global `GDK_BACKEND=wayland`; for troubleshooting,
set the app-specific `FLOATICK_GDK_BACKEND=wayland` to opt out. This keeps
GTK's always-on-top requests available. Hyprland rules own panel placement; native Wayland
cannot provide the same positioning behavior. Linux does not emit Tauri tray
click events or expose tray geometry, so **right-click the system tray icon**
and choose **显示 Floatick** (Show Floatick), or launch `floatick` again to show the existing instance.
The panel opens centered on its screen, independently of the tray icon.
Tray count labels depend on the status bar's support.

## Build and install

From this directory in a source checkout:

```sh
# Install build/runtime dependencies first (Omarchy).
omarchy pkg add base-devel rust nodejs pnpm webkit2gtk-4.1 libayatana-appindicator xorg-xwayland
makepkg -si
```

This local PKGBUILD builds the current checkout, including local changes. It is
not an AUR recipe. The result is `floatick-omarchy-*.pkg.tar.zst`. No macOS
Sparkle framework is downloaded on Linux. Updates use a rebuilt package and
`pacman -U`, not Sparkle. The desktop launcher and autostart both run the same
binary; launching twice does not create competing writers to `~/.floatick`.

For development, run `pnpm install --frozen-lockfile` and `pnpm tauri:dev` from
the repository root. To only build a binary, use `pnpm tauri build --no-bundle`.

## Omarchy floating panel rules

For Omarchy with Hyprland **0.55+ and Lua configuration**, add this line after
the Omarchy defaults in `~/.config/hypr/hyprland.lua`:

```lua
dofile("/usr/share/floatick/floatick.lua")
```

Then run `hyprctl reload` and `hyprctl configerrors`. The package provides its
own file under `/usr/share/floatick`; it does not modify Omarchy's files or
rewrite your configuration. The rule centers the floating panel on its screen in the current workspace. It deliberately does not
pin the window across workspaces: Hyprland renders pinned XWayland windows
above Fcitx candidate popups, hiding the candidate list. The outer frame
inherits Omarchy’s border colors, width, rounding, opacity and shadow (square
corners by default). Floatick fills the window without a rounded inset or its
own border; internal controls keep their usual styling. Older Hyprland configurations
need rules matching their version; do not source this Lua file from `.conf`.
Before removing the package, remove the `dofile` line as well.

Optionally bind an unused shortcut in `~/.config/hypr/bindings.lua`:

```lua
-- Check existing bindings before assigning this example shortcut.
o.bind("SUPER + CTRL + SHIFT + F", "Floatick", "floatick")
```

The recommended summon shortcut is **Super+Ctrl+Shift+F**. Check `hyprctl -j binds`
first for personal conflicts. Do not use Super+Shift+F (Omarchy file manager)
or Super+Enter (terminal). The binding launches Floatick or shows its existing
window in the center of the current screen. For a source checkout without an
installed package, replace `floatick` above with the absolute path to
`src-tauri/target/release/floatick`.

Use **Ctrl** instead of **⌘** for in-app shortcuts, including **Ctrl+Enter**
to save todos and notes from either the title or body. Linux does not treat
Super/Win as an application shortcut modifier. Escape and window-manager
close hide the panel; use the tray's **退出 Floatick** or the settings quit
button to exit. Autostart is controlled in Floatick's settings.

## Chinese input (Fcitx5 / Rime)

Install `fcitx5-gtk` when using Fcitx with this GTK application. Floatick uses
its native input-method module; it does not draw the candidate list itself.
Do not add `pin = true` to the Floatick window rule: on Hyprland this can put
the panel above the Fcitx candidate window. Remove an older pin rule and
reopen the panel after reloading Hyprland. Keep `float = true` enabled.
Candidate colors, fonts and spacing are controlled globally by Fcitx, not by
the Floatick UI theme.

## Desktop smoke check

- Launch from the application menu; check the floating panel and tray, with
  square outer corners and the system theme border (default content size: 440×700).
- Hide with Escape, then launch again; the same process should reopen.
- Right-click the tray icon and choose **显示 Floatick**; check focus and
  click-outside collapse.
- Compose Chinese in search, title and body fields. Check that candidates
  appear above the panel, Space/Enter commits a candidate, and Escape cancels
  composition without closing the editor.
- Create and save a todo/note using Ctrl+N and Ctrl+Enter, then relaunch.
- Check both monitors and their scaling; XWayland may be less sharp at
  fractional scales than a native Wayland application.
- Enable autostart and verify after the next login.

References: [Tauri tray limitations](https://v2.tauri.app/learn/system-tray/),
[Hyprland window rules](https://wiki.hypr.land/Configuring/Basics/Window-Rules/).

## Follow the Omarchy theme

In Settings → Appearance, choose **Omarchy** (the system-theme option on
Omarchy). Floatick reads `~/.local/state/omarchy/current/theme/colors.toml`
(respecting `XDG_STATE_HOME`, with the older config-directory path as a fallback).
It follows background, foreground, accent, selection and light/dark mode.
Controls derive their hover/border colors from this palette, and accent buttons
choose a contrasting label color. The outer frame remains managed by Hyprland.

Theme changes are detected within about two seconds while the app is active,
and refreshed on focus. No hook, restart, or changes to Omarchy theme files
are required. Explicit Light/Dark choices keep Floatick's original colors.
Missing or invalid palettes fall back to ordinary system light/dark mode.
