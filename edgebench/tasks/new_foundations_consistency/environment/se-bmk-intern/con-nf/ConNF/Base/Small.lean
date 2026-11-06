import ConNF.Background.Rel
import ConNF.Background.Set
import ConNF.Base.Params

/-!
# Small sets

In this file, we define the notion of a small set, and prove many of the basic properties of small
sets.
-/

universe u v

open Cardinal Set
open scoped symmDiff

namespace ConNF

variable [Params.{u}] {ι α β : Type _} {s t u : Set α}

/-- We say that a set is *small* if its cardinality is less than `#κ`. -/
def Small (s : Set α) : Prop :=
  #s < #κ

theorem Small.lt : Small s → #s < #κ := by
  sorry

/-!
## Criteria for smallness
-/

/-- The empty set is small. -/
@[simp]
theorem small_empty : Small (∅ : Set α) := by
  sorry

/-- Singletons are small. -/
@[simp]
theorem small_singleton (x : α) : Small {x} := by
  sorry

/-- Subsets of small sets are small. We say that the 'smallness' relation is monotone. -/
theorem Small.mono (h : s ⊆ t) : Small t → Small s := by
  sorry

/-- Binary unions of small sets are small. -/
theorem small_union (hs : Small s) (ht : Small t) : Small (s ∪ t) := by
  sorry

/-- The *symmetric difference* of two small sets is small; recall that the symmetric difference
`s ∆ t` of two sets `s` and `t` is the union of their differences: `s ∆ t = s \ t ∪ t \ s`. -/
theorem small_symmDiff (hs : Small s) (ht : Small t) : Small (s ∆ t) := by
  sorry

/-- A small set-indexed union of sets is small. -/
theorem small_biUnion {s : Set ι} (hs : Small s) {f : ∀ i ∈ s, Set α}
    (hf : ∀ (i : ι) (hi : i ∈ s), Small (f i hi)) : Small (⋃ (i : ι) (hi : i ∈ s), f i hi) := by
  sorry

/-- The preimage of a small set under an injective function `f` is small. -/
theorem Small.preimage (f : β → α) (h : f.Injective) : Small s → Small (f ⁻¹' s) := by
  sorry

/-- Initial segments of `κ` (including the endpoint) are small. -/
theorem iic_small (i : κ) : Small {j | j ≤ i} := by
  sorry

/-!
## Cardinality bounds on collections of small sets
-/

/-!
## Small relations

One of the crucial differences between this formalisation and previous iterations of the paper is
our extensive use of relational reasoning as opposed to function-based reasoning. This has some
technical advantages that should hopefully become clear over the course of this work.

We will begin our study of relations by proving some smallness results for them, but we will first
establish some terminology that will be used throughout this document.

The *domain* of a relation `r` is the set `{a | ∃ b, r a b}`.
The *codomain* of `r` is the set `{b | ∃ a, r a b}`.

A relation `r` is called

* *injective*, if `r a b` and `r a' b` imply `a = a'`;
* *surjective*, if for every `b`, there is some `a` such that `r a b`;
* *coinjective*, if `r a b` and `r a b'` imply `b = b'`;
* *cosurjective*, if for every `a`, there is some `b` such that `r a b`;
* *one-to-one*, if `r` is both injective and coinjective;
* *functional*, if `r` is both coinjective and cosurjective
    (so is a set-theoretic function);
* *cofunctional*, if `r` is both injective and surjective
    (so is the converse of a set-theoretic function);
* *bijective*, if `r` is both functional and cofunctional;
* *permutative*, if `r` is one-to-one and its domain and codomain are equal.

The *image* of a set `s` under a relation `r` is the set `{b | ∃ a ∈ s, r a b}`.
The *graph* of a relation `r` is the set `{(a, b) | r a b}`.
We can now state our results.
-/

/-!
## Nearness

Once we fix a notion of smallness, we can define an equivalence relation on sets of any type by
declaring that two sets are *near* each other if their symmetric difference is small. This notion
is used when defining *near-litters*, an important part of the ambient structure at the base type
level.
-/

/-- Two sets are called *near* if their symmetric difference is small. -/
def Near (s t : Set α) : Prop :=
  Small (s ∆ t)

/-! We establish the symbol `~` to denote nearness. -/
@[inherit_doc] infix:50 " ~ "  => Near

/-- Like `near_refl`, but leaving all arguments implicit. -/
theorem near_rfl : s ~ s := by
  sorry

/-- Nearness is transitive. -/
@[trans]
theorem near_trans (h₁ : s ~ t) (h₂ : t ~ u) : s ~ u := by
  sorry

instance {α : Type u} : Trans (Near : Set α → Set α → Prop) Near Near where
  trans := near_trans

/-- Symmetric differences can be cancelled when comparing sets for nearness. -/
theorem near_symmDiff_iff (u : Set α) : u ∆ s ~ u ∆ t ↔ s ~ t := by
  sorry

/-- If `α` is any type with cardinality bounded by `μ`, then the amount of sets near a given set `s`
is also bounded by `μ`. -/
theorem card_near_le (s : Set α) (h : #α ≤ #μ) : #{t | t ~ s} ≤ #μ := by
  sorry

end ConNF
