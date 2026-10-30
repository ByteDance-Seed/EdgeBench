module

public import Carleson.ToMathlib.LorentzType
public import Carleson.ToMathlib.RealInterpolation.Main

/-! # The Marcinkiewisz interpolation theorem for Lorentz spaces

Upstreaming status: this file is under construction and being worked on. Don't upstream yet! -/

@[expose] public section

open NNReal ENNReal MeasureTheory Set Pointwise

variable {α α' ε E E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞}
  {C₀ C₁ : ℝ≥0} {μ : Measure α} {ν : Measure α'}
  [TopologicalSpace E] [TopologicalSpace E₁] [TopologicalSpace E₂] [TopologicalSpace E₃]
  [ENormedAddCommMonoid E]
  [ENormedAddCommMonoid E₁] [ENormedAddCommMonoid E₂] [ENormedAddCommMonoid E₃]
  [MeasurableSpace E] [BorelSpace E]
  [MeasurableSpace E₃] [BorelSpace E₃]
  {f : α → E₁} {t : ℝ≥0∞}
  {T : (α → E₁) → (α' → E₂)}

/-- The constant occurring in the general real interpolation theorem (for Lorentz spaces) -/
def C_LorentzInterpolation (p₀ p₁ q₀ q₁ q : ℝ≥0∞) (C₀ C₁ A : ℝ≥0) (t : ℝ≥0∞) : ℝ≥0 :=
    sorry

/-- General Marcinkiewicz real interpolation theorem -/
theorem exists_hasLorentzType_real_interpolation {p₀ p₁ r₀ r₁ q₀ q₁ s₀ s₁ p q : ℝ≥0∞}
    [MeasurableSpace E₁] [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    [MeasurableSpace E₂] [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    -- TODO: find out which of the conditions `(1 ≤ ·)` are actually necessary.
    (hp₀ : 1 ≤ p₀) (hp₁ : 1 ≤ p₁) (hr₀ : 1 ≤ r₀) (hr₁ : 1 ≤ r₁)
    (hq₀ : 1 ≤ q₀) (hq₁ : 1 ≤ q₁) (hs₀ : 1 ≤ s₀) (hs₁ : 1 ≤ s₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ t A : ℝ≥0} (hA : 0 < A) (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁) (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (hmT : ∀ f, MemLorentz f p q μ → AEStronglyMeasurable (T f) ν)
    (hT : AESubadditiveOn T (fun f ↦ MemLorentz f p₀ r₀ μ ∨ MemLorentz f p₁ r₁ μ) A ν)
    (h₀T : HasLorentzType T p₀ r₀ q₀ s₀ μ ν C₀) (h₁T : HasLorentzType T p₁ r₁ q₁ s₁ μ ν C₁) :
      ∀ r, 0 < r → HasLorentzType T p r q r μ ν (C_LorentzInterpolation p₀ p₁ q₀ q₁ q C₀ C₁ A t) := by
  sorry
