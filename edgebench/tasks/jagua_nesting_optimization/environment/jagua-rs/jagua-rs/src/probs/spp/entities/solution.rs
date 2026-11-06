use crate::Instant;
use crate::entities::LayoutSnapshot;
use crate::probs::spp::entities::SPInstance;
use crate::probs::spp::entities::strip::Strip;

/// Snapshot of [`SPProblem`](crate::probs::spp::entities::SPProblem) at a specific moment. Can be used to restore to a previous state.
#[derive(Debug, Clone)]
pub struct SPSolution {
    pub strip: Strip,
    pub layout_snapshot: LayoutSnapshot,
    /// Instant the solution was created
    pub time_stamp: Instant,
}

impl SPSolution {
    #[must_use]
    pub fn density(&self, instance: &SPInstance) -> f32 {
        self.layout_snapshot.density(instance)
    }
    #[must_use]
    pub fn strip_width(&self) -> f32 {
        self.strip.width
    }
}
