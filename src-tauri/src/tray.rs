use tauri::{
    menu::{Menu, MenuItem, PredefinedMenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, LogicalPosition, Manager, Position, Rect,
};

// Linux tray-icon uses this ID in a shared runtime icon directory.
// Keep it application-specific to avoid collisions with other Tauri apps.
const TRAY_ID: &str = "io.github.lucaslushuo.floatick.tray";

pub fn setup_tray(app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let show_item = MenuItem::with_id(app, "show", "显示 Floatick", true, None::<&str>)?;
    let quit_item = MenuItem::with_id(app, "quit", "退出 Floatick", true, None::<&str>)?;
    let sep = PredefinedMenuItem::separator(app)?;

    let menu = Menu::with_items(app, &[&show_item, &sep, &quit_item])?;

    #[cfg(target_os = "macos")]
    let tray_icon = tauri::image::Image::from_bytes(include_bytes!("../icons/tray-icon@2x.png"))?;
    #[cfg(not(target_os = "macos"))]
    let tray_icon = tauri::image::Image::from_bytes(include_bytes!("../icons/32x32.png"))?;

    let initial_count = crate::storage::load_todos()
        .map(|todos| {
            todos
                .iter()
                .filter(|t| t.completed_at.is_none() && t.archived_at.is_none())
                .count()
        })
        .unwrap_or(0);

    let title_str = if initial_count > 0 {
        format!(" {}", if initial_count > 99 { "99+".to_string() } else { initial_count.to_string() })
    } else {
        "".to_string()
    };

    let _tray = TrayIconBuilder::with_id(TRAY_ID)
        .icon(tray_icon)
        .icon_as_template(cfg!(target_os = "macos"))
        .title(title_str)
        .menu(&menu)
        .show_menu_on_left_click(cfg!(target_os = "linux"))
        .tooltip("Floatick")
        .on_menu_event(|app_handle, event| match event.id.as_ref() {
            "show" => {
                show_window(app_handle);
            }
            "quit" => {
                app_handle.exit(0);
            }
            _ => {}
        })
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click { button, button_state, .. } = &event {
                log::info!(target: "floatick::panel", "tray: {button:?} {button_state:?}");
            }
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state,
                rect,
                ..
            } = event
            {
                let app_handle = tray.app_handle();
                match button_state {
                    MouseButtonState::Down => {
                        update_cached_tray_rect(rect);
                        if let Some(window) = app_handle.get_webview_window("main") {
                            crate::panel::tray_pressed(window.is_visible().unwrap_or(false));
                        }
                    }
                    MouseButtonState::Up => toggle_window_at_rect(app_handle, rect),
                }
            }
        })
        .build(app)?;

    Ok(())
}

use std::sync::RwLock;

static LAST_TRAY_RECT: RwLock<Option<Rect>> = RwLock::new(None);

pub fn update_cached_tray_rect(rect: Rect) {
    let size = rect.size.to_logical::<f64>(1.0);
    if size.width > 0.0 && size.height > 0.0 {
        if let Ok(mut guard) = LAST_TRAY_RECT.write() {
            *guard = Some(rect);
        }
    }
}

pub fn get_cached_tray_rect() -> Option<Rect> {
    LAST_TRAY_RECT.read().ok().and_then(|guard| *guard)
}

