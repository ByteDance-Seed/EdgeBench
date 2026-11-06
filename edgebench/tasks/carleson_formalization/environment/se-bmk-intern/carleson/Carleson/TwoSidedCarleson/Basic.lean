module

public import Carleson.Calculations
public import Carleson.ToMathlib.MeasureTheory.Integral.IntegrableOn

@[expose] public section

open MeasureTheory Set Metric Function Topology NNReal ENNReal

variable {X : Type*} {a : ℕ} [MetricSpace X] [DoublingMeasure X (defaultA a : ℕ)]
variable {r : ℝ}
variable {K : X → X → ℂ} {x x' : X} [IsOneSidedKernel a K]

/-- The Calderon Zygmund operator `T_r` in chapter Two-sided Metric Space Carleson -/
noncomputable def czOperator {X : Type*} [PseudoMetricSpace X] [MeasureSpace X] (K : X → X → ℂ)
    (r : ℝ) (f : X → ℂ) (x : X) : ℂ := ∫ y in (ball x r)ᶜ, K x y * f y

lemma czOperator_bound {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : 0 < r) (x : X) :
    ∃ (M : ℝ≥0), ∀ᵐ y ∂(volume.restrict (ball x r)ᶜ), ‖K x y * g y‖ ≤ M := by
  sorry

omit [IsOneSidedKernel a K] in
@[fun_prop]
lemma czOperator_aestronglyMeasurable' (hK : Measurable (uncurry K))
    {g : X → ℂ} (hg : AEStronglyMeasurable g) :
    AEStronglyMeasurable (fun x ↦ czOperator K r g x) := by
  sorry

@[fun_prop]
lemma czOperator_aestronglyMeasurable
    {g : X → ℂ} (hg : AEStronglyMeasurable g) :
    AEStronglyMeasurable (fun x ↦ czOperator K r g x) := by
  sorry

/- Next lemma is useful for fun_prop in a context where it can not find the relevant measure to
apply `czOperator_aestronglyMeasurable`.
TODO: investigate -/
@[fun_prop]
lemma czOperator_aestronglyMeasurable_aux {g : X → ℂ} (hg : BoundedFiniteSupport g) :
    AEStronglyMeasurable (fun x ↦ czOperator K r g x) := by
  sorry

lemma czOperator_welldefined {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : 0 < r) (x : X) :
    IntegrableOn (fun y => K x y * g y) (ball x r)ᶜ volume := by
  sorry

-- This could be adapted to state T_r is a linear operator but maybe it's not worth the effort
lemma czOperator_sub {f g : X → ℂ} (hf : BoundedFiniteSupport f) (hg : BoundedFiniteSupport g) (hr : 0 < r) :
    czOperator K r (f - g) = czOperator K r f - czOperator K r g := by
  sorry

/-- Lemma 10.1.1 -/
lemma geometric_series_estimate {x : ℝ} (hx : 2 ≤ x) :
    ∑' (n : ℕ), (2 : ℝ≥0∞) ^ (-n / x) ≤ 2 ^ x := by
  sorry
