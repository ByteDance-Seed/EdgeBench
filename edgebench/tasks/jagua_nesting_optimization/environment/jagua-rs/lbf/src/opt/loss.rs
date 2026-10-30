use std::cmp::Ordering;

use jagua_rs::geometry::primitives::{Rect, SPolygon};

const X_MULTIPLIER: f32 = 10.0;

/// The loss LBF assigned to a placing option.
/// Weighted sum of the x_max and y_max of the shape, with the horizontal dimension being more important.
/// <br>
/// A pure lexicographic comparison (always prioritizing x-axis) would lead to undesirable results due to the continuous nature of the values.
#[derive(Copy, Clone, Debug, PartialEq)]
pub struct LBFLoss {
    x_max: f32,
    y_max: f32,
}

impl LBFLoss {
    pub fn from_bbox(bbox: Rect) -> Self {
        Self {
            x_max: bbox.x_max,
            y_max: bbox.y_max,
        }
    }

    pub fn from_shape(shape: &SPolygon) -> Self {
        LBFLoss::from_bbox(shape.bbox)
    }

    pub fn cost(&self) -> f32 {
        self.x_max * X_MULTIPLIER + self.y_max
    }

    /// Tightens a sampling `Rect` to eliminate regions which would never have a lower loss than `self`.
    pub fn tighten_sample_bbox(&self, sample_bbox: Rect) -> Rect {
        let cost = self.cost();
        let x_max_bound = cost / X_MULTIPLIER;

        let mut tightened_bbox = sample_bbox;
        tightened_bbox.x_max = f32::min(sample_bbox.x_max, x_max_bound);

        tightened_bbox
    }
}

impl PartialOrd for LBFLoss {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        let self_cost = self.cost();
        let other_cost = other.cost();

        self_cost.partial_cmp(&other_cost)
    }
}
