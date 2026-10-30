use crate::geometry::Transformation;
use crate::geometry::geo_traits::{CollidesWith, DistanceTo, Transformable, TransformableFrom};
use crate::geometry::primitives::Point;
use crate::geometry::primitives::Rect;
use anyhow::Result;
use anyhow::ensure;

/// Line segment between two [`Point`]s
#[derive(Clone, Debug, PartialEq, Copy)]
pub struct Edge {
    pub start: Point,
    pub end: Point,
}

impl Edge {
    pub fn try_new(start: Point, end: Point) -> Result<Self> {
        ensure!(start != end, "degenerate edge, {start:?} == {end:?}");
        Ok(Edge { start, end })
    }

    #[must_use]
    pub fn extend_at_front(mut self, d: f32) -> Self {
        //extend the line at the front by distance d
        let (dx, dy) = (self.end.0 - self.start.0, self.end.1 - self.start.1);
        let l = self.length();
        self.start.0 -= dx * (d / l);
        self.start.1 -= dy * (d / l);
        self
    }

    #[must_use]
    pub fn extend_at_back(mut self, d: f32) -> Self {
        //extend the line at the back by distance d
        let (dx, dy) = (self.end.0 - self.start.0, self.end.1 - self.start.1);
        let l = self.length();
        self.end.0 += dx * (d / l);
        self.end.1 += dy * (d / l);
        self
    }

    #[must_use]
    pub fn scale(mut self, factor: f32) -> Self {
        let (dx, dy) = (self.end.0 - self.start.0, self.end.1 - self.start.1);
        self.start.0 -= dx * (factor - 1.0) / 2.0;
        self.start.1 -= dy * (factor - 1.0) / 2.0;
        self.end.0 += dx * (factor - 1.0) / 2.0;
        self.end.1 += dy * (factor - 1.0) / 2.0;
        self
    }

    #[must_use]
    pub fn reverse(mut self) -> Self {
        std::mem::swap(&mut self.start, &mut self.end);
        self
    }

    #[must_use]
    pub fn collides_at(&self, other: &Edge) -> Option<Point> {
        match edge_intersection(self, other, true) {
            Intersection::No => None,
            Intersection::Yes(point) => Some(
                point.expect("Intersection::Yes, but returned no point when this was requested"),
            ),
        }
    }

    /// Returns the closest point which lies on the edge to the given point
    #[must_use]
    #[allow(clippy::many_single_char_names)]
    pub fn closest_point_on_edge(&self, point: &Point) -> Point {
        //from https://stackoverflow.com/a/6853926
        let Point(x1, y1) = self.start;
        let Point(x2, y2) = self.end;
        let Point(x, y) = point;

        let a = x - x1;
        let b = y - y1;
        let c = x2 - x1;
        let d = y2 - y1;

        let dot = a * c + b * d;
        let len_sq = c * c + d * d;
        let mut param = -1.0;
        if len_sq != 0.0 {
            param = dot / len_sq;
        }
        let (xx, yy) = match param {
            p if p < 0.0 => (x1, y1),              //start is the closest point
            p if p > 1.0 => (x2, y2),              //end is the closest point
            _ => (x1 + param * c, y1 + param * d), //closest point is on the edge
        };

        Point(xx, yy)
    }

    #[must_use]
    pub fn x_min(&self) -> f32 {
        f32::min(self.start.0, self.end.0)
    }

    #[must_use]
    pub fn y_min(&self) -> f32 {
        f32::min(self.start.1, self.end.1)
    }

    #[must_use]
    pub fn x_max(&self) -> f32 {
        f32::max(self.start.0, self.end.0)
    }

    #[must_use]
    pub fn y_max(&self) -> f32 {
        f32::max(self.start.1, self.end.1)
    }

    #[must_use]
    pub fn length(&self) -> f32 {
        self.start.distance_to(&self.end)
    }

