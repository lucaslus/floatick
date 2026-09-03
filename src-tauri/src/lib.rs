pub mod commands;
pub mod models;
pub mod storage;
pub mod tray;

use tauri::{Manager, WindowEvent};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            Some(vec!["--autostart"]),
        ))
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }

            // Setup macOS Menu Bar System Tray
            tray::setup_tray(app.handle())?;

            // Blur / Click-outside handling & initial window position
            if let Some(window) = app.get_webview_window("main") {
                let is_autostart = std::env::args().any(|arg| arg == "--autostart");
                if !is_autostart {
                    if let Ok(Some(monitor)) = window.primary_monitor() {
                        let mon_pos = monitor.position();
                        let mon_size = monitor.size();
                        let window_width = 380;
                        let window_x = mon_pos.x + mon_size.width as i32 - window_width - 24;
                        let window_y = mon_pos.y + 36;
                        let _ = window.set_position(tauri::Position::Physical(tauri::PhysicalPosition::new(window_x, window_y)));
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                }

                let w_clone = window.clone();
                window.on_window_event(move |event| {
                    if let WindowEvent::Focused(false) = event {
                        // Check if user enabled collapse on click outside
                        let collapse = storage::load_settings()
                            .map(|s| s.collapse_when_clicking_outside)
                            .unwrap_or(true);
                        if collapse {
                            let _ = w_clone.hide();
                        }
                    }
                });
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::get_todos,
            commands::save_todos,
            commands::get_tags,
            commands::save_tags,
            commands::get_notes,
            commands::save_notes,
            commands::get_settings,
            commands::save_settings,
            commands::hide_window,
            commands::toggle_window,
            commands::set_always_on_top,
            commands::is_autostart_enabled,
            commands::set_autostart_enabled,
            commands::quit_app,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
