use crate::collision_detection::hazards::HazKey;
use crate::collision_detection::hazards::Hazard;
use crate::collision_detection::hazards::HazardEntity;
use crate::collision_detection::hazards::collector::HazardCollector;
use crate::collision_detection::hazards::filter::HazardFilter;
use crate::collision_detection::quadtree::{QTHazPresence, QTHazard, QTNode};
use crate::entities::PItemKey;
use crate::geometry::Transformation;
use crate::geometry::fail_fast::{SPSurrogate, SPSurrogateConfig};
use crate::geometry::geo_enums::{GeoPosition, GeoRelation};
use crate::geometry::geo_traits::{CollidesWith, Transformable};
use crate::geometry::primitives::Rect;
use crate::geometry::primitives::SPolygon;
use crate::util::assertions;
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use slotmap::SlotMap;

/// The Collision Detection Engine (CDE).
/// [`Hazard`]s can be (de)registered and collision queries can be performed.
#[derive(Clone, Debug)]
pub struct CDEngine {
    /// Root node of the quadtree
    pub quadtree: QTNode,
    /// All hazards registered in the CDE (active and inactive)
    pub hazards_map: SlotMap<HazKey, Hazard>,
    /// Configuration of the CDE
    pub config: CDEConfig,
    /// The key of the hazard that represents the exterior of the container.
    hkey_exterior: HazKey,
}

impl CDEngine {
    #[must_use]
    pub fn new(bbox: Rect, static_hazards: Vec<Hazard>, config: CDEConfig) -> CDEngine {
        let mut quadtree = QTNode::new(config.quadtree_depth, bbox, config.cd_threshold);
        let mut hazards_map = SlotMap::with_key();

        for haz in static_hazards {
            let hkey = hazards_map.insert(haz);
            let qt_haz = QTHazard::from_root(quadtree.bbox, &hazards_map[hkey], hkey);
            quadtree.register_hazard(qt_haz, &hazards_map);
        }

        let hkey_exterior = hazards_map
            .iter()
            .find(|(_, h)| matches!(h.entity, HazardEntity::Exterior))
            .map(|(hkey, _)| hkey)
            .expect("No exterior hazard registered in the CDE");

        CDEngine {
            quadtree,
            hazards_map,
            config,
            hkey_exterior,
        }
    }

    /// Registers a new hazard in the CDE.
    pub fn register_hazard(&mut self, hazard: Hazard) {
        debug_assert!(
            !self.hazards_map.values().any(|h| h.entity == hazard.entity),
            "Hazard with an identical entity already registered"
        );
        let hkey = self.hazards_map.insert(hazard);
        let qt_hazard = QTHazard::from_root(self.bbox(), &self.hazards_map[hkey], hkey);
        self.quadtree.register_hazard(qt_hazard, &self.hazards_map);

        debug_assert!(assertions::qt_contains_no_dangling_hazards(self));
    }

    /// Removes a hazard from the CDE.
    pub fn deregister_hazard_by_entity(&mut self, hazard_entity: HazardEntity) -> Hazard {
        let hkey = self
            .hazards_map
            .iter()
            .find(|(_, h)| h.entity == hazard_entity)
            .map(|(hkey, _)| hkey)
            .expect("Cannot deregister hazard that is not registered");

        self.quadtree.deregister_hazard(hkey);
        let hazard = self.hazards_map.remove(hkey).unwrap();
        debug_assert!(assertions::qt_contains_no_dangling_hazards(self));

        hazard
    }

    pub fn deregister_hazard_by_key(&mut self, hkey: HazKey) -> Hazard {
        let hazard = self
            .hazards_map
            .remove(hkey)
            .expect("Cannot deregister hazard that is not registered");
        self.quadtree.deregister_hazard(hkey);
        debug_assert!(assertions::qt_contains_no_dangling_hazards(self));

        hazard
    }

    #[must_use]
    pub fn save(&self) -> CDESnapshot {
        let dynamic_hazards = self
            .hazards_map
            .values()
            .filter(|h| h.dynamic)
            .cloned()
            .collect_vec();
        CDESnapshot { dynamic_hazards }
    }

