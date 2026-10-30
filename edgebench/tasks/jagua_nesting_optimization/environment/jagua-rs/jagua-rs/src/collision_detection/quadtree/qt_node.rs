use crate::collision_detection::hazards::collector::HazardCollector;
use crate::collision_detection::hazards::filter::HazardFilter;
use crate::collision_detection::hazards::{HazKey, Hazard, HazardEntity};
use crate::collision_detection::quadtree::QTHazPresence;
use crate::collision_detection::quadtree::QTHazard;
use crate::collision_detection::quadtree::qt_hazard_vec::QTHazardVec;
use crate::collision_detection::quadtree::qt_traits::QTQueryable;
use crate::geometry::geo_traits::CollidesWith;
use crate::geometry::primitives::Rect;
use slotmap::SlotMap;

/// Quadtree node
#[derive(Clone, Debug)]
pub struct QTNode {
    /// The level of the node in the tree, 0 being the bottom-most level
    pub level: u8,
    /// The bounding box of the node
    pub bbox: Rect,
    /// The children of the node, if any
    pub children: Option<Box<[QTNode; 4]>>,
    /// The hazards present in the node
    pub hazards: QTHazardVec,
    /// Stop traversing the quadtree and perform collision detection immediately when the total number of edges in a node falls below this number
    pub cd_threshold: u8,
}

impl QTNode {
    #[must_use]
    pub fn new(level: u8, bbox: Rect, cd_threshold: u8) -> Self {
        QTNode {
            level,
            bbox,
            children: None,
            hazards: QTHazardVec::new(),
            cd_threshold,
        }
    }

    pub fn register_hazard(&mut self, new_qt_haz: QTHazard, haz_map: &SlotMap<HazKey, Hazard>) {
        let constrict_and_register_to_children =
            |qt_hazard: &QTHazard, children: &mut Box<[QTNode; 4]>| {
                // Constrict the hazard to the bounding boxes of the children
                let child_bboxes = children.each_ref().map(|c| c.bbox);
                let child_hazards = qt_hazard.constrict(child_bboxes, haz_map);

                // Register the hazards to the children if present
                child_hazards
                    .into_iter()
                    .enumerate()
                    .for_each(|(i, child_haz)| {
                        match child_haz.presence {
                            QTHazPresence::None => (), // No need to register if the hazard is not present
                            QTHazPresence::Partial(_) | QTHazPresence::Entire => {
                                children[i].register_hazard(child_haz, haz_map);
                            }
                        }
                    });
            };

        //Check if we have to expand the node (generate children)
        if self.children.is_none()
            && self.level > 0
            && matches!(new_qt_haz.presence, QTHazPresence::Partial(_))
        {
            // Generate a child for every quadrant
            let children = self
                .bbox
                .quadrants()
                .map(|quad| QTNode::new(self.level - 1, quad, self.cd_threshold));
            self.children = Some(Box::new(children));

            // Register all previous hazards to them
            for qt_hazard in self.hazards.iter() {
                constrict_and_register_to_children(qt_hazard, self.children.as_mut().unwrap());
            }
        }
        if let Some(children) = self.children.as_mut() {
            // If there are children, register the hazard to them
            constrict_and_register_to_children(&new_qt_haz, children);
        }
        self.hazards.add(new_qt_haz);
    }

    pub fn deregister_hazard(&mut self, hkey: HazKey) {
        let modified = self.hazards.remove(hkey).is_some();

        if modified {
            if self.hazards.no_partial_hazards() {
                // Drop the children if there are no partially present hazards left
                self.children = None;
            } else if let Some(children) = self.children.as_mut() {
                children.iter_mut().for_each(|c| c.deregister_hazard(hkey));
            }
        }
    }

    /// Used to detect collisions in a binary fashion: either there is a collision or there isn't.
    /// Returns `None` if no collision between the entity and any hazard is detected,
    /// otherwise the first encountered hazard that collides with the entity is returned.
    pub fn collides<T: QTQueryable>(
        &self,
        entity: &T,
        filter: &impl HazardFilter,
    ) -> Option<&HazardEntity> {
        match self.hazards.strongest(filter) {
            None => None,
            Some(strongest_hazard) => match strongest_hazard.presence {
                QTHazPresence::None => None,
                QTHazPresence::Entire => Some(&strongest_hazard.entity),
                QTHazPresence::Partial(_) => {
                    // Condition to perform collision detection now or pass it to children:
                    if let Some(children) = &self.children {
                        //Check if any of the children collide with the entity
                        let quadrants = [0, 1, 2, 3].map(|idx| &children[idx].bbox);
                        let colliding_quadrants =
                            entity.collides_with_quadrants(&self.bbox, quadrants);

                        colliding_quadrants
                            .iter()
                            .enumerate()
                            .filter(|(_, collides)| **collides)
                            .map(|idx| children[idx.0].collides(entity, filter))
                            .find(Option::is_some)
                            .flatten()
                    } else {
                        //Check if any of the partially present (and active) hazards collide with the entity
                        let mut relevant_hazards = self
                            .hazards
                            .iter()
                            .filter(|hz| !filter.is_irrelevant(hz.hkey));

                        relevant_hazards
                            .find(|hz| match &hz.presence {
                                QTHazPresence::None => false,
                                QTHazPresence::Entire => {
                                    unreachable!("should have been handled above")
                                }
                                QTHazPresence::Partial(p_haz) => p_haz.collides_with(entity),
                            })
                            .map(|hz| &hz.entity)
                    }
                }
            },
        }
    }

    /// Gathers all hazards that collide with the entity and reports them to the `collector`.
    /// All hazards already present in the `collector` are ignored.
    pub fn collect_collisions<T: QTQueryable>(
        &self,
        entity: &T,
        collector: &mut impl HazardCollector,
    ) {
        // Condition to perform collision detection now or pass it to children:
        let perform_cd_now = self.hazards.n_active_edges() <= self.cd_threshold as usize;

        match (self.children.as_ref(), perform_cd_now) {
            (Some(children), false) => {
                // Collect collisions from all children that collide with the entity
                let quadrants = [0, 1, 2, 3].map(|idx| &children[idx].bbox);
                let colliding_quadrants = entity.collides_with_quadrants(&self.bbox, quadrants);

                colliding_quadrants
                    .iter()
                    .enumerate()
                    .filter(|(_, collides)| **collides)
                    .map(|(i, _)| &children[i])
                    .for_each(|child| {
                        child.collect_collisions(entity, collector);
                    });
            }
            _ => {
                //Check the hazards now
                for hz in self.hazards.iter() {
                    if !collector.contains_key(hz.hkey) {
                        match &hz.presence {
                            QTHazPresence::None => (),
                            QTHazPresence::Entire => collector.insert(hz.hkey, hz.entity),
                            QTHazPresence::Partial(p_haz) => {
                                if p_haz.collides_with(entity) {
                                    collector.insert(hz.hkey, hz.entity);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
