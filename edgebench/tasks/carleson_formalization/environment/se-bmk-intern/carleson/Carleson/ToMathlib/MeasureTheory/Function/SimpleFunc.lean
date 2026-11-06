module

public import Mathlib.Algebra.Order.Pi
public import Mathlib.MeasureTheory.Constructions.BorelSpace.Order
public import Mathlib.MeasureTheory.Function.SimpleFunc

@[expose] public section

-- Upstreaming status: needs cleanup (lemma names, shorter proofs, etc.)

noncomputable section

open Set hiding restrict restrict_apply

open Filter ENNReal

open Function (support)

open Topology NNReal ENNReal MeasureTheory

namespace MeasureTheory

variable {α β γ δ : Type*}

namespace SimpleFunc

--TODO: tag this as @[fun_prop] (currently this gives an error)
theorem measurable_comp [MeasurableSpace α] [MeasurableSpace γ] {f : SimpleFunc α β}
  {g : β → γ} :
    Measurable (g ∘ f) := by
  sorry

theorem measurable_comp' [MeasurableSpace α] [MeasurableSpace γ] {f : SimpleFunc α β}
  {g : β → γ} :
    Measurable fun a ↦ g (f a) := by
  sorry

/- Proof stolen from the mathlib `SimpleFunc.induction` with a minor modification
   that is even suggested there. -/
--TODO: update notation in mathlib version to match this one
@[elab_as_elim]
protected theorem induction₀ [MeasurableSpace α] [AddZeroClass γ]
    {motive : SimpleFunc α γ → Prop}
    (const : ∀ (c) {s} (_ : MeasurableSet s),
      motive ((SimpleFunc.const _ c).restrict s))
    (add : ∀ ⦃f : SimpleFunc α γ⦄ (c : γ) ⦃s : Set α⦄ (_ : MeasurableSet s), Disjoint (Function.support ⇑f) s →
      motive f → motive ((SimpleFunc.const α c).restrict s) →
        motive (f + ((SimpleFunc.const α c).restrict s)))
    (f : SimpleFunc α γ) : motive f := by
  sorry

