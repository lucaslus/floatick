use tauri::{AppHandle, Manager};
use tauri_plugin_autostart::ManagerExt;

use crate::models::{AppSettings, NoteItem, TagWorkspace, TodoItem};
use crate::storage;

#[tauri::command]
pub fn get_todos() -> Result<Vec<TodoItem>, String> {
    storage::load_todos()
}

#[tauri::command]
pub fn save_todos(app_handle: AppHandle, todos: Vec<TodoItem>) -> Result<(), String> {
    let active_count = todos
        .iter()
        .filter(|t| t.completed_at.is_none() && t.archived_at.is_none())
        .count();
    crate::tray::update_tray_todo_count(&app_handle, active_count);
    storage::save_todos(&todos)
}

#[tauri::command]
pub fn update_tray_count(app_handle: AppHandle, count: usize) {
    crate::tray::update_tray_todo_count(&app_handle, count);
}

#[tauri::command]
pub fn get_tags() -> Result<TagWorkspace, String> {
    storage::load_tags()
}

#[tauri::command]
pub fn save_tags(workspace: TagWorkspace) -> Result<(), String> {
    storage::save_tags(&workspace)
}

#[tauri::command]
pub fn get_notes() -> Result<Vec<NoteItem>, String> {
    storage::load_notes()
}

#[tauri::command]
pub fn save_notes(notes: Vec<NoteItem>) -> Result<(), String> {
    storage::save_notes(&notes)
}

#[tauri::command]
pub fn get_settings() -> Result<AppSettings, String> {
    storage::load_settings()
}

#[tauri::command]
pub fn save_settings(settings: AppSettings) -> Result<(), String> {
    storage::save_settings(&settings)
}

#[tauri::command]
pub fn hide_window(app_handle: AppHandle) -> Result<(), String> {
    if let Some(window) = app_handle.get_webview_window("main") {
        crate::panel::hide_window(&window).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
pub fn toggle_window(app_handle: AppHandle) -> Result<(), String> {
    if let Some(window) = app_handle.get_webview_window("main") {
        if window.is_visible().unwrap_or(false) {
            crate::panel::hide_window(&window).map_err(|e| e.to_string())?;
        } else {
            crate::tray::show_window(&app_handle);
        }
    }
    Ok(())
}

#[tauri::command]
pub fn set_always_on_top(app_handle: AppHandle, always_on_top: bool) -> Result<(), String> {
    if let Some(window) = app_handle.get_webview_window("main") {
        window.set_always_on_top(always_on_top).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
pub fn is_autostart_enabled(app_handle: AppHandle) -> Result<bool, String> {
    app_handle
        .autolaunch()
        .is_enabled()
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn set_autostart_enabled(app_handle: AppHandle, enabled: bool) -> Result<(), String> {
    let autolaunch = app_handle.autolaunch();
    if enabled {
        autolaunch.enable().map_err(|e| e.to_string())?;
    } else {
        autolaunch.disable().map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
pub fn quit_app(app_handle: AppHandle) {
    app_handle.exit(0);
}
