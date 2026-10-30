import Analysis.MeasureTheory.Section_1_2_0
import Analysis.Misc.«Real-EReal-ENNReal»
import Analysis.Misc.Combinatorics

/-!
# Introduction to Measure Theory, Section 1.2.1: Properties of Lebesgue outer measure

A companion to (the introduction to) Section 1.2.1 of the book "An introduction to Measure Theory".

-/

open BoundedInterval

/-- The closure of `Box.toSet` expressed as a preimage. -/
lemma Box.closure_toSet {d : ℕ} (B : Box d) :
    closure B.toSet = (PiLp.homeomorph 2 (fun _ : Fin d => ℝ)) ⁻¹'
      Set.univ.pi (fun i => closure (B.side i).toSet) := by
  sorry

noncomputable def set_dist {X:Type*} [PseudoMetricSpace X] (A B: Set X) : ℝ :=
  sInf ((fun p: X × X ↦ dist p.1 p.2) '' (A ×ˢ B))

-- ========================================================================
-- Start of Helpers for lemma 1.2.5: Lebesgue_outer_measure.union_of_separated
-- ========================================================================

namespace BoundedInterval
/-- Extract the left and right endpoints of a `BoundedInterval`.
    Returns (a, b) where a is the left endpoint and b is the right endpoint. -/
def endpoints (I : BoundedInterval) : ℝ × ℝ :=
  match I with
  | Ioo a b => (a, b)
  | Icc a b => (a, b)
  | Ioc a b => (a, b)
  | Ico a b => (a, b)

/-- Compute the midpoint of a `BoundedInterval`. -/
noncomputable def midpoint (I : BoundedInterval) : ℝ :=
  let (a, b) := I.endpoints
  (a + b) / 2

/-- Bisect a `BoundedInterval` into left and right halves using closed intervals.
    Left half: \[a, m\], Right half: \[m, b\], where m is the midpoint.
    Using closed intervals ensures coverage (union equals original) while
    maintaining measure-theoretic properties (overlap has measure zero). -/
noncomputable def bisect (I : BoundedInterval) : BoundedInterval × BoundedInterval :=
  let (a, b) := I.endpoints
  let m := I.midpoint
  (Icc a m, Icc m b)

/-- Cross-case: if bisect.fst = bisect.snd, the intervals have overlapping midpoint and endpoint -/
lemma bisect_fst_eq_snd_shift {I₁ I₂ : BoundedInterval}
    (h : I₁.bisect.fst = I₂.bisect.snd) : I₁.a = (I₂.a + I₂.b) / 2 := by
  sorry

end BoundedInterval

namespace Box
/-- The diameter of a box is the supremum of Euclidean distances between points in the box -/
noncomputable def diameter {d:ℕ} (B: Box d) : ℝ :=
  sSup { r | ∃ x ∈ B.toSet, ∃ y ∈ B.toSet, r = √(∑ i, (x i - y i)^2) }

/-- The diameter of a nonempty box equals the diagonal length √(∑ |side i|ₗ²).
    This is the key fact: the supremum of pairwise distances equals the diagonal.
    For closed intervals, the diagonal is achieved at corners.
    For open intervals, the diagonal is the limit (supremum) of achievable distances. -/
lemma diameter_eq_sqrt_sum_sq {d:ℕ} (B: Box d) (h: B.toSet.Nonempty) :
    B.diameter = √(∑ i, |B.side i|ₗ^2) := by
  sorry

/-- If B.diameter < set\_dist E F, then B cannot intersect both E and F.
    This is the core geometric fact needed for finite additivity of separated sets. -/