open Pointwise in
private lemma helper [MeasurableSpace α] [LinearOrder β] [AddCommMonoid β] [CanonicallyOrderedAdd β]
  [OrderBot β] [Sub β] [OrderedSub β]
  {f : SimpleFunc α β} (hs : (f.range \ {0}).Nonempty) :
  let s := f.range \ {0};
  ((f - (const α (s.min' hs)).restrict (support ⇑f)).range \ {0}).card + 1
    = (f.range \ {0}).card := by
  sorry

--TODO: move
--TODO: formulate this with `IsLowerSet` and write a separate lemma to distinguish the cases
open Classical in
lemma Antitone.support_eq [ConditionallyCompleteLinearOrderBot α] [AddMonoid β] [LinearOrder β] [CanonicallyOrderedAdd β] [OrderBot β]
  {f : α → β} (hf : Antitone f) :
    f.support = if (BddAbove f.support) then
                  if (sSup f.support ∈ f.support)
                    then Set.Iic (sSup f.support)
                  else Set.Iio (sSup f.support)
                else Set.univ
    := by
  sorry

@[elab_as_elim]
protected theorem antitone_induction [MeasurableSpace α] [ConditionallyCompleteLinearOrderBot α]
  [LinearOrder β] [AddCommMonoid β] [CanonicallyOrderedAdd β] [OrderBot β] [Sub β] [OrderedSub β]
  {motive : (SimpleFunc α β) → Prop}
  (const'' : ∀ (c : β) (b : α), motive ((SimpleFunc.const α c).restrict (Set.Iio b)))
  (const' : ∀ (c : β) (b : α), motive ((SimpleFunc.const α c).restrict (Set.Iic b)))
  (const : ∀ (c : β), motive (SimpleFunc.const α c))
  (add : ∀ ⦃f : SimpleFunc α β⦄ (c : β) ⦃s : Set α⦄ (_ : MeasurableSet s), (Function.support ⇑f) ⊆ s →
    motive f → motive ((SimpleFunc.const α c).restrict s) →
      motive (f + ((SimpleFunc.const α c).restrict s))) (f : SimpleFunc α β) (hf : Antitone f) :
        motive f := by
  sorry

@[elab_as_elim]
protected theorem induction'' [MeasurableSpace α] [LinearOrder β] [AddCommMonoid β]
  [CanonicallyOrderedAdd β] [OrderBot β] [Sub β] [OrderedSub β]
  {motive : (SimpleFunc α β) → Prop}
  (const : ∀ (c : β) {s : Set α} (_ : MeasurableSet s), motive ((SimpleFunc.const α c).restrict s))
  (add : ∀ ⦃f : SimpleFunc α β⦄ (c : β) ⦃s : Set α⦄ (_ : MeasurableSet s), (Function.support ⇑f) ⊆ s →
    motive f → motive ((SimpleFunc.const α c).restrict s) →
      motive (f + ((SimpleFunc.const α c).restrict s))) (f : SimpleFunc α β) :
        motive f := by
  sorry

variable [MeasurableSpace α]

section Approx

theorem approx_le {α : Type u_1} {β : Type u_2}
  [inst : MeasurableSpace α] [ConditionallyCompleteLinearOrderBot β] [Zero β] [TopologicalSpace β]
  [OrderClosedTopology β] [MeasurableSpace β] [OpensMeasurableSpace β]
  {i : ℕ → β} {f : α → β} (hf : Measurable f) (h_zero : (0 : β) = ⊥)
  {a : α} {n : ℕ} :
    (approx i f n) a ≤ f a := by
  sorry

/- Version of `iSup_approx_apply` for `ConditionallyCompleteLinearOrderBot`. -/
theorem iSup_approx_apply' [ConditionallyCompleteLinearOrderBot β] [TopologicalSpace β] [OrderClosedTopology β] [Zero β]
    [MeasurableSpace β] [OpensMeasurableSpace β] (i : ℕ → β) (f : α → β) (a : α) (hf : Measurable f)
    (h_zero : (0 : β) = ⊥) : ⨆ n, (approx i f n : SimpleFunc α β) a = ⨆ (k) (_ : i k ≤ f a), i k := by
  sorry

end Approx

section NNApprox

variable {f : α → ℝ≥0}

/-- A sequence of `ℝ≥0`s such that its range is the set of non-negative rational numbers. -/
def nnrealRatEmbed (n : ℕ) : ℝ≥0 :=
  Real.toNNReal ((Encodable.decode (α := ℚ) n).getD (0 : ℚ))

theorem nnrealRatEmbed_encode (q : ℚ) :
    nnrealRatEmbed (Encodable.encode q) = Real.toNNReal q := by
  sorry

/-- Approximate a function `α → ℝ≥0` by a sequence of simple functions. -/
def nnapprox : (α → ℝ≥0) → ℕ → SimpleFunc α ℝ≥0 :=
  approx nnrealRatEmbed

lemma nnapprox_le {f : α → ℝ≥0} (hf : Measurable f) {a : α} {n : ℕ} :
    (nnapprox f n) a ≤ f a := by
  sorry

@[mono]
theorem monotone_nnapprox {f : α → ℝ≥0} : Monotone (nnapprox f) := by
  sorry

set_option linter.style.multiGoal false in
lemma iSup_nnapprox_apply (hf : Measurable f) (a : α) : ⨆ n, (nnapprox f n : SimpleFunc α ℝ≥0) a = f a := by
  sorry

lemma iSup_nnapprox (hf : Measurable f) : (fun a ↦ ⨆ n, (nnapprox f n) a) = f := by
  sorry

end NNApprox

end SimpleFunc

/-- modelled after Measurable.ennreal_induction but with very raw assumptions -/
@[elab_as_elim]
protected theorem Measurable.nnreal_induction {α : Type*} {mα : MeasurableSpace α} {motive : (α → ℝ≥0) → Prop}
    (simpleFunc : ∀ ⦃f : SimpleFunc α ℝ≥0⦄, motive f)
    (approx :
      ∀ ⦃f : α → ℝ≥0⦄, (_ : Measurable f) → (∀ (n : ℕ), motive (SimpleFunc.nnapprox f n)) → motive f)
    ⦃f : α → ℝ≥0⦄ (hf : Measurable f) : motive f := by
  sorry

--modified from ennreal_induction
@[elab_as_elim]
protected theorem Measurable.ennreal_induction' {α : Type*} {mα : MeasurableSpace α} {motive : (α → ℝ≥0∞) → Prop}
    (simpleFunc : ∀ ⦃f : SimpleFunc α ℝ≥0∞⦄, motive f)
    (iSup :
      ∀ ⦃f : ℕ → (SimpleFunc α ℝ≥0∞)⦄,
        Monotone f → (∀ (n : ℕ), motive (f n)) → motive fun x ↦ ⨆ n, f n x)
    ⦃f : α → ℝ≥0∞⦄ (hf : Measurable f) : motive f := by
  sorry

lemma Antitone.antitone_eapprox {α : Type*} [TopologicalSpace α] {mα : MeasurableSpace α} [BorelSpace α]
  [LinearOrder α] [OrderClosedTopology α] ⦃f : α → ℝ≥0∞⦄ (hf : Antitone f) {n : ℕ} :
    Antitone (SimpleFunc.eapprox f n) := by
  sorry

--modified from ennreal_induction
@[elab_as_elim]
protected theorem Antitone.ennreal_induction' {α : Type*} [TopologicalSpace α] {mα : MeasurableSpace α} [BorelSpace α]
  [LinearOrder α] [OrderClosedTopology α]
   {motive : (α → ℝ≥0∞) → Prop}
    (simpleFunc : ∀ ⦃f : SimpleFunc α ℝ≥0∞⦄, Antitone f → motive f)
    (iSup :
      ∀ ⦃f : ℕ → (SimpleFunc α ℝ≥0∞)⦄,
        Monotone f → (∀ (n : ℕ), motive (f n)) → motive fun x ↦ ⨆ n, f n x)
    ⦃f : α → ℝ≥0∞⦄ (hf : Antitone f) : motive f := by
  sorry

end MeasureTheory
