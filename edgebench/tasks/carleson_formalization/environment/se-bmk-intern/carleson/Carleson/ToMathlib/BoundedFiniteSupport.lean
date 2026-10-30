module

public import Mathlib.MeasureTheory.Function.L1Space.Integrable

public section

/-
This file defines BoundedFiniteSupport.

Upstreaming status: this will remain in place but not be upstreamed, only BoundedCompactSupport.
- rationale on Zulip: https://leanprover.zulipchat.com/#narrow/with/591174350
- TODO: can other proofs be golfed using fun_prop now?
-/

open MeasureTheory Function ENNReal TopologicalSpace

noncomputable section

variable {X E : Type*} [MeasurableSpace X] {f g : X → E} {μ : Measure X}

variable [TopologicalSpace E] [ENorm E] [Zero E] in
/-- Definition to avoid repeating ourselves.
Blueprint states: *bounded measurable function $g$ on $X$ supported on a set of finite measure*. -/
@[fun_prop]
structure BoundedFiniteSupport (f : X → E) (μ : Measure X := by volume_tac) : Prop where
  memLp_top : MemLp f ∞ μ
  measure_support_lt : μ (support f) < ∞

namespace BoundedFiniteSupport

section Includebfs
variable [TopologicalSpace E] [ENorm E] [Zero E] (bfs : BoundedFiniteSupport f μ)
include bfs

@[fun_prop]
theorem aestronglyMeasurable : AEStronglyMeasurable f μ := by
  sorry

@[fun_prop]
theorem aemeasurable [MeasurableSpace E] [PseudoMetrizableSpace E]
    [BorelSpace E] : AEMeasurable f μ := by
  sorry

@[fun_prop]
theorem aestronglyMeasurable_restrict {s : Set X} :
    AEStronglyMeasurable f (μ.restrict s) := by
  sorry

@[fun_prop]
theorem aemeasurable_restrict [MeasurableSpace E] [PseudoMetrizableSpace E]
    [BorelSpace E] {s : Set X} :
    AEMeasurable f (μ.restrict s) := by
  sorry

@[aesop (rule_sets := [finiteness]) unsafe 80% apply]
theorem eLpNorm_lt_top : eLpNorm f ∞ μ < ∞ := by
  sorry

end Includebfs

section ESeminormedAddMonoid
variable [TopologicalSpace E] [ESeminormedAddMonoid E]

/-- Bounded finitely supported functions are in all `Lᵖ` spaces. -/
theorem memLp (hf : BoundedFiniteSupport f μ) (p : ℝ≥0∞) : MemLp f p μ := by
  sorry

end ESeminormedAddMonoid

section NormedAddCommGroup

variable [NormedAddCommGroup E]

/-- Bounded finitely supported functions are integrable. -/
@[fun_prop]
theorem integrable (hf : BoundedFiniteSupport f μ) : Integrable f μ := by
  sorry

@[fun_prop]
theorem indicator (bfs : BoundedFiniteSupport f μ) {s : Set X} (hs : MeasurableSet s) :
    BoundedFiniteSupport (s.indicator f) μ := by
  sorry

@[fun_prop]
protected theorem neg (hf : BoundedFiniteSupport f μ) : BoundedFiniteSupport (-f) μ := by
  sorry

@[fun_prop]
protected theorem add (hf : BoundedFiniteSupport f μ) (hg : BoundedFiniteSupport g μ) :
    BoundedFiniteSupport (f + g) μ := by
  sorry

@[fun_prop]
protected theorem sub (hf : BoundedFiniteSupport f μ) (hg : BoundedFiniteSupport g μ) :
    BoundedFiniteSupport (f - g) μ := by
  sorry

end NormedAddCommGroup

end BoundedFiniteSupport
