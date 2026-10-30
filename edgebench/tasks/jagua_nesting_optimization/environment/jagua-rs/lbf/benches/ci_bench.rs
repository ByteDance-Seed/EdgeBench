use crate::util::{N_ITEMS_REMOVED, create_base_config};
use criterion::{BenchmarkId, Criterion, criterion_group, criterion_main};
use jagua_rs::collision_detection::hazards::collector::BasicHazardCollector;
use jagua_rs::collision_detection::hazards::filter::NoFilter;
use jagua_rs::entities::Instance;
use jagua_rs::geometry::geo_traits::TransformableFrom;
use jagua_rs::probs::spp::entities::SPPlacement;
use lbf::samplers::uniform_rect_sampler::UniformRectSampler;
use rand::SeedableRng;
use rand::prelude::{IteratorRandom, SmallRng};

criterion_main!(benches);
criterion_group!(
    benches,
    cde_collect_bench,
    cde_update_bench,
    cde_detect_bench,
);

mod util;

const QT_DEPTHS: [u8; 3] = [3, 4, 5];
const N_SAMPLES_PER_ITER: usize = 1000;

/// Benchmark how many complete collision collection queries can be performed every second with different quadtree depths. (no early exit)
/// The layout is dense.
fn cde_collect_bench(c: &mut Criterion) {
    let mut config = create_base_config();

    let mut group = c.benchmark_group("cde_collect_1k");
    for depth in QT_DEPTHS {
        config.cde_config.quadtree_depth = depth;
        let instance = util::create_instance(config.cde_config, config.poly_simpl_tolerance);
        let (problem, _) = util::create_lbf_problem(instance.clone(), config, 0);

        let mut rng = SmallRng::seed_from_u64(0);

        let mut n_detected = 0;

        // Configure throughput measurement - this tells Criterion each iteration performs N_SAMPLES_PER_ITER operations
        group.throughput(criterion::Throughput::Elements(N_SAMPLES_PER_ITER as u64));

        group.bench_function(BenchmarkId::from_parameter(depth), |b| {
            b.iter(|| {
                let search_for = problem
                    .layout
                    .placed_items
                    .iter()
                    .choose(&mut rng)
                    .expect("No items in layout");
                let item = instance.item(search_for.1.item_id);
                let cde = &problem.layout.cde();
                let mut buffer_shape = item.shape_cd.as_ref().clone();
                let mut collector = BasicHazardCollector::with_capacity(cde.hazards_map.len());
                let sampler = UniformRectSampler::new(cde.bbox(), item);
                for _ in 0..N_SAMPLES_PER_ITER {
                    let d_transf = sampler.sample(&mut rng);
                    let transf = d_transf.compose();
                    //detect collisions with the surrogate
                    cde.collect_surrogate_collisions(
                        item.shape_cd.surrogate(),
                        &transf,
                        &mut collector,
                    );
                    //detect collisions with the actual shape
                    buffer_shape.transform_from(&item.shape_cd, &transf);
                    cde.collect_poly_collisions(&buffer_shape, &mut collector);
                    n_detected += collector.len();
                    collector.clear();
                }
            })
        });
    }
    group.finish();
}

/// Benchmark how many complete collision detection queries can be performed every second with different quadtree depths.
/// The layout has a couple of items removed.
fn cde_detect_bench(c: &mut Criterion) {
    let mut config = util::create_base_config();

    let mut group = c.benchmark_group("cde_detect_1k");
    for depth in QT_DEPTHS {
        config.cde_config.quadtree_depth = depth;
        let instance = util::create_instance(config.cde_config, config.poly_simpl_tolerance);
        let (problem, _) = util::create_lbf_problem(instance.clone(), config, N_ITEMS_REMOVED);

        let mut rng = SmallRng::seed_from_u64(0);

        let mut n_detected = 0;

        // Configure throughput measurement - this tells Criterion each iteration performs N_SAMPLES_PER_ITER operations
        group.throughput(criterion::Throughput::Elements(N_SAMPLES_PER_ITER as u64));

        group.bench_function(BenchmarkId::from_parameter(depth), |b| {
            b.iter(|| {
                let item_to_move = problem
                    .layout
                    .placed_items
                    .iter()
                    .choose(&mut rng)
                    .expect("No items in layout");
                let item = instance.item(item_to_move.1.item_id);
                let cde = &problem.layout.cde();
                let mut buffer_shape = item.shape_cd.as_ref().clone();
                let sampler = UniformRectSampler::new(cde.bbox(), item);
                for _ in 0..N_SAMPLES_PER_ITER {
                    let d_transf = sampler.sample(&mut rng);
                    let transf = d_transf.compose();
                    //detect collisions with the surrogate
                    if !cde.detect_surrogate_collision(
                        item.shape_cd.surrogate(),
                        &transf,
                        &NoFilter,
                    ) {
                        buffer_shape.transform_from(&item.shape_cd, &transf);
                        if !cde.detect_poly_collision(&buffer_shape, &NoFilter) {
                            n_detected += 1;
                        }
                    }
                }
            })
        });
    }
    group.finish();
}

/// Benchmarks updating the state of the CDEngine by removing an item and placing it again.
fn cde_update_bench(c: &mut Criterion) {
    let mut config = create_base_config();

    let mut group = c.benchmark_group("cde_update_1k");
    for depth in QT_DEPTHS {
        config.cde_config.quadtree_depth = depth;
        let instance = util::create_instance(config.cde_config, config.poly_simpl_tolerance);
        let (mut problem, _) = util::create_lbf_problem(instance.clone(), config, 0);

        let mut rng = SmallRng::seed_from_u64(0);

        group.throughput(criterion::Throughput::Elements(N_SAMPLES_PER_ITER as u64));

        group.bench_function(BenchmarkId::from_parameter(depth), |b| {
            b.iter(|| {
                for _ in 0..N_SAMPLES_PER_ITER {
                    // Remove an item from the layout
                    let (pkey, pi) = problem
                        .layout
                        .placed_items
                        .iter()
                        .choose(&mut rng)
                        .expect("No items in layout");

                    let p_opt = SPPlacement {
                        item_id: pi.item_id,
                        d_transf: pi.d_transf,
                    };

                    //println!("Removing item with id: {}\n", pi_uid.item_id);
                    problem.remove_item(pkey);

                    problem.place_item(p_opt);
                }
            })
        });
    }
    group.finish();
}
