use rand::Rng;
use rand_distr::Distribution;
use rand_distr::Normal;
use std::f32::consts::PI;

use crate::samplers::rotation_distr::NormalRotDistr;
use jagua_rs::entities::Item;
use jagua_rs::geometry::DTransformation;
use jagua_rs::geometry::primitives::Rect;

/// The stddev of translation starts at 1% and ends at 0.05% of the largest dimension of the bounding box.
pub const SD_TRANSL: (f32, f32) = (0.01, 0.0005);

/// The stddev of rotation starts at 2° and ends at 0.5°.
pub const SD_ROT: (f32, f32) = (2.0 * PI / 180.0, 0.5 * PI / 180.0);

///Creates `Transformation` samples for a given item.
///The samples are drawn from normal distributions with decaying standard deviations.
///Each time an improvement is found, the mean of the distributions is shifted to the new best transformation.
pub struct LSSampler {
    normal_x: Normal<f32>,
    normal_y: Normal<f32>,
    normal_r: NormalRotDistr,
    sd_transl: f32,
    sd_rot: f32,
    sd_transl_range: (f32, f32),
    sd_rot_range: (f32, f32),
    pub(crate) n_samples: usize,
}

impl LSSampler {
    pub fn new(
        item: &Item,
        ref_transform: DTransformation,
        sd_transl_range: (f32, f32),
        sd_rot_range: (f32, f32),
    ) -> Self {
        let sd_transl = sd_transl_range.0;
        let sd_rot = sd_rot_range.0;

        let normal_x = Normal::new(ref_transform.translation().0, sd_transl).unwrap();
        let normal_y = Normal::new(ref_transform.translation().1, sd_transl).unwrap();
        let normal_r = NormalRotDistr::from_item(item, ref_transform.rotation(), sd_rot);

        Self {
            normal_x,
            normal_y,
            normal_r,
            sd_transl,
            sd_rot,
            sd_transl_range,
            sd_rot_range,
            n_samples: 0,
        }
    }

    /// Creates a new sampler with default standard deviation ranges: [SD_TRANSL] and [SD_ROT].
    pub fn from_defaults(item: &Item, ref_transform: DTransformation, bbox: Rect) -> Self {
        let max_dim = f32::max(bbox.width(), bbox.height());
        let sd_transl_range = (SD_TRANSL.0 * max_dim, SD_TRANSL.1 * max_dim);
        Self::new(item, ref_transform, sd_transl_range, SD_ROT)
    }

    /// Shifts the mean of the normal distributions to the given reference transformation.
    pub fn shift_mean(&mut self, ref_transform: DTransformation) {
        self.normal_x = Normal::new(ref_transform.translation().0, self.sd_transl).unwrap();
        self.normal_y = Normal::new(ref_transform.translation().1, self.sd_transl).unwrap();
        self.normal_r.set_mean(ref_transform.rotation());
    }

    /// Sets the standard deviation of the normal distributions.
    pub fn set_stddev(&mut self, stddev_transl: f32, stddev_rot: f32) {
        assert!(stddev_transl >= 0.0 && stddev_rot >= 0.0);

        self.sd_transl = stddev_transl;
        self.sd_rot = stddev_rot;
        self.normal_x = Normal::new(self.normal_x.mean(), self.sd_transl).unwrap();
        self.normal_y = Normal::new(self.normal_y.mean(), self.sd_transl).unwrap();
        self.normal_r.set_stddev(self.sd_rot);
    }

    /// Adjusts the standard deviation according to the fraction of samples that have passed,
    /// following an exponential decay curve.
    /// `progress_pct` is a value in [0, 1].
    ///
    /// f(0) = init;
    /// f(1) = end;
    /// f(x) = init * (end/init)^x;
    pub fn decay_stddev(&mut self, progress_pct: f32) {
        let calc_stddev = |(init, end): (f32, f32), pct: f32| init * (end / init).powf(pct);
        self.set_stddev(
            calc_stddev(self.sd_transl_range, progress_pct),
            calc_stddev(self.sd_rot_range, progress_pct),
        );
    }

    /// Samples a transformation from the distribution.
    pub fn sample(&mut self, rng: &mut impl Rng) -> DTransformation {
        self.n_samples += 1;

        DTransformation::new(
            self.normal_r.sample(rng),
            (self.normal_x.sample(rng), self.normal_y.sample(rng)),
        )
    }
}
