use serde::Serialize;
use tauri::AppHandle;
#[cfg(target_os = "macos")]
use tauri_plugin_sparkle_updater::SparkleUpdaterExt;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateSettings {
    current_version: String,
    available: bool,
    can_check: bool,
    automatically_checks: bool,
    last_checked_at: Option<f64>,
}

#[tauri::command]
pub async fn get_update_settings(app: AppHandle) -> Result<UpdateSettings, String> {
    #[allow(unused_mut)] // Only Sparkle mutates this on macOS.
    let mut settings = UpdateSettings {
        current_version: app.package_info().version.to_string(),
        available: false,
        can_check: false,
        automatically_checks: false,
        last_checked_at: None,
    };
    #[cfg(target_os = "macos")]
    if let Some(updater) = app.sparkle_updater() {
        settings.available = true;
        settings.can_check = updater.can_check_for_updates().map_err(|e| e.to_string())?;
        settings.automatically_checks = updater
            .automatically_checks_for_updates()
            .map_err(|e| e.to_string())?;
        settings.last_checked_at = updater
            .last_update_check_date()
            .map_err(|e| e.to_string())?;
    }
    Ok(settings)
}

#[tauri::command]
pub async fn check_for_updates(_app: AppHandle) -> Result<(), String> {
    #[cfg(target_os = "macos")]
    if let Some(updater) = _app.sparkle_updater() {
        if !updater.can_check_for_updates().map_err(|e| e.to_string())? {
            return Err("update_in_progress".into());
        }
        // Sparkle owns the complete native UI, including errors, download
        // progress, Ed25519 verification, installation and relaunch consent.
        return updater.check_for_updates().map_err(|e| e.to_string());
    }
    Err("updater_unavailable".into())
}

#[tauri::command]
pub async fn set_automatically_checks_for_updates(
    _app: AppHandle,
    enabled: bool,
) -> Result<(), String> {
    #[cfg(not(target_os = "macos"))]
    let _ = enabled;
    #[cfg(target_os = "macos")]
    if let Some(updater) = _app.sparkle_updater() {
        return updater
            .set_automatically_checks_for_updates(enabled)
            .map_err(|e| e.to_string());
    }
    Err("updater_unavailable".into())
}
