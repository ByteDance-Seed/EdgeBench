/-
Copyright (c) 2024 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Yaël Dillies
-/
module

public import Mathlib.Order.GameAdd
public import Mathlib.SetTheory.Ordinal.Arithmetic

/-!
# Interaction between successors and arithmetic

We define the `SuccAddOrder` and `PredSubOrder` typeclasses, for orders satisfying `succ x = x + 1`
and `pred x = x - 1` respectively. This allows us to transfer the API for successors and
predecessors into these common arithmetical forms.
-/

public section

/-- A typeclass expressing that the `0` of a type is a bottom element. In a partial `OrderBot`, this
is equivalent to `⊥ = 0`. -/
class IsBotZeroClass (α : Type*) [LE α] [Zero α] : Prop where
  isBot_zero : IsBot (0 : α)

instance (priority := 100) {α : Type*} [LE α] [Add α]
    [Zero α] [One α] [IsBotZeroClass α] : ZeroLEOneClass α where
  zero_le_one :=
    have : IsBot (0 : α) := IsBotZeroClass.isBot_zero
    le_of_le_of_eq (this 1) rfl

instance instIsBotZeroClass {α : Type*} [AddZeroClass α] [LE α]
    [CanonicallyOrderedAdd α] : IsBotZeroClass α where
  isBot_zero x := zero_le x

variable {α : Type*} {x y : α}

namespace Order

section PartialOrder

variable [PartialOrder α]

theorem one_le_iff_ne_zero [AddMonoidWithOne α] [NeZero (1 : α)]
    [SuccAddOrder α] [IsBotZeroClass α] [CanonicallyOrderedAdd α] : 1 ≤ x ↔ x ≠ 0 := by
  rw [Order.one_le_iff_pos, pos_iff_ne_zero]

end PartialOrder

section LinearOrder

variable [LinearOrder α]

section Add

variable [Add α] [One α] [SuccAddOrder α]

@[simp]
theorem add_one_inj [NoMaxOrder α] : x + 1 = y + 1 ↔ x = y := by
  simp [← succ_eq_add_one]

end Add

section AddMonoidWithOne
variable [AddMonoidWithOne α] [NoMaxOrder α] [SuccAddOrder α]

@[simp]
theorem lt_one_iff [CanonicallyOrderedAdd α] : x < 1 ↔ x = 0 := by
  rw [← zero_add 1, lt_add_one_iff, nonpos_iff_eq_zero]

theorem le_one_iff [CanonicallyOrderedAdd α] : x ≤ 1 ↔ x = 0 ∨ x = 1 := by
  rw [le_iff_lt_or_eq, lt_one_iff]

@[simp]
theorem Iio_one [CanonicallyOrderedAdd α] : Set.Iio (1 : α) = {0} := by
  ext; simp

theorem Iic_one [CanonicallyOrderedAdd α] : Set.Iic (1 : α) = {0, 1} := by
  ext; simp [le_one_iff]

@[simp]
theorem lt_two_iff : x < 2 ↔ x ≤ 1 := by
  rw [← one_add_one_eq_two, lt_add_one_iff]

theorem le_two_iff [CanonicallyOrderedAdd α] : x ≤ 2 ↔ x = 0 ∨ x = 1 ∨ x = 2 := by
  rw [le_iff_lt_or_eq, lt_two_iff, le_one_iff, or_assoc]

theorem Iio_two [CanonicallyOrderedAdd α] : Set.Iio (2 : α) = {0, 1} := by
  ext; simp [le_one_iff]

theorem Iic_two [CanonicallyOrderedAdd α] : Set.Iic (2 : α) = {0, 1, 2} := by
  ext; simp [le_two_iff]

end AddMonoidWithOne

end LinearOrder

end Order

@[simp]
theorem Ordinal.natCast_lt_omega0 (n : ℕ) : ↑n < Ordinal.omega0 :=
  Ordinal.lt_omega0.2 ⟨_, rfl⟩

variable {α β γ : Type*} {r : α → α → Prop} {s : β → β → Prop} {t : γ → γ → Prop}

