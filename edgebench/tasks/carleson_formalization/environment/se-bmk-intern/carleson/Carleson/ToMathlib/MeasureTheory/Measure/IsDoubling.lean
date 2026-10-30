module

public import Carleson.ToMathlib.Misc
public import Carleson.ToMathlib.CoveredByBalls
public import Mathlib.Data.Real.StarOrdered
public import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
public import Mathlib.Order.CompletePartialOrder

@[expose] public section

open MeasureTheory Measure NNReal Metric Filter Topology TopologicalSpace
open ENNReal hiding one_lt_two
noncomputable section

-- Upstreaming status: we want this in mathlib in principle, but a fair amount of polish is
-- possible and needed. Move one lemma, streamline proofs (and perhaps add further documentation).

section Doubling

/-- The blow-up factor of repeatedly increasing the size of balls. -/
def As (A : ℝ≥0) (s : ℝ) : ℝ≥0 := A ^ ⌈Real.logb 2 s⌉₊

end Doubling

namespace MeasureTheory

/-- A doubling measure is a measure on a metric space with the condition that doubling
the radius of a ball only increases the volume by a constant factor, independent of the ball. -/
-- should `ℝ≥0` be `ℝ≥0∞`?
class Measure.IsDoubling {X : Type*} [MeasurableSpace X] [PseudoMetricSpace X]
    (μ : Measure X) (A : outParam ℝ≥0) : Prop where
  measure_ball_two_le_same : ∀ (x : X) r, μ (ball x (2 * r)) ≤ A * μ (ball x r)
export IsDoubling (measure_ball_two_le_same)

section PseudoMetric

variable {X : Type*} [PseudoMetricSpace X]

lemma ball_subset_ball_of_le {x x' : X} {r r' : ℝ}
    (hr : dist x x' + r' ≤ r) : ball x' r' ⊆ ball x r := by
  sorry

lemma dist_lt_of_not_disjoint_ball {x x' : X} {r r' : ℝ} (hd : ¬Disjoint (ball x r) (ball x' r')) :
    dist x x' < r + r' := by
  sorry

lemma eq_zero_of_isDoubling_zero [MeasurableSpace X] (μ : Measure X) [hμ : μ.IsDoubling 0] :
    μ = 0 := by
  sorry

variable {A : ℝ≥0} [MeasurableSpace X] {μ : Measure X} [μ.IsDoubling A]

variable (μ) in
lemma eq_zero_of_isDoubling_lt_one [ProperSpace X] [IsFiniteMeasureOnCompacts μ] (hA : A < 1) :
    μ = 0 := by
  sorry

lemma IsDoubling.mono {A'} (h : A ≤ A') : IsDoubling μ A' := by
  sorry

lemma measure_ball_two_le_same_iterate (x : X) (r : ℝ) (n : ℕ) :
    μ (ball x ((2 ^ n) * r)) ≤ A ^ n * μ (ball x r) := by
  sorry

lemma measure_ball_four_le_same (x : X) (r : ℝ) :
    μ (ball x (4 * r)) ≤ A ^ 2 * μ (ball x r) := by
  sorry

