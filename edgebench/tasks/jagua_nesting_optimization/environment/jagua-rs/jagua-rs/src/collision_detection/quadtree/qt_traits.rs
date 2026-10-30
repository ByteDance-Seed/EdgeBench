use crate::geometry::geo_traits::CollidesWith;
use crate::geometry::primitives::Rect;
use crate::geometry::primitives::{Circle, Edge, Point};
use std::cmp::Ordering;

/// Common trait for all geometric primitives that can be directly queried in the quadtree
/// for collisions with the edges of the registered hazards. These include: [Rect], [Edge] and [Circle].
pub trait QTQueryable: CollidesWith<Edge> + CollidesWith<Rect> {
    /// Checks
    fn collides_with_quadrants(&self, r: &Rect, qs: [&Rect; 4]) -> [bool; 4] {
        debug_assert!(r.quadrants().iter().zip(qs.iter()).all(|(q, r)| *q == **r));
        qs.map(|q| self.collides_with(q))
    }
}

impl QTQueryable for Circle {}
impl QTQueryable for Rect {}

impl QTQueryable for Edge {
    #[allow(clippy::similar_names)]
    fn collides_with_quadrants(&self, r: &Rect, qs: [&Rect; 4]) -> [bool; 4] {
        debug_assert!(r.quadrants().iter().zip(qs.iter()).all(|(q, r)| *q == **r));
        let e_x_min = self.x_min();
        let e_x_max = self.x_max();
        let e_y_min = self.y_min();
        let e_y_max = self.y_max();

        let [mut c_q0, mut c_q1, mut c_q2, mut c_q3] = [0, 1, 2, 3].map(|idx| {
            let q = qs[idx];

            let x_no_overlap = e_x_min.max(q.x_min) > e_x_max.min(q.x_max);
            let y_no_overlap = e_y_min.max(q.y_min) > e_y_max.min(q.y_max);

            if x_no_overlap || y_no_overlap {
                // Edge is completely outside the x- or y-range of the quadrant
                Some(false)
            } else if q.collides_with(&self.start) || q.collides_with(&self.end) {
                // Edge has at least one end point in the quadrant
                Some(true)
            } else {
                // Undetermined, we need to check for intersections with the sides of the quadrants
                None
            }
        });

        // If all quadrants are already determined, we can return early
        if let (Some(c_q0), Some(c_q1), Some(c_q2), Some(c_q3)) = (c_q0, c_q1, c_q2, c_q3) {
            return [c_q0, c_q1, c_q2, c_q3];
        }

        // Otherwise, we need to check for intersections with the sides of the quadrants
        // We can exploit the fact that the quadrants have a fixed layout, and share edges.

        let c = r.centroid();

        let [top, left, bottom, right] = r.sides();

        let h_bisect = Edge {
            start: Point(r.x_min, c.1),
            end: Point(r.x_max, c.1),
        };
        let v_bisect = Edge {
            start: Point(c.0, r.y_min),
            end: Point(c.0, r.y_max),
        };

        //  1    0
        //  2    3

        half_intersect(self, &left, [&mut c_q1], [&mut c_q2]);
        half_intersect(self, &right, [&mut c_q3], [&mut c_q0]);
        half_intersect(self, &top, [&mut c_q0], [&mut c_q1]);
        half_intersect(self, &bottom, [&mut c_q2], [&mut c_q3]);
        half_intersect(
            self,
            &h_bisect,
            [&mut c_q1, &mut c_q2],
            [&mut c_q0, &mut c_q3],
        );
        half_intersect(
            self,
            &v_bisect,
            [&mut c_q2, &mut c_q3],
            [&mut c_q0, &mut c_q1],
        );

        let [c_q0, c_q1, c_q2, c_q3] = [c_q0, c_q1, c_q2, c_q3].map(|c| c.unwrap_or(false));
        debug_assert!(
            {
                // make sure all quadrants which are colliding according to the individual collision check are at least
                // also caught by the quadrant collision check
                qs.map(|q| self.collides_with(q))
                    .iter()
                    .zip([c_q0, c_q1, c_q2, c_q3].iter())
                    .all(|(&i_c, &q_c)| !i_c || q_c)
            },
            "{:?}, {:?}, {:?}, {:?}, {:?}",
            self,
            r,
            qs,
            [c_q0, c_q1, c_q2, c_q3],
            qs.map(|q| self.collides_with(q))
        );

        [c_q0, c_q1, c_q2, c_q3]
    }
}

/// If e1 intersects with e2 in the first half of e2, it sets all bools in `fst_qs` to true,
/// if e1 intersects with e2 the second half of e2, it sets all bools in `sec_qs` to true.
fn half_intersect<const N: usize>(
    e1: &Edge,
    e2: &Edge,
    fst_qs: [&mut Option<bool>; N],
    sec_qs: [&mut Option<bool>; N],
) {
    if fst_qs.iter().chain(sec_qs.iter()).any(|t| t.is_none())
        && let Some((_, e2_col_loc)) = edge_intersection_half(e1, e2)
    {
        match e2_col_loc {
            CollisionHalf::FirstHalf => {
                for c in fst_qs {
                    *c = Some(true);
                }
            }
            CollisionHalf::Halfway => {
                for c in fst_qs {
                    *c = Some(true);
                }
                for c in sec_qs {
                    *c = Some(true);
                }
            }
            CollisionHalf::SecondHalf => {
                for c in sec_qs {
                    *c = Some(true);
                }
            }
        }
    }
}

#[allow(clippy::inline_always)]
#[inline(always)]
// Similar to `edge_intersection`, but in case of an intersection, it returns in which half for both edge the intersection occurs.
fn edge_intersection_half(e1: &Edge, e2: &Edge) -> Option<(CollisionHalf, CollisionHalf)> {
    let Point(x1, y1) = e1.start;
    let Point(x2, y2) = e1.end;
    let Point(x3, y3) = e2.start;
    let Point(x4, y4) = e2.end;

    //based on: https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
    let t_nom = (x2 - x4) * (y4 - y3) - (y2 - y4) * (x4 - x3);
    let t_denom = (x2 - x1) * (y4 - y3) - (y2 - y1) * (x4 - x3);
    let u_nom = (x2 - x4) * (y2 - y1) - (y2 - y4) * (x2 - x1);
    let u_denom = (x2 - x1) * (y4 - y3) - (y2 - y1) * (x4 - x3);
    if t_denom == 0.0 || u_denom == 0.0 {
        //parallel edges
        return None;
    }

    let t = t_nom / t_denom; //refers to the position along e1
    let u = u_nom / u_denom; //refers to the position along e2
    if (0.0..=1.0).contains(&t) && (0.0..=1.0).contains(&u) {
        let e1_loc = match t.partial_cmp(&0.5).unwrap() {
            Ordering::Greater => CollisionHalf::FirstHalf,
            Ordering::Less => CollisionHalf::SecondHalf,
            Ordering::Equal => CollisionHalf::Halfway,
        };
        let e2_loc = match u.partial_cmp(&0.5).unwrap() {
            Ordering::Greater => CollisionHalf::FirstHalf,
            Ordering::Less => CollisionHalf::SecondHalf,
            Ordering::Equal => CollisionHalf::Halfway,
        };

        return Some((e1_loc, e2_loc));
    }
    None
}

pub enum CollisionHalf {
    FirstHalf,
    Halfway,
    SecondHalf,
}
