import Mathlib.Data.Rel
import Mathlib.Data.Set.Lattice
import Mathlib.Order.Preorder.Chain

open Set
open scoped symmDiff

namespace Rel

variable {α β γ : Type _}

def field (r : Rel α α) : Set α :=
  r.dom ∪ r.codom

@[mk_iff]
structure Injective (r : Rel α β) : Prop where
  injective : ∀ ⦃x₁ x₂ y⦄, r x₁ y → r x₂ y → x₁ = x₂

@[mk_iff]
structure Coinjective (r : Rel α β) : Prop where
  coinjective : ∀ ⦃y₁ y₂ x⦄, r x y₁ → r x y₂ → y₁ = y₂

@[mk_iff]
structure Surjective (r : Rel α β) : Prop where
  surjective : ∀ y, ∃ x, r x y

@[mk_iff]
structure Cosurjective (r : Rel α β) : Prop where
  cosurjective : ∀ x, ∃ y, r x y

@[mk_iff]
structure Functional (r : Rel α β) : Prop extends Coinjective r, Cosurjective r

@[mk_iff]
structure Cofunctional (r : Rel α β) : Prop extends Injective r, Surjective r

@[mk_iff]
structure OneOne (r : Rel α β) : Prop extends Injective r, Coinjective r

@[mk_iff]
structure Bijective (r : Rel α β) : Prop extends Functional r, Cofunctional r

@[mk_iff]
structure CodomEqDom (r : Rel α α) : Prop where
  codom_eq_dom : r.codom = r.dom

@[mk_iff]
structure Permutative (r : Rel α α) : Prop extends OneOne r, CodomEqDom r

theorem CodomEqDom.dom_union_codom {r : Rel α α} (h : r.CodomEqDom) :
    r.dom ∪ r.codom = r.dom := by
  sorry

/-- An elementary description of the property `CodomEqDom`. -/
theorem codomEqDom_iff' (r : Rel α α) :
    r.CodomEqDom ↔ (∀ x y, r x y → ∃ z, r y z) ∧ (∀ x y, r x y → ∃ z, r z x) := by
  sorry

theorem OneOne.inv {r : Rel α β} (h : r.OneOne) : r.inv.OneOne := by
  sorry

@[simp]
theorem inv_apply {r : Rel α β} {x : α} {y : β} :
    r.inv y x ↔ r x y := by
  sorry

@[simp]
theorem inv_inj {r s : Rel α β} : r.inv = s.inv ↔ r = s := by
  sorry

@[simp]
theorem inv_injective_iff {r : Rel α β} :
    r.inv.Injective ↔ r.Coinjective := by
  sorry

@[simp]
theorem inv_coinjective_iff {r : Rel α β} :
    r.inv.Coinjective ↔ r.Injective := by
  sorry

@[simp]
theorem inv_surjective_iff {r : Rel α β} :
    r.inv.Surjective ↔ r.Cosurjective := by
  sorry

@[simp]
theorem inv_cosurjective_iff {r : Rel α β} :
    r.inv.Cosurjective ↔ r.Surjective := by
  sorry

@[simp]
theorem inv_functional_iff {r : Rel α β} :
    r.inv.Functional ↔ r.Cofunctional := by
  sorry

@[simp]
theorem inv_cofunctional_iff {r : Rel α β} :
    r.inv.Cofunctional ↔ r.Functional := by
  sorry

@[simp]
theorem inv_preimage {r : Rel α β} {s : Set α} :
    r.inv.preimage s = r.image s := by
  sorry

theorem Permutative.inv {r : Rel α α} (h : r.Permutative) : r.inv.Permutative := by
  sorry

theorem Permutative.inv_dom {r : Rel α α} (h : r.Permutative) : r.inv.dom = r.dom := by
  sorry

theorem Coinjective.comp {r : Rel α β} {s : Rel β γ} (hr : r.Coinjective) (hs : s.Coinjective) :
    (r.comp s).Coinjective := by
  sorry

