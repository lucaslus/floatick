pub mod commands;
pub mod models;
pub mod storage;
pub mod tray;

use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};
use tauri::{Manager, WindowEvent};

fn current_time_millis() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

pub static LAST_SHOWN_MILLIS: AtomicU64 = AtomicU64::new(0);

pub fn mark_window_shown() {
    LAST_SHOWN_MILLIS.store(current_time_millis(), Ordering::SeqCst);
}

pub fn is_window_recently_shown(threshold_ms: u64) -> bool {
    let last = LAST_SHOWN_MILLIS.load(Ordering::SeqCst);
    current_time_millis().saturating_sub(last) < threshold_ms
}

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
                    tray::show_window(app.handle());
                }

                let w_clone = window.clone();
                window.on_window_event(move |event| {
                    if let WindowEvent::Focused(false) = event {
                        if is_window_recently_shown(1000) {
                            return;
                        }
                        let collapse = storage::load_settings()
                            .map(|s| s.collapse_when_clicking_outside)
                            .unwrap_or(true);
                        if collapse {
                            let w_clone2 = w_clone.clone();
                            std::thread::spawn(move || {
                                std::thread::sleep(std::time::Duration::from_millis(200));
                                if is_window_recently_shown(1000) {
                                    return;
                                }
                                if let Ok(false) = w_clone2.is_focused() {
                                    let _ = w_clone2.hide();
                                }
                            });
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
            commands::update_tray_count,
            commands::quit_app,
        ])
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|app_handle, event| {
            if let tauri::RunEvent::Reopen { .. } = event {
                tray::show_window(app_handle);
            }
        });
}
