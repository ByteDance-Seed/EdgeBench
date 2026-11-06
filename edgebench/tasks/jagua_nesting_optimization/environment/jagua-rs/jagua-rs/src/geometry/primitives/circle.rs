use crate::geometry::Transformation;
use crate::geometry::geo_enums::GeoPosition;
use crate::geometry::geo_traits::{
    CollidesWith, DistanceTo, SeparationDistance, Transformable, TransformableFrom,
};
use crate::geometry::primitives::Edge;
use crate::geometry::primitives::Point;
use crate::geometry::primitives::Rect;
use anyhow::Result;
use anyhow::ensure;
use std::cmp::Ordering;
use std::f32::consts::PI;

/// Circle
#[derive(Clone, Debug, PartialEq, Copy)]
pub struct Circle {
    pub center: Point,
    pub radius: f32,
}

impl Circle {
    pub fn try_new(center: Point, radius: f32) -> Result<Self> {
        ensure!(
            radius.is_finite() && radius >= 0.0,
            "invalid circle radius: {radius}",
        );
        ensure!(
            center.0.is_finite() && center.1.is_finite(),
            "invalid circle center: {center:?}",
        );

        Ok(Self { center, radius })
    }

    /// Returns the smallest possible circle that fully contains all ```circles```
    pub fn bounding_circle<'a>(circles: impl IntoIterator<Item = &'a Circle>) -> Circle {
        let mut circles = circles.into_iter();
        let mut bounding_circle = *circles.next().expect("no circles provided");

        for circle in circles {
            let distance_between_centers = bounding_circle.center.distance_to(&circle.center);
            if bounding_circle.radius < distance_between_centers + circle.radius {
                // circle not contained in bounding circle, expand
                let diameter = Edge {
                    start: bounding_circle.center,
                    end: circle.center,
                }
                .extend_at_front(bounding_circle.radius)
                .extend_at_back(circle.radius);

                bounding_circle = Circle {
                    center: diameter.centroid(),
                    radius: diameter.length() / 2.0,
                }
            }
        }
        bounding_circle
    }

    #[must_use]
    pub fn area(&self) -> f32 {
        self.radius * self.radius * PI
    }

    #[must_use]
    pub fn bbox(&self) -> Rect {
        let (r, x, y) = (self.radius, self.center.0, self.center.1);
        Rect {
            x_min: x - r,
            y_min: y - r,
            x_max: x + r,
            y_max: y + r,
        }
    }

    #[must_use]
    pub fn diameter(&self) -> f32 {
        self.radius * 2.0
    }
}

impl Transformable for Circle {
    fn transform(&mut self, t: &Transformation) -> &mut Self {
        let Circle { center, radius: _ } = self;
        center.transform(t);
        self
    }
}

impl TransformableFrom for Circle {
    fn transform_from(&mut self, reference: &Self, t: &Transformation) -> &mut Self {
        let Circle { center, radius: _ } = self;
        center.transform_from(&reference.center, t);
        self
    }
}

impl CollidesWith<Circle> for Circle {
    fn collides_with(&self, other: &Circle) -> bool {
        let (cx1, cx2) = (self.center.0, other.center.0);
        let (cy1, cy2) = (self.center.1, other.center.1);
        let (r1, r2) = (self.radius, other.radius);

        let dx = cx1 - cx2;
        let dy = cy1 - cy2;
        let sq_d = dx * dx + dy * dy;

        sq_d <= (r1 + r2) * (r1 + r2)
    }
}

impl CollidesWith<Edge> for Circle {
    fn collides_with(&self, edge: &Edge) -> bool {
        edge.sq_distance_to(&self.center) <= self.radius.powi(2)
    }
}

impl CollidesWith<Rect> for Circle {
    #[inline(always)]
    fn collides_with(&self, rect: &Rect) -> bool {
        //Based on: https://yal.cc/rectangle-circle-intersection-test/

        let Point(c_x, c_y) = self.center;

        //x and y coordinates inside the rectangle, closest to the circle center
        let nearest_x = f32::max(rect.x_min, f32::min(c_x, rect.x_max));
        let nearest_y = f32::max(rect.y_min, f32::min(c_y, rect.y_max));

        (nearest_x - c_x).powi(2) + (nearest_y - c_y).powi(2) <= self.radius.powi(2)
    }
}

