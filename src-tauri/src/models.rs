use serde::{Deserialize, Serialize};
use std::collections::HashMap;

fn default_true() -> bool {
    true
}

fn default_system() -> String {
    "system".to_string()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TodoItem {
    pub id: String,
    pub title: String,
    #[serde(default)]
    pub content: String,
    pub created_at: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub started_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub completed_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub archived_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub due_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reminder_at: Option<String>,
    #[serde(default = "default_true")]
    pub notify_at_deadline: bool,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub deadline_notified_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reminder_notified_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub snoozed_until: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TodoTag {
    pub id: String,
    pub name: String,
    pub color_hex: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TagWorkspace {
    pub version: u32,
    pub tags: Vec<TodoTag>,
    pub assignments: HashMap<String, Vec<String>>,
}

impl Default for TagWorkspace {
    fn default() -> Self {
        Self {
            version: 1,
            tags: Vec::new(),
            assignments: HashMap::new(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NoteItem {
    pub id: String,
    pub title: String,
    #[serde(default)]
    pub content: String,
    pub created_at: String,
    pub updated_at: String,
    #[serde(default)]
    pub tag_ids: Vec<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub pinned_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub archived_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AppSettings {
    #[serde(default = "default_system")]
    pub theme: String,
    #[serde(default = "default_system")]
    pub language: String,
    #[serde(default = "default_true")]
    pub always_on_top: bool,
    #[serde(default = "default_true")]
    pub collapse_when_clicking_outside: bool,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            theme: default_system(),
            language: default_system(),
            always_on_top: true,
            collapse_when_clicking_outside: true,
        }
    }
}
