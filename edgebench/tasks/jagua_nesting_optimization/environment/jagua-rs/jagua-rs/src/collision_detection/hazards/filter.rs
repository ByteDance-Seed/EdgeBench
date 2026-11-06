use crate::collision_detection::hazards::collector::HazardCollector;
use crate::collision_detection::hazards::{HazKey, Hazard, HazardEntity};
use slotmap::{SecondaryMap, SlotMap};

/// Trait for filters to ignore all [`Hazard`]s induced by specific [`HazardEntity`]s.
/// Enables collision queries to ignore specific hazards during the check.
pub trait HazardFilter {
    fn is_irrelevant(&self, haz_key: HazKey) -> bool;
}

/// Deems hazards with specific [`HazKey`]'s as irrelevant.
#[derive(Clone, Debug)]
pub struct HazKeyFilter(pub SecondaryMap<HazKey, ()>);

impl HazKeyFilter {
    pub fn from_keys(keys: impl IntoIterator<Item = HazKey>) -> Self {
        HazKeyFilter(keys.into_iter().map(|k| (k, ())).collect())
    }

    /// Creates a filter that deems all inferior quality zones above or at a certain quality as irrelevant.
    #[must_use]
    pub fn from_irrelevant_qzones(
        required_quality: usize,
        haz_map: &SlotMap<HazKey, Hazard>,
    ) -> Self {
        HazKeyFilter(
            haz_map
                .iter()
                .filter_map(|(hkey, h)| {
                    match h.entity {
                        HazardEntity::InferiorQualityZone { quality, .. }
                            if quality < required_quality =>
                        {
                            // Only consider inferior quality zones below the required quality
                            Some((hkey, ()))
                        }
                        _ => None,
                    }
                })
                .collect(),
        )
    }
}

impl HazardFilter for HazKeyFilter {
    fn is_irrelevant(&self, haz_key: HazKey) -> bool {
        self.0.contains_key(haz_key)
    }
}

/// Deems hazards induced by itself as irrelevant.
impl HazardFilter for HazKey {
    fn is_irrelevant(&self, hk: HazKey) -> bool {
        *self == hk
    }
}

/// Deems no hazards as irrelevant.
#[derive(Clone, Debug)]
pub struct NoFilter;

impl HazardFilter for NoFilter {
    fn is_irrelevant(&self, _haz_key: HazKey) -> bool {
        false
    }
}

/// Implements [`HazardFilter`] for any type that implements [`HazardCollector`].
/// Any [`HazardEntity`]s that are already in the collector are considered irrelevant.
impl<T> HazardFilter for T
where
    T: HazardCollector,
{
    fn is_irrelevant(&self, hkey: HazKey) -> bool {
        self.contains_key(hkey)
    }
}
