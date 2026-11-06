import Mathlib.Topology.Germ
import Mathlib.Analysis.Complex.Norm
import Mathlib.Analysis.RCLike.Basic
import SphereEversion.ToMathlib.Topology.Misc
import SphereEversion.Indexing
import SphereEversion.Notations

-- set_option trace.filter_inst_type true

open Set Filter Function
open scoped Topology unitInterval

/-!
Notes by Patrick:

The goal of this file is to explore how to prove `exists_surrounding_loops` and the local to global
inductive homotopy construction in a way that uncouples the general
topological argument from the things specific to loops or homotopies of jet sections.

First there is a lemma `inductive_construction` which abstracts the locally ultimately constant
arguments, assuming we work with a fixed covering. It builds on
`LocallyFinite.exists_forall_eventually_of_indexType`.

From `inductive_construction` alone we deduce `inductive_htpy_construction` which builds a homotopy
in a similar context. This is meant to be used to go from Chapter 2 to Chapter 3.

Combining `inductive_construction` with an argument using local existence and exhaustions, we
get `inductive_construction_of_loc` building a function from local existence and patching
assumptions. It also has a version `relative_inductive_construction_of_loc` which does this
relative to a closed set. This is used for `exists_surrounding_loops`.

This file also contains supporting lemmas about `IndexType`. A short term goal will be to
get rid of the `indexing` abstraction and do everything in terms of `IndexType`, unless
`indexing` makes those supporting lemmas really cleaner to prove.
-/

section inductive_construction

@[inherit_doc] local notation "𝓘" => IndexType

