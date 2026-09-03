use tauri::{
    menu::{Menu, MenuItem, PredefinedMenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Manager, PhysicalPosition, Position, Rect,
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
                if let Some(window) = app_handle.get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
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
            // Position window below the tray icon
            if let Ok(window_size) = window.outer_size() {
                let window_width = window_size.width as i32;
                let tray_pos = rect.position.to_physical::<i32>(1.0);
                let tray_size = rect.size.to_physical::<u32>(1.0);

                let tray_center_x = tray_pos.x + (tray_size.width as i32 / 2);
                let mut window_x = tray_center_x - (window_width / 2);
                let window_y = tray_pos.y + tray_size.height as i32 + 6;

                if let Ok(Some(monitor)) = window.current_monitor() {
                    let mon_pos = monitor.position();
                    let mon_size = monitor.size();
                    let min_x = mon_pos.x + 8;
                    let max_x = mon_pos.x + mon_size.width as i32 - window_width - 8;
                    window_x = window_x.clamp(min_x, max_x);
                }

                let _ = window.set_position(Position::Physical(PhysicalPosition::new(window_x, window_y)));
            }
            let _ = window.show();
            let _ = window.set_focus();
        }
    }
}