theorem OneOne.mono {r s : Rel α β} (hs : s.OneOne) (h : r ≤ s) :
    r.OneOne := by
  sorry

/-- An alternative spelling of `Rel.graph` that is useful for proving inequalities of cardinals. -/
def graph' (r : Rel α β) : Set (α × β) :=
  r.uncurry

theorem graph'_subset_iff {r s : Rel α β} :
    r.graph' ⊆ s.graph' ↔ r ≤ s := by
  sorry

theorem graph'_injective :
    Function.Injective (Rel.graph' : Rel α β → Set (α × β)) := by
  sorry

@[simp]
theorem preimage_codom {r : Rel α β} :
    r.preimage r.codom = r.dom := by
  sorry

theorem sup_apply {r s : Rel α β} {x : α} {y : β} :
    (r ⊔ s) x y ↔ r x y ∨ s x y := by
  sorry

@[simp]
theorem sup_dom {r s : Rel α β} :
    (r ⊔ s).dom = r.dom ∪ s.dom := by
  sorry

@[simp]
theorem sup_codom {r s : Rel α β} :
    (r ⊔ s).codom = r.codom ∪ s.codom := by
  sorry

theorem sup_oneOne {r s : Rel α β} (hr : r.OneOne) (hs : s.OneOne)
    (h₁ : Disjoint r.dom s.dom) (h₂ : Disjoint r.codom s.codom) : (r ⊔ s).OneOne := by
  sorry

theorem sup_permutative {r s : Rel α α} (hr : r.Permutative) (hs : s.Permutative)
    (h : Disjoint r.dom s.dom) : (r ⊔ s).Permutative := by
  sorry

@[simp]
theorem inf_inv {r s : Rel α β} :
    (r ⊓ s).inv = r.inv ⊓ s.inv := by
  sorry

theorem inf_apply {r s : Rel α β} {x : α} {y : β} :
    (r ⊓ s) x y ↔ r x y ∧ s x y := by
  sorry

theorem inf_codom {r s : Rel α β} :
    (r ⊓ s).codom ⊆ r.codom ∩ s.codom := by
  sorry

@[simp]
theorem inv_le_inv_iff {r s : Rel α β} :
    r.inv ≤ s.inv ↔ r ≤ s := by
  sorry

@[simp]
theorem iSup_apply_iff {T : Type _} {r : T → Rel α β} (x : α) (y : β) :
    (⨆ t, r t) x y ↔ ∃ t, r t x y := by
  sorry

@[simp]
theorem biSup_apply_iff {T : Type _} {r : T → Rel α β} {s : Set T} (x : α) (y : β) :
    (⨆ t ∈ s, r t) x y ↔ ∃ t ∈ s, r t x y := by
  sorry

theorem biSup_permutative_of_isChain {T : Type _} {r : T → Rel α α} {s : Set T}
    (h₁ : ∀ t ∈ s, (r t).Permutative) (h₂ : IsChain (· ≤ ·) (r '' s)) :
    (⨆ t ∈ s, r t).Permutative := by
  sorry

noncomputable def toFunction (r : Rel α β) (hr : r.Functional) : α → β :=
  λ a ↦ (hr.cosurjective a).choose

theorem toFunction_rel (r : Rel α β) (hr : r.Functional) (a : α) :
    r a (r.toFunction hr a) := by
  sorry

theorem toFunction_eq_iff (r : Rel α β) (hr : r.Functional) (a : α) (b : β) :
    r.toFunction hr a = b ↔ r a b := by
  sorry

noncomputable def toEquiv (r : Rel α β) (hr : r.Bijective) : α ≃ β where
  toFun := r.toFunction hr.toFunctional
  invFun := r.inv.toFunction (inv_functional_iff.mpr hr.toCofunctional)
  left_inv a := by
    rw [toFunction_eq_iff]
    exact toFunction_rel r _ a
  right_inv b := by
    rw [toFunction_eq_iff]
    exact toFunction_rel r.inv _ b

end Rel
