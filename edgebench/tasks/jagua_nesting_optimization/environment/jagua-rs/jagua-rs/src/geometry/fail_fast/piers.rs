use itertools::{Itertools, izip};
use ndarray::Array;
use ordered_float::NotNan;
use rand_distr::num_traits::FloatConst;

use crate::geometry::Transformation;
use crate::geometry::geo_traits::{CollidesWith, DistanceTo, Transformable};
use crate::geometry::primitives::Circle;
use crate::geometry::primitives::Edge;
use crate::geometry::primitives::Point;
use crate::geometry::primitives::Rect;
use crate::geometry::primitives::SPolygon;

use anyhow::{Result, bail};

static RAYS_PER_ANGLE: usize = if cfg!(debug_assertions) { 10 } else { 200 };
static N_ANGLES: usize = if cfg!(debug_assertions) { 4 } else { 90 };
static N_POINTS_PER_DIMENSION: usize = if cfg!(debug_assertions) { 10 } else { 100 };
static CLIPPING_TRIM: f32 = 0.999;
static ACTION_RADIUS_RATIO: f32 = 0.10;

/// Generates a set of `n` *piers* - line segments fully contained within `shape`.
/// This function generates them in such a way as to *cover* areas of the `shape` that are
/// poorly represented by `poles` as well as possible.
pub fn generate_piers(shape: &SPolygon, n: usize, poles: &[Circle]) -> Result<Vec<Edge>> {
    if n == 0 {
        return Ok(vec![]);
    }

    //Start by creating a set of N_TESTS_PER_ANGLE vertical lines across the bounding box
    let bbox = shape.bbox;
    let expanded_bbox = bbox.clone().inflate_to_square();
    let centroid = shape.centroid();
    //vertical ray from the centroid
    let base_ray = Edge::try_new(
        Point(centroid.0, centroid.1 - 2.0 * expanded_bbox.height()),
        Point(centroid.0, centroid.1 + 2.0 * expanded_bbox.height()),
    )
    .unwrap();

    let transformations = generate_ray_transformations(expanded_bbox, RAYS_PER_ANGLE, N_ANGLES);

    //transform the base edge by each transformation
    let rays = transformations
        .into_iter()
        .map(|t| base_ray.transform_clone(&t))
        .collect_vec();

    //clip the lines to the shape
    let clipped_rays = rays.iter().flat_map(|l| clip(shape, l)).collect_vec();
    let grid_of_unrepresented_points =
        generate_unrepresented_point_grid(expanded_bbox, shape, poles, N_POINTS_PER_DIMENSION);

    let mut selected_piers = Vec::new();

    let radius_of_ray_influence = ACTION_RADIUS_RATIO * expanded_bbox.width();
    let forfeit_distance = f32::sqrt(bbox.width().powi(2) * bbox.height().powi(2));

    for _ in 0..n {
        let min_distance_selected_rays = min_distances_to_rays(
            &grid_of_unrepresented_points,
            &selected_piers,
            forfeit_distance,
        );
        let min_distance_poles =
            min_distances_to_poles(&grid_of_unrepresented_points, poles, forfeit_distance);

        let loss_values = clipped_rays
            .iter()
            .map(|new_ray| {
                loss_function(
                    new_ray,
                    &grid_of_unrepresented_points,
                    &min_distance_selected_rays,
                    &min_distance_poles,
                    radius_of_ray_influence,
                )
            })
            .map(|x| NotNan::new(x).unwrap())
            .collect_vec();

        let min_loss_ray = clipped_rays
            .iter()
            .enumerate()
            .min_by_key(|(i, _)| loss_values[*i])
            .map(|(_i, ray)| ray);

        match min_loss_ray {
            None => bail!("no ray found"),
            Some(ray) => selected_piers.push(*ray),
        }
    }
    Ok(selected_piers)
}

