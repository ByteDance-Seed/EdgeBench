import Mathlib.Order.RelClasses
import Mathlib.Data.Part

/-!
# The inductive construction theorem
-/

universe u v w

variable {I : Type u} {r : I → I → Prop} [IsTrans I r] [inst : IsWellFounded I r]
  {α : I → Type v} {p : ∀ i, α i → (∀ j, r j i → α j) → Prop}
  (f : ∀ i, ∀ d : (∀ j, r j i → α j),
    (∀ j, ∀ h : r j i, p j (d j h) (λ k h' ↦ d k (Trans.trans h' h))) →
    α i)
  (hp : ∀ i d h, p i (f i d h) d)

namespace ICT

structure IndHyp (i : I) (t : ∀ j, r j i → Part (α j)) : Prop where
  dom : ∀ j, ∀ h : r j i, (t j h).Dom
  prop : ∀ j, ∀ h : r j i, p j ((t j h).get (dom j h))
    (λ k h' ↦ (t k (Trans.trans h' h)).get (dom k _))

def core : ∀ i, Part (α i) :=
  inst.fix _ λ i t ↦ {
    Dom := IndHyp i t
    get := λ h ↦ f i (λ j h' ↦ (t j h').get (h.dom j h')) h.prop
  }

theorem core_dom (hp : ∀ i d h, p i (f i d h) d) : ∀ i, (core f i).Dom := by
  sorry

def fix' (i : I) : α i :=
  (core f i).get (core_dom f hp i)

theorem fix'_prop (i : I) :
    p i (fix' f hp i) (λ j _ ↦ fix' f hp j) := by
  sorry

variable {I : Type u} {r : I → I → Prop} [IsTrans I r] [inst : IsWellFounded I r]
  {α : I → Type v} {p : ∀ i, α i → (∀ j, r j i → α j) → Sort w}
  (f : ∀ i, ∀ d : (∀ j, r j i → α j),
    (∀ j, ∀ h : r j i, p j (d j h) (λ k h' ↦ d k (Trans.trans h' h))) →
    α i)
  (hp : ∀ i d h, p i (f i d h) d)

noncomputable def fix : ∀ i, α i :=
  fix' (r := r) (p := λ i h t ↦ Nonempty (p i h t))
    (λ i d h ↦ f i d (λ j h' ↦ (h j h').some))
    (λ i d h ↦ ⟨hp i d (λ j h' ↦ (h j h').some)⟩)

noncomputable def fix_prop (i : I) :
    p i (fix f hp i) (λ j _ ↦ fix f hp j) :=
  (fix'_prop (p := λ i h t ↦ Nonempty (p i h t)) _ _ i).some

end ICT
