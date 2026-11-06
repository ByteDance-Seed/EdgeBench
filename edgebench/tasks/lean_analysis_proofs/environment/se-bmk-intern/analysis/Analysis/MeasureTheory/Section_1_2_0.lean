import Analysis.MeasureTheory.Section_1_1_3
import Mathlib.Topology.Algebra.InfiniteSum.Basic
import Mathlib.Data.Set.Countable
import Mathlib.Topology.Instances.Irrational
/-!
# Introduction to Measure Theory, Section 1.2: Lebesgue measure

A companion to (the introduction to) Section 1.2 of the book "An introduction to Measure Theory".

-/

open BoundedInterval

/-- Exercise 1.2.1 (countable union) -/
lemma exercise_1_2_1_union :
    ∃ E: ℕ → Set ℝ, (∀ n, Bornology.IsBounded (E n)) ∧
      (∀ n, JordanMeasurable (Real.equiv_EuclideanSpace' '' (E n))) ∧
      (∀ n, E n ⊆ Set.Icc 0 1) ∧
      ¬ JordanMeasurable (⋃ n, Real.equiv_EuclideanSpace' '' (E n)) := by
  sorry

/-- Exercise 1.2.1 (countable union) -/
example :
    ∃ E: ℕ → Set ℝ, (∀ n, Bornology.IsBounded (E n)) ∧
      (∀ n, JordanMeasurable (Real.equiv_EuclideanSpace' '' (E n)))
      ∧ ¬ JordanMeasurable (⋃ n, Real.equiv_EuclideanSpace' '' (E n)) := by
  sorry

/-- Exercise 1.2.1 (countable intersection) -/
example :
    ∃ E: ℕ → Set ℝ, (∀ n, Bornology.IsBounded (E n)) ∧
      (∀ n, JordanMeasurable (Real.equiv_EuclideanSpace' '' (E n))) ∧
      ¬ JordanMeasurable (⋂ n, Real.equiv_EuclideanSpace' '' (E n)) := by
  sorry

/-- Exercise 1.2.2 -/
-- The pointwise limit of uniformly bounded Riemann integrable functions need not be Riemann integrable.
example : ∃ f: ℕ → ℝ → ℝ, ∃ F: ℝ → ℝ, ∃ M, ∀ n, ∀ x ∈ Set.Icc 0 1, |f n x| ≤ M ∧
    (∀ x ∈ Set.Icc 0 1, Filter.atTop.Tendsto (fun n ↦ f n x) (nhds (F x))) ∧
    (∀ n, RiemannIntegrableOn (f n) (Icc 0 1)) ∧
    ¬ RiemannIntegrableOn F (Icc 0 1) := by
  sorry

/-- Exercise 1.2.2 -/
-- Determine whether uniform convergence of uniformly bounded Riemann integrable functions preserves Riemann integrability (true or false).
def Ex_1_2_2b : Decidable ( ∀ f: ℕ → ℝ → ℝ, ∀ F: ℝ → ℝ, (∃ M, ∀ n, ∀ x ∈ Set.Icc 0 1, |f n x| ≤ M) → (∀ x ∈ Set.Icc 0 1, TendstoUniformly f F Filter.atTop) → (∀ n, RiemannIntegrableOn (f n) (Icc 0 1)) → RiemannIntegrableOn F (Icc 0 1) ) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`, depending on whether you believe the given statement to be true or false.
  sorry

-- The Jordan outer measure equals the infimum of sums of box volumes over all finite box covers.
theorem Jordan_outer_eq {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) : Jordan_outer_measure E = sInf (((fun S: Finset (Box d) ↦ ∑ B ∈ S, |B|ᵥ)) '' { S | E ⊆ ⋃ B ∈ S, B.toSet }) := by
  sorry

/-- This definition deviates from the text by working with countable families of boxes rather than boxes indexed by the natural numbers.  This becomes important in dimension zero, when all boxes are non-empty. -/
noncomputable def Lebesgue_outer_measure {d:ℕ} (E: Set (EuclideanSpace' d)) : EReal :=
  sInf { V | ∃ (X : Set ℕ) (S: X → Box d), E ⊆ ⋃ n, (S n).toSet ∧ V = ∑' n, (S n).volume.toEReal }

open Classical in

open Classical in
/-- In dimension 0, the Lebesgue outer measure is 1 for non-empty sets and 0 for the empty set.
    This is because all boxes in dimension 0 are singletons with volume 1 (empty product). -/
lemma Lebesgue_outer_measure_of_dim_zero {E: Set (EuclideanSpace' 0)} :
    Lebesgue_outer_measure E = if E.Nonempty then 1 else 0 := by
  sorry

-- For any bounded set, the Lebesgue outer measure is at most the Jordan outer measure.
theorem Lebesgue_outer_measure_le_Jordan {d:ℕ} {E: Set (EuclideanSpace' d)} (hE: Bornology.IsBounded E) : Lebesgue_outer_measure E ≤ Jordan_outer_measure E := by
  sorry

/-- Example 1.2.1.  With the junk value conventions of this companion, the Jordan outer measure of the rationals is zero rather than infinite (I think). -/
-- The Jordan outer measure of the rationals in a bounded interval equals the interval length.
example {R:ℝ} (hR: 0 < R) : Jordan_outer_measure (Real.equiv_EuclideanSpace' '' (Set.Icc (-R) R ∩ Set.range (fun q:ℚ ↦ (q:ℝ)))) = 2*R := by
  sorry

-- Any countable set (in positive dimension) has Lebesgue outer measure zero.

-- The Lebesgue outer measure of the rationals in a bounded interval is zero.
example {R:ℝ} : Lebesgue_outer_measure (Real.equiv_EuclideanSpace' '' (Set.Icc (-R) R ∩ Set.range (fun q:ℚ ↦ (q:ℝ)))) = 0 := by
  sorry

-- The Lebesgue outer measure of all rationals is zero.
example : Lebesgue_outer_measure (Real.equiv_EuclideanSpace' '' (Set.range (fun q:ℚ ↦ (q:ℝ)))) = 0 := by
  sorry

-- A set is Lebesgue measurable if it can be approximated arbitrarily well from the outside by open sets.
def LebesgueMeasurable {d:ℕ} (E: Set (EuclideanSpace' d)) : Prop :=
  ∀ ε > 0, ∃ U: Set (EuclideanSpace' d), IsOpen U ∧ E ⊆ U ∧ Lebesgue_outer_measure (U \ E) ≤ ε

-- The Lebesgue measure of a set (equals its Lebesgue outer measure).
noncomputable def Lebesgue_measure {d:ℕ} (E: Set (EuclideanSpace' d)) : EReal := Lebesgue_outer_measure E
