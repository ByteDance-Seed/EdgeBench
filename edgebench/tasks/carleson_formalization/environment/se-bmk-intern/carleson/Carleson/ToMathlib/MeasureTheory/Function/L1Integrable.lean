module

public import Mathlib.MeasureTheory.Function.L1Space.Integrable
public import Carleson.ToMathlib.BoundedCompactSupport

public section

-- Upstreaming status: both lemmas are useful, but need moving or comparing with other lemmas
-- Do upstream, but only after putting in that work.

open MeasureTheory Complex

variable {X : Type*} [MeasureSpace X]

open scoped ComplexConjugate

-- move to Function/L1/Integrable.lean
@[fun_prop]
lemma _root_.MeasureTheory.Integrable.conj {f : X → ℂ} (hf : Integrable f) :
    Integrable (fun x ↦ conj (f x)) := by
  sorry

-- TODO: compare with mul and conj in BoundedCompactSupport
@[fun_prop]
lemma _root_.MeasureTheory.Integrable.mul_conj [TopologicalSpace X] {f g : X → ℂ} (hf : Integrable f)
    (hf' : BoundedCompactSupport f) (hg : Integrable g) : Integrable (fun x ↦ f x * conj (g x)) := by
  sorry