theorem Ordinal.eq_natCast_of_le_natCast {a : Ordinal} {b : ℕ} (h : a ≤ ↑b) :
    ∃ (c : ℕ), a = ↑c := lt_omega0.1 (h.trans_lt (natCast_lt_omega0 b))

instance Set.isEmpty_Iio_zero {α : Type*} [PartialOrder α] [Zero α] [IsBotZeroClass α] :
    IsEmpty (Set.Iio (0 : α)) :=
  ⟨fun a ↦ by
    obtain ⟨val, property⟩ := a
    have := (IsBotZeroClass.isBot_zero (α := α)).lt_of_ne (b := val)
    simp only [mem_Iio] at property
    by_cases! ha : 0 = val
    · rw [← ha] at property
      absurd property
      exact Std.not_gt_of_lt property
    · specialize this ha
      absurd this
      exact Std.not_gt_of_lt property
    ⟩

@[expose] public section

variable {α β : Type*} {rα : α → α → Prop} {rβ : β → β → Prop} {a : α} {b : β}

/-! ### `Prod.GameAdd` -/
namespace Prod

/-- Recursion on the well-founded `Prod.GameAdd` relation.
  Note that it's strictly more general to recurse on the lexicographic order instead. -/
@[elab_as_elim]
def GameAdd.recursion {C : α → β → Sort*} (hα : WellFounded rα) (hβ : WellFounded rβ)
    (IH : ∀ a₁ b₁, (∀ a₂ b₂, GameAdd rα rβ (a₂, b₂) (a₁, b₁) → C a₂ b₂) → C a₁ b₁) (a : α) (b : β) :
    C a b :=
  @WellFounded.fix (α × β) (fun x => C x.1 x.2) _ (hα.prod_gameAdd hβ)
    (fun ⟨x₁, x₂⟩ IH' => IH x₁ x₂ fun a' b' => IH' ⟨a', b'⟩) ⟨a, b⟩

theorem GameAdd.recursion_eq {C : α → β → Sort*} (hα : WellFounded rα) (hβ : WellFounded rβ)
    (IH : ∀ a₁ b₁, (∀ a₂ b₂, GameAdd rα rβ (a₂, b₂) (a₁, b₁) → C a₂ b₂) → C a₁ b₁) (a : α) (b : β) :
    GameAdd.recursion hα hβ IH a b = IH a b fun a' b' _ => GameAdd.recursion hα hβ IH a' b' :=
  WellFounded.fix_eq _ _ _

end Prod

/-! ### `Sym2.GameAdd` -/
namespace Sym2

attribute [local instance] Sym2.Rel.setoid

/-- Recursion on the well-founded `Sym2.GameAdd` relation. -/
@[elab_as_elim]
def GameAdd.recursion {C : α → α → Sort*} (hr : WellFounded rα)
    (IH : ∀ a₁ b₁, (∀ a₂ b₂, Sym2.GameAdd rα s(a₂, b₂) s(a₁, b₁) → C a₂ b₂) → C a₁ b₁) (a b : α) :
    C a b :=
  @WellFounded.fix (α × α) (fun x => C x.1 x.2)
    (fun x y ↦ Prod.GameAdd rα rα x y ∨ Prod.GameAdd rα rα x.swap y)
    (by simpa [← Sym2.gameAdd_iff] using hr.sym2_gameAdd.onFun)
    (fun ⟨x₁, x₂⟩ IH' => IH x₁ x₂ fun a' b' => IH' ⟨a', b'⟩) (a, b)

theorem GameAdd.recursion_eq {C : α → α → Sort*} (hr : WellFounded rα)
    (IH : ∀ a₁ b₁, (∀ a₂ b₂, Sym2.GameAdd rα s(a₂, b₂) s(a₁, b₁) → C a₂ b₂) → C a₁ b₁) (a b : α) :
    GameAdd.recursion hr IH a b = IH a b fun a' b' _ => GameAdd.recursion hr IH a' b' :=
  WellFounded.fix_eq ..

end Sym2
