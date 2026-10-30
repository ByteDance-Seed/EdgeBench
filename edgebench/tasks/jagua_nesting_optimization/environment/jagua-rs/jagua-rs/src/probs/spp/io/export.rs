use crate::Instant;
use crate::io::export::export_layout_snapshot;
use crate::probs::spp::entities::{SPInstance, SPSolution};
use crate::probs::spp::io::ext_repr::ExtSPSolution;

/// Exports a solution out of the library
#[must_use]
pub fn export(instance: &SPInstance, solution: &SPSolution, epoch: Instant) -> ExtSPSolution {
    ExtSPSolution {
        strip_width: solution.strip.width,
        layout: export_layout_snapshot(&solution.layout_snapshot, instance),
        density: solution.density(instance),
        run_time_sec: solution.time_stamp.duration_since(epoch).as_secs(),
    }
}
