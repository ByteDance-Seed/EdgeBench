module

public import Carleson.Classical.CarlesonOnTheRealLine

@[expose] public section

/- This file contains most of Section 11.6 (The error bound) from the blueprint.
   The main result is control_approximation_effect.
-/

noncomputable section

local notation "T" => carlesonOperatorReal K
local notation "S_" => partialFourierSum

open scoped Real
open MeasureTheory
open Real (pi_pos)

/- TODO: might be generalized. -/
lemma ENNReal.le_on_subset {X : Type} [MeasurableSpace X] (μ : Measure X) {f g : X → ENNReal}
    {E : Set X} (hE : MeasurableSet E)
    (hf : Measurable f) (hg : Measurable g) {a : ENNReal} (h : ∀ x ∈ E, a ≤ f x + g x) :
    ∃ E' ⊆ E, MeasurableSet E' ∧ μ E ≤ 2 * μ E'
      ∧ ((∀ x ∈ E', a / 2 ≤ f x) ∨ (∀ x ∈ E', a / 2 ≤ g x)) := by
  sorry

open Complex ComplexConjugate

lemma Dirichlet_Hilbert_eq {N : ℕ} {x : ℝ} :
    (max (1 - |x|) 0) * dirichletKernel' N (x) =
      exp (I * (-N * x)) * k x + conj (exp (I * (-N * x)) * k x) := by
  sorry

lemma Dirichlet_Hilbert_diff {N : ℕ} {x : ℝ} (hx : x ∈ Set.Icc (-π) π) :
    ‖dirichletKernel' N (x) - (exp (I * (-N * x)) * k x + conj (exp (I * (-N * x)) * k x))‖ ≤ π := by
  sorry

section

open Filter Topology

lemma le_iSup_of_tendsto {α β} [TopologicalSpace α] [CompleteLinearOrder α] [OrderTopology α]
    [Nonempty β] [SemilatticeSup β] {f : β → α} {a : α} (ha : Tendsto f atTop (𝓝 a)) : a ≤ iSup f := by
  sorry

lemma integrable_annulus {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π)) {f : ℝ → ℂ}
    (hf : IntervalIntegrable f volume (-π) (3 * π)) {r : ℝ} (r_nonneg : 0 ≤ r) (rle1 : r < 1) :
    Integrable (fun x ↦ f x) (volume.restrict {y | dist x y ∈ Set.Ioo r 1}) := by
  sorry