pub fn find_monitor_for_rect(window: &tauri::WebviewWindow, rect: &Rect) -> Option<tauri::Monitor> {
    let monitors = window.available_monitors().ok()?;
    if monitors.is_empty() {
        return None;
    }
    if monitors.len() == 1 {
        return monitors.into_iter().next();
    }

    // Pass 1: 2D check evaluating each monitor with its own scale factor
    for m in &monitors {
        let scale = m.scale_factor();
        let mon_pos = m.position().to_logical::<f64>(scale);
        let mon_size = m.size().to_logical::<f64>(scale);
        let tray_pos = rect.position.to_logical::<f64>(scale);
        let tray_size = rect.size.to_logical::<f64>(scale);

        let tray_center_x = tray_pos.x + (tray_size.width / 2.0);
        let tray_center_y = tray_pos.y + (tray_size.height / 2.0);

        let in_x = tray_center_x >= (mon_pos.x - 4.0) && tray_center_x <= (mon_pos.x + mon_size.width + 4.0);
        let in_y = tray_center_y >= (mon_pos.y - 100.0) && tray_center_y <= (mon_pos.y + mon_size.height + 50.0);

        if in_x && in_y {
            return Some(m.clone());
        }
    }

    // Pass 2: Horizontal span check
    for m in &monitors {
        let scale = m.scale_factor();
        let mon_pos = m.position().to_logical::<f64>(scale);
        let mon_size = m.size().to_logical::<f64>(scale);
        let tray_pos = rect.position.to_logical::<f64>(scale);
        let tray_size = rect.size.to_logical::<f64>(scale);

        let tray_center_x = tray_pos.x + (tray_size.width / 2.0);
        if tray_center_x >= mon_pos.x && tray_center_x <= (mon_pos.x + mon_size.width) {
            return Some(m.clone());
        }
    }

    // Pass 3: Closest monitor center
    let mut best_monitor = None;
    let mut min_dist_sq = f64::MAX;
    for m in &monitors {
        let scale = m.scale_factor();
        let mon_pos = m.position().to_logical::<f64>(scale);
        let mon_size = m.size().to_logical::<f64>(scale);
        let tray_pos = rect.position.to_logical::<f64>(scale);

        let mon_center_x = mon_pos.x + (mon_size.width / 2.0);
        let mon_center_y = mon_pos.y + (mon_size.height / 2.0);
        let dx = tray_pos.x - mon_center_x;
        let dy = tray_pos.y - mon_center_y;
        let dist_sq = dx * dx + dy * dy;
        if dist_sq < min_dist_sq {
            min_dist_sq = dist_sq;
            best_monitor = Some(m.clone());
        }
    }

    best_monitor.or_else(|| window.primary_monitor().ok().flatten())
}

pub fn position_window_at_rect(window: &tauri::WebviewWindow, rect: Rect) {
    update_cached_tray_rect(rect);

    let target_monitor = find_monitor_for_rect(window, &rect)
        .or_else(|| window.primary_monitor().ok().flatten())
        .or_else(|| window.current_monitor().ok().flatten());

    let scale_factor = target_monitor
        .as_ref()
        .map(|m| m.scale_factor())
        .unwrap_or_else(|| window.scale_factor().unwrap_or(2.0));

    let window_width = 440.0;
    let window_height = 700.0;

    let tray_pos = rect.position.to_logical::<f64>(scale_factor);
    let tray_size = rect.size.to_logical::<f64>(scale_factor);

    let tray_center_x = tray_pos.x + (tray_size.width / 2.0);
    let mut window_x = tray_center_x - (window_width / 2.0);
    let mut window_y = if tray_size.height > 0.0 {
        tray_pos.y + tray_size.height + 4.0
    } else {
        36.0
    };

    if let Some(monitor) = target_monitor {
        let mon_scale = monitor.scale_factor();
        let mon_pos = monitor.position().to_logical::<f64>(mon_scale);
        let mon_size = monitor.size().to_logical::<f64>(mon_scale);

        let min_x = mon_pos.x + 8.0;
        let max_x = mon_pos.x + mon_size.width - window_width - 8.0;
        window_x = window_x.clamp(min_x, max_x.max(min_x));

        if tray_size.height > 0.0 {
            let min_y = mon_pos.y + 8.0;
            let max_y = mon_pos.y + mon_size.height - window_height - 8.0;
            window_y = window_y.clamp(min_y, max_y.max(min_y));
        } else {
            window_y = mon_pos.y + 36.0;
        }
    }

    let _ = window.set_position(Position::Logical(LogicalPosition::new(window_x, window_y)));
}

pub fn toggle_window_at_rect(app_handle: &AppHandle, rect: Rect) {
    if let Some(window) = app_handle.get_webview_window("main") {
        let is_visible = window.is_visible().unwrap_or(false);
        let action = crate::panel::tray_released(is_visible);
        log::info!(target: "floatick::panel", "tray action: {action:?}, visible={is_visible}");
        match action {
            crate::panel::TrayAction::Hide => {
                let _ = crate::panel::hide_window(&window);
            }
            crate::panel::TrayAction::Show => {
                crate::panel::cancel_pending_hide();
                position_window_at_rect(&window, rect);
                let _ = window.show();
                let _ = window.set_focus();
            }
        }
    }
}

