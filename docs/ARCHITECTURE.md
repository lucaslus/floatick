# Architecture

Floatick is a native macOS Menu Bar productivity application built on Tauri v2, Rust, React 19, and Tailwind CSS.

## High-Level Architecture

```text
┌────────────────────────────────────────────────────────┐
│                   React 19 Frontend                    │
│                                                        │
│  Components & UI            State & Domain             │
│  ├── ActionBar              ├── useTodoStore           │
│  ├── TodoList / TodoDrawer  ├── useNoteStore           │
│  ├── NoteList / NoteDrawer  ├── useTagStore            │
│  ├── FloatickTiptapEditor   └── useSettingsStore       │
│  └── Settings / Tag Modals                             │
└───────────────────────────┬────────────────────────────┘
                            │ Tauri IPC (Commands & Events)
┌───────────────────────────▼────────────────────────────┐
│                    Rust Tauri Backend                  │
│                                                        │
│  Window & Tray Management   Storage Engine             │
│  ├── AppKit NSStatusBar     ├── ~/.floatick/           │
│  │   (Live badge counter)   │   ├── todos.json         │
│  ├── Popover Positioning    │   ├── notes.json         │
│  │   (Anchored under tray)  │   ├── tags.json          │
│  └── Blur event listener    │   └── settings.json      │
│      (Auto-hide on click)   └── Atomic tempfile rename │
└───────────────────────────┬────────────────────────────┘
```

## Layers and Responsibilities

### 1. Presentation Layer (React 19 & Tailwind CSS)
- **State Management**: Lightweight Zustand stores (`useTodoStore`, `useNoteStore`, `useTagStore`, `useSettingsStore`) handle in-memory reactive state, filtering (active, completed, archived, tag-based), and fast tag queries.
- **Rich Document Editing**: Built-in **TipTap Markdown Editor** (`FloatickTiptapEditor`) provides interactive checkbox task lists (`TaskList`), code blocks with syntax highlighting, blockquotes, headings, and slash command popup (`/task`, `/h1`-`/h3`, `/code`, `/quote`, `/divider`).
- **Keyboard-First Workflow**: Global keyboard shortcuts (`⌘N`, `⌘F`, `Esc`, `Tab`, `⌘,`, `Enter`) provide fluid interaction without lifting hands from the keyboard.
- **Internationalization**: Localized via `i18next` (`zh-CN` and `en-US`), hot-swappable in Settings.

### 2. IPC & Bridge Layer (`src/services/tauri.ts`)
- Bridges the web view and the Rust core using strongly-typed Tauri v2 commands:
  - `load_todos` / `save_todos`: Fetch and atomically persist todos.
  - `load_notes` / `save_notes`: Fetch and atomically persist notes.
  - `load_tags` / `save_tags`: Fetch and atomically persist user tags.
  - `load_settings` / `save_settings`: Read and persist user preferences.
  - `hide_window`: Programmatically close or collapse the window.
  - `update_tray_badge`: Update the live pending task count in the macOS Menu Bar.

### 3. Native & System Layer (Rust & AppKit)
- **Menu Bar Tray Item (`src-tauri/src/tray.rs`)**:
  - Registered as a macOS `NSStatusBar` item with a template double-checkmark icon.
  - Features dynamic badge text reflecting the count of uncompleted tasks.
- **Window Management (`src-tauri/src/window.rs`)**:
  - Frameless, transparent, 440×700 popover window.
  - Automatically calculates screen bounds and anchors directly beneath the tray icon.
  - Listens to window blur (`on_window_event(WindowEvent::Focused(false))`) to automatically hide when clicking outside if `close_on_blur` is enabled.
- **Atomic Storage Engine (`src-tauri/src/commands/storage.rs`)**:
  - Operates strictly in `~/.floatick/`.
  - Implements atomic write semantics (write to `.tmp` file, sync, then rename) to eliminate any risk of file corruption during system shutdowns or crashes.

## Directory Layout

```text
src/
  components/
    common/         # TipTap editor, slash menu, ActionBar, TagBadge, etc.
    notes/          # NoteList, NoteCard, NoteEditorDrawer
    settings/       # SettingsModal
    tags/           # TagManagerModal, TagFilterBar
    todos/          # TodoList, TodoItem, TodoEditorDrawer, DeadlinePicker
  hooks/            # Keyboard shortcuts, blur handlers, window controls
  i18n/             # Locales (zh.json, en.json)
  services/         # Tauri IPC invocation wrappers
  stores/           # Zustand stores (useTodoStore, useNoteStore, etc.)
  types/            # Domain models (Todo, Note, Tag, Settings)
src-tauri/
  src/
    commands/       # Rust IPC handlers (storage, settings, updates)
    tray.rs         # macOS Menu Bar tray extra & live badge
    window.rs       # Positioning, toggle, blur and window behaviors
    lib.rs          # Tauri app builder and plugin registration
    main.rs         # Desktop entry point
  tauri.conf.json   # Tauri v2 window and security configuration
  Cargo.toml        # Rust dependencies
website/            # Official Astro bilingual marketing website
docs/               # Technical documentation and guides
legacy/             # Archived Flutter implementation
```

## Persistence and Data Flow

1. On application launch, React triggers `load_todos`, `load_notes`, `load_tags`, and `load_settings`.
2. Rust loads and parses JSON files from `~/.floatick/`. If files do not exist, sensible defaults are returned and initialized.
3. Mutations in React update the Zustand store immediately (optimistic UI update).
4. Store subscribers trigger asynchronous debounced saves through Tauri IPC.
5. Rust writes data to temporary files and atomically renames them to `todos.json`, `notes.json`, etc.
6. When todo completion status or count changes, `update_tray_badge` updates the macOS Menu Bar tray text.

## Architecture Guardrails

- **Local-First & Privacy**: Floatick operates strictly locally without remote servers, user tracking, or telemetry. All user data resides in `~/.floatick/`.
- **Zero Heavy Background Processes**: Idle memory consumption should remain under ~40-60 MB thanks to Tauri v2 and Rust.
- **Fail-Safe Persistence**: File writes must always use atomic rename patterns.
- **Platform Integrity**: Window behavior must feel native to macOS (tray anchor, blur-to-dismiss, instant toggle).
