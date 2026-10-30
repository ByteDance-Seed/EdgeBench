use crate::ui::factory::daemon::imports::*;
use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;

impl FactoryDaemon {
    pub(super) fn accept_clients(&mut self) -> anyhow::Result<bool> { todo!() }

    /// Process input from all connected clients
    pub(super) async fn process_client_input(&mut self) -> anyhow::Result<bool> { todo!() }

    /// Parse client input, extracting control sequences
    fn parse_client_input(buf: &mut Vec<u8>) -> (Vec<u8>, Vec<ControlEvent>) { todo!() }

    /// Process input bytes (handles escape sequences for arrow keys)
    async fn process_input(&mut self, input: &[u8]) -> anyhow::Result<()> { todo!() }

    fn resolve_drop_target(&self, col: u16, row: u16) -> Option<String> { todo!() }
}

fn bracketed_paste_bytes(payload: &str) -> Vec<u8> { todo!() }
