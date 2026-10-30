use crate::util::{N_ITEMS_REMOVED, create_base_config};
use criterion::{BenchmarkId, Criterion, criterion_group, criterion_main};
use itertools::Itertools;
use jagua_rs::collision_detection::hazards::filter::NoFilter;
use jagua_rs::entities::Instance;
use jagua_rs::geometry::convex_hull;
use jagua_rs::geometry::fail_fast::{
    SPSurrogate, SPSurrogateConfig, generate_piers, generate_surrogate_poles,
};
use jagua_rs::geometry::geo_traits::TransformableFrom;
use jagua_rs::geometry::primitives::SPolygon;
use lbf::samplers::uniform_rect_sampler::UniformRectSampler;
use rand::SeedableRng;
use rand::prelude::SmallRng;

criterion_main!(benches);
criterion_group!(benches, fast_fail_query_bench);

mod util;

const FF_POLES: &[usize] = &[0, 1, 2, 3, 4];
const FF_PIERS: &[usize] = &[0, 1, 2, 3, 4];

const ITEMS_ID_TO_TEST: &[usize] = &[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

const N_TOTAL_SAMPLES: usize = 100_000;
const N_SAMPLES_PER_ITER: usize = 1000;

/// Benchmark the query operation of the quadtree for different depths
/// We validate 1000 sampled transformations for each of the 5 removed items
fn fast_fail_query_bench(c: &mut Criterion) {
    let mut group = c.benchmark_group("fast_fail_query_bench");

    let config_combos = FF_POLES
        .iter()
        .flat_map(|n_ff_poles| {
            FF_PIERS
                .iter()
                .map(|n_ff_piers| (*n_ff_poles, *n_ff_piers))
                .collect_vec()
        })
        .collect_vec();

    let mut config = create_base_config();
    config.cde_config.quadtree_depth = 5;

    let instance = util::create_instance(config.cde_config, config.poly_simpl_tolerance);
    let (problem, _) = util::create_lbf_problem(instance.clone(), config, N_ITEMS_REMOVED);

    println!(
        "avg number of edges per item: {}",
        ITEMS_ID_TO_TEST
            .iter()
            .map(|&item_id| instance.item(item_id).shape_cd.n_vertices())
            .sum::<usize>() as f32
            / ITEMS_ID_TO_TEST.len() as f32
    );

    let mut rng = SmallRng::seed_from_u64(0);
    let layout = &problem.layout;
    let samples = ITEMS_ID_TO_TEST
        .iter()
        .map(|&item_id| {
            let sampler = UniformRectSampler::new(layout.cde().bbox(), instance.item(item_id));
            (0..N_TOTAL_SAMPLES)
                .map(|_| sampler.sample(&mut rng))
                .collect_vec()
        })
        .collect_vec();

    for ff_surr_config in config_combos {
        let (n_ff_poles, n_ff_piers) = ff_surr_config;

        let custom_surrogates = ITEMS_ID_TO_TEST
            .iter()
            .map(|&item_id| {
                create_custom_surrogate(&instance.item(item_id).shape_cd, n_ff_poles, n_ff_piers)
            })
            .collect_vec();

        let mut samples_cyclers = samples
            .iter()
            .map(|s| s.chunks(N_SAMPLES_PER_ITER).cycle())
            .collect_vec();

        let mut n_invalid: i64 = 0;
        let mut n_valid: i64 = 0;

        let mut i_cycler = ITEMS_ID_TO_TEST.iter().enumerate().cycle();

        let mut buffer_shapes = ITEMS_ID_TO_TEST
            .iter()
            .map(|&item_id| instance.item(item_id))
            .map(|item| {
                let mut buffer = (*item.shape_cd).clone();
                buffer.surrogate = None; //strip the surrogate for faster transforms, we don't need it for the buffer shape
                buffer
            })
            .collect_vec();

        group.bench_function(
            BenchmarkId::from_parameter(format!("{n_ff_poles}_poles_{n_ff_piers}_piers")),
            |b| {
                b.iter(|| {
                    let (i, &item_id) = i_cycler.next().unwrap();
                    let item = instance.item(item_id);
                    let surrogate = &custom_surrogates[i];
                    let buffer_shape = &mut buffer_shapes[i];
                    for dtransf in samples_cyclers[i].next().unwrap() {
                        let transf = dtransf.compose();
                        let collides = match layout
                            .cde()
                            .detect_surrogate_collision(surrogate, &transf, &NoFilter)
                        {
                            true => true,
                            false => {
                                buffer_shape.transform_from(&item.shape_cd, &transf);
                                layout.cde().detect_poly_collision(buffer_shape, &NoFilter)
                            }
                        };
                        match collides {
                            true => n_invalid += 1,
                            false => n_valid += 1,
                        }
                    }
                })
            },
        );
        println!(
            "{:.3}% valid",
            n_valid as f32 / (n_invalid + n_valid) as f32 * 100.0
        );
    }
    group.finish();
}

pub fn create_custom_surrogate(
    simple_poly: &SPolygon,
    n_poles: usize,
    n_piers: usize,
) -> SPSurrogate {
    let sp_config = SPSurrogateConfig {
        n_pole_limits: [(n_poles, 0.0); 3],
        n_ff_poles: n_poles,
        n_ff_piers: n_piers,
    };

    let convex_hull_indices = convex_hull::convex_hull_indices(simple_poly);
    let mut poles = vec![simple_poly.poi];
    poles.extend(generate_surrogate_poles(simple_poly, &sp_config.n_pole_limits).unwrap());

    let piers = generate_piers(simple_poly, n_piers, &poles).unwrap();
    let convex_hull_area = SPolygon::new(
        convex_hull_indices
            .iter()
            .map(|&i| simple_poly.vertices[i])
            .collect(),
    )
    .unwrap()
    .area;

    SPSurrogate {
        convex_hull_indices,
        poles,
        piers,
        convex_hull_area,
        config: sp_config,
    }
}
