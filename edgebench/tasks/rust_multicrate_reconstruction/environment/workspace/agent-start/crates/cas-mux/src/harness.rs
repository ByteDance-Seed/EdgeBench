use std::str::FromStr;

/// Supported interactive harnesses for factory panes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SupervisorCli {
    Claude,
    Codex,
}

impl SupervisorCli {
    pub fn as_str(self) -> &'static str { todo!() }

    pub fn capabilities(self) -> HarnessCapabilities { todo!() }
}

impl FromStr for SupervisorCli {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HarnessCapabilities {
    pub supports_hooks: bool,
    pub supports_subagents: bool,
    pub supports_textbox_submit: bool,
    pub tool_prefix: &'static str,
}