lemma not_intersects_both_of_diameter_lt {d:ℕ} (B: Box d) (E F : Set (EuclideanSpace' d))
    (h : B.diameter < set_dist E F) :
    ¬((B.toSet ∩ E).Nonempty ∧ (B.toSet ∩ F).Nonempty) := by
  sorry

open Classical in
/-- Decidable equality for boxes, needed for `Finset` operations -/
noncomputable instance {d:ℕ} : DecidableEq (Box d) := instDecidableEqOfLawfulBEq

/-- Subdivide a box by bisecting each coordinate axis, producing 2^d sub-boxes.
    Each sub-box is formed by taking one half-interval from each coordinate.
    We use `Finset.univ` (all possible d-bit patterns) to enumerate all 2^d combinations. -/
noncomputable def subdivide {d:ℕ} (B: Box d) : Finset (Box d) :=
  -- For each choice ∈ Fin d → Bool (which half to take for each coordinate),
  -- construct a sub-box by taking the left half (if false) or right half (if true)
  Finset.univ.image fun (choice : Fin d → Bool) =>
    { side := fun i =>
        let (left, right) := (B.side i).bisect
        if choice i then right else left }

/-- The volume of a subdivided box equals the sum of its sub-box volumes -/
lemma volume_subdivide {d:ℕ} (B: Box d) :
    ∑ B' ∈ B.subdivide, |B'|ᵥ = |B|ᵥ := by
  sorry

/-- Each sub-box of a subdivision has diameter at most the original diameter divided by √2.
    This follows because each side is halved, reducing the diagonal by a factor related to √2.
    Note: The hypothesis that B is nonempty is necessary because bisection always creates closed
    intervals, which can turn degenerate open intervals ({given -show}`a` {lean}`Ioo a a`) into
    nonempty singletons. -/
lemma subdivide_diameter_bound {d:ℕ} (B: Box d) (hB : B.toSet.Nonempty) :
    ∀ B' ∈ B.subdivide, B'.diameter ≤ B.diameter / Real.sqrt 2 := by
  sorry

/-- Subdivide a box k times, producing a `Finset` of boxes.
    After k iterations, each original box becomes up to 2^(d\*k) sub-boxes. -/
noncomputable def subdivide_iter {d:ℕ} (B: Box d) : ℕ → Finset (Box d)
  | 0 => {B}
  | k+1 => (subdivide_iter B k).biUnion Box.subdivide

lemma subdivide_iter_succ {d:ℕ} (B: Box d) (k: ℕ) :
    subdivide_iter B (k+1) = (subdivide_iter B k).biUnion Box.subdivide := by
  sorry

/-- Grid alignment: sides in `Box.subdivide_iter` start at grid positions.
    Requires nonempty box to ensure sides have a ≤ b (backwards intervals break the formula). -/
lemma subdivide_iter_side_grid {d:ℕ} (B : Box d) (hB : B.toSet.Nonempty) (k : ℕ) (B' : Box d)
    (hB' : B' ∈ subdivide_iter B k) (i : Fin d) :
    ∃ j : ℕ, j < 2^k ∧ (B'.side i).a = (B.side i).a + j * (|B.side i|ₗ / 2^k) := by
  sorry

/-- Volume is preserved through iterative subdivision -/
lemma volume_subdivide_iter {d:ℕ} (B: Box d) (hB : B.toSet.Nonempty) (k: ℕ) :
    ∑ B' ∈ subdivide_iter B k, |B'|ᵥ = |B|ᵥ := by
  sorry

/-- Diameter bound after k iterations of subdivision.
    Each iteration reduces diameter by factor of √2. -/
lemma diameter_subdivide_iter {d:ℕ} (B: Box d) (hB: B.toSet.Nonempty) (k: ℕ) :
    ∀ B' ∈ subdivide_iter B k, B'.diameter ≤ B.diameter / (Real.sqrt 2) ^ k := by
  sorry

/-- Number of subdivisions needed to get diameter below threshold r.
    Each subdivision reduces diameter by factor of √2, so after k iterations:
    diameter ≤ original\_diameter / (√2)^k
    We need (√2)^k > diameter/r, i.e., k > log(diameter/r) / log(√2) = 2·log₂(diameter/r). -/
noncomputable def iter_count {d:ℕ} (B: Box d) (r: ℝ) : ℕ :=
  if B.diameter ≤ 0 then 0
  else if B.diameter < r then 0
  else Nat.ceil (2 * Real.log (B.diameter / r) / Real.log 2) + 1

/-- After iter\_count subdivisions, all sub-boxes have diameter < r -/
lemma diameter_lt_of_iter_count {d:ℕ} (B: Box d) (hB: B.toSet.Nonempty) (r: ℝ) (hr: 0 < r) :
    ∀ B' ∈ subdivide_iter B (B.iter_count r), B'.diameter < r := by
  sorry

end Box

namespace Lebesgue_outer_measure

/-- Any ℕ-indexed cover gives an upper bound on outer measure.
    Follows directly from the infimum definition. -/
lemma le_of_nat_cover {d:ℕ} (hd: 0 < d) (E: Set (EuclideanSpace' d))
    (S : ℕ → Box d) (hcover : E ⊆ ⋃ n, (S n).toSet) :
    Lebesgue_outer_measure E ≤ ∑' n, (S n).volume.toEReal := by
  sorry

/-- Upper bound from finset-indexed cover: if a set is covered by {lean}`⋃ n, ⋃ B ∈ I n, B.toSet`
    where each {given -show}`n` {lean}`I n` is a finite set of boxes, then the outer measure is bounded by the
    sum of volumes.

    Proof strategy:
    1. The sigma type {lean}`(n : ℕ) × ↑(I n)` is countable (and hence `Encodable`)
    2. Use `Encodable` instance to define {lit}`S` of type {lean}`ℕ → Box d` via decoding
    3. Pad with zero-volume box for invalid decodings
    4. Apply `Lebesgue_outer_measure.le_of_nat_cover` and bound the enumerated sum -/
lemma le_of_finset_cover {d:ℕ} (hd: 0 < d) (E: Set (EuclideanSpace' d))
    (I : ℕ → Finset (Box d)) (hcover : E ⊆ ⋃ n, ⋃ B ∈ I n, B.toSet) :
    Lebesgue_outer_measure E ≤ ∑' n, (∑ B ∈ I n, B.volume).toEReal := by
  sorry

/-- For any set with finite outer measure, we can find a cover whose volume is within ε of the outer measure.
    This follows from the definition of outer measure as an infimum. -/
lemma exists_cover_close {d:ℕ} (hd: 0 < d)
    (E: Set (EuclideanSpace' d)) (ε: ℝ) (hε: 0 < ε)
    (h_finite: Lebesgue_outer_measure E ≠ ⊤) :
    ∃ (S: ℕ → Box d), E ⊆ ⋃ n, (S n).toSet ∧
      ∑' n, (S n).volume.toEReal ≤ Lebesgue_outer_measure E + ε := by
  sorry

end Lebesgue_outer_measure

-- ========================================================================
-- End of Helpers for lemma 1.2.5
-- ========================================================================

/-- Lemma 1.2.5 (Finite additivity for separated sets).
    If E and F are separated (dist(E,F) > 0), then m\*(E ∪ F) = m\*(E) + m\*(F).

    Proof strategy (from textbook):
    1. Direction ≤: Use subadditivity
    2. Direction ≥: Show m\*(E ∪ F) ≥ m\*(E) + m\*(F)
       - If m\*(E ∪ F) = ⊤, trivial
       - If m\*(E ∪ F) < ⊤:
         \* Get epsilon-close cover of E ∪ F
         \* Refine cover so all boxes have diameter < dist(E,F)
         \* Partition boxes into E-intersecting and F-intersecting (disjoint by geometric separation)
         \* Sum volumes separately: m\*(E) + m\*(F) ≤ sum of refined cover ≤ m\*(E ∪ F) + ε
         \* Take ε → 0 to conclude
-/
theorem Lebesgue_outer_measure.union_of_separated {d:ℕ} (hd: 0 < d) {E F : Set (EuclideanSpace' d)}
    (hsep: set_dist E F > 0) :
    Lebesgue_outer_measure (E ∪ F) = Lebesgue_outer_measure E + Lebesgue_outer_measure F := by
  sorry

example : set_dist (Ico 0 1).toSet (Icc 1 2).toSet = 0 := by
  sorry

-- ========================================================================
-- Start of Helper lemmas for Lemma 1.2.6
-- ========================================================================

/-- Shrink a box to a closed sub-box with controlled volume decrease.
    The output is always nonempty when the input is nonempty. -/
lemma Box.shrink_to_closed {d:ℕ} (B: Box d) (hB: B.toSet.Nonempty) (δ: ℝ) (hδ: 0 < δ) :
    ∃ B': Box d, B'.toSet ⊆ B.toSet ∧ IsClosed B'.toSet ∧ |B'|ᵥ ≥ |B|ᵥ - δ ∧ B'.toSet.Nonempty := by
  sorry

namespace IsElementary

/-- Elementary measure of empty set is zero (handles proof term mismatch) -/
lemma measure_of_empty_eq {d : ℕ} {E : Set (EuclideanSpace' d)}
    (hE : IsElementary E) (hempty : E = ∅) : hE.measure = 0 := by
  sorry

/-- Finite indexed union of boxes is elementary (uses `IsElementary.union'` which takes a finset of sets) -/
lemma iUnion_boxes {d : ℕ} {ι : Type*} [Fintype ι] (B : ι → Box d) :
    IsElementary (⋃ i, (B i).toSet) := by
  sorry

/-- The measure of a finite union of boxes (indexed by finset membership) is at most the sum of volumes.
    This is finite subadditivity specialized to boxes with a finset index. -/
lemma measure_le_finset_boxes_volume' {d : ℕ} (t : Finset ℕ) (B : ℕ → Box d) :
    (IsElementary.iUnion_boxes (fun (n : { n // n ∈ t }) => B n.1)).measure ≤ ∑ n ∈ t, (B n).volume := by
  sorry

/-- For any box cover of an elementary set, the sum of volumes bounds the measure from below.
    This is the key step using Heine-Borel compactness: inflate boxes to open cover,
    extract finite subcover of compact approximation, use finite subadditivity. -/
lemma measure_le_cover_sum {d : ℕ} (_hd : 0 < d) {E : Set (EuclideanSpace' d)}
    (hE : IsElementary E) (S : ℕ → Box d) (hS_cover : E ⊆ ⋃ n, (S n).toSet) :
    (hE.measure : EReal) ≤ ∑' n, (S n).volume.toEReal := by
  sorry

/-- Direction 1: Elementary measure is a lower bound for outer measure
    (Partition gives a finite cover, outer measure is infimum over covers)
    Uses measure\_le\_cover\_sum for the core Heine-Borel argument. -/
lemma measure_le_outer_measure {d:ℕ} (hd: 0 < d) {E: Set (EuclideanSpace' d)}
    (hE: IsElementary E) : (hE.measure : EReal) ≤ Lebesgue_outer_measure E := by
  sorry

/-- Direction 2: Outer measure is bounded by elementary measure
    (Uses: m\*(E) ≤ J\*(E) for bounded E, and J\*(E) ≤ hE.measure for elementary E) -/
lemma outer_measure_le_measure {d:ℕ} (_hd: 0 < d) {E: Set (EuclideanSpace' d)}
    (hE: IsElementary E) : Lebesgue_outer_measure E ≤ (hE.measure : EReal) := by
  sorry

end IsElementary

/-- Dimension 0 case of Lemma 1.2.6 -/
lemma Lebesgue_outer_measure.elementary_dim_zero (E: Set (EuclideanSpace' 0)) (hE: IsElementary E) :
    Lebesgue_outer_measure E = hE.measure := by
  sorry

-- ========================================================================
-- End of Helper lemmas for Lemma 1.2.6
-- ========================================================================
/-- Lemma 1.2.6 (Outer measure of elementary sets).
    For any elementary set E, Lebesgue outer measure equals elementary measure. -/
theorem Lebesgue_outer_measure.elementary {d:ℕ} (E: Set (EuclideanSpace' d)) (hE: IsElementary E) :
    Lebesgue_outer_measure E = hE.measure := by
  sorry

/-- Cantor's theorem -/
theorem EuclideanSpace'.uncountable (d:ℕ) (hd: 0 < d) : Uncountable (EuclideanSpace' d) := by
  sorry

/-- No uncountable subadditivity: the unit cube has measure 1, but decomposed into
singletons (each with measure 0), the sum is 0. -/
example {d:ℕ} {hd: 0 < d} : ∃ (S:Type) (E: S → Set (EuclideanSpace' d)), ¬ Lebesgue_outer_measure (⋃ i, E i) ≤ ∑' i, Lebesgue_outer_measure (E i) := by
  sorry

-- ========================================================================
--  Start of Helpers for remark 1.2.8 -/
-- ========================================================================

namespace Lebesgue_outer_measure

/-- Lebesgue outer measure of a closed interval \[a,b\] equals b - a -/
lemma of_Icc (a b : ℝ) (hab : a ≤ b) :
    Lebesgue_outer_measure (EuclideanSpace'.equiv_Real ⁻¹' Set.Icc a b) = ((b - a : ℝ) : EReal) := by
  sorry

/-- Lebesgue measure of an open interval ≤ length (when a < b) -/
lemma of_Ioo_le (a b : ℝ) (h : a < b) :
    Lebesgue_outer_measure (EuclideanSpace'.equiv_Real ⁻¹' Set.Ioo a b) ≤ ((b - a : ℝ) : EReal) := by
  sorry

end Lebesgue_outer_measure

/-- Monotonicity of Jordan outer measure, for two bounded sets -/
lemma Jordan_outer_measure_mono {E F : Set (EuclideanSpace' 1)}
    (hEF: E ⊆ F) (_hF: Bornology.IsBounded F) :
    Jordan_outer_measure E ≤ Jordan_outer_measure F := by
  sorry

namespace Remark_1_2_8

/-- Rationals in \[0,1\] form a nonempty countable set. -/
lemma rationals_unit_interval_nonempty : (Set.Icc (0:ℝ) 1 ∩ Set.range (fun q:ℚ ↦ (q:ℝ))).Nonempty := by
  sorry

lemma rationals_unit_interval_countable : (Set.Icc (0:ℝ) 1 ∩ Set.range (fun q:ℚ ↦ (q:ℝ))).Countable := by
  sorry

/-- An enumeration function of rationals in \[0,1\] -/
noncomputable def q_enum : ℕ → { x : ℝ // x ∈ Set.Icc (0:ℝ) 1 ∩ Set.range (fun q:ℚ ↦ (q:ℝ)) } :=
  (rationals_unit_interval_countable.exists_surjective rationals_unit_interval_nonempty).choose

/-- An enumeration of rationals in \[0,1\] as real numbers -/
noncomputable def q (n : ℕ) : ℝ := (q_enum n).val

/-- The counterexample set U: union of open intervals around rationals in \[0,1\].
    U(ε) = ⋃\_\{n:ℕ\} (q\_n - ε/2^\{n+1\}, q\_n + ε/2^\{n+1\}) -/
noncomputable def U_real (ε : ℝ) : Set ℝ :=
  ⋃ n : ℕ, Set.Ioo (q n - ε / 2^(n+1)) (q n + ε / 2^(n+1))

/-- The set U lifted to {lean}`EuclideanSpace' 1` -/
noncomputable def U (ε : ℝ) : Set (EuclideanSpace' 1) :=
  EuclideanSpace'.equiv_Real ⁻¹' (U_real ε)

/-- U is open in {lean}`EuclideanSpace' 1` -/
lemma U_isOpen (ε : ℝ) : IsOpen (U ε) := by
  sorry

/-- The radius at step n -/
noncomputable def radius (ε : ℝ) (n : ℕ) : ℝ := ε / 2^(n+1)

-- lemma radius_pos (ε : ℝ) (hε : 0 < ε) (n : ℕ) : 0 < radius ε n := by
  -- unfold radius
  -- apply div_pos hε
  -- exact pow_pos (by norm_num : (0:ℝ) < 2) (n+1)

/-- Bound on each component interval's Lebesgue measure -/
lemma component_lebesgue_le (ε : ℝ) (hε : 0 < ε) (n : ℕ) :
    Lebesgue_outer_measure (EuclideanSpace'.equiv_Real ⁻¹' Set.Ioo (q n - ε / 2^(n+1)) (q n + ε / 2^(n+1)))
    ≤ ((2 * ε / 2^(n+1) : ℝ) : EReal) := by
  sorry

/-- Unit interval \[0,1\] as a `BoundedInterval` -/
abbrev unit_interval : BoundedInterval := BoundedInterval.Icc 0 1

/-- Unit box in 1D: \[0,1\] lifted to {lean}`Box 1` -/
abbrev unit_box_1D : Box 1 := unit_interval.toBox

/-- Jordan outer measure of unit box is 1 -/
lemma Jordan_outer_unit_box : Jordan_outer_measure unit_box_1D.toSet = 1 := by
  sorry

/-- Closure of U contains the preimage of \[0,1\] -/
lemma U_closure_contains_unit_box (ε : ℝ) (hε : 0 < ε) :
    unit_box_1D.toSet ⊆ closure (U ε) := by
  sorry

/-- Jordan outer measure of U ≥ 1.
    Proof uses: density of ℚ → closure(U) ⊇ \[0,1\] → Jordan\_outer(U) ≥ Jordan\_outer(\[0,1\]) = 1. -/
lemma U_jordan_outer_ge (ε : ℝ) (hε : 0 < ε) :
    Jordan_outer_measure (U ε) ≥ 1 := by
  sorry

/-- Lebesgue outer measure of U ≤ 2ε (countable subadditivity).
    U = ⋃\_n (q\_n - ε/2^\{n+1\}, q\_n + ε/2^\{n+1\}), each interval has length 2ε/2^\{n+1\},
    and ∑ 2ε/2^\{n+1\} = 2ε.

    Proof structure:
    1. Express U as countable union: U = ⋃\_n E\_n
    2. By countable subadditivity (union\_le): m\*(U) ≤ ∑' m\*(E\_n)
    3. Each component bounded: m\*(E\_n) ≤ 2ε/2^\{n+1\} (component\_lebesgue\_le)
    4. Geometric sum: ∑' 2ε/2^\{n+1\} = 2ε (tsum\_interval\_lengths)
    5. `EReal` tsum comparison: ∑' m\*(E\_n) ≤ ∑' (2ε/2^\{n+1\}) = 2ε -/
lemma U_lebesgue_le (ε : ℝ) (hε : 0 < ε) :
    Lebesgue_outer_measure (U ε) ≤ ((2 * ε : ℝ) : EReal) := by
  sorry

end Remark_1_2_8
-- ========================================================================
--  End of Helpers for remark 1.2.8 -/
-- ========================================================================

/-- Remark 1.2.8: There exists a bounded open set that is not Jordan measurable.
    Proof sketch: Take U = ⋃\_\{n\} (q\_n - ε/2^\{n+1\}, q\_n + ε/2^\{n+1\}) where \{q\_n\} enumerates ℚ ∩ \[0,1\].
    U is open and bounded. By countable subadditivity, m\*(U) ≤ 2ε.
    By density of ℚ, closure(U) ⊇ \[0,1\], so m\*,J(U) ≥ 1.
    For ε = 1/3, we get m\*(U) ≤ 2/3 < 1 ≤ m\*,J(U), contradicting Jordan measurability. -/
example : ∃ (E: Set (EuclideanSpace' 1)), Bornology.IsBounded E ∧
    IsOpen E ∧ ¬ JordanMeasurable E := by
  sorry

/-- Remark 1.2.8: The complement of U in \[-2,2\] is compact but not Jordan measurable. -/
example : ∃ (E: Set (EuclideanSpace' 1)), Bornology.IsBounded E ∧
    IsCompact E ∧ ¬ JordanMeasurable E := by
  sorry

def AlmostDisjoint {d:ℕ} (B B': Box d) : Prop := interior B.toSet ∩ interior B'.toSet = ∅

-- Helpers for theorem IsElementary.almost_disjoint
/-- Measure is additive on unions of elementary sets with disjoint interiors: μ(E ∪ F) = μ(E) + μ(F). -/
lemma IsElementary.measure_of_almostDisjUnion {d:ℕ} {E F: Set (EuclideanSpace' d)}
    (hE: IsElementary E) (hF: IsElementary F)
    (h: interior E ∩ interior F = ∅) :
    (hE.union hF).measure = hE.measure + hF.measure := by
  sorry

/-- The interior of a finite union of box frontiers is empty. This is because each box frontier
    is a closed set with empty interior, and we can apply `interior_union_isClosed_of_interior_empty`
    iteratively. -/
lemma interior_iUnion_Box_frontier_eq_empty {d n : ℕ} (B : Fin n → Box d) :
    interior (⋃ i, frontier (B i).toSet) = ∅ := by
  sorry

theorem IsElementary.almost_disjoint {d k:ℕ} {E: Set (EuclideanSpace' d)} (hE: IsElementary E) (B: Fin k → Box d) (hEB: E = ⋃ i, (B i).toSet) (hdisj : Pairwise (Function.onFun AlmostDisjoint B)) : hE.measure = ∑ i, |B i|ᵥ := by
  sorry

/-- Lemma 1.2.9 (Outer measure of countable unions of almost disjoint boxes).
    For pairwise almost disjoint boxes, m*(⋃ Bᵢ) = ∑' m*(Bᵢ) = ∑' |Bᵢ|. -/
theorem Lebesgue_outer_measure.union_of_almost_disjoint {d:ℕ} {B : ℕ → Box d} (h : Pairwise (Function.onFun AlmostDisjoint B)) :
    Lebesgue_outer_measure (⋃ i, (B i).toSet) = ∑' i, Lebesgue_outer_measure (B i).toSet := by
  sorry

theorem Lebesgue_outer_measure.univ {d:ℕ} {hd: 0 < d} : Lebesgue_outer_measure (Set.univ : Set (EuclideanSpace' d)) = ⊤ := by
  sorry

/-- Remark 1.2.10 -/
theorem Box.sum_volume_eq {d:ℕ} (B B': ℕ → Box d) (hdisj: Pairwise (Function.onFun AlmostDisjoint B)) (hdisj': Pairwise (Function.onFun AlmostDisjoint B')) (hcover: (⋃ n, (B n).toSet) = (⋃ n, (B' n).toSet)) :
    ∑' n, (B n).volume = ∑' n, (B' n).volume := by
  sorry

/-- Exercise 1.2.5: For any set that equals a countable union of almost disjoint boxes,
    the Lebesgue outer measure equals the Jordan inner measure. -/
theorem Lebesgue_outer_measure.eq_Jordan_inner_of_boxes {d:ℕ} (E: Set (EuclideanSpace' d)) (B: ℕ → Box d)
    (hE: E = ⋃ n, (B n).toSet) (hdisj: Pairwise (Function.onFun AlmostDisjoint B)) :
    Lebesgue_outer_measure E = Jordan_inner_measure E := by
  sorry

def IsCube {d:ℕ} (B: Box d) : Prop := ∃ r, ∀ i, |B.side i|ₗ = r

noncomputable def DyadicCube {d:ℕ} (n:ℤ) (a: Fin d → ℤ) : Box d := { side := fun i ↦ Icc (a i/2^n) ((a i + 1)/2^n) }

lemma DyadicCube.isCube {d:ℕ} (n:ℤ) (a: Fin d → ℤ) : IsCube (DyadicCube n a) := by
  sorry

def Box.IsDyadicAtScale {d:ℕ} (B: Box d) (n:ℤ) : Prop := ∃ a: Fin d → ℤ, B = DyadicCube n a

def Box.IsDyadic {d:ℕ} (B: Box d) : Prop := ∃ n:ℕ, B.IsDyadicAtScale n

-- Helper lemmas for Lemma 1.2.11
namespace DyadicCube

/-- Dyadic cubes at scale n ≥ 0 have sidelength at most 1. -/
lemma sidelength_le_one {d:ℕ} {n:ℕ} (a: Fin d → ℤ) (i : Fin d) :
    |(DyadicCube (n:ℤ) a).side i|ₗ ≤ 1 := by
  sorry

/-- The dyadic cubes at scale n cover all of ℝᵈ. -/
lemma cover_univ {d:ℕ} (n:ℤ) :
    (⋃ (a : Fin d → ℤ), (DyadicCube n a).toSet) = Set.univ := by
  sorry

/-- Dyadic cubes at the same scale are pairwise almost disjoint. -/
lemma pairwise_almost_disjoint {d:ℕ} (n:ℤ) :
    Pairwise (Function.onFun AlmostDisjoint (DyadicCube n : (Fin d → ℤ) → Box d)) := by
  sorry

/-- Two dyadic cubes are either almost disjoint or one contains the other. -/
lemma nesting {d:ℕ} {n m : ℤ} {a : Fin d → ℤ} {b : Fin d → ℤ} :
    AlmostDisjoint (DyadicCube n a) (DyadicCube m b) ∨
    (DyadicCube n a).toSet ⊆ (DyadicCube m b).toSet ∨
    (DyadicCube m b).toSet ⊆ (DyadicCube n a).toSet := by
  sorry

end DyadicCube

/-- For a point x, the unique dyadic cube at scale n containing x. -/
noncomputable def dyadicCubeContaining {d:ℕ} (n:ℤ) (x : EuclideanSpace' d) : Box d :=
  DyadicCube n (fun i => ⌊x i * 2^n⌋)

/-- The dyadic cube containing x at scale n indeed contains x. -/
lemma dyadicCubeContaining_mem {d:ℕ} (n:ℤ) (x : EuclideanSpace' d) :
    x ∈ (dyadicCubeContaining n x).toSet := by
  sorry

/-- Lemma 1.2.11: Every open set is a countable union of almost disjoint dyadic cubes.
Note: every dyadic cube is nonempty
    Proof outline:
    1. For each x ∈ E, by `IsOpen.exists_dyadic_cube_subset`, there exists a dyadic cube containing x ⊆ E
    2. The set of all such dyadic cubes is countable (subset of {lean}`ℕ × (Fin d → ℤ)`)
    3. Take maximal cubes (not strictly contained in another cube in the collection)
    4. By `DyadicCube.nesting`, distinct maximal cubes are almost disjoint
    5. E equals the union of these maximal cubes -/
theorem IsOpen.eq_union_boxes {d:ℕ} (hd : 0 < d) (E: Set (EuclideanSpace' d)) (hE: IsOpen E)
    (hE_nonempty : E.Nonempty) :
    ∃ B: ℕ → Box d, (E = ⋃ n, (B n).toSet) ∧ (∀ n, (B n).IsDyadic) ∧
    Pairwise (Function.onFun AlmostDisjoint B) := by
  sorry

theorem Lebesgue_outer_measure.of_open {d:ℕ} (E: Set (EuclideanSpace' d)) (hE: IsOpen E) : Lebesgue_outer_measure E = Jordan_inner_measure E := by
  sorry

/-- Lemma 1.2.12 (Outer regularity). m\*(E) = inf\{m\*(U) : E ⊆ U, U open\}. -/
theorem Lebesgue_outer_measure.eq {d:ℕ} (E: Set (EuclideanSpace' d)) : Lebesgue_outer_measure E = sInf { M | ∃ U, E ⊆ U ∧ IsOpen U ∧ M = Lebesgue_outer_measure U} := by
  sorry

/-- For any set E and ε > 0, there exists an open U ⊇ E with m*(U) ≤ m*(E) + ε.
    This follows from outer regularity (Lemma 1.2.12). -/
lemma Lebesgue_outer_measure.exists_open_superset_measure_le {d:ℕ} (E: Set (EuclideanSpace' d)) (ε : EReal) (hε : 0 < ε) :
    ∃ U : Set (EuclideanSpace' d), IsOpen U ∧ E ⊆ U ∧ Lebesgue_outer_measure U ≤ Lebesgue_outer_measure E + ε := by
  sorry

/-- Compact sets in Euclidean space have finite Lebesgue outer measure. -/
lemma Lebesgue_outer_measure.finite_of_compact {d : ℕ} {E : Set (EuclideanSpace' d)}
    (hE : IsCompact E) : Lebesgue_outer_measure E ≠ ⊤ := by
  sorry

/-- Exercise 1.2.6 -/
example : ∃ (d:ℕ) (E: Set (EuclideanSpace' d)), Lebesgue_outer_measure E ≠ sSup { M | ∃ U, U ⊆ E ∧ IsOpen U ∧ M = Lebesgue_outer_measure U} := by
  sorry
