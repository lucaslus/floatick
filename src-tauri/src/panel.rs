use std::sync::Mutex;
use std::time::Duration;
use tauri::WebviewWindow;

// Hyprland supplies the outer frame, including Omarchy's square theme border.
pub(crate) fn uses_system_window_frame() -> bool {
    cfg!(target_os = "linux")
        && std::env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some()
}

const BLUR_SETTLE_DELAY: Duration = Duration::from_millis(150);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum TrayAction {
    Show,
    Hide,
}

impl TrayAction {
    fn for_visibility(visible: bool) -> Self {
        if visible {
            Self::Hide
        } else {
            Self::Show
        }
    }
}

#[derive(Default)]
struct PanelState {
    revision: u64,
    tray_action: Option<TrayAction>,
}

impl PanelState {
    fn cancel_pending_hide(&mut self) {
        self.revision = self.revision.wrapping_add(1);
    }

    fn request_blur_hide(&mut self) -> Option<u64> {
        self.cancel_pending_hide();
        // The tray gesture owns visibility until mouse-up, including long presses.
        self.tray_action.is_none().then_some(self.revision)
    }

    fn can_hide(&self, revision: u64) -> bool {
        self.revision == revision && self.tray_action.is_none()
    }

    fn tray_pressed(&mut self, visible: bool) {
        self.cancel_pending_hide();
        self.tray_action = Some(TrayAction::for_visibility(visible));
    }

    fn tray_released(&mut self, visible: bool) -> TrayAction {
        self.cancel_pending_hide();
        self.tray_action
            .take()
            .unwrap_or_else(|| TrayAction::for_visibility(visible))
    }
}

static STATE: Mutex<PanelState> = Mutex::new(PanelState {
    revision: 0,
    tray_action: None,
});

pub(crate) fn cancel_pending_hide() {
    STATE.lock().unwrap().cancel_pending_hide();
}

pub(crate) fn tray_pressed(visible: bool) {
    STATE.lock().unwrap().tray_pressed(visible);
}

pub(crate) fn tray_released(visible: bool) -> TrayAction {
    STATE.lock().unwrap().tray_released(visible)
}

pub(crate) fn hide_window(window: &WebviewWindow) -> tauri::Result<()> {
    cancel_pending_hide();
    window.hide()
}

pub(crate) fn on_focus_changed(window: &WebviewWindow, focused: bool) {
    log::info!(target: "floatick::panel", "focus={focused}");
    if focused {
        cancel_pending_hide();
        return;
    }
    if !matches!(window.is_visible(), Ok(true)) {
        return;
    }

    let Some(revision) = STATE.lock().unwrap().request_blur_hide() else {
        return;
    };
    let window = window.clone();
    std::thread::spawn(move || {
        // run_on_main_thread executes inline when already on the UI thread, so it
        // cannot itself debounce AppKit's transient focus changes.
        std::thread::sleep(BLUR_SETTLE_DELAY);
        let w = window.clone();
        if let Err(error) = window.run_on_main_thread(move || {
            if !STATE.lock().unwrap().can_hide(revision) {
                return;
            }
            // Check live native state as well as the request revision: native
            // focus may already have recovered before its event is delivered.
            if !matches!(w.is_visible(), Ok(true)) || !matches!(w.is_focused(), Ok(false)) {
                return;
            }
            let collapse = crate::storage::load_settings()
                .map(|s| s.collapse_when_clicking_outside)
                .unwrap_or(true);
            if collapse {
                log::info!(target: "floatick::panel", "hide: settled blur");
                if let Err(error) = hide_window(&w) {
                    log::warn!(target: "floatick::panel", "blur hide failed: {error}");
                }
            }
        }) {
            log::warn!(target: "floatick::panel", "blur check dispatch failed: {error}");
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn persistent_blur_can_close_the_panel() {
        let mut state = PanelState::default();
        let request = state.request_blur_hide().unwrap();
        assert!(state.can_hide(request));
    }

    #[test]
    fn reopening_cancels_a_hide_from_the_previous_visibility_cycle() {
        let mut state = PanelState::default();
        let old_blur = state.request_blur_hide().unwrap();
        state.cancel_pending_hide(); // Show, even if focus has not arrived yet.
        assert!(!state.can_hide(old_blur));
    }

    #[test]
    fn focus_recovery_cancels_old_blur_but_a_new_blur_can_close() {
        let mut state = PanelState::default();
        let old_blur = state.request_blur_hide().unwrap();
        state.cancel_pending_hide(); // Focused(true).
        let new_blur = state.request_blur_hide().unwrap();
        assert!(!state.can_hide(old_blur));
        assert!(state.can_hide(new_blur));
    }

    #[test]
    fn repeated_blur_only_keeps_the_latest_request() {
        let mut state = PanelState::default();
        let first = state.request_blur_hide().unwrap();
        let second = state.request_blur_hide().unwrap();
        assert!(!state.can_hide(first));
        assert!(state.can_hide(second));
    }

    #[test]
    fn blur_before_tray_press_cannot_close_the_panel_mid_click() {
        let mut state = PanelState::default();
        let blur = state.request_blur_hide().unwrap();
        state.tray_pressed(true);
        assert!(!state.can_hide(blur));
        assert_eq!(state.tray_released(true), TrayAction::Hide);
    }

    #[test]
    fn blur_during_a_long_tray_press_cannot_reverse_a_close_into_an_open() {
        let mut state = PanelState::default();
        state.tray_pressed(true);
        assert_eq!(state.request_blur_hide(), None);
        assert_eq!(state.request_blur_hide(), None);
        // Even if native visibility changed, honor the intent at mouse-down.
        assert_eq!(state.tray_released(false), TrayAction::Hide);
    }

    #[test]
    fn an_intervening_show_cannot_reverse_a_tray_open_into_a_close() {
        let mut state = PanelState::default();
        state.tray_pressed(false);
        state.cancel_pending_hide(); // For example, a concurrent Reopen event.
        assert_eq!(state.tray_released(true), TrayAction::Show);
    }

    #[test]
    fn consecutive_tray_clicks_toggle_independently() {
        let mut state = PanelState::default();
        state.tray_pressed(false);
        assert_eq!(state.tray_released(false), TrayAction::Show);
        state.tray_pressed(true);
        assert_eq!(state.tray_released(true), TrayAction::Hide);
        state.tray_pressed(false);
        assert_eq!(state.tray_released(false), TrayAction::Show);
    }

    #[test]
    fn mouse_up_without_mouse_down_uses_current_visibility() {
        let mut state = PanelState::default();
        assert_eq!(state.tray_released(false), TrayAction::Show);
        assert_eq!(state.tray_released(true), TrayAction::Hide);
    }
}
