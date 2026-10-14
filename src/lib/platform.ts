export const isMac = /Mac|iPhone|iPad/.test(navigator.platform);
export const shortcutLabel = (label: string) =>
  isMac ? label : label.replaceAll("⌘", "Ctrl+").replaceAll("⇧", "Shift+");

// Keep Super/Win available to the Linux desktop, including Omarchy.
export const isPrimaryShortcut = (event: {
  metaKey: boolean;
  ctrlKey: boolean;
  altKey: boolean;
  shiftKey: boolean;
}) => !event.altKey && !event.shiftKey && (
  isMac ? event.metaKey && !event.ctrlKey : event.ctrlKey && !event.metaKey
);
