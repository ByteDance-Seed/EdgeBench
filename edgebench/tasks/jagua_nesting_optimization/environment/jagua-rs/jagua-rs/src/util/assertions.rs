use crate::collision_detection::CDEngine;
use crate::collision_detection::hazards::Hazard;
use crate::collision_detection::hazards::HazardEntity;
use crate::collision_detection::quadtree::QTHazPresence;
use crate::collision_detection::quadtree::QTHazard;
use crate::collision_detection::quadtree::QTNode;
use crate::entities::Layout;
use crate::entities::LayoutSnapshot;
use crate::geometry::primitives::Rect;
use itertools::Itertools;
use log::error;
use std::collections::HashSet;
//Various checks to verify correctness of the state of the system
//Used in debug_assertion!() blocks

#[must_use]
pub fn snapshot_matches_layout(layout: &Layout, layout_snapshot: &LayoutSnapshot) -> bool {
    if layout.container.id != layout_snapshot.container.id {
        return false;
    }
    for placed_item in layout_snapshot.placed_items.values() {
        if !layout
            .placed_items
            .values()
            .any(|pi| pi.item_id == placed_item.item_id && pi.d_transf == placed_item.d_transf)
        {
            return false;
        }
    }
    true
}

#[must_use]
pub fn collision_hazards_sorted_correctly(hazards: &[QTHazard]) -> bool {
    let mut partial_hazard_detected = false;
    for hazard in hazards {
        match hazard.presence {
            QTHazPresence::Partial(_) => {
                partial_hazard_detected = true;
            }
            QTHazPresence::Entire => {
                if partial_hazard_detected {
                    return false;
                }
            }
            QTHazPresence::None => {
                panic!("None hazard should never be collision hazard vec");
            }
        }
    }
    true
}

#[must_use]
pub fn qt_contains_no_dangling_hazards(cde: &CDEngine) -> bool {
    if let Some(children) = &cde.quadtree.children {
        for child in children.as_ref() {
            if !qt_node_contains_no_dangling_hazards(child, &cde.quadtree) {
                return false;
            }
        }
    }
    true
}

fn qt_node_contains_no_dangling_hazards(node: &QTNode, parent: &QTNode) -> bool {
    let parent_h_entities = parent
        .hazards
        .iter()
        .map(|h| &h.entity)
        .unique()
        .collect_vec();

    let dangling_hazards = node
        .hazards
        .iter()
        .any(|h| !parent_h_entities.contains(&&h.entity));
    if dangling_hazards {
        println!("Node contains dangling hazard");
        return false;
    }

    if let Some(children) = &node.children {
        for child in children.as_ref() {
            if !qt_node_contains_no_dangling_hazards(child, node) {
                return false;
            }
        }
    }

    true
}

#[must_use]
pub fn layout_qt_matches_fresh_qt(layout: &Layout) -> bool {
    //check if every placed item is correctly represented in the quadtree

    //rebuild the quadtree
    let container = &layout.container;
    let mut fresh_cde = container.base_cde.as_ref().clone();
    for (pk, pi) in &layout.placed_items {
        let hazard = Hazard::new((pk, pi).into(), pi.shape.clone(), true);
        fresh_cde.register_hazard(hazard);
    }

    qt_nodes_match(Some(&layout.cde().quadtree), Some(&fresh_cde.quadtree))
        && hazards_match(layout.cde().hazards(), fresh_cde.hazards())
}

