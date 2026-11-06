use serde::{Deserialize, Serialize};

use crate::io::ext_repr::ExtLayout;

/// Strip Packing Problem instance
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtSPInstance {
    /// The name of the instance
    pub name: String,
    /// Set of items to be produced
    pub items: Vec<ExtItem>,
    /// Fixed height of the strip
    pub strip_height: f32,
}

/// Item with a demand
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtItem {
    #[serde(flatten)]
    /// External representation of the item in the base library
    pub base: crate::io::ext_repr::ExtItem,
    /// Amount of times this item has to be produced
    pub demand: u64,
}

/// Strip Packing Problem solution
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtSPSolution {
    /// The strip width of the solution
    pub strip_width: f32,
    /// Layouts which compose the solution
    pub layout: ExtLayout,
    /// Sum of the area of the produced items divided by the sum of the area of the containers
    pub density: f32,
    /// The time it took to generate the solution in seconds
    pub run_time_sec: u64,
}