pub fn show_window(app_handle: &AppHandle) {
    log::info!(target: "floatick::panel", "show requested");
    if let Some(window) = app_handle.get_webview_window("main") {
        crate::panel::cancel_pending_hide();

        #[cfg(target_os = "linux")]
        if std::env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some() {
            // Let the compositor's Floatick rule position the panel. XWayland
            // coordinates differ from monitor logical coordinates at fractional
            // scales; applying GTK positions here can move it to another screen.
            let _ = window.show();
            let _ = window.set_focus();
            return;
        }

        let mut positioned = false;
        if let Some(tray) = app_handle.tray_by_id(TRAY_ID) {
            if let Ok(Some(rect)) = tray.rect() {
                let size = rect.size.to_logical::<f64>(1.0);
                if size.width > 0.0 && size.height > 0.0 {
                    position_window_at_rect(&window, rect);
                    positioned = true;
                }
            }
        }

        if !positioned {
            if let Some(cached_rect) = get_cached_tray_rect() {
                position_window_at_rect(&window, cached_rect);
                positioned = true;
            }
        }

        if !positioned {
            if let Ok(Some(monitor)) = window.primary_monitor().or_else(|_| window.current_monitor()) {
                let scale = monitor.scale_factor();
                let mon_pos = monitor.position().to_logical::<f64>(scale);
                let mon_size = monitor.size().to_logical::<f64>(scale);
                let window_width = 440.0;
                let window_x = mon_pos.x + mon_size.width - window_width - 20.0;
                let window_y = mon_pos.y + 36.0;
                let _ = window.set_position(Position::Logical(LogicalPosition::new(window_x, window_y)));
            }
        }

        let _ = window.show();
        let _ = window.set_focus();
    }
}

pub fn update_tray_todo_count(app: &AppHandle, count: usize) {
    if let Some(tray) = app.tray_by_id(TRAY_ID) {
        let title_str = if count > 0 {
            format!(" {}", count)
        } else {
            "".to_string()
        };
        let _ = tray.set_title(Some(title_str));
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct MonitorBounds {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

pub fn match_monitor_index(monitors: &[MonitorBounds], tray_center: (f64, f64)) -> Option<usize> {
    if monitors.is_empty() {
        return None;
    }
    if monitors.len() == 1 {
        return Some(0);
    }

    let (cx, cy) = tray_center;

    // Pass 1: 2D check evaluating each monitor with generous margin for menu bar
    for (i, m) in monitors.iter().enumerate() {
        let in_x = cx >= (m.x - 4.0) && cx <= (m.x + m.width + 4.0);
        let in_y = cy >= (m.y - 100.0) && cy <= (m.y + m.height + 50.0);
        if in_x && in_y {
            return Some(i);
        }
    }

    // Pass 2: Horizontal span check
    for (i, m) in monitors.iter().enumerate() {
        if cx >= m.x && cx <= (m.x + m.width) {
            return Some(i);
        }
    }

    // Pass 3: Closest monitor center
    let mut best = 0;
    let mut min_dist_sq = f64::MAX;
    for (i, m) in monitors.iter().enumerate() {
        let mcx = m.x + (m.width / 2.0);
        let mcy = m.y + (m.height / 2.0);
        let dist_sq = (cx - mcx).powi(2) + (cy - mcy).powi(2);
        if dist_sq < min_dist_sq {
            min_dist_sq = dist_sq;
            best = i;
        }
    }
    Some(best)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_single_monitor() {
        let monitors = vec![MonitorBounds {
            x: 0.0,
            y: 0.0,
            width: 1920.0,
            height: 1080.0,
        }];
        assert_eq!(match_monitor_index(&monitors, (1500.0, 15.0)), Some(0));
    }

    #[test]
    fn test_dual_monitor_left_vertical_right_horizontal() {
        // User's multi-monitor setup:
        // Screen 0 (Main/Right): (0, 0, 1920, 1080)
        // Screen 1 (Vertical/Left): (-1080, -318, 1080, 1920)
        let monitors = vec![
            MonitorBounds {
                x: 0.0,
                y: 0.0,
                width: 1920.0,
                height: 1080.0,
            },
            MonitorBounds {
                x: -1080.0,
                y: -318.0,
                width: 1080.0,
                height: 1920.0,
            },
        ];

        // Click on right screen tray icon
        assert_eq!(match_monitor_index(&monitors, (1639.5, 15.0)), Some(0));

        // Click on left screen tray icon
        assert_eq!(match_monitor_index(&monitors, (-200.0, -300.0)), Some(1));
    }
}
