use std::sync::RwLock;

/// Thread-safe counter for generating unique IDs.
#[derive(Debug, Default)]
pub(crate) struct IdCounter(pub(crate) RwLock<u32>);

impl IdCounter {
    pub(crate) fn next(&self) -> u32 { todo!() }
}
