use std::borrow::Borrow;

use itertools::Itertools;
use ordered_float::{NotNan, OrderedFloat};

use crate::geometry::Transformation;
use crate::geometry::convex_hull::convex_hull_from_points;
use crate::geometry::fail_fast::{SPSurrogate, SPSurrogateConfig, compute_pole};
use crate::geometry::geo_enums::GeoPosition;
use crate::geometry::geo_traits::{
    CollidesWith, DistanceTo, SeparationDistance, Transformable, TransformableFrom,
};
use crate::geometry::primitives::Circle;
use crate::geometry::primitives::Edge;
use crate::geometry::primitives::Point;
use crate::geometry::primitives::Rect;
use crate::util::FPA;
use anyhow::{Result, bail};

/// A Simple Polygon is a polygon that does not intersect itself and contains no holes.
/// It is a closed shape with a finite number of vertices and edges.
/// [read more](https://en.wikipedia.org/wiki/Simple_polygon)
#[derive(Clone, Debug)]
pub struct SPolygon {
    /// Set of points that form the polygon
    pub vertices: Vec<Point>,
    /// Bounding box
    pub bbox: Rect,
    /// Area of its interior
    pub area: f32,
    /// Maximum distance between any two points in the polygon
    pub diameter: f32,
    /// [Pole of inaccessibility](https://en.wikipedia.org/wiki/Pole_of_inaccessibility) represented as a circle
    pub poi: Circle,
    /// Optional surrogate representation of the polygon (subset of the original)
    pub surrogate: Option<SPSurrogate>,
}

impl SPolygon {
    /// Create a new simple polygon from a set of points, expensive operations are performed here! Use [`Self::clone()`] or [`Self::transform()`] to avoid recomputation.
    pub fn new(mut points: Vec<Point>) -> Result<Self> {
        if points.len() < 3 {
            bail!("Simple polygon must have at least 3 points: {points:?}");
        }
        if points.iter().unique().count() != points.len() {
            bail!("Simple polygon should not contain duplicate points: {points:?}");
        }
        if let Some((e1_idx, e2_idx)) = SPolygon::find_self_intersection(&points) {
            bail!("Simple polygon contains intersecting edges {e1_idx} and {e2_idx}: {points:?}");
        }

        let area = match SPolygon::calculate_area(&points) {
            0.0 => bail!("Simple polygon has no area: {points:?}"),
            area if area < 0.0 => {
                //edges should always be ordered counterclockwise (positive area)
                points.reverse();
                -area
            }
            area => area,
        };

        let diameter = SPolygon::calculate_diameter(points.clone());
        let bbox = SPolygon::generate_bounding_box(&points);
        let poi = SPolygon::calculate_poi(&points, diameter)?;

        Ok(SPolygon {
            vertices: points,
            bbox,
            area,
            diameter,
            poi,
            surrogate: None,
        })
    }

    pub fn generate_surrogate(&mut self, config: SPSurrogateConfig) -> Result<()> {
        //regenerate the surrogate if it is not present or if the config has changed
        match &self.surrogate {
            Some(surrogate) if surrogate.config == config => {}
            _ => self.surrogate = Some(SPSurrogate::new(self, config)?),
        }
        Ok(())
    }

    #[must_use]
    pub fn vertex(&self, i: usize) -> Point {
        self.vertices[i]
    }

    #[must_use]
    pub fn edge(&self, i: usize) -> Edge {
        assert!(i < self.n_vertices(), "index out of bounds");
        let j = if i == self.n_vertices() - 1 { 0 } else { i + 1 };
        Edge {
            start: self.vertices[i],
            end: self.vertices[j],
        }
    }

