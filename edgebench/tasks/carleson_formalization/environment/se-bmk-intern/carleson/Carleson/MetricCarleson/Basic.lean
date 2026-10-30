module

public import Carleson.DoublingMeasure
public import Carleson.ToMathlib.RealInterpolation.Misc
public import Mathlib.Order.CompleteLattice.Group

@[expose] public section

open scoped NNReal
open ENNReal hiding one_lt_two
open MeasureTheory Set Filter Topology ShortVariables Metric Complex

noncomputable section

variable {X : Type*} {a : ℕ} [MetricSpace X] {K : X → X → ℂ}

namespace MetricΘ

variable [CompatibleFunctions ℝ X (defaultA a)]

/-- We choose as metric space instance on `Θ` one given by an arbitrary ball.
The metric given by all other balls are equivalent. -/
instance : PseudoMetricSpace (Θ X) :=
  inferInstanceAs <| PseudoMetricSpace <| WithFunctionDistance o 1

lemma dist_eq_cdist {f g : Θ X} : dist f g = dist_{o, 1} f g := by
  sorry

/-!
The following two lemmas state that the distance could be equivalently given by any other cdist.
-/

lemma dist_le_cdist {f g : Θ X} {x : X} {r : ℝ} (hr : 0 < r) :
    dist f g ≤ As (defaultA a) ((1 + dist o x) / r) * dist_{x, r} f g := by
  sorry

lemma cdist_le_dist {f g : Θ X} {x : X} {r : ℝ} (hr : 0 < r) :
    dist_{x, r} f g ≤ As (defaultA a) (r + dist o x) * dist f g := by
  sorry

instance : SecondCountableTopology (Θ X) :=
  CompatibleFunctions.allBallsCoverBalls.secondCountableTopology one_lt_two

end MetricΘ

open MetricΘ

variable [KernelProofData a K] {θ ϑ : Θ X} {Q : SimpleFunc X (Θ X)} {R₁ R₂ : ℝ} {f g : X → ℂ} {x : X}

@[simp]
theorem carlesonOperator_zero : carlesonOperator K 0 = 0 := by
  sorry

theorem carlesonOperatorIntegrand_congr_ae (h : f =ᶠ[ae volume] g) {x : X} {θ : Θ X} {R₁ R₂ : ℝ} :
    carlesonOperatorIntegrand K ((fun _ ↦ θ) x) R₁ R₂ f x
      = carlesonOperatorIntegrand K ((fun _ ↦ θ) x) R₁ R₂ g x := by
  sorry

theorem linearizedCarlesonOperator_congr_ae (h : f =ᶠ[ae volume] g)
  (x : X) (θ : Θ X) :
    linearizedCarlesonOperator (fun _ ↦ θ) K f x = linearizedCarlesonOperator (fun _ ↦ θ) K g x := by
  sorry

theorem carlesonOperator_congr_ae (h : f =ᶠ[ae volume] g) :
    carlesonOperator K f = carlesonOperator K g := by
  sorry

theorem carlesonOperator_zero_of_ae_zero (hf : f =ᶠ[ae volume] 0) :
    carlesonOperator K f = 0 := by
  sorry

@[fun_prop]
lemma measurable_carlesonOperatorIntegrand (mf : Measurable f) :
    Measurable (fun x ↦ carlesonOperatorIntegrand K (Q x) R₁ R₂ f x) := by
  sorry

open Annulus in
/-- Let `f` be integrable over an annulus with fixed radii `R₁, R₂`.
Then `fun R ↦ ∫ y in oo x R R₂, f y` is right-continuous at `R₁`. -/
lemma rightContinuous_integral_annulus (iof : IntegrableOn f (oo x R₁ R₂)) :
    ContinuousWithinAt (fun R ↦ ∫ y in oo x R R₂, f y) (Ici R₁) R₁ := by
  sorry

open Annulus in
/-- Let `f` be integrable over an annulus with fixed radii `R₁, R₂`.
Then `fun R ↦ ∫ y in oo x R₁ R, f y` is left-continuous at `R₂`. -/
lemma leftContinuous_integral_annulus (iof : IntegrableOn f (oo x R₁ R₂)) :
    ContinuousWithinAt (fun R ↦ ∫ y in oo x R₁ R, f y) (Iic R₂) R₂ := by
  sorry

lemma integrableOn_annulus_of_bounded (mf : AEStronglyMeasurable f volume)
  (nf : (‖f ·‖) ≤ 1) :
    IntegrableOn f (Annulus.oo x R₁ R₂) volume := by
  sorry

/-- The integrand of `carlesonOperatorIntegrand` is integrable over the `R₁, R₂` annulus. -/
lemma integrableOn_coi_inner_annulus' (nf : IntegrableOn f (Annulus.oo x R₁ R₂)) (hR₁ : 0 < R₁) :
    IntegrableOn (fun y ↦ K x y * f y * exp (I * θ y)) (Annulus.oo x R₁ R₂) := by
  sorry

