use crate::Instant;
use crate::entities::LayoutSnapshot;
use crate::probs::mspp::entities::instance::MSPInstance;
use crate::probs::mspp::entities::problem::LayKey;
use crate::probs::mspp::entities::strip::Strip;
use slotmap::SecondaryMap;

/// Snapshot of [`MSPProblem`](crate::probs::mspp::entities::MSPProblem) at a specific moment.
/// Can be used to restore to a previous state.
#[derive(Debug, Clone)]
pub struct MSPSolution {
    /// A map of the layout snapshots, identified by the same keys as in the problem
    pub layout_snapshots: SecondaryMap<LayKey, LayoutSnapshot>,
    /// Snapshot of the strips used in each layout
    pub strips: SecondaryMap<LayKey, Strip>,
    /// Instant the solution was created
    pub time_stamp: Instant,
}

impl MSPSolution {
    /// Computes the density of the solution as the ratio between the total area of placed items and the total area of the containers.
    #[must_use]
    pub fn density(&self, instance: &MSPInstance) -> f32 {
        let total_container_area = self
            .strips
            .values()
            .map(|s| s.fixed_height * s.width)
            .sum::<f32>();

        let total_item_area = self
            .layout_snapshots
            .values()
            .map(|ls| ls.placed_item_area(instance))
            .sum::<f32>();

        total_item_area / total_container_area
    }

    /// Returns the total width of the strips of all the layouts in the solution.
    #[must_use]
    pub fn total_strip_width(&self) -> f32 {
        self.strips.iter().map(|(_, s)| s.width).sum()
    }
}