fn qt_nodes_match(qn1: Option<&QTNode>, qn2: Option<&QTNode>) -> bool {
    let hashable = |h: &QTHazard| {
        let p_sk = match h.presence {
            QTHazPresence::None => 0,
            QTHazPresence::Partial(_) => 1,
            QTHazPresence::Entire => 2,
        };
        (h.entity, p_sk)
    };
    match (qn1, qn2) {
        (Some(qn1), Some(qn2)) => {
            //if both nodes exist
            let hv1 = &qn1.hazards;
            let hv2 = &qn2.hazards;

            //collect active hazards to hashsets
            let active_haz_1 = hv1
                .iter()
                .map(hashable)
                .collect::<HashSet<(HazardEntity, u8)>>();

            let active_haz_2 = hv2
                .iter()
                .map(hashable)
                .collect::<HashSet<(HazardEntity, u8)>>();

            let active_in_1_but_not_2 = active_haz_1
                .difference(&active_haz_2)
                .collect::<HashSet<_>>();
            let active_in_2_but_not_1 = active_haz_2
                .difference(&active_haz_1)
                .collect::<HashSet<_>>();

            if !(active_in_1_but_not_2.is_empty() && active_in_2_but_not_1.is_empty()) {
                let from_1 = **active_in_1_but_not_2.iter().next().unwrap();
                let from_2 = **active_in_2_but_not_1.iter().next().unwrap();
                println!("{}", from_1 == from_2);
                error!(
                    "Active hazards don't match {active_in_1_but_not_2:?} vs {active_in_2_but_not_1:?}"
                );
                return false;
            }
        }
        (Some(qn1), None) => {
            if qn1.hazards.iter().next().is_some() {
                error!("qn1 contains active hazards while other qn2 does not exist");
                return false;
            }
        }
        (None, Some(qn2)) => {
            if qn2.hazards.iter().next().is_some() {
                error!("qn2 contains active hazards while other qn1 does not exist");
                return false;
            }
        }
        (None, None) => panic!("Both nodes are none"),
    }

    //Check children
    match (
        qn1.map_or(&None, |qn| &qn.children),
        qn2.map_or(&None, |qn| &qn.children),
    ) {
        (None, None) => true,
        (Some(c1), None) => {
            let qn1_has_partial_hazards = qn1.is_some_and(|qn| {
                qn.hazards
                    .iter()
                    .any(|h| matches!(h.presence, QTHazPresence::Partial(_)))
            });
            if qn1_has_partial_hazards {
                for child in c1.as_ref() {
                    if !qt_nodes_match(Some(child), None) {
                        return false;
                    }
                }
            }
            true
        }
        (None, Some(c2)) => {
            let qn2_has_partial_hazards = qn2.is_some_and(|qn| {
                qn.hazards
                    .iter()
                    .any(|h| matches!(h.presence, QTHazPresence::Partial(_)))
            });
            if qn2_has_partial_hazards {
                for child in c2.as_ref() {
                    if !qt_nodes_match(None, Some(child)) {
                        return false;
                    }
                }
            }
            true
        }
        (Some(c1), Some(c2)) => {
            for (child1, child2) in c1.as_ref().iter().zip(c2.as_ref().iter()) {
                if !qt_nodes_match(Some(child1), Some(child2)) {
                    return false;
                }
            }
            true
        }
    }
}

fn hazards_match<'a>(
    chv1: impl Iterator<Item = &'a Hazard>,
    chv2: impl Iterator<Item = &'a Hazard>,
) -> bool {
    let chv1_active_hazards = chv1.map(|h| h.entity).collect::<HashSet<_>>();

    let chv2_active_hazards = chv2.map(|h| h.entity).collect::<HashSet<_>>();

    if chv1_active_hazards != chv2_active_hazards {
        println!("Hazard vecs don't match");
        return false;
    }
    true
}

/// Checks if the quadrants follow the layout set in [`Rect::QUADRANT_NEIGHBOR_LAYOUT`]
#[must_use]
pub fn quadrants_have_valid_layout(quadrants: &[Rect; 4]) -> bool {
    let layout = Rect::QUADRANT_NEIGHBOR_LAYOUT;
    for (idx, q) in quadrants.iter().enumerate() {
        //make sure they share two points (an edge) with each neighbor
        let [n_0, n_1] = layout[idx];
        let q_corners = q.corners();
        let n_0_corners = quadrants[n_0].corners();
        let n_1_corners = quadrants[n_1].corners();

        assert_eq!(
            2,
            n_0_corners
                .iter()
                .filter(|c| q_corners.iter().any(|qc| &qc == c))
                .count()
        );
        assert_eq!(
            2,
            n_1_corners
                .iter()
                .filter(|c| q_corners.iter().any(|qc| &qc == c))
                .count()
        );
    }
    true
}

///Prints code to rebuild a layout. Intended for debugging purposes.
pub fn print_layout(layout: &Layout) {
    println!(
        "let mut layout = Layout::new(0, instance.container({}).clone());",
        layout.container.id
    );
    println!();

    for pi in layout.placed_items.values() {
        let transformation_str = {
            let t_decomp = &pi.d_transf;
            let (tr, (tx, ty)) = (t_decomp.rotation(), t_decomp.translation());
            format!("&DTransformation::new({tr:.6},({tx:.6},{ty:.6}))")
        };

        println!(
            "layout.place_item(instance.item({}), {});",
            pi.item_id, transformation_str
        );
    }
}