    #[must_use]
    pub fn centroid(&self) -> Point {
        Point(
            f32::midpoint(self.start.0, self.end.0),
            f32::midpoint(self.start.1, self.end.1),
        )
    }

    #[must_use]
    pub fn bbox(&self) -> Rect {
        Rect {
            x_min: self.x_min(),
            y_min: self.y_min(),
            x_max: self.x_max(),
            y_max: self.y_max(),
        }
    }
}

impl Transformable for Edge {
    fn transform(&mut self, t: &Transformation) -> &mut Self {
        let Edge { start, end } = self;
        start.transform(t);
        end.transform(t);

        self
    }
}

impl TransformableFrom for Edge {
    fn transform_from(&mut self, reference: &Self, t: &Transformation) -> &mut Self {
        let Edge { start, end } = self;
        start.transform_from(&reference.start, t);
        end.transform_from(&reference.end, t);

        self
    }
}

impl DistanceTo<Point> for Edge {
    #[inline(always)]
    fn distance_to(&self, point: &Point) -> f32 {
        f32::sqrt(self.sq_distance_to(point))
    }

    #[inline(always)]
    fn sq_distance_to(&self, point: &Point) -> f32 {
        let Point(x, y) = point;
        let Point(xx, yy) = self.closest_point_on_edge(point);

        let (dx, dy) = (x - xx, y - yy);
        dx.powi(2) + dy.powi(2)
    }
}

impl CollidesWith<Edge> for Edge {
    #[inline(always)]
    fn collides_with(&self, other: &Edge) -> bool {
        match edge_intersection(self, other, false) {
            Intersection::No => false,
            Intersection::Yes(_) => true,
        }
    }
}

impl CollidesWith<Rect> for Edge {
    #[inline(always)]
    fn collides_with(&self, other: &Rect) -> bool {
        other.collides_with(self)
    }
}

#[inline(always)]
fn edge_intersection(e1: &Edge, e2: &Edge, calc_loc: bool) -> Intersection {
    let Point(x1, y1) = e1.start;
    let Point(x2, y2) = e1.end;
    let Point(x3, y3) = e2.start;
    let Point(x4, y4) = e2.end;

    // Early exit if bounding boxes do not overlap
    {
        let x_min_e1 = x1.min(x2);
        let x_max_e1 = x1.max(x2);
        let y_min_e1 = y1.min(y2);
        let y_max_e1 = y1.max(y2);

        let x_min_e2 = x3.min(x4);
        let x_max_e2 = x3.max(x4);
        let y_min_e2 = y3.min(y4);
        let y_max_e2 = y3.max(y4);

        let x_axis_no_overlap = x_min_e1.max(x_min_e2) > x_max_e1.min(x_max_e2);
        let y_axis_no_overlap = y_min_e1.max(y_min_e2) > y_max_e1.min(y_max_e2);

        if x_axis_no_overlap || y_axis_no_overlap {
            return Intersection::No;
        }
    }

    //based on: https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
    let t_nom = (x2 - x4) * (y4 - y3) - (y2 - y4) * (x4 - x3);
    let t_denom = (x2 - x1) * (y4 - y3) - (y2 - y1) * (x4 - x3);
    let u_nom = (x2 - x4) * (y2 - y1) - (y2 - y4) * (x2 - x1);
    let u_denom = (x2 - x1) * (y4 - y3) - (y2 - y1) * (x4 - x3);

    if t_denom == 0.0 || u_denom == 0.0 {
        //parallel edges
        return Intersection::No;
    }

    let t = t_nom / t_denom;
    let u = u_nom / u_denom;
    if (0.0..=1.0).contains(&t) && (0.0..=1.0).contains(&u) {
        //intersection point is within the bounds of both edges
        let loc = if calc_loc {
            Some(Point(x2 + t * (x1 - x2), y2 + t * (y1 - y2)))
        } else {
            None
        };
        return Intersection::Yes(loc);
    }
    Intersection::No
}

enum Intersection {
    Yes(Option<Point>),
    No,
}