lemma intervalIntegrable_mul_dirichletKernel' {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π)) {f : ℝ → ℂ}
    (hf : IntervalIntegrable f volume (-π) (3 * π)) {N : ℕ} :
    IntervalIntegrable (fun y ↦ f y * dirichletKernel' N (x - y)) volume (x - π) (x + π) := by
  sorry

lemma intervalIntegrable_mul_dirichletKernel'_max {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π)) {f : ℝ → ℂ}
   (hf : IntervalIntegrable f volume (-π) (3 * π)) {N : ℕ} :
    IntervalIntegrable (fun y ↦ f y * ((max (1 - |x - y|) 0)
      * dirichletKernel' N (x - y))) volume (x - π) (x + π) := by
  sorry

lemma intervalIntegrable_mul_dirichletKernel'_max' {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π)) {f : ℝ → ℂ}
    (hf : IntervalIntegrable f volume (-π) (3 * π)) {N : ℕ} :
    IntervalIntegrable (fun y ↦ f y
      * (dirichletKernel' N (x - y) - (max (1 - |x - y|) 0) * dirichletKernel' N (x - y)))
      volume (x - π) (x + π) := by
  sorry

lemma domain_reformulation {g : ℝ → ℂ} (hg : IntervalIntegrable g volume (-π) (3 * π)) {N : ℕ}
    {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π)) :
    ∫ (y : ℝ) in x - π..x + π, g y * ((max (1 - |x - y|) 0) * dirichletKernel' N (x - y))
    = ∫ (y : ℝ) in {y | dist x y ∈ Set.Ioo 0 1},
        g y * ((max (1 - |x - y|) 0) * dirichletKernel' N (x - y)) := by
  sorry

lemma intervalIntegrable_mul_dirichletKernel'_specific {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π))
    {f : ℝ → ℂ} (hf : IntervalIntegrable f volume (-π) (3 * π)) {N : ℕ} :
    IntegrableOn (fun y ↦ f y * ((max (1 - |x - y|) 0)
      * dirichletKernel' N (x - y))) {y | dist x y ∈ Set.Ioo 0 1} volume := by
  sorry

attribute [gcongr] iSup_congr

set_option backward.isDefEq.respectTransparency false in
lemma le_CarlesonOperatorReal {g : ℝ → ℂ} (hg : IntervalIntegrable g volume (-π) (3 * π)) {N : ℕ} {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π)) :
    ‖∫ (y : ℝ) in x - π..x + π, g y * ((max (1 - |x - y|) 0) * dirichletKernel' N (x - y))‖ₑ
    ≤ T g x + T (conj ∘ g) x := by
  sorry

lemma partialFourierSum_bound {δ : ℝ} (hδ : 0 < δ) {g : ℝ → ℂ} (measurable_g : Measurable g)
    (periodic_g : Function.Periodic g (2 * π)) (bound_g : ∀ x, ‖g x‖ ≤ δ)
    {N : ℕ} {x : ℝ} (hx : x ∈ Set.Icc 0 (2 * π)) :
    ‖S_ N g x‖ₑ ≤
    (T g x + T (conj ∘ g) x) / (ENNReal.ofReal (2 * π)) + ENNReal.ofReal (π * δ) := by
  sorry

end

set_option linter.flexible false in
lemma rcarleson_exceptional_set_estimate {δ : ℝ} (δpos : 0 < δ) {f : ℝ → ℂ} (hmf : Measurable f)
    {F : Set ℝ} (measurableSetF : MeasurableSet F) (hf : ∀ x, ‖f x‖ ≤ δ * F.indicator 1 x)
    {E : Set ℝ} (measurableSetE : MeasurableSet E) {ε : ENNReal} (hE : ∀ x ∈ E, ε ≤ T f x) :
      ε * volume E ≤ ENNReal.ofReal (δ * C10_0_1 4 2) * volume F ^ (2 : ℝ)⁻¹ * volume E ^ (2 : ℝ)⁻¹ := by
  sorry

lemma rcarleson_exceptional_set_estimate_specific {δ : ℝ} (δpos : 0 < δ) {f : ℝ → ℂ} (hmf : Measurable f) (hf : ∀ x, ‖f x‖ ≤ δ)
    {E : Set ℝ} (measurableSetE : MeasurableSet E) (E_subset : E ⊆ Set.Icc 0 (2 * π)) {ε : ENNReal} (hE : ∀ x ∈ E, ε ≤ T f x) :
      ε * volume E ≤ ENNReal.ofReal (δ * C10_0_1 4 2 * (2 * π + 2) ^ (2 : ℝ)⁻¹) * volume E ^ (2 : ℝ)⁻¹ := by
  sorry

def C_control_approximation_effect (ε : ℝ) := (C10_0_1 4 2 * (8 / (π * ε)) ^ (2 : ℝ)⁻¹) + π

lemma lt_C_control_approximation_effect {ε : ℝ} (εpos : 0 < ε) : π < C_control_approximation_effect ε := by
  sorry

lemma C_control_approximation_effect_pos {ε : ℝ} (εpos : 0 < ε) : 0 < C_control_approximation_effect ε := by
  sorry

lemma C_control_approximation_effect_eq {ε : ℝ} {δ : ℝ} (ε_nonneg : 0 ≤ ε) :
    C_control_approximation_effect ε * δ =
      ((δ * C10_0_1 4 2 * (4 * π) ^ (2 : ℝ)⁻¹ * (2 / ε) ^ (2 : ℝ)⁻¹) / π) + π * δ := by
  sorry

/- This is Lemma 11.6.4 (partial Fourier sums of small) in the blueprint.-/
lemma control_approximation_effect {ε : ℝ} (εpos : 0 < ε) {δ : ℝ} (hδ : 0 < δ)
    {h : ℝ → ℂ} (h_measurable : Measurable h)
    (h_periodic : h.Periodic (2 * π)) (h_bound : ∀ x, ‖h x‖ ≤ δ) :
    ∃ E ⊆ Set.Icc 0 (2 * π), MeasurableSet E ∧ volume.real E ≤ ε ∧ ∀ x ∈ Set.Icc 0 (2 * π) \ E,
      ∀ N, ‖S_ N h x‖ ≤ C_control_approximation_effect ε * δ := by
  sorry

end
