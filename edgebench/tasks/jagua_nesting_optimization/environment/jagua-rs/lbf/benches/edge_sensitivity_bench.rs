use crate::util::N_ITEMS_REMOVED;
use criterion::measurement::WallTime;
use criterion::{BenchmarkGroup, BenchmarkId, Criterion, criterion_group, criterion_main};
use itertools::Itertools;
use jagua_rs::collision_detection::hazards::filter::NoFilter;
use jagua_rs::entities::Instance;
use jagua_rs::geometry::geo_traits::TransformableFrom;
use jagua_rs::geometry::primitives::Point;
use jagua_rs::geometry::primitives::SPolygon;
use jagua_rs::probs::spp::entities::SPInstance;
use lbf::config::LBFConfig;
use lbf::samplers::uniform_rect_sampler::UniformRectSampler;
use rand::SeedableRng;
use rand::prelude::SmallRng;
use std::sync::Arc;

criterion_main!(benches);
criterion_group!(
    benches,
    edge_sensitivity_bench_no_ff,
    edge_sensitivity_bench_with_ff
);

mod util;

const EDGE_MULTIPLIERS: [u8; 5] = [1, 2, 4, 8, 16];

const N_TOTAL_SAMPLES: usize = 100_000;
const N_SAMPLES_PER_ITER: usize = 1000;

fn edge_sensitivity_bench_no_ff(c: &mut Criterion) {
    let mut config = util::create_base_config();
    config.cde_config.item_surrogate_config.n_ff_poles = 0;
    config.cde_config.item_surrogate_config.n_ff_piers = 0;

    let group = c.benchmark_group("edge_sensitivity_bench_no_ff");
    edge_sensitivity_bench(config, group);
}

fn edge_sensitivity_bench_with_ff(c: &mut Criterion) {
    let config = util::create_base_config();
    let group = c.benchmark_group("edge_sensitivity_bench_ff");
    edge_sensitivity_bench(config, group);
}

fn edge_sensitivity_bench(config: LBFConfig, mut g: BenchmarkGroup<WallTime>) {
    for edge_multiplier in EDGE_MULTIPLIERS {
        let instance = {
            let instance = util::create_instance(config.cde_config, config.poly_simpl_tolerance);
            modify_instance(instance, edge_multiplier as usize)
        };

        let (problem, selected_pi_uids) =
            util::create_lbf_problem(instance.clone(), config, N_ITEMS_REMOVED);

        {
            // let draw_options = SvgDrawOptions {
            //     quadtree: true,
            //     surrogate: true,
            //     ..SvgDrawOptions::default()
            // };
            //let svg = layout_to_svg(&problem.layout, &instance, draw_options, "");
            // io::write_svg(
            //     &svg,
            //     Path::new(&format!("edge_sensitivity_{edge_multiplier}.svg")),
            // ).unwrap();
        }

        let mut rng = SmallRng::seed_from_u64(0);

        let layout = &problem.layout;
        /*let samples = {
            let sampler = UniformAARectSampler::new(layout.bin.bbox(), instance.item(0));
            (0..N_SAMPLES).map(
                |_| sampler.sample(&mut rng).compose()
            ).collect_vec()
        };*/

        let samples = {
            let sampler = UniformRectSampler::new(layout.cde().bbox(), instance.item(0));
            (0..N_TOTAL_SAMPLES)
                .map(|_| sampler.sample(&mut rng))
                .collect_vec()
        };

        let mut samples_cycler = samples.chunks(N_SAMPLES_PER_ITER).cycle();

        let mut n_invalid: i64 = 0;
        let mut n_valid: i64 = 0;

        g.bench_function(BenchmarkId::from_parameter(edge_multiplier), |b| {
            b.iter(|| {
                for pi_uid in selected_pi_uids.iter().take(N_ITEMS_REMOVED) {
                    let item = instance.item(pi_uid.item_id);
                    let mut buffer_shape = item.shape_cd.as_ref().clone();
                    for dtransf in samples_cycler.next().unwrap() {
                        let transf = dtransf.compose();
                        let collides = match layout.cde().detect_surrogate_collision(
                            item.shape_cd.surrogate(),
                            &transf,
                            &NoFilter,
                        ) {
                            true => true,
                            false => {
                                buffer_shape.transform_from(&item.shape_cd, &transf);
                                layout.cde().detect_poly_collision(&buffer_shape, &NoFilter)
                            }
                        };
                        match collides {
                            true => n_invalid += 1,
                            false => n_valid += 1,
                        }
                    }
                }
            })
        });
        println!(
            "{:.3}% valid",
            n_valid as f32 / (n_invalid + n_valid) as f32 * 100.0
        );
    }
    g.finish();
}

fn modify_instance(mut instance: SPInstance, multiplier: usize) -> SPInstance {
    instance.items.iter_mut().for_each(|(item, _)| {
        let multiplied_shape = multiply_edge_count(&item.shape_cd, multiplier);
        item.shape_cd = Arc::new(multiplied_shape);
    });
    instance
}

fn multiply_edge_count(shape: &SPolygon, multiplier: usize) -> SPolygon {
    let mut new_points = vec![];

    for edge in shape.edge_iter() {
        //split x and y into "times" parts
        let x_step = (edge.end.0 - edge.start.0) / multiplier as f32;
        let y_step = (edge.end.1 - edge.start.1) / multiplier as f32;
        let mut start = edge.start;
        for _ in 0..multiplier {
            new_points.push(start);
            start = Point(start.0 + x_step, start.1 + y_step);
        }
    }
    let new_polygon = SPolygon::new(new_points).unwrap();
    float_cmp::assert_approx_eq!(f32, shape.area, new_polygon.area);
    new_polygon
}
