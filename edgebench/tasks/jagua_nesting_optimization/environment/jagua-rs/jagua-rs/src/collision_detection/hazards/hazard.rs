use crate::entities::{PItemKey, PlacedItem};
use crate::geometry::DTransformation;
use crate::geometry::geo_enums::GeoPosition;
use crate::geometry::primitives::SPolygon;
use slotmap::new_key_type;
use std::borrow::Borrow;
use std::sync::Arc;

new_key_type! {
    /// Key to identify hazards inside the CDE.
    pub struct HazKey;
}

/// Any spatial constraint affecting the feasibility of a placement of an Item.
/// See [`HazardEntity`] for the different entities that can induce a hazard.
#[derive(Clone, Debug)]
pub struct Hazard {
    /// The entity inducing the hazard
    pub entity: HazardEntity,
    /// The shape of the hazard
    pub shape: Arc<SPolygon>,
    /// Whether the hazard is dynamic, meaning it can change over time (e.g., moving items)
    pub dynamic: bool,
}

impl Hazard {
    #[must_use]
    pub fn new(entity: HazardEntity, shape: Arc<SPolygon>, dynamic: bool) -> Self {
        Self {
            entity,
            shape,
            dynamic,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
/// Entity inducing a [`Hazard`].
/// All entities are uniquely identified.
pub enum HazardEntity {
    /// An item placed in the layout, defined by its id, applied transformation and key
    PlacedItem {
        id: usize,
        dt: DTransformation,
        pk: PItemKey,
    },
    /// Represents all regions outside the container
    Exterior,
    /// Represents a hole in the container.
    Hole { idx: usize },
    /// Represents a zone in the container with a specific quality level that is inferior to the base quality.
    InferiorQualityZone { quality: usize, idx: usize },
}

impl HazardEntity {
    /// Whether the entity induced a hazard within the entire interior or exterior of its shape
    #[must_use]
    pub fn scope(&self) -> GeoPosition {
        match self {
            HazardEntity::PlacedItem { .. }
            | HazardEntity::Hole { .. }
            | HazardEntity::InferiorQualityZone { .. } => GeoPosition::Interior,
            HazardEntity::Exterior => GeoPosition::Exterior,
        }
    }
}

impl<T> From<(PItemKey, T)> for HazardEntity
where
    T: Borrow<PlacedItem>,
{
    fn from((pk, pi): (PItemKey, T)) -> Self {
        HazardEntity::PlacedItem {
            id: pi.borrow().item_id,
            dt: pi.borrow().d_transf,
            pk,
        }
    }
}