theorem inductive_construction_of_loc' {X Y : Type*} [EMetricSpace X] [LocallyCompactSpace X]
    [SecondCountableTopology X] (P₀ P₀' P₁ : ∀ x : X, Germ (𝓝 x) Y → Prop) {f₀ : X → Y}
    (hP₀f₀ : ∀ x, P₀ x f₀ ∧ P₀' x f₀)
    (loc : ∀ x, ∃ f : X → Y, (∀ x, P₀ x f) ∧ ∀ᶠ x' in 𝓝 x, P₁ x' f)
    (ind : ∀ {U₁ U₂ K₁ K₂ : Set X} {f₁ f₂ : X → Y}, IsOpen U₁ → IsOpen U₂ →
      IsCompact K₁ → IsCompact K₂ → K₁ ⊆ U₁ → K₂ ⊆ U₂ →
      (∀ x, P₀ x f₁ ∧ P₀' x f₁) → (∀ x, P₀ x f₂) → (∀ x ∈ U₁, P₁ x f₁) → (∀ x ∈ U₂, P₁ x f₂) →
      ∃ f : X → Y, (∀ x, P₀ x f ∧ P₀' x f) ∧
        (∀ᶠ x near K₁ ∪ K₂, P₁ x f) ∧ ∀ᶠ x near K₁ ∪ U₂ᶜ, f x = f₁ x) :
    ∃ f : X → Y, ∀ x, P₀ x f ∧ P₀' x f ∧ P₁ x f := by
  sorry

/-- We are given a suitably nice extended metric space `X` and three local constraints `P₀`,`P₀'`
and `P₁` on maps from `X` to some type `Y`. All maps entering the discussion are required to
statisfy `P₀` everywhere. The goal is to turn a map `f₀` satisfying `P₁` near a compact set `K` into
one satisfying everywhere without changing `f₀` near `K`. The assumptions are:
* For every `x` in `X` there is a map which satisfies `P₁` near `x`
* One can patch two maps `f₁ f₂` satisfying `P₁` on open sets `U₁` and `U₂` respectively
  and such that `f₁` satisfies `P₀'` everywhere into a map satisfying `P₁` on `K₁ ∪ K₂` for any
  compact sets `Kᵢ ⊆ Uᵢ` and `P₀'` everywhere. -/
theorem inductive_construction_of_loc {X Y : Type*} [EMetricSpace X] [LocallyCompactSpace X]
    [SecondCountableTopology X] (P₀ P₀' P₁ : ∀ x : X, Germ (𝓝 x) Y → Prop) {f₀ : X → Y}
    (hP₀f₀ : ∀ x, P₀ x f₀ ∧ P₀' x f₀)
    (loc : ∀ x, ∃ f : X → Y, (∀ x, P₀ x f) ∧ ∀ᶠ x' in 𝓝 x, P₁ x' f)
    (ind : ∀ {U₁ U₂ K₁ K₂ : Set X} {f₁ f₂ : X → Y}, IsOpen U₁ → IsOpen U₂ →
      IsCompact K₁ → IsCompact K₂ → K₁ ⊆ U₁ → K₂ ⊆ U₂ →
      (∀ x, P₀ x f₁ ∧ P₀' x f₁) → (∀ x, P₀ x f₂) → (∀ x ∈ U₁, P₁ x f₁) → (∀ x ∈ U₂, P₁ x f₂) →
      ∃ f : X → Y, (∀ x, P₀ x f ∧ P₀' x f) ∧
        (∀ᶠ x near K₁ ∪ K₂, P₁ x f) ∧ ∀ᶠ x near K₁ ∪ U₂ᶜ, f x = f₁ x) :
    ∃ f : X → Y, ∀ x, P₀ x f ∧ P₀' x f ∧ P₁ x f := by
  sorry

/-- We are given a suitably nice extended metric space `X` and three local constraints `P₀`,`P₀'`
and `P₁` on maps from `X` to some type `Y`. All maps entering the discussion are required to
statisfy `P₀` everywhere. The goal is to turn a map `f₀` satisfying `P₁` near a compact set `K` into
one satisfying everywhere without changing `f₀` near `K`. The assumptions are:
* For every `x` in `X` there is a map which satisfies `P₁` near `x`
* One can patch two maps `f₁ f₂` satisfying `P₁` on open sets `U₁` and `U₂` respectively
  into a map satisfying `P₁` on `K₁ ∪ K₂` for any compact sets `Kᵢ ⊆ Uᵢ`.
This is deduced this version from the version where `K` is empty but adding some `P'₀`, see
`inductive_construction_of_loc`. -/
theorem relative_inductive_construction_of_loc {X Y : Type*} [EMetricSpace X]
    [LocallyCompactSpace X] [SecondCountableTopology X] (P₀ P₁ : ∀ x : X, Germ (𝓝 x) Y → Prop)
    {K : Set X} (hK : IsClosed K) {f₀ : X → Y} (hP₀f₀ : ∀ x, P₀ x f₀) (hP₁f₀ : ∀ᶠ x near K, P₁ x f₀)
    (loc : ∀ x, ∃ f : X → Y, (∀ x, P₀ x f) ∧ ∀ᶠ x' in 𝓝 x, P₁ x' f)
    (ind : ∀ {U₁ U₂ K₁ K₂ : Set X} {f₁ f₂ : X → Y},
      IsOpen U₁ → IsOpen U₂ → IsCompact K₁ → IsCompact K₂ → K₁ ⊆ U₁ → K₂ ⊆ U₂ →
      (∀ x, P₀ x f₁) → (∀ x, P₀ x f₂) → (∀ x ∈ U₁, P₁ x f₁) → (∀ x ∈ U₂, P₁ x f₂) →
      ∃ f : X → Y, (∀ x, P₀ x f) ∧ (∀ᶠ x near K₁ ∪ K₂, P₁ x f) ∧ ∀ᶠ x near K₁ ∪ U₂ᶜ, f x = f₁ x) :
    ∃ f : X → Y, (∀ x, P₀ x f ∧ P₁ x f) ∧ ∀ᶠ x near K, f x = f₀ x := by
  sorry

end inductive_construction

section Htpy

private noncomputable def T : ℕ → ℝ := fun n ↦ Nat.rec 0 (fun k x ↦ x + 1 / (2 : ℝ) ^ (k + 1)) n

-- Note this is more painful than Patrick hoped for. Maybe this should be the definition of T.

private theorem T_le_succ (n : ℕ) : T n ≤ T (n + 1) := by
  sorry

private theorem T_one : T 1 = 1 / 2 := by
  sorry

private theorem not_T_succ_le (n : ℕ) : ¬T (n + 1) ≤ 0 := by
  sorry

theorem inductive_htpy_construction' {X Y : Type*} [TopologicalSpace X] {N : ℕ}
    {U K : IndexType N → Set X} (P₀ P₁ : ∀ x : X, Germ (𝓝 x) Y → Prop)
    (P₂ : ∀ p : ℝ × X, Germ (𝓝 p) Y → Prop)
    (hP₂ : ∀ (a b) (p : ℝ × X) (f : ℝ × X → Y), P₂ (a * p.1 + b, p.2) f →
      P₂ p fun p : ℝ × X ↦ f (a * p.1 + b, p.2))
    (U_fin : LocallyFinite U) (K_cover : (⋃ i, K i) = univ) {f₀ : X → Y} (init : ∀ x, P₀ x f₀)
    (init' : ∀ p, P₂ p fun p : ℝ × X ↦ f₀ p.2)
    -- Not in the original version
    (ind : ∀ (i : IndexType N) (f : X → Y), (∀ x, P₀ x f) → (∀ᶠ x near ⋃ j < i, K j, P₁ x f) →
      ∃ F : ℝ → X → Y, (∀ t, ∀ x, P₀ x <| F t) ∧ (∀ᶠ x near ⋃ j ≤ i, K j, P₁ x <| F 1) ∧
        (∀ p, P₂ p ↿F) ∧ (∀ t, ∀ x ∉ (U i), F t x = f x) ∧
          (∀ᶠ t near Iic 0, F t = f) ∧ ∀ᶠ t near Ici 1, F t = F 1) :
    ∃ F : ℝ → X → Y, F 0 = f₀ ∧ (∀ t x, P₀ x (F t)) ∧ (∀ x, P₁ x (F 1)) ∧ ∀ p, P₂ p ↿F := by
  sorry

theorem inductive_htpy_construction {X Y : Type*}
    [EMetricSpace X] [LocallyCompactSpace X] [SecondCountableTopology X]
    (P₀ P₁ : ∀ x : X, Germ (𝓝 x) Y → Prop)
    (P₂ : ∀ p : ℝ × X, Germ (𝓝 p) Y → Prop)
    (hP₂ : ∀ (a b) (p : ℝ × X) (f : ℝ × X → Y), P₂ (a * p.1 + b, p.2) f →
      P₂ p fun p : ℝ × X ↦ f (a * p.1 + b, p.2))
    (hP₂' : ∀ t x (f : X → Y), P₀ x f → P₂ (t, x) fun p : ℝ × X ↦ f p.2)
    {f₀ : X → Y} (init : ∀ x, P₀ x f₀)
    (ind : ∀ x, ∃ V ∈ 𝓝 x, ∀ K₁ ⊆ V, ∀ K₀ ⊆ interior K₁, IsCompact K₀ → IsCompact K₁ →
      ∀ (C : Set X) (f : X → Y), IsClosed C → (∀ x, P₀ x f) →
      (∀ᶠ x near C, P₁ x f) → ∃ F : ℝ → X → Y, (∀ t, ∀ x, P₀ x <| F t)
        ∧ (∀ᶠ x near C ∪ K₀, P₁ x <| F 1) ∧
      (∀ p, P₂ p ↿F) ∧ (∀ t, ∀ x ∉ K₁, F t x = f x) ∧
      (∀ᶠ t near Iic 0, F t = f) ∧ ∀ᶠ t near Ici 1, F t = F 1) :
    ∃ F : ℝ → X → Y, F 0 = f₀ ∧ (∀ t x, P₀ x (F t)) ∧ (∀ x, P₁ x (F 1)) ∧ ∀ p, P₂ p ↿F := by
  sorry
end Htpy
