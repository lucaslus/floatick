pub mod commands;
pub mod models;
mod panel;
pub mod storage;
pub mod tray;
mod updates;
mod desktop_theme;

use tauri::{Manager, WindowEvent};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // GTK must choose its backend before any toolkit or worker threads start.
    // Hyprland's native Wayland backend cannot honor absolute panel positions.
    #[cfg(target_os = "linux")]
    if std::env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some()
        && std::env::var_os("DISPLAY").is_some()
    {
        // Omarchy may export GDK_BACKEND=wayland globally. Use an app-specific
        // override so launching from the menu and autostart behave identically.
        let backend = std::env::var_os("FLOATICK_GDK_BACKEND")
            .unwrap_or_else(|| "x11".into());
        std::env::set_var("GDK_BACKEND", backend);
    }

    let builder = tauri::Builder::default();
    #[cfg(target_os = "linux")]
    let builder = builder.plugin(tauri_plugin_single_instance::init(|app, args, _cwd| {
        if !args.iter().any(|arg| arg == "--autostart") {
            tray::show_window(app);
        }
    }));
    #[cfg(target_os = "macos")]
    let builder = builder.plugin(tauri_plugin_sparkle_updater::init());
    builder
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

            // Setup the desktop system tray
            tray::setup_tray(app.handle())?;

            // Blur / Click-outside handling & initial window position
            if let Some(window) = app.get_webview_window("main") {
                if panel::uses_system_window_frame() {
                    window.set_decorations(true)?;
                }
                let is_autostart = std::env::args().any(|arg| arg == "--autostart");
                if !is_autostart {
                    let app_handle = app.handle().clone();
                    std::thread::spawn(move || {
                        std::thread::sleep(std::time::Duration::from_millis(120));
                        let h = app_handle.clone();
                        let _ = app_handle.run_on_main_thread(move || {
                            tray::show_window(&h);
                        });
                    });
                }

                let w_clone = window.clone();
                window.on_window_event(move |event| {
                    match event {
                        WindowEvent::Focused(focused) => panel::on_focus_changed(&w_clone, *focused),
                        #[cfg(target_os = "linux")]
                        WindowEvent::CloseRequested { api, .. } => {
                            api.prevent_close();
                            let _ = panel::hide_window(&w_clone);
                        }
                        _ => {}
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
            commands::uses_system_window_frame,
            desktop_theme::get_omarchy_theme,
            commands::hide_window,
            commands::toggle_window,
            commands::set_always_on_top,
            commands::is_autostart_enabled,
            commands::set_autostart_enabled,
            commands::update_tray_count,
            commands::quit_app,
            updates::get_update_settings,
            updates::check_for_updates,
            updates::set_automatically_checks_for_updates,
        ])
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|_app_handle, _event| {
            #[cfg(target_os = "macos")]
            if let tauri::RunEvent::Reopen { .. } = _event {
                log::info!(target: "floatick::panel", "reopen");
                tray::show_window(_app_handle);
            }
        });
}