    pub fn edge_iter(&self) -> impl Iterator<Item = Edge> + '_ {
        (0..self.n_vertices()).map(move |i| self.edge(i))
    }

    #[must_use]
    pub fn n_vertices(&self) -> usize {
        self.vertices.len()
    }

    #[must_use]
    pub fn surrogate(&self) -> &SPSurrogate {
        self.surrogate.as_ref().expect("surrogate not generated")
    }

    #[must_use]
    pub fn calculate_diameter(points: Vec<Point>) -> f32 {
        //The two points furthest apart must be part of the convex hull
        let ch = convex_hull_from_points(points);

        //go through all pairs of points and find the pair with the largest distance
        let sq_diam = ch
            .iter()
            .tuple_combinations()
            .map(|(p1, p2)| p1.sq_distance_to(p2))
            .max_by_key(|sq_d| NotNan::new(*sq_d).unwrap())
            .expect("convex hull is empty");

        sq_diam.sqrt()
    }

    #[must_use]
    pub fn generate_bounding_box(points: &[Point]) -> Rect {
        let (mut x_min, mut y_min) = (f32::MAX, f32::MAX);
        let (mut x_max, mut y_max) = (f32::MIN, f32::MIN);

        for point in points {
            x_min = x_min.min(point.0);
            y_min = y_min.min(point.1);
            x_max = x_max.max(point.0);
            y_max = y_max.max(point.1);
        }
        Rect::try_new(x_min, y_min, x_max, y_max).unwrap()
    }

    //https://en.wikipedia.org/wiki/Shoelace_formula
    //counterclockwise = positive area, clockwise = negative area
    #[must_use]
    pub fn calculate_area(points: &[Point]) -> f32 {
        let mut sigma: f32 = 0.0;
        for i in 0..points.len() {
            //next point
            let j = (i + 1) % points.len();

            let (x_i, y_i) = points[i].into();
            let (x_j, y_j) = points[j].into();

            sigma += (y_i + y_j) * (x_i - x_j);
        }

        0.5 * sigma
    }

    pub fn calculate_poi(points: &[Point], diameter: f32) -> Result<Circle> {
        //need to make a dummy simple polygon, because the pole generation algorithm
        //relies on many of the methods provided by the simple polygon struct
        let dummy_sp = {
            let bbox = SPolygon::generate_bounding_box(points);
            let area = SPolygon::calculate_area(points);
            let dummy_poi = Circle::try_new(Point(f32::MAX, f32::MAX), f32::MAX).unwrap();

            SPolygon {
                vertices: points.to_vec(),
                bbox,
                area,
                diameter,
                poi: dummy_poi,
                surrogate: None,
            }
        };

        compute_pole(&dummy_sp, &[])
    }

    #[must_use]
    pub fn centroid(&self) -> Point {
        //based on: https://en.wikipedia.org/wiki/Centroid#Of_a_polygon

        let area = self.area;
        let mut c_x = 0.0;
        let mut c_y = 0.0;

        for i in 0..self.n_vertices() {
            let j = if i == self.n_vertices() - 1 { 0 } else { i + 1 };
            let Point(x_i, y_i) = self.vertex(i);
            let Point(x_j, y_j) = self.vertex(j);
            c_x += (x_i + x_j) * (x_i * y_j - x_j * y_i);
            c_y += (y_i + y_j) * (x_i * y_j - x_j * y_i);
        }

        c_x /= 6.0 * area;
        c_y /= 6.0 * area;

        (c_x, c_y).into()
    }

    fn find_self_intersection(points: &[Point]) -> Option<(usize, usize)> {
        let edge = |i| Edge {
            start: points[i],
            end: points[(i + 1) % points.len()],
        };
        let are_neighboring_edges = |i, j| i + 1 == j || (i == 0 && j == points.len() - 1);

        (0..points.len()).combinations(2).find_map(|pair| {
            let (i, j) = (pair[0], pair[1]);
            (!are_neighboring_edges(i, j) && edge(i).collides_with(&edge(j))).then_some((i, j))
        })
    }
}

impl Transformable for SPolygon {
    fn transform(&mut self, t: &Transformation) -> &mut Self {
        //destructuring pattern to ensure that the code is updated when the struct changes
        let SPolygon {
            vertices: points,
            bbox,
            area: _,
            diameter: _,
            poi,
            surrogate,
        } = self;

        //transform all points of the simple poly
        for p in points.iter_mut() {
            p.transform(t);
        }

        poi.transform(t);

        //transform the surrogate
        if let Some(surrogate) = surrogate.as_mut() {
            surrogate.transform(t);
        }

        //regenerate bounding box
        *bbox = SPolygon::generate_bounding_box(points);

        self
    }
}

