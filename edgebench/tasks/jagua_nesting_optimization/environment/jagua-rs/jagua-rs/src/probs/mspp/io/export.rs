use crate::Instant;
use crate::io::export::export_layout_snapshot;
use crate::io::ext_repr::ExtContainer;
use crate::io::ext_repr::ExtShape;
use crate::probs::mspp::entities::MSPInstance;
use crate::probs::mspp::entities::MSPSolution;
use crate::probs::mspp::io::ext_repr::ExtMSPSolution;
use itertools::Itertools;

/// Exports a solution out of the library
#[must_use]
pub fn export(instance: &MSPInstance, solution: &MSPSolution, epoch: Instant) -> ExtMSPSolution {
    ExtMSPSolution {
        layouts: solution
            .layout_snapshots
            .values()
            .map(|ls| export_layout_snapshot(ls, instance))
            .collect(),
        density: solution.density(instance),
        containers: solution
            .layout_snapshots
            .values()
            .map(|ls| {
                let bbox = ls.container.outer_orig.bbox();
                ExtContainer {
                    id: ls.container.id as u64,
                    shape: ExtShape::Rectangle {
                        x_min: bbox.x_min,
                        y_min: bbox.y_min,
                        width: bbox.width(),
                        height: bbox.height(),
                    },
                    zones: vec![],
                }
            })
            .unique_by(|c| c.id)
            .collect(),
        run_time_sec: solution.time_stamp.duration_since(epoch).as_secs(),
    }
}
