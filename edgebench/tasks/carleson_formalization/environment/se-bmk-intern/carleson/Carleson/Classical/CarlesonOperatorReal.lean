module

public import Carleson.Classical.HilbertKernel
public import Mathlib.MeasureTheory.Integral.Prod

@[expose] public section

/- This file contains the definition and basic properties of the Carleson operator on the real line.
-/

noncomputable section

open MeasureTheory

--TODO: avoid this extra definition?
def carlesonOperatorReal (K : ℝ → ℝ → ℂ) (f : ℝ → ℂ) (x : ℝ) : ENNReal :=
  ⨆ (n : ℤ) (r : ℝ) (_ : 0 < r) (_ : r < 1),
  ‖∫ y in {y | dist x y ∈ Set.Ioo r 1}, f y * K x y * Complex.exp (Complex.I * n * y)‖ₑ

lemma annulus_real_eq {x r R : ℝ} (r_nonneg : 0 ≤ r) : {y | dist x y ∈ Set.Ioo r R} = Set.Ioo (x - R) (x - r) ∪ Set.Ioo (x + r) (x + R) := by
  sorry

lemma annulus_real_volume {x r R : ℝ} (hr : r ∈ Set.Icc 0 R) :
    volume {y | dist x y ∈ Set.Ioo r R} = ENNReal.ofReal (2 * (R - r)) := by
  sorry

lemma annulus_measurableSet {x r R : ℝ} : MeasurableSet {y | dist x y ∈ Set.Ioo r R} := by
  sorry

lemma sup_eq_sup_dense_of_continuous {f : ℝ → ENNReal} {S : Set ℝ} (D : Set ℝ) (hS : IsOpen S) (hD : Dense D) (hf : ContinuousOn f S) :
    ⨆ r ∈ S, f r = ⨆ r ∈ (S ∩ D), f r := by
  sorry

lemma measurable_mul_kernel {n : ℤ} {f : ℝ → ℂ} (hf : Measurable f) :
    Measurable (Function.uncurry fun x y ↦ f y * K x y * (Complex.I * n * y).exp) := by
  sorry

/-- Rationals as a set of real numbers. -/
private def Qᵣ : Set ℝ := Rat.cast '' Set.univ

/-- Rationals are dense in reals. -/
private lemma Qᵣ_dense : Dense Qᵣ := by
  sorry

/-- Rationals are countable after conversion to reals, too. -/
private lemma Qᵣ_countable : Countable Qᵣ := by
  sorry

local notation "T" => carlesonOperatorReal K

lemma carlesonOperatorReal_measurable {f : ℝ → ℂ} (f_measurable : Measurable f)
    {B : ℝ} (f_bounded : ∀ x, ‖f x‖ ≤ B) :
    Measurable (T f) := by
  sorry

--TODO: Refactor the measurability proof to use the following.

/-
import Mathlib.MeasureTheory.Measure.MeasureSpace
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic

open TopologicalSpace MeasureTheory Set

variable {α β : Type*} [MeasurableSpace α]
  [MeasurableSpace β]
  {ι : Type*} [LinearOrder ι] [TopologicalSpace ι] [OrderTopology ι] [DenselyOrdered ι] [SecondCountableTopology ι]
  {f : ι → α → β} [ConditionallyCompleteLattice β]
  [TopologicalSpace β] [OrderTopology β] [SecondCountableTopology β]
  [BorelSpace β]

-- lemma Measurable_iSup_gt {s : Set ι} [OrdConnected s]
--     (h1f : ∀ x i, ContinuousWithinAt (f · x) s i)
--     (h2f : ∀ i, Measurable (f i)) :
--     Measurable (⨆ i ∈ s, f i ·) := by
  -- use SecondCountableTopology to rewrite the sup as a sup over the countable dense set (or similar)
  -- then use measurable_iSup
-/

lemma carlesonOperatorReal_mul {f : ℝ → ℂ} {x : ℝ} {a : ℝ} (ha : 0 < a) :
    T f x = ENNReal.ofReal a * T (fun x ↦ 1 / a * f x) x := by
  sorry

lemma carlesonOperatorReal_eq_of_restrict_interval {f : ℝ → ℂ} {a b : ℝ} {x : ℝ} (hx : x ∈ Set.Icc a b) : T f x = T ((Set.Ioo (a - 1) (b + 1)).indicator f) x := by
  sorry
