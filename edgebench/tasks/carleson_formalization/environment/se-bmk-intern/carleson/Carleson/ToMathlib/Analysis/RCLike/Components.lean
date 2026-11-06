module

public import Mathlib.Algebra.EuclideanDomain.Field
public import Mathlib.Analysis.InnerProductSpace.Basic
public import Carleson.ToMathlib.Analysis.RCLike.Basic
public import Carleson.ToMathlib.ENorm

/-
Upstreaming status: Not sure whether `Components` is the right definition and `RCLike.induction`
really is a good statement; if it should go to mathlib, this file needs significant cleanup
-/

public section

namespace RCLike

open NNReal

/-- TODO: check whether this is the right approach -/
@[expose]
def Components {𝕂 : Type*} [RCLike 𝕂] : Finset 𝕂 := {1, -1, RCLike.I, -RCLike.I}

lemma Components.norm_eq_one {𝕂 : Type*} [RCLike 𝕂] {c : 𝕂} (hc : c ∈ Components) (hc' : c ≠ 0) :
    ‖c‖ = 1 := by
  sorry

lemma Components.norm_le_one {𝕂 : Type*} [RCLike 𝕂] {c : 𝕂} (hc : c ∈ Components) : ‖c‖ ≤ 1 := by
  sorry

open ComplexConjugate

/-- TODO: check whether this is the right approach -/
@[expose]
def component {𝕂 : Type*} [RCLike 𝕂] (c : 𝕂) (a : 𝕂) : ℝ≥0 :=
  Real.toNNReal (RCLike.re (a * conj c))

lemma component_le_norm {𝕂 : Type*} [RCLike 𝕂] {c a : 𝕂} (hc : c ∈ Components) :
    component c a ≤ ‖a‖ := by
  sorry

lemma component_le_nnnorm {𝕂 : Type*} [RCLike 𝕂] {c a : 𝕂} (hc : c ∈ Components) :
    component c a ≤ ‖a‖₊ := by
  sorry

lemma decomposition {𝕂 : Type*} [RCLike 𝕂] {a : 𝕂} :
  1 * ((algebraMap ℝ 𝕂) (component 1 a).toReal)
  + -1 * ((algebraMap ℝ 𝕂) (component (-1) a).toReal)
  + RCLike.I * ((algebraMap ℝ 𝕂) (component RCLike.I a).toReal)
  + -RCLike.I * ((algebraMap ℝ 𝕂) (component (-RCLike.I) a).toReal) = a := by
  sorry

theorem nnnorm_ofReal
  {𝕂 : Type*} [RCLike 𝕂] {a : ℝ≥0} :
  a = ‖(@RCLike.ofReal 𝕂 _) (NNReal.toReal a)‖₊ := by
  sorry

theorem enorm_ofReal
  {𝕂 : Type*} [RCLike 𝕂] {a : ℝ≥0} :
    ‖a‖ₑ = ‖(@RCLike.ofReal 𝕂 _) (NNReal.toReal a)‖ₑ := by
  sorry

/-
--TODO: move / generalize or find existing version
theorem add_induction {β γ} [AddCommMonoid β] [AddCommMonoid γ]
  {g : α → β} {f : β → γ} {motive : γ → γ → Prop}
  (motive_trans : IsTrans γ motive)
  (motive_add_left : ∀ {x y z : γ}, motive y z → motive (x + y) (x + z))
  (zero : motive (f 0) 0)
  (add : ∀ {x y : β}, motive (f (x + y)) (f x + f y))
  {s : Finset α} :
    motive (f (∑ x ∈ s, g x)) (∑ x ∈ s, f (g x)) := by
  classical
  induction s using Finset.induction_on with
  | empty =>
    simpa only [Finset.sum_empty]
  | insert a s ha ih =>
    rw [Finset.sum_insert ha, Finset.sum_insert ha]
    have : motive (f (g a + ∑ x ∈ s, g x)) (f (g a) + f (∑ x ∈ s, g x)) := add
    apply motive_trans.trans _ _ _ this
    apply motive_add_left ih

--TODO: move / generalize or find existing version
theorem vector_valued_induction {β γ} [AddCommMonoid β] [AddCommMonoid γ]
  {M : Type*} [AddCommMonoid M] [Module ℝ M]
  {Q : (α → M) → Prop} {motive : ℕ → (α → M) → Prop}
  {f : α → M} (hf : Q f)
  :
  motive 1 f := sorry
-/

/-! ### Helper lemmas for the RCLike component decomposition norm bounds -/

section RCLikeComponentHelpers

private lemma component_one_add_neg_one {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    algebraMap ℝ 𝕂 (component 1 a).toReal +
      (-1 : 𝕂) * algebraMap ℝ 𝕂 (component (-1) a).toReal = algebraMap ℝ 𝕂 (re a) := by
  sorry

private lemma component_I_add_neg_I {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    (I : 𝕂) * algebraMap ℝ 𝕂 (component I a).toReal +
      (-I : 𝕂) * algebraMap ℝ 𝕂 (component (-I) a).toReal = algebraMap ℝ 𝕂 (im a) * I := by
  sorry

/-- Norm of the real component part is at most `‖a‖`. -/
private lemma norm_realPart_le {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    ‖algebraMap ℝ 𝕂 (component 1 a).toReal +
      (-1 : 𝕂) * algebraMap ℝ 𝕂 (component (-1) a).toReal‖ ≤ ‖a‖ := by
  sorry

/-- Norm of the imaginary component part is at most `‖a‖`. -/
private lemma norm_imPart_le {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    ‖(I : 𝕂) * algebraMap ℝ 𝕂 (component I a).toReal +
      (-I : 𝕂) * algebraMap ℝ 𝕂 (component (-I) a).toReal‖ ≤ ‖a‖ := by
  sorry

/-- `max(re a, 0)` embedded in 𝕂 has norm at most `|re a|`. -/
private lemma norm_posReal_le {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    ‖(algebraMap ℝ 𝕂 (component 1 a).toReal : 𝕂)‖ ≤
      ‖algebraMap ℝ 𝕂 (component 1 a).toReal +
        (-1 : 𝕂) * algebraMap ℝ 𝕂 (component (-1) a).toReal‖ := by
  sorry

/-- `max(-re a, 0)` negated and embedded in 𝕂 has norm at most `|re a|`. -/
private lemma norm_negReal_le {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    ‖(-1 : 𝕂) * algebraMap ℝ 𝕂 (component (-1) a).toReal‖ ≤
      ‖algebraMap ℝ 𝕂 (component 1 a).toReal +
        (-1 : 𝕂) * algebraMap ℝ 𝕂 (component (-1) a).toReal‖ := by
  sorry

/-- `I * max(im a, 0)` has norm at most `‖I * im⁺ - I * im⁻‖`. -/
private lemma norm_posIm_le {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    ‖(I : 𝕂) * algebraMap ℝ 𝕂 (component I a).toReal‖ ≤
      ‖(I : 𝕂) * algebraMap ℝ 𝕂 (component I a).toReal +
        (-I : 𝕂) * algebraMap ℝ 𝕂 (component (-I) a).toReal‖ := by
  sorry

/-- `-I * max(-im a, 0)` has norm at most `‖I * im⁺ - I * im⁻‖`. -/
private lemma norm_negIm_le {𝕂 : Type*} [RCLike 𝕂] (a : 𝕂) :
    ‖(-I : 𝕂) * algebraMap ℝ 𝕂 (component (-I) a).toReal‖ ≤
      ‖(I : 𝕂) * algebraMap ℝ 𝕂 (component I a).toReal +
        (-I : 𝕂) * algebraMap ℝ 𝕂 (component (-I) a).toReal‖ := by
  sorry

end RCLikeComponentHelpers

--TODO: clean up the proof
theorem induction {α : Type*} {𝕂 : Type*} [RCLike 𝕂]
  {β : Type*} [Mul β] {a b}
  {P : (α → 𝕂) → Prop}
  (P_add : ∀ {f g : α → 𝕂}, P f → P g → P (f + g))
  (P_components : ∀ {f : α → 𝕂} {c : 𝕂} (_ : c ∈ RCLike.Components),
    P f → P (algebraMap ℝ 𝕂 ∘ NNReal.toReal ∘ RCLike.component c ∘ f))
  (P_mul_unit : ∀ {f : α → 𝕂} {c : 𝕂} (_ : c ∈ RCLike.Components), P f → P (c • f))
  {motive : (α → 𝕂) → β → Prop}
  (motive_nnreal : ∀ {f : α → ℝ≥0} (_ : P (algebraMap ℝ 𝕂 ∘ NNReal.toReal ∘ f)),
    motive (algebraMap ℝ 𝕂 ∘ NNReal.toReal ∘ f) a)
  (motive_add' : ∀ {n : β} {f g : α → 𝕂} (_ : ∀ {x}, ‖f x‖ ≤ ‖f x + g x‖)
    (_ : ∀ {x}, ‖g x‖ ≤ ‖f x + g x‖) (_ : P f) (_ : P g),
      motive f n → motive g n → motive (f + g) (n * b))
  (motive_mul_unit : ∀ {f : α → 𝕂} {c : 𝕂} {n : β} (_ : c ∈ RCLike.Components) (_ : P f),
    motive f n → motive (c • f) n)
  ⦃f : α → 𝕂⦄ (hf : P f) :
    motive f (a * b * b) := by
  sorry

end RCLike
