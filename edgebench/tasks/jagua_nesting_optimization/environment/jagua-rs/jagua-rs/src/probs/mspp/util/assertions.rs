use crate::entities::Item;
use crate::probs::mspp::entities::{MSPProblem, MSPSolution};
use crate::util::assertions::snapshot_matches_layout;

#[must_use]
pub fn problem_matches_solution(mspp: &MSPProblem, sol: &MSPSolution) -> bool {
    let MSPSolution {
        layout_snapshots,
        strips,
        time_stamp: _,
    } = sol;

    assert!((mspp.density() - sol.density(&mspp.instance)).abs() <= f32::EPSILON);
    assert_eq!(mspp.layouts.len(), layout_snapshots.len());
    assert_eq!(mspp.strips.len(), strips.len());

    mspp.layouts.iter().for_each(|(lk, l)| {
        let ls = &layout_snapshots[lk];
        assert!(snapshot_matches_layout(l, ls));
    });

    // Check that each layout in the problem has a matching snapshot in the solution
    mspp.layouts.iter().all(|(p_lk, l)| {
        let prob_strip = &mspp.strips[p_lk];
        layout_snapshots.iter().any(|(s_lk, ls)| {
            let sol_strip = &strips[s_lk];
            prob_strip == sol_strip && snapshot_matches_layout(l, ls)
        })
    });

    true
}

#[must_use]
pub fn instance_item_ids_correct(items: &[(Item, usize)]) -> bool {
    items
        .iter()
        .enumerate()
        .all(|(i, (item, _qty))| item.id == i)
}