impl TransformableFrom for SPolygon {
    fn transform_from(&mut self, reference: &Self, t: &Transformation) -> &mut Self {
        //destructuring pattern to ensure that the code is updated when the struct changes
        let SPolygon {
            vertices: points,
            bbox,
            area: _,
            diameter: _,
            poi,
            surrogate,
        } = self;

        for (p, ref_p) in points.iter_mut().zip(&reference.vertices) {
            p.transform_from(ref_p, t);
        }

        poi.transform_from(&reference.poi, t);

        //transform the surrogate
        if let Some(surrogate) = surrogate.as_mut() {
            surrogate.transform_from(reference.surrogate(), t);
        }
        //regenerate bounding box
        *bbox = SPolygon::generate_bounding_box(points);

        self
    }
}

impl CollidesWith<Point> for SPolygon {
    fn collides_with(&self, point: &Point) -> bool {
        //based on the ray casting algorithm: https://en.wikipedia.org/wiki/Point_in_polygon#Ray_casting_algorithm
        if self.bbox.collides_with(point) {
            //horizontal ray shot to the right.
            //Starting from the point to another point that is certainly outside the shape
            let point_outside = Point(self.bbox.x_max + self.bbox.width(), point.1);
            let ray = Edge {
                start: *point,
                end: point_outside,
            };

            let mut n_intersections = 0;
            for edge in self.edge_iter() {
                //Check if the ray does not go through (or almost through) a vertex
                //This can result in funky behaviour, which could incorrect results
                //Therefore we handle this case
                let (s_x, s_y) = (FPA(edge.start.0), FPA(edge.start.1));
                let (e_x, e_y) = (FPA(edge.end.0), FPA(edge.end.1));
                let (p_x, p_y) = (FPA(point.0), FPA(point.1));

                if (s_y == p_y && s_x > p_x) || (e_y == p_y && e_x > p_x) {
                    //in this case, the ray passes through (or dangerously close to) a vertex
                    //We handle this case by only counting an intersection if the edge is below the ray
                    if s_y < p_y || e_y < p_y {
                        n_intersections += 1;
                    }
                } else if ray.collides_with(&edge) {
                    n_intersections += 1;
                }
            }
            n_intersections % 2 == 1
        } else {
            false
        }
    }
}

impl DistanceTo<Point> for SPolygon {
    fn distance_to(&self, point: &Point) -> f32 {
        self.sq_distance_to(point).sqrt()
    }
    fn sq_distance_to(&self, point: &Point) -> f32 {
        if self.collides_with(point) {
            0.0
        } else {
            self.edge_iter()
                .map(|edge| edge.sq_distance_to(point))
                .min_by(|a, b| a.partial_cmp(b).unwrap())
                .unwrap()
        }
    }
}

impl SeparationDistance<Point> for SPolygon {
    fn separation_distance(&self, point: &Point) -> (GeoPosition, f32) {
        let (position, sq_distance) = self.sq_separation_distance(point);
        (position, sq_distance.sqrt())
    }

    fn sq_separation_distance(&self, point: &Point) -> (GeoPosition, f32) {
        let distance_to_closest_edge = self
            .edge_iter()
            .map(|edge| edge.sq_distance_to(point))
            .min_by_key(|sq_d| OrderedFloat(*sq_d))
            .unwrap();

        if self.collides_with(point) {
            (GeoPosition::Interior, distance_to_closest_edge)
        } else {
            (GeoPosition::Exterior, distance_to_closest_edge)
        }
    }
}

impl<T> From<T> for SPolygon
where
    T: Borrow<Rect>,
{
    fn from(r: T) -> Self {
        let r = r.borrow();
        SPolygon::new(vec![
            (r.x_min, r.y_min).into(),
            (r.x_max, r.y_min).into(),
            (r.x_max, r.y_max).into(),
            (r.x_min, r.y_max).into(),
        ])
        .unwrap()
    }
}