lemma measure_ball_le_same (x : X) {r s r' : ℝ} (hsp : 0 < s) (hs : r' ≤ s * r) :
    μ (ball x r') ≤ As A s * μ (ball x r) := by
  sorry

lemma measure_ball_le_of_dist_le' {x x' : X} {r r' s : ℝ} (hs : 0 < s)
    (h : dist x x' + r' ≤ s * r) :
    μ (ball x' r') ≤ As A s * μ (ball x r) := by
  sorry

include A in
variable (μ) in
lemma isOpenPosMeasure_of_isDoubling [NeZero μ] : IsOpenPosMeasure μ := by
  sorry

instance : IsUnifLocDoublingMeasure (μ : Measure X) where
  exists_measure_closedBall_le_mul'' := by
    use max 1 A^2, Set.univ, by simp, Set.univ
    simp only [mem_principal, Set.subset_univ, Set.inter_self, true_and]
    ext r
    simp only [ENNReal.coe_pow, Set.mem_setOf_eq, Set.mem_univ, iff_true]
    intro x
    letI : Nonempty X := ⟨x⟩
    by_cases hr : r ≤ 0
    · have cball_eq : closedBall x (2 * r) = closedBall x r:= by
        by_cases! hr' : r < 0
        · have : 2 * r < 0 := by linarith
          simp [*]
        · simp [le_antisymm hr hr']
      rw [cball_eq]
      nth_rw 1 [← one_mul (μ (closedBall x r))]
      gcongr
      have : (1 : ℝ≥0∞) ≤ (max 1 A : ℝ≥0) := by simp
      rw [← one_mul 1, pow_two]
      gcongr
    · calc
        μ (closedBall x (2 * r))
          ≤ μ (ball x (2 * (2 * r))) := μ.mono (closedBall_subset_ball (by linarith))
        _ ≤ A * μ (ball x (2 * r)) := measure_ball_two_le_same x (2 * r)
        _ ≤ A * (A * μ (ball x r)) := by gcongr; exact measure_ball_two_le_same x r
        _ = ↑(A ^ 2) * μ (ball x r) := by simp only [pow_two, coe_mul, mul_assoc]
        _ ≤ ↑(A ^ 2) * μ (closedBall x r) := by gcongr; exact ball_subset_closedBall
        _ ≤ ↑(max 1 A ^ 2) * μ (closedBall x r) := by gcongr; exact le_max_right 1 A

-- todo: move
lemma Nat.exists_max_image {α : Type*} {s : Set α} (hs : s.Nonempty)
    {f : α → ℕ} (h : BddAbove (f '' s)) : ∃ x ∈ s, ∀ y ∈ s, f y ≤ f x := by
  sorry

include A in
lemma IsDoubling.measure_ball_lt_top [IsLocallyFiniteMeasure μ] {x : X} {r : ℝ} :
    μ (ball x r) < ∞ := by
  sorry

include μ in
variable (μ) in
lemma IsDoubling.allBallsCoverBalls [OpensMeasurableSpace X] [NeZero μ]
    [IsLocallyFiniteMeasure μ] : AllBallsCoverBalls X 2 ⌈As A 9⌉₊ := by
  sorry

variable [ProperSpace X] [IsFiniteMeasureOnCompacts μ]

lemma measureReal_ball_two_le_same (x : X) (r : ℝ) :
    μ.real (ball x (2 * r)) ≤ A * μ.real (ball x r) := by
  sorry

lemma measureReal_ball_two_le_same_iterate (x : X) (r : ℝ) (n : ℕ) :
    μ.real (ball x ((2 ^ n) * r)) ≤ A ^ n * μ.real (ball x r) := by
  sorry

lemma measureReal_ball_pos [μ.IsOpenPosMeasure] (x : X) {r : ℝ} (hr : 0 < r) :
    0 < μ.real (ball x r) := by
  sorry

variable (μ) in
lemma one_le_A [Nonempty X] [μ.IsOpenPosMeasure] : 1 ≤ A := by
  sorry

variable (μ) in
lemma A_pos [Nonempty X] [μ.IsOpenPosMeasure] : 0 < A := by
  sorry

variable (μ) in
lemma A_pos' [Nonempty X] [μ.IsOpenPosMeasure] : 0 < (A : ℝ≥0∞) := by
  sorry

variable (μ) in
lemma As_pos [Nonempty X] [μ.IsOpenPosMeasure] (s : ℝ) : 0 < As A s := by
  sorry

variable (μ) in
lemma As_pos' [Nonempty X] [μ.IsOpenPosMeasure] (s : ℝ) : 0 < (As A s : ℝ≥0∞) := by
  sorry

lemma measureReal_ball_four_le_same (x : X) (r : ℝ) :
    μ.real (ball x (4 * r)) ≤ A ^ 2 * μ.real (ball x r) := by
  sorry

lemma measureReal_ball_le_same (x : X) {r s r' : ℝ} (hsp : 0 < s) (hs : r' ≤ s * r) :
    μ.real (ball x r') ≤ As A s * μ.real (ball x r) := by
  sorry

/-- Version of `measureReal_ball_le_same` without ceiling function. -/
lemma measureReal_ball_le_same' (x : X) {r t : ℝ} (ht : 0 < t) (h't : t ≤ 1) :
    μ.real (ball x r) ≤ A * t ^ (- Real.logb 2 A) * μ.real (ball x (t * r)) := by
  sorry

lemma measureNNReal_ball_le_of_dist_le' {x x' : X} {r r' s : ℝ} (hs : 0 < s)
    (h : dist x x' + r' ≤ s * r) :
    (μ (ball x' r')).toNNReal ≤ As A s * (μ (ball x r)).toNNReal := by
  sorry

end PseudoMetric

section Normed

open Module

lemma Subsingleton.ball_eq {α} [PseudoMetricSpace α] [Subsingleton α] {x : α} {r : ℝ} :
    ball x r = if r > 0 then {x} else ∅ := by
  sorry

instance InnerProductSpace.IsDoubling {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℝ E] [MeasurableSpace E] [BorelSpace E] [FiniteDimensional ℝ E] :
    IsDoubling (volume : Measure E) (2 ^ finrank ℝ E) where
  measure_ball_two_le_same x r := by
    obtain hE|hE := subsingleton_or_nontrivial E
    · simp_rw [Subsingleton.ball_eq, finrank_zero_of_subsingleton]; simp
    simp_rw [InnerProductSpace.volume_ball, ofReal_mul zero_le_two, ← ENNReal.rpow_natCast,
      ENNReal.mul_rpow_of_ne_top ofReal_ne_top ofReal_ne_top, ENNReal.rpow_natCast, mul_assoc]
    simp

end Normed

end MeasureTheory