impl CollidesWith<Point> for Circle {
    fn collides_with(&self, point: &Point) -> bool {
        point.sq_distance_to(&self.center) <= self.radius.powi(2)
    }
}

impl DistanceTo<Point> for Circle {
    fn distance_to(&self, point: &Point) -> f32 {
        let Point(x, y) = point;
        let Point(cx, cy) = self.center;
        let sq_d = (x - cx).powi(2) + (y - cy).powi(2);
        if sq_d < self.radius.powi(2) {
            0.0 //point is inside circle
        } else {
            //point is outside circle
            f32::sqrt(sq_d) - self.radius
        }
    }

    fn sq_distance_to(&self, other: &Point) -> f32 {
        self.distance_to(other).powi(2)
    }
}

impl SeparationDistance<Point> for Circle {
    fn separation_distance(&self, point: &Point) -> (GeoPosition, f32) {
        let Point(x, y) = point;
        let Point(cx, cy) = self.center;
        let d_center = f32::sqrt((x - cx).powi(2) + (y - cy).powi(2));
        match d_center.partial_cmp(&self.radius).unwrap() {
            Ordering::Less | Ordering::Equal => (GeoPosition::Interior, self.radius - d_center),
            Ordering::Greater => (GeoPosition::Exterior, d_center - self.radius),
        }
    }

    fn sq_separation_distance(&self, point: &Point) -> (GeoPosition, f32) {
        let (pos, distance) = self.separation_distance(point);
        (pos, distance.powi(2))
    }
}

impl DistanceTo<Circle> for Circle {
    fn distance_to(&self, other: &Circle) -> f32 {
        match self.separation_distance(other) {
            (GeoPosition::Interior, _) => 0.0,
            (GeoPosition::Exterior, d) => d,
        }
    }

    fn sq_distance_to(&self, other: &Circle) -> f32 {
        self.distance_to(other).powi(2)
    }
}

impl SeparationDistance<Circle> for Circle {
    fn separation_distance(&self, other: &Circle) -> (GeoPosition, f32) {
        let sq_center_dist = self.center.sq_distance_to(&other.center);
        let sq_radii_sum = (self.radius + other.radius).powi(2);
        if sq_center_dist < sq_radii_sum {
            let dist = sq_radii_sum.sqrt() - sq_center_dist.sqrt();
            (GeoPosition::Interior, dist)
        } else {
            let dist = sq_center_dist.sqrt() - sq_radii_sum.sqrt();
            (GeoPosition::Exterior, dist)
        }
    }

    fn sq_separation_distance(&self, other: &Circle) -> (GeoPosition, f32) {
        let (pos, distance) = self.separation_distance(other);
        (pos, distance.powi(2))
    }
}

impl DistanceTo<Edge> for Circle {
    fn distance_to(&self, e: &Edge) -> f32 {
        match self.separation_distance(e) {
            (GeoPosition::Interior, _) => 0.0,
            (GeoPosition::Exterior, d) => d,
        }
    }

    fn sq_distance_to(&self, e: &Edge) -> f32 {
        self.distance_to(e).powi(2)
    }
}

impl SeparationDistance<Edge> for Circle {
    fn separation_distance(&self, e: &Edge) -> (GeoPosition, f32) {
        let distance_to_center = e.distance_to(&self.center);
        if distance_to_center < self.radius {
            (GeoPosition::Interior, self.radius - distance_to_center)
        } else {
            (GeoPosition::Exterior, distance_to_center - self.radius)
        }
    }

    fn sq_separation_distance(&self, e: &Edge) -> (GeoPosition, f32) {
        let (pos, distance) = self.separation_distance(e);
        (pos, distance.powi(2))
    }
}
