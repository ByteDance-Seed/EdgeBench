use crate::samplers::rotation_distr::UniformRotDistr;
use jagua_rs::entities::Item;
use jagua_rs::geometry::DTransformation;
use jagua_rs::geometry::primitives::Rect;
use rand::Rng;
use rand_distr::Distribution;
use rand_distr::Uniform;

/// Samples a [`DTransformation`] uniformly at random in a given [`Rect`] and [`UniformRotDistr`].
pub struct UniformRectSampler {
    pub bbox: Rect,
    pub uniform_x: Uniform<f32>,
    pub uniform_y: Uniform<f32>,
    pub uniform_r: UniformRotDistr,
}

impl UniformRectSampler {
    pub fn new(bbox: Rect, item: &Item) -> Self {
        let uniform_x = Uniform::new(bbox.x_min, bbox.x_max).unwrap();
        let uniform_y = Uniform::new(bbox.y_min, bbox.y_max).unwrap();
        let uniform_r = UniformRotDistr::from_item(item);
        Self {
            bbox,
            uniform_x,
            uniform_y,
            uniform_r,
        }
    }

    pub fn sample(&self, rng: &mut impl Rng) -> DTransformation {
        let r_sample = self.uniform_r.sample(rng);
        let x_sample = self.uniform_x.sample(rng);
        let y_sample = self.uniform_y.sample(rng);

        DTransformation::new(r_sample, (x_sample, y_sample))
    }
}
