use crate::io::ext_repr::ExtLayout;
use serde::{Deserialize, Serialize};

/// Bin Packing Problem instance
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtBPInstance {
    /// The name of the instance
    pub name: String,
    /// Set of items to be produced
    pub items: Vec<ExtItem>,
    /// Set of bins to be used
    pub bins: Vec<ExtBin>,
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

/// Bin with a stock quantity and cost
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtBin {
    #[serde(flatten)]
    pub base: crate::io::ext_repr::ExtContainer,
    /// The number of copies of this bin available to be use
    pub stock: usize,
    /// The cost of using a bin of this type
    pub cost: u64,
}

/// Bin Packing Problem solution
#[derive(Serialize, Deserialize, Clone)]
pub struct ExtBPSolution {
    /// Total cost of all the bins used in the solution
    pub cost: u64,
    /// Layouts which compose the solution
    pub layouts: Vec<ExtLayout>,
    /// Sum of the area of the produced items divided by the sum of the area of the containers
    pub density: f32,
    /// The time it took to generate the solution in seconds
    pub run_time_sec: u64,
}