#[allow(clippy::cast_precision_loss)]
fn generate_ray_transformations(
    bbox: Rect,
    rays_per_angle: usize,
    n_angles: usize,
) -> Vec<Transformation> {
    //translations
    let dx = bbox.width() / rays_per_angle as f32;
    let translations = (0..rays_per_angle)
        .map(|i| bbox.x_min + dx * i as f32)
        .map(|x| Transformation::from_translation((x, 0.0)))
        .collect_vec();

    let angles = Array::linspace(0.0, f32::PI(), n_angles + 1).to_vec();
    let angles_slice = &angles[0..n_angles]; //skip the last angle, which is the same as the first

    //rotate the translations by each angle
    angles_slice
        .iter()
        .flat_map(|angle| {
            translations
                .iter()
                .cloned()
                .map(move |translation| translation.rotate(*angle))
        })
        .collect_vec()
}

//clips a ray against the border of a polygon, potentially creating multiple "clips"
fn clip(shape: &SPolygon, ray: &Edge) -> Vec<Edge> {
    //both ends of the ray should be outside the shape
    assert!(!shape.collides_with(&ray.start) && !shape.collides_with(&ray.end));

    //collect all intersections of the ray with the shape, sorted by distance to the ray's start
    let intersections = shape
        .edge_iter()
        .filter_map(|edge| edge.collides_at(ray))
        .sorted_by_key(|p| NotNan::new(ray.start.distance_to(p)).unwrap())
        .collect_vec();

    //every pair of (sorted) intersections defines a clipped line
    intersections
        .chunks(2)
        .filter_map(|pair| {
            if pair.len() == 1 {
                return None;
            }
            let start = pair[0];
            let end = pair[1];
            if start == end {
                None
            } else {
                Some(Edge::try_new(start, end).unwrap().scale(CLIPPING_TRIM))
            }
        })
        .collect_vec()
}

fn generate_unrepresented_point_grid(
    bbox: Rect,
    shape: &SPolygon,
    poles: &[Circle],
    n_points_per_dimension: usize,
) -> Vec<Point> {
    let x_range = Array::linspace(bbox.x_min, bbox.x_max, n_points_per_dimension);
    let y_range = Array::linspace(bbox.y_min, bbox.y_max, n_points_per_dimension);

    x_range
        .iter()
        .flat_map(|x| {
            y_range
                .iter()
                .map(move |y| Point::from((*x, *y))) //create the points
                .filter(|p| shape.collides_with(p)) //make sure they are in the shape
                .filter(|p| poles.iter().all(|c| !c.collides_with(p)))
        })
        .collect_vec()
}

fn loss_function(
    new_ray: &Edge,
    point_grid: &[Point],
    min_distance_to_rays: &[f32],
    min_distance_to_poles: &[f32],
    radius_of_ray_influence: f32,
) -> f32 {
    //every point in the grid gets a certain score, sum of all these scores is the loss function
    //the score depends on how close it is to being "represented" by either a pole or a ray
    //rays have a certain radius of influence, outside which they don't count. Poles have no such radius
    //the score is the squared distance to the closest ray or pole

    izip!(
        point_grid.iter(),
        min_distance_to_rays.iter(),
        min_distance_to_poles.iter()
    )
    .map(|(p, min_distance_to_existing_ray, min_distance_to_pole)| {
        let distance_to_new_ray = new_ray.distance_to(p);

        let min_distance_to_ray = f32::min(*min_distance_to_existing_ray, distance_to_new_ray);

        if min_distance_to_ray < radius_of_ray_influence {
            f32::min(*min_distance_to_pole, min_distance_to_ray)
        } else {
            *min_distance_to_pole
        }
    })
    .map(|d| d.powi(2))
    .sum()
}

fn min_distances_to_rays(points: &[Point], rays: &[Edge], forfeit_distance: f32) -> Vec<f32> {
    points
        .iter()
        .map(|p| {
            rays.iter()
                .map(|r| r.distance_to(p))
                .fold(forfeit_distance, f32::min)
        })
        .collect_vec()
}

fn min_distances_to_poles(points: &[Point], poles: &[Circle], forfeit_distance: f32) -> Vec<f32> {
    points
        .iter()
        .map(|p| {
            poles
                .iter()
                .map(|c| c.distance_to(p))
                .fold(forfeit_distance, f32::min)
        })
        .collect_vec()
}