    /// Restores the CDE to a previous state, as described by the snapshot.
    pub fn restore(&mut self, snapshot: &CDESnapshot) {
        //Restore the quadtree, by doing a 'diff' between the current state and the snapshot
        //Only dynamic hazards are considered

        //Determine which dynamic hazards need to be removed and which need to be added
        let mut hazards_to_remove = self
            .hazards_map
            .iter()
            .filter(|(_, h)| h.dynamic)
            .map(|(hkey, h)| (hkey, h.entity))
            .collect_vec();
        let mut hazards_to_add = vec![];

        for hazard in &snapshot.dynamic_hazards {
            let present = hazards_to_remove
                .iter()
                .position(|(_, h)| h == &hazard.entity);
            if let Some(idx) = present {
                //the hazard is already present in the CDE, remove it from the hazards to remove
                hazards_to_remove.swap_remove(idx);
            } else {
                //the hazard is not present in the CDE, add it to the list of hazards to add
                hazards_to_add.push(hazard.clone());
            }
        }

        //Remove all hazards currently in the CDE but not in the snapshot
        for (hkey, _) in hazards_to_remove {
            self.deregister_hazard_by_key(hkey);
        }

        //Add all hazards in the snapshot but not currently in the CDE
        for hazard in hazards_to_add {
            self.register_hazard(hazard);
        }

        debug_assert!(
            self.hazards_map.values().filter(|h| h.dynamic).count()
                == snapshot.dynamic_hazards.len()
        );
    }

    /// Returns all hazards in the CDE
    pub fn hazards(&self) -> impl Iterator<Item = &Hazard> {
        self.hazards_map.values()
    }

    /// Checks whether a simple polygon collides with any of the (relevant) hazards
    /// # Arguments
    /// * `shape` - The shape (already transformed) to be checked for collisions
    /// * `filter` - Hazard filter to be applied
    pub fn detect_poly_collision(&self, shape: &SPolygon, filter: &impl HazardFilter) -> bool {
        if self.bbox().relation_to(shape.bbox) == GeoRelation::Surrounding {
            //Instead of each time starting from the quadtree root, we can use the virtual root (lowest level node which fully surrounds the shape)
            let v_qt_root = self.get_virtual_root(shape.bbox);

            // Check for edge intersections with the shape
            for edge in shape.edge_iter() {
                if v_qt_root.collides(&edge, filter).is_some() {
                    return true;
                }
            }

            // Check for containment of the shape in any of the hazards
            for qt_hazard in v_qt_root.hazards.iter() {
                match &qt_hazard.presence {
                    QTHazPresence::None => {}
                    QTHazPresence::Entire => unreachable!(
                        "Entire hazards in the virtual root should have been caught by the edge intersection tests"
                    ),
                    QTHazPresence::Partial(_) => {
                        if !filter.is_irrelevant(qt_hazard.hkey) {
                            let haz_shape = &self.hazards_map[qt_hazard.hkey].shape;
                            if self.detect_containment_collision(shape, haz_shape, qt_hazard.entity)
                            {
                                // The hazard is contained in the shape (or vice versa)
                                return true;
                            }
                        }
                    }
                }
            }

            false
        } else {
            //The CDE does not capture the entire shape, so we can immediately return true
            true
        }
    }

    /// Checks whether a surrogate collides with any of the (relevant) hazards.
    /// # Arguments
    /// * `base_surrogate` - The (untransformed) surrogate to be checked for collisions
    /// * `transform` - The transformation to be applied to the surrogate (on the fly)
    /// * `filter` - Hazard filter to be applied
    pub fn detect_surrogate_collision(
        &self,
        base_surrogate: &SPSurrogate,
        transform: &Transformation,
        filter: &impl HazardFilter,
    ) -> bool {
        for pole in base_surrogate.ff_poles() {
            let t_pole = pole.transform_clone(transform);
            if self.quadtree.collides(&t_pole, filter).is_some() {
                return true;
            }
        }
        for pier in base_surrogate.ff_piers() {
            let t_pier = pier.transform_clone(transform);
            if self.quadtree.collides(&t_pier, filter).is_some() {
                return true;
            }
        }
        false
    }

    /// Check for collision by containment between a shape and a hazard.
    /// This only guarantees to detect collisions caused by full containment of one shape in another.
    /// # Arguments
    /// * `shape` - The shape to be checked for containment
    /// * `haz_shape` - The shape of the respective hazard
    /// * `haz_entity` - The entity inducing the hazard
    #[must_use]
    pub fn detect_containment_collision(
        &self,
        shape: &SPolygon,
        haz_shape: &SPolygon,
        haz_entity: HazardEntity,
    ) -> bool {
        //Due to possible fp issues, we check if the bboxes are "almost" related --
        //meaning that, when edges are very close together, they are considered equal.
        //Some relations which would normally be seen as `Intersecting` are now being considered `Enclosed`/`Surrounding` (which triggers the containment check).
        let haz_to_shape_bbox_relation = haz_shape.bbox.almost_relation_to(shape.bbox);

        //If the bounding boxes are contained, we have to check the actual shapes for containment.
        //This can be done by testing whether a single point of the smaller shape is contained in the larger shape.
        let contained = match haz_to_shape_bbox_relation {
            GeoRelation::Surrounding => haz_shape.collides_with(&shape.poi.center),
            GeoRelation::Enclosed => shape.collides_with(&haz_shape.poi.center),
            GeoRelation::Disjoint | GeoRelation::Intersecting => false,
        };

        //Depending on the scope of the hazard this results a collision or not
        match (haz_entity.scope(), contained) {
            (GeoPosition::Interior, true) | (GeoPosition::Exterior, false) => true,
            (GeoPosition::Interior, false) | (GeoPosition::Exterior, true) => false,
        }
    }

