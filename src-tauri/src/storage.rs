use std::fs::{self, File};
use std::io::Write;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::models::{AppSettings, NoteItem, TagWorkspace, TodoItem};

const ROOT_DIR_NAME: &str = ".floatick";
const TODOS_FILE: &str = "todos.json";
const TAGS_FILE: &str = "tags.json";
const NOTES_FILE: &str = "notes.json";
const SETTINGS_FILE: &str = "settings.json";

pub fn get_storage_dir() -> Result<PathBuf, String> {
    let home = dirs::home_dir().ok_or_else(|| "Could not locate home directory".to_string())?;
    let path = home.join(ROOT_DIR_NAME);
    if !path.exists() {
        fs::create_dir_all(&path).map_err(|e| format!("Failed to create storage directory: {e}"))?;
    }
    Ok(path)
}

fn atomic_save<T: serde::Serialize>(file_name: &str, data: &T) -> Result<(), String> {
    let dir = get_storage_dir()?;
    let target_path = dir.join(file_name);

    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_micros())
        .unwrap_or(0);
    let tmp_path = dir.join(format!("{}.tmp-{}", file_name, ts));

    let json_bytes = serde_json::to_vec_pretty(data)
        .map_err(|e| format!("Serialization error for {file_name}: {e}"))?;

    {
        let mut file = File::create(&tmp_path)
            .map_err(|e| format!("Failed to create temp file {tmp_path:?}: {e}"))?;
        file.write_all(&json_bytes)
            .map_err(|e| format!("Failed to write to temp file: {e}"))?;
        file.sync_all()
            .map_err(|e| format!("Failed to sync temp file: {e}"))?;
    }

    fs::rename(&tmp_path, &target_path)
        .map_err(|e| format!("Failed to rename temp file to target {target_path:?}: {e}"))?;

    Ok(())
}

pub fn load_todos() -> Result<Vec<TodoItem>, String> {
    let dir = get_storage_dir()?;
    let path = dir.join(TODOS_FILE);
    if !path.exists() {
        return Ok(Vec::new());
    }
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Failed to read {TODOS_FILE}: {e}"))?;
    let items: Vec<TodoItem> = serde_json::from_str(&content)
        .map_err(|e| format!("Failed to parse {TODOS_FILE}: {e}"))?;
    Ok(items)
}

pub fn save_todos(todos: &[TodoItem]) -> Result<(), String> {
    atomic_save(TODOS_FILE, &todos)
}

pub fn load_tags() -> Result<TagWorkspace, String> {
    let dir = get_storage_dir()?;
    let path = dir.join(TAGS_FILE);
    if !path.exists() {
        return Ok(TagWorkspace::default());
    }
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Failed to read {TAGS_FILE}: {e}"))?;
    let workspace: TagWorkspace = serde_json::from_str(&content)
        .map_err(|e| format!("Failed to parse {TAGS_FILE}: {e}"))?;
    Ok(workspace)
}

pub fn save_tags(workspace: &TagWorkspace) -> Result<(), String> {
    atomic_save(TAGS_FILE, workspace)
}

pub fn load_notes() -> Result<Vec<NoteItem>, String> {
    let dir = get_storage_dir()?;
    let path = dir.join(NOTES_FILE);
    if !path.exists() {
        return Ok(Vec::new());
    }
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Failed to read {NOTES_FILE}: {e}"))?;
    let notes: Vec<NoteItem> = serde_json::from_str(&content)
        .map_err(|e| format!("Failed to parse {NOTES_FILE}: {e}"))?;
    Ok(notes)
}

pub fn save_notes(notes: &[NoteItem]) -> Result<(), String> {
    atomic_save(NOTES_FILE, &notes)
}

pub fn load_settings() -> Result<AppSettings, String> {
    let dir = get_storage_dir()?;
    let path = dir.join(SETTINGS_FILE);
    if !path.exists() {
        return Ok(AppSettings::default());
    }
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Failed to read {SETTINGS_FILE}: {e}"))?;
    let settings: AppSettings = serde_json::from_str(&content)
        .map_err(|e| format!("Failed to parse {SETTINGS_FILE}: {e}"))?;
    Ok(settings)
}

pub fn save_settings(settings: &AppSettings) -> Result<(), String> {
    atomic_save(SETTINGS_FILE, settings)
}
