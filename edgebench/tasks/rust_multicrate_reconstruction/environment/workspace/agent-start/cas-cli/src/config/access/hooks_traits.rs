use crate::config::*;

impl cas_core::hooks::HooksConfig for Config {
    fn token_budget(&self) -> usize { todo!() }

    fn minimal_start(&self) -> bool { todo!() }

    fn mcp_enabled(&self) -> bool { todo!() }

    fn ai_context(&self) -> bool { todo!() }

    fn ai_model(&self) -> String { todo!() }

    fn ai_fallback(&self) -> bool { todo!() }

    fn inject_context(&self) -> bool { todo!() }

    fn plan_mode(&self) -> cas_core::hooks::PlanModeConfig { todo!() }

    fn supervisor_guidance(&self) -> String { todo!() }

    fn worker_guidance(&self) -> String { todo!() }
}

/// Implement HooksConfig for HookConfig directly (convenience)
impl cas_core::hooks::HooksConfig for HookConfig {
    fn token_budget(&self) -> usize { todo!() }

    fn minimal_start(&self) -> bool { todo!() }

    fn mcp_enabled(&self) -> bool { todo!() }

    fn ai_context(&self) -> bool { todo!() }

    fn ai_model(&self) -> String { todo!() }

    fn ai_fallback(&self) -> bool { todo!() }

    fn inject_context(&self) -> bool { todo!() }

    fn plan_mode(&self) -> cas_core::hooks::PlanModeConfig { todo!() }

    fn supervisor_guidance(&self) -> String { todo!() }

    fn worker_guidance(&self) -> String { todo!() }
}
