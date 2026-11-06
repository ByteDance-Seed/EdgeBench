#[cfg(test)]
mod tests {
    use anyhow::Result;
    use jagua_rs::io::import::Importer;
    use jagua_rs::probs::{bpp, spp};
    use lbf::config::LBFConfig;
    use lbf::io::{read_bpp_instance, read_spp_instance};
    use lbf::opt::lbf_bpp::LBFOptimizerBP;
    use lbf::opt::lbf_spp::LBFOptimizerSP;
    use rand::SeedableRng;
    use rand::prelude::IteratorRandom;
    use rand::prelude::SmallRng;
    use std::path::Path;
    use test_case::test_case;

    const N_ITEMS_TO_REMOVE: usize = 5;

    const QT_DEPTHS: [u8; 3] = [0, 3, 10];

    #[test_case("../assets/albano.json"; "albano")]
    #[test_case("../assets/blaz1.json"; "blaz1")]
    #[test_case("../assets/dagli.json"; "dagli")]
    #[test_case("../assets/fu.json"; "fu")]
    #[test_case("../assets/jakobs1.json"; "jakobs1")]
    #[test_case("../assets/jakobs2.json"; "jakobs2")]
    #[test_case("../assets/mao.json"; "mao")]
    #[test_case("../assets/marques.json"; "marques")]
    #[test_case("../assets/shapes0.json"; "shapes0")]
    #[test_case("../assets/shapes1.json"; "shapes1")]
    #[test_case("../assets/shirts.json"; "shirts")]
    #[test_case("../assets/swim.json"; "swim")]
    #[test_case("../assets/trousers.json"; "trousers")]
    fn test_strip_packing(instance_path: &str) -> Result<()> {
        let ext_instance = read_spp_instance(Path::new(instance_path))?;
        let instance = spp::io::import_instance(&importer(), &ext_instance)?;

        for qt_depth in QT_DEPTHS {
            let mut config = config();
            config.cde_config.quadtree_depth = qt_depth;

            let mut opt = LBFOptimizerSP::new(instance.clone(), config, SmallRng::seed_from_u64(0));

            let mut rng = SmallRng::seed_from_u64(0);

            // a first lbf run
            opt.solve();
            {
                // remove some items
                let problem = &mut opt.problem;
                for _ in 0..N_ITEMS_TO_REMOVE {
                    //pick random existing layout
                    let random_placed_item = problem
                        .layout
                        .placed_items
                        .iter()
                        .choose(&mut rng)
                        .map(|(key, _)| key);

                    if let Some(random_placed_item) = random_placed_item {
                        // remove the item
                        problem.remove_item(random_placed_item);
                    } else {
                        // no items to remove
                        break;
                    }
                }

                let solution = opt.problem.save();
                // second optimization run
                opt.solve();
                // restore the solution
                opt.problem.restore(&solution);
                // third optimization run
                opt.solve();
            }
        }
        Ok(())
    }

    #[test_case("../assets/baldacci1.json"; "baldacci1")]
    #[test_case("../assets/baldacci2.json"; "baldacci2")]
    #[test_case("../assets/baldacci3.json"; "baldacci3")]
    #[test_case("../assets/baldacci4.json"; "baldacci4")]
    #[test_case("../assets/baldacci5.json"; "baldacci5")]
    #[test_case("../assets/baldacci6.json"; "baldacci6")]
    fn test_bin_packing(instance_path: &str) -> Result<()> {
        let ext_instance = read_bpp_instance(Path::new(instance_path))?;
        let instance = bpp::io::import_instance(&importer(), &ext_instance)?;

        for qt_depth in QT_DEPTHS {
            let mut config = config();
            config.cde_config.quadtree_depth = qt_depth;
            let mut opt = LBFOptimizerBP::new(instance.clone(), config, SmallRng::seed_from_u64(0));

            let mut rng = SmallRng::seed_from_u64(0);

            // a first optimization run
            opt.solve();

            {
                // remove some items
                let problem = &mut opt.problem;
                for _ in 0..N_ITEMS_TO_REMOVE {
                    //pick random existing layout
                    let lkey = problem.layouts.keys().choose(&mut rng).unwrap();
                    let random_placed_item = problem.layouts[lkey]
                        .placed_items
                        .iter()
                        .choose(&mut rng)
                        .map(|(key, _)| key);

                    if let Some(random_placed_item) = random_placed_item {
                        // remove the item
                        problem.remove_item(lkey, random_placed_item);
                    } else {
                        // no items to remove
                        break;
                    }
                }

                let solution = opt.problem.save();
                // second optimization run
                opt.solve();
                // restore the solution
                opt.problem.restore(&solution);
                // third optimization run
                opt.solve();
            }
        }
        Ok(())
    }

    #[test]
    fn test_rejects_self_intersecting_polygon() -> Result<()> {
        let ext_instance = read_spp_instance(Path::new("../assets/self_intersecting.json"))?;

        assert!(spp::io::import_instance(&importer(), &ext_instance).is_err());
        Ok(())
    }

    fn config() -> LBFConfig {
        LBFConfig {
            n_samples: 100,
            ..LBFConfig::default()
        }
    }

    fn importer() -> Importer {
        Importer::new(
            config().cde_config,
            config().poly_simpl_tolerance,
            config().min_item_separation,
            config().narrow_concavity_cutoff,
        )
    }
}
