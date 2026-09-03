use tauri::{
    menu::{Menu, MenuItem, PredefinedMenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, LogicalPosition, LogicalSize, Manager, Position, Rect,
};

pub fn setup_tray(app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let show_item = MenuItem::with_id(app, "show", "显示 Floatick", true, None::<&str>)?;
    let quit_item = MenuItem::with_id(app, "quit", "退出 Floatick", true, None::<&str>)?;
    let sep = PredefinedMenuItem::separator(app)?;

    let menu = Menu::with_items(app, &[&show_item, &sep, &quit_item])?;

    let _tray = TrayIconBuilder::new()
        .icon(app.default_window_icon().cloned().unwrap())
        .menu(&menu)
        .show_menu_on_left_click(false)
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
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                rect,
                ..
            } = event
            {
                let app_handle = tray.app_handle();
                toggle_window_at_rect(app_handle, rect);
            }
        })
        .build(app)?;

    Ok(())
}

pub fn toggle_window_at_rect(app_handle: &AppHandle, rect: Rect) {
    if let Some(window) = app_handle.get_webview_window("main") {
        let is_visible = window.is_visible().unwrap_or(false);
        if is_visible {
            let _ = window.hide();
        } else {
            crate::mark_window_shown();
            // Position window below the tray icon using logical points
            let scale_factor = window.scale_factor().unwrap_or(2.0);
            let window_logical_size = window
                .outer_size()
                .map(|s| s.to_logical::<f64>(scale_factor))
                .unwrap_or(LogicalSize::new(440.0, 700.0));
            let window_width = window_logical_size.width;

            let tray_pos = rect.position.to_logical::<f64>(scale_factor);
            let tray_size = rect.size.to_logical::<f64>(scale_factor);

            let tray_center_x = tray_pos.x + (tray_size.width / 2.0);
            let mut window_x = tray_center_x - (window_width / 2.0);
            let window_y = tray_pos.y + tray_size.height + 6.0;

            if let Ok(Some(monitor)) = window.current_monitor() {
                let mon_scale = monitor.scale_factor();
                let mon_pos = monitor.position().to_logical::<f64>(mon_scale);
                let mon_size = monitor.size().to_logical::<f64>(mon_scale);
                let min_x = mon_pos.x + 8.0;
                let max_x = mon_pos.x + mon_size.width - window_width - 8.0;
                window_x = window_x.clamp(min_x, max_x);
            }

            let _ = window.set_position(Position::Logical(LogicalPosition::new(window_x, window_y)));
            let _ = window.show();
            let _ = window.set_focus();
        }
    }
}

pub fn show_window(app_handle: &AppHandle) {
    if let Some(window) = app_handle.get_webview_window("main") {
        crate::mark_window_shown();
        if let Ok(Some(monitor)) = window.primary_monitor().or_else(|_| window.current_monitor()) {
            let scale = monitor.scale_factor();
            let mon_pos = monitor.position().to_logical::<f64>(scale);
            let mon_size = monitor.size().to_logical::<f64>(scale);
            let window_width = 440.0;
            let window_x = mon_pos.x + mon_size.width - window_width - 20.0;
            let window_y = mon_pos.y + 36.0;
            let _ = window.set_position(Position::Logical(LogicalPosition::new(window_x, window_y)));
        }
        let _ = window.show();
        let _ = window.set_focus();
    }
}