/-- The integrand of `carlesonOperatorIntegrand` is integrable over the `R₁, R₂` annulus. -/
lemma integrableOn_coi_inner_annulus₀ (mf : AEStronglyMeasurable f volume) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    IntegrableOn (fun y ↦ K x y * f y * exp (I * θ y)) (Annulus.oo x R₁ R₂) := by
  sorry

/-- The integrand of `carlesonOperatorIntegrand` is integrable over the `R₁, R₂` annulus. -/
-- (this is a weaker version assuming full measurability)
-- TODO: remove this version and only keep the above?
lemma integrableOn_coi_inner_annulus (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    IntegrableOn (fun y ↦ K x y * f y * exp (I * θ y)) (Annulus.oo x R₁ R₂) := by
  sorry

lemma rightContinuous_carlesonOperatorIntegrand'
    (mf : IntegrableOn f (Annulus.oo x R₁ R₂) volume) (hR₁ : 0 < R₁) :
    ContinuousWithinAt (carlesonOperatorIntegrand K θ · R₂ f x) (Ici R₁) R₁ := by
  sorry

lemma rightContinuous_carlesonOperatorIntegrand
    (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    ContinuousWithinAt (carlesonOperatorIntegrand K θ · R₂ f x) (Ici R₁) R₁ := by
  sorry

lemma leftContinuous_carlesonOperatorIntegrand'
    (mf : IntegrableOn f (Annulus.oo x R₁ R₂) volume) (hR₁ : 0 < R₁) :
    ContinuousWithinAt (carlesonOperatorIntegrand K θ R₁ · f x) (Iic R₂) R₂ := by
  sorry

lemma leftContinuous_carlesonOperatorIntegrand
    (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    ContinuousWithinAt (carlesonOperatorIntegrand K θ R₁ · f x) (Iic R₂) R₂ := by
  sorry

variable (θ x) in
/-- Given `0 < R₁ < R₂`, move `(R₁, R₂)` to rational `(q₁, q₂)` where `R₁ < q₁ < q₂ < R₂`
and the norm of `carlesonOperatorIntegrand` changes by at most `ε`. -/
lemma exists_rat_near_carlesonOperatorIntegrand'
    (mf : IntegrableOn f (Annulus.oo x R₁ R₂) volume) (hR₁ : 0 < R₁) (hR₂ : R₁ < R₂) {ε : ℝ} (εpos : 0 < ε) :
    ∃ q₁ q₂ : ℚ, R₁ < q₁ ∧ q₁ < q₂ ∧ q₂ < R₂ ∧
    dist (carlesonOperatorIntegrand K θ q₁ q₂ f x)
    (carlesonOperatorIntegrand K θ R₁ R₂ f x) < ε := by
  sorry

variable (θ x) in
/-- Given `0 < R₁ < R₂`, move `(R₁, R₂)` to rational `(q₁, q₂)` where `R₁ < q₁ < q₂ < R₂`
and the norm of `carlesonOperatorIntegrand` changes by at most `ε`. -/
lemma exists_rat_near_carlesonOperatorIntegrand
    (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) (hR₂ : R₁ < R₂) {ε : ℝ} (εpos : 0 < ε) :
    ∃ q₁ q₂ : ℚ, R₁ < q₁ ∧ q₁ < q₂ ∧ q₂ < R₂ ∧
    dist (carlesonOperatorIntegrand K θ q₁ q₂ f x)
    (carlesonOperatorIntegrand K θ R₁ R₂ f x) < ε := by
  sorry

/-- The constant used in the proof of `int-continuous`. -/
irreducible_def C3_0_1 (a : ℕ) (R₁ R₂ : ℝ≥0) : ℝ≥0 :=
  2 ^ (a ^ 3) * (2 * R₂ / R₁) ^ a

lemma lintegral_inv_vol_le {R₁ R₂ : ℝ≥0} (hR₁ : 0 < R₁) (hR₂ : R₁ < R₂) :
    ∫⁻ y in Annulus.oo x R₁ R₂, (vol x y)⁻¹ ≤ ↑((2 * R₂ / R₁) ^ a) := by
  sorry

lemma edist_carlesonOperatorIntegrand_le
    {R₁ R₂ : ℝ≥0} (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    edist (carlesonOperatorIntegrand K θ R₁ R₂ f x) (carlesonOperatorIntegrand K ϑ R₁ R₂ f x) ≤
    C3_0_1 a R₁ R₂ * edist_{x, dist o x + R₂} θ ϑ := by
  sorry

lemma dist_carlesonOperatorIntegrand_le
    {R₁ R₂ : ℝ≥0} (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    dist (carlesonOperatorIntegrand K θ R₁ R₂ f x) (carlesonOperatorIntegrand K ϑ R₁ R₂ f x) ≤
    C3_0_1 a R₁ R₂ * dist_{x, dist o x + R₂} θ ϑ := by
  sorry

lemma continuous_carlesonOperatorIntegrand (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    Continuous (carlesonOperatorIntegrand K · R₁ R₂ f x) := by
  sorry

-- not sure if this is the best phrasing
lemma enorm_carlesonOperatorIntegrand_le {R₁ R₂ : ℝ≥0} (nf : (‖f ·‖) ≤ 1) (hR₁ : 0 < R₁) :
    ‖carlesonOperatorIntegrand K θ R₁ R₂ f x‖ₑ ≤ C3_0_1 a R₁ R₂ := by
  sorry

@[fun_prop]
theorem carlesonOperatorIntegrand_measurable {θ : Θ X} (mf : AEStronglyMeasurable f) :
    Measurable (carlesonOperatorIntegrand K θ R₁ R₂ f) := by
  sorry

@[fun_prop]
theorem linearizedCarlesonOperator_measurable {θ : Θ X} (hf : LocallyIntegrable f) :
    Measurable (linearizedCarlesonOperator (fun _ ↦ θ) K f) := by
  sorry

-- TODO: get rid of the countability assumption
@[fun_prop]
theorem carlesonOperator_measurable (hf : LocallyIntegrable f) [Countable (Θ X)] :
    Measurable (carlesonOperator K f) := by
  sorry

theorem enorm_carlesonOperatorIntegrand_add_le_add_enorm_carlesonOperatorIntegrand
  {f g : X → ℂ} (hf : LocallyIntegrable f) (hg : LocallyIntegrable g)
  {θ : Θ X} {R₁ R₂ : ℝ} (R₁_pos : 0 < R₁) :
  ‖carlesonOperatorIntegrand K θ R₁ R₂ (f + g) x‖ₑ ≤
    ‖carlesonOperatorIntegrand K θ R₁ R₂ f x‖ₑ + ‖carlesonOperatorIntegrand K θ R₁ R₂ g x‖ₑ := by
  sorry

-- TODO: this proof is a good target for automation
theorem linearizedCarlesonOperator_add_le_add_linearizedCarlesonOperator
  {f g : X → ℂ} (hf : LocallyIntegrable f) (hg : LocallyIntegrable g) {θ : Θ X} :
  linearizedCarlesonOperator (fun _ ↦ θ) K (f + g) x ≤
    linearizedCarlesonOperator (fun _ ↦ θ) K f x + linearizedCarlesonOperator (fun _ ↦ θ) K g x := by
  sorry

theorem carlesonOperator_add_le_add_carlesonOperator
  {f g : X → ℂ} (hf : LocallyIntegrable f) (hg : LocallyIntegrable g) :
    carlesonOperator K (f + g) x ≤ carlesonOperator K f x + carlesonOperator K g x := by
  sorry

lemma tendsto_carlesonOperatorIntegrand_of_dominated_convergence
  (hR₁ : 0 < R₁)
  {l : Filter ℕ} [l.IsCountablyGenerated]
  {F : ℕ → X → ℂ} (bound : X → ℝ)
  (hF_meas : ∀ᶠ (n : ℕ) in l, AEStronglyMeasurable (F n))
  (h_bound : ∀ᶠ (n : ℕ) in l, ∀ᵐ (a : X), ‖F n a‖ ≤ bound a)
  (bound_integrable : IntegrableOn (fun y ↦ bound y) (Annulus.oo x R₁ R₂) volume)
  (h_lim : ∀ᵐ (a : X), Filter.Tendsto (fun (n : ℕ) => F n a) l (nhds (f a))) :
    Filter.Tendsto (fun (n : ℕ) => carlesonOperatorIntegrand K θ R₁ R₂ (F n) x) l
      (nhds (carlesonOperatorIntegrand K θ R₁ R₂ f x)) := by
  sorry

lemma linearizedCarlesonOperator_le_liminf_linearizedCarlesonOperator_of_tendsto
  {Q : X → Θ X}
  {l : Filter ℕ} [l.IsCountablyGenerated] [l.NeBot]
  {F : ℕ → X → ℂ} (bound : X → ℝ)
  (hF_meas : ∀ᶠ (n : ℕ) in l, AEStronglyMeasurable (F n))
  (h_bound : ∀ᶠ (n : ℕ) in l, ∀ᵐ (a : X), ‖F n a‖ ≤ bound a)
  (bound_integrable : LocallyIntegrable bound)
  (h_lim : ∀ᵐ (a : X), Filter.Tendsto (fun (n : ℕ) => F n a) l (nhds (f a))) :
      linearizedCarlesonOperator Q K f x ≤ Filter.liminf (fun n ↦ linearizedCarlesonOperator Q K (F n) x) l := by
  sorry

lemma carlesonOperator_le_liminf_carlesonOperator_of_tendsto
  {l : Filter ℕ} [l.IsCountablyGenerated] [l.NeBot]
  {F : ℕ → X → ℂ} (bound : X → ℝ)
  (hF_meas : ∀ᶠ (n : ℕ) in l, AEStronglyMeasurable (F n))
  (h_bound : ∀ᶠ (n : ℕ) in l, ∀ᵐ (a : X), ‖F n a‖ ≤ bound a)
  (bound_integrable : LocallyIntegrable bound)
  (h_lim : ∀ᵐ (a : X), Filter.Tendsto (fun (n : ℕ) => F n a) l (nhds (f a))) :
    carlesonOperator K f x ≤ Filter.liminf (fun n ↦ carlesonOperator K (F n) x) l := by
  sorry
