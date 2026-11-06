use serde::{Deserialize, Serialize};

use crate::io::ext_repr::{ExtContainer, ExtLayout};

/// Multi-Strip Packing Problem instance
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtMSPInstance {
    /// The name of the instance
    pub name: String,
    /// Set of items to be produced
    pub items: Vec<ExtItem>,
    /// Container in which to pack the items
    pub strips: ExtMSPStrip,
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

/// Multi-Strip Packing Problem solution
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtMSPSolution {
    /// Layouts which compose the solution
    pub layouts: Vec<ExtLayout>,
    /// Containers used in the solution
    pub containers: Vec<ExtContainer>,
    /// Sum of the area of the produced items divided by the sum of the area of the containers
    pub density: f32,
    /// The time it took to generate the solution in seconds
    pub run_time_sec: u64,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct ExtMSPStrip {
    /// Height of the container
    pub height: f32,
    /// Width of the container
    pub max_width: f32,
}
