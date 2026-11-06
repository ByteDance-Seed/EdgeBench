//! Factory view mode and focus types.

use super::director::SidecarFocus;

/// Which top-level view the factory TUI is showing.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum FactoryViewMode {
    /// Standard pane layout (workers + supervisor + sidecar).
    #[default]
    Panes,
    /// Mission Control dashboard (no PTY panes, all panels).
    MissionControl,
}

/// Which panel has focus in Mission Control view.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum MissionControlFocus {
    #[default]
    None,
    Workers,
    Tasks,
    Changes,
    Activity,
}

impl MissionControlFocus {
    /// Cycle to the next focusable panel.
    pub fn next(self) -> Self { todo!() }

    /// Cycle to the previous focusable panel.
    pub fn prev(self) -> Self { todo!() }

    /// Convert to a SidecarFocus for shared PanelRegistry access.
    pub fn to_sidecar_focus(self) -> SidecarFocus { todo!() }

    /// Panel display name for the status bar.
    pub fn label(self) -> &'static str { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_factory_view_mode_default_is_panes() {
        let mode = FactoryViewMode::default();
        assert_eq!(mode, FactoryViewMode::Panes);
    }

}
