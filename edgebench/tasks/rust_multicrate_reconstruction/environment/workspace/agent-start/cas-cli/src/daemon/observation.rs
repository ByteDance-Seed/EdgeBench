use std::sync::Arc;

use crate::daemon::DaemonConfig;
use crate::error::CasError;
use crate::store::Store;

pub(crate) fn process_observations(
    store: &Arc<dyn Store>,
    config: &DaemonConfig,
) -> Result<usize, CasError> { todo!() }
