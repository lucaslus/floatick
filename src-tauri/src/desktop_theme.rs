use serde::Serialize;
use std::collections::BTreeMap;

#[derive(Debug, Serialize, PartialEq)]
pub struct DesktopTheme {
    colors: BTreeMap<String, String>,
    mode: Option<String>,
}

fn parse_theme(source: &str) -> Option<DesktopTheme> {
    let values: BTreeMap<String, toml::Value> = toml::from_str(source).ok()?;
    let mut colors = BTreeMap::new();
    for key in ["background", "foreground", "accent", "selection", "muted"] {
        if let Some(value) = values.get(key).and_then(|v| v.as_str()) {
            if value.len() == 7 && value.starts_with('#')
                && value[1..].bytes().all(|c| c.is_ascii_hexdigit()) {
                colors.insert(key.to_string(), value.to_string());
            }
        }
    }
    if !["background", "foreground", "accent"].iter().all(|key| colors.contains_key(*key)) {
        return None;
    }
    let mode = values.get("mode").and_then(|v| v.as_str())
        .filter(|m| matches!(*m, "dark" | "light")).map(String::from);
    Some(DesktopTheme { colors, mode })
}

/// Read only Omarchy's active palette, including older config-dir installations.
#[tauri::command]
pub fn get_omarchy_theme() -> Option<DesktopTheme> {
    #[cfg(target_os = "linux")]
    {
        for base in [dirs::state_dir(), dirs::config_dir()].into_iter().flatten() {
            let path = base.join("omarchy/current/theme/colors.toml");
            if path.is_file() {
                return std::fs::read_to_string(path).ok().and_then(|s| parse_theme(&s));
            }
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn supports_dark_light_and_legacy_palettes() {
        for mode in ["mode = 'dark'", "mode = 'light'", ""] {
            let theme = parse_theme(&format!("{mode}\nbackground='#121212'\nforeground='#bebebe'\naccent='#e68e0d'\nselection='#333333'\n")).unwrap();
            assert_eq!(theme.colors["accent"], "#e68e0d");
            assert_eq!(theme.mode.is_some(), !mode.is_empty());
        }
    }
    #[test]
    fn rejects_missing_invalid_and_css_injection_values() {
        for source in ["", "background = 42", "background='#121212'\nforeground='#ffffff'\naccent='red; background: url(x)'", "background='#121212'\nforeground='#ffffff'\naccent='#zzzzzz'"] {
            assert!(parse_theme(source).is_none());
        }
    }
}