    /// Collects all hazards with which the polygon collides and reports them to the collector.
    /// # Arguments
    /// * `shape` - The shape to be checked for collisions
    /// * `collector` - The collector to which the hazards are reported
    pub fn collect_poly_collisions(&self, shape: &SPolygon, collector: &mut impl HazardCollector) {
        if self.bbox().relation_to(shape.bbox) != GeoRelation::Surrounding {
            collector.insert(self.hkey_exterior, HazardEntity::Exterior);
        }

        //Instead of each time starting from the quadtree root, we can use the virtual root (lowest level node which fully surrounds the shape)
        let v_quadtree = self.get_virtual_root(shape.bbox);

        //Collect all colliding entities due to edge intersection
        shape
            .edge_iter()
            .for_each(|e| v_quadtree.collect_collisions(&e, collector));

        //Check if there are any other collisions due to containment
        for qt_haz in v_quadtree.hazards.iter() {
            match &qt_haz.presence {
                // No need to check these, guaranteed to be detected by edge intersection
                QTHazPresence::None | QTHazPresence::Entire => {}
                QTHazPresence::Partial(_) => {
                    if !collector.contains_key(qt_haz.hkey) {
                        let h_shape = &self.hazards_map[qt_haz.hkey].shape;
                        if self.detect_containment_collision(shape, h_shape, qt_haz.entity) {
                            collector.insert(qt_haz.hkey, qt_haz.entity);
                        }
                    }
                }
            }
        }
    }

    /// Collects all hazards with which the surrogate collides and reports them to the collector.
    /// # Arguments
    /// * `base_surrogate` - The (untransformed) surrogate to be checked for collisions
    /// * `transform` - The transformation to be applied to the surrogate (on the fly)
    /// * `collector` - The collector to which the hazards are reported
    pub fn collect_surrogate_collisions(
        &self,
        base_surrogate: &SPSurrogate,
        transform: &Transformation,
        collector: &mut impl HazardCollector,
    ) {
        for pole in base_surrogate.ff_poles() {
            let t_pole = pole.transform_clone(transform);
            self.quadtree.collect_collisions(&t_pole, collector);
        }
        for pier in base_surrogate.ff_piers() {
            let t_pier = pier.transform_clone(transform);
            self.quadtree.collect_collisions(&t_pier, collector);
        }
    }

    /// Returns the lowest `QTNode` that completely surrounds the given bounding box.
    /// Used to initiate collision checks from lower in the quadtree.
    #[must_use]
    pub fn get_virtual_root(&self, bbox: Rect) -> &QTNode {
        let mut v_root = &self.quadtree;
        while let Some(children) = v_root.children.as_ref() {
            // Keep going down the tree until we cannot find a child that fully surrounds the shape
            let surrounding_child = children
                .iter()
                .find(|child| child.bbox.relation_to(bbox) == GeoRelation::Surrounding);
            match surrounding_child {
                Some(child) => v_root = child,
                None => break,
            }
        }
        v_root
    }

    #[must_use]
    pub fn bbox(&self) -> Rect {
        self.quadtree.bbox
    }

    #[must_use]
    pub fn haz_key_from_pi_key(&self, pik: PItemKey) -> Option<HazKey> {
        self.hazards_map
            .iter()
            .find(|(_, hazard)| match hazard.entity {
                HazardEntity::PlacedItem { pk, .. } => pik == pk,
                _ => false,
            })
            .map(|(key, _)| key)
    }
}

///Configuration of the [`CDEngine`]
#[derive(Serialize, Deserialize, Clone, Copy, Debug, PartialEq)]
pub struct CDEConfig {
    ///Maximum depth of the quadtree
    pub quadtree_depth: u8,
    /// Stop traversing the quadtree and perform collision collection immediately when the total number of edges in a node falls below this number
    pub cd_threshold: u8,
    ///Configuration of the surrogate generation for items
    pub item_surrogate_config: SPSurrogateConfig,
}

/// Snapshot of the state of [`CDEngine`]. Can be used to restore to a previous state.
#[derive(Clone, Debug)]
pub struct CDESnapshot {
    pub dynamic_hazards: Vec<Hazard>,
}
