import ConNF.Background.WellOrder
import Mathlib.SetTheory.Cardinal.Aleph
import Mathlib.SetTheory.Cardinal.Arithmetic

noncomputable section
universe u v

open Cardinal
open scoped InitialSeg

namespace Ordinal

def withBotOrderIso {α : Type u} [Preorder α] [IsWellOrder α (· < ·)] :
    ((· < ·) : WithBot α → WithBot α → Prop) ≃r
      Sum.Lex (EmptyRelation (α := PUnit)) ((· < ·) : α → α → Prop) where
  toFun := WithBot.recBotCoe (Sum.inl PUnit.unit) Sum.inr
  invFun := Sum.elim (λ _ ↦ ⊥) (λ x ↦ x)
  left_inv x := by cases x <;> rfl
  right_inv x := by cases x <;> rfl
  map_rel_iff' {x y} := by cases x <;> cases y <;>
    simp only [Equiv.coe_fn_mk, WithBot.recBotCoe_bot, WithBot.recBotCoe_coe,
    WithBot.coe_lt_coe, WithBot.bot_lt_coe, empty_relation_apply, lt_self_iff_false, not_lt_bot,
    Sum.lex_inl_inl, Sum.lex_inr_inl, Sum.lex_inr_inr, Sum.Lex.sep]

theorem noMaxOrder_of_isLimit {α : Type u} [Preorder α] [IsWellOrder α (· < ·)]
    (h : (type ((· < ·) : α → α → Prop)).IsLimit) : NoMaxOrder α := by
  sorry

def iicOrderIso {α : Type u} [LtWellOrder α] (x : α) :
    (Subrel ((· < ·) : α → α → Prop) (Set.Iic x)) ≃r
      Sum.Lex (Subrel ((· < ·) : α → α → Prop) (Set.Iio x)) (EmptyRelation (α := PUnit)) where
  toFun y := if h : y = x then Sum.inr PUnit.unit else Sum.inl ⟨y, y.prop.lt_of_ne h⟩
  invFun := Sum.elim (λ y ↦ ⟨y, y.prop.le⟩) (λ _ ↦ ⟨x, le_rfl⟩)
  left_inv y := by aesop
  right_inv y := by
    obtain (y | y) := y
    · simp only [Sum.elim_inl, Subtype.coe_eta, dite_eq_ite, ite_eq_right_iff, reduceCtorEq,
        imp_false]
      exact y.prop.ne
    · simp only [Sum.elim_inr, ↓reduceDIte]
  map_rel_iff' {y z} := by
    simp only [Equiv.coe_fn_mk, subrel_val, Subtype.coe_lt_coe]
    split_ifs with h h' h'
    · rw [Sum.lex_inr_inr, empty_relation_apply, false_iff, not_lt,
        Subtype.coe_injective (h.trans h'.symm)]
    · simp only [Sum.lex_inr_inl, false_iff, not_lt, ← Subtype.coe_le_coe, h]
      exact z.prop
    · simp only [Sum.Lex.sep, true_iff]
      rw [← Subtype.coe_lt_coe]
      exact lt_of_le_of_ne (y.prop.trans_eq h'.symm) (h'.trans_ne (Ne.symm h)).symm
    · simp only [Sum.lex_inl_inl, subrel_val, Subtype.coe_lt_coe]

/-!
## Lifting ordinals
-/

instance ULift.isTrichotomous {α : Type u} {r : α → α → Prop} [IsTrichotomous α r] :
    IsTrichotomous (ULift.{v} α) (InvImage r ULift.down) := by
  constructor
  rintro ⟨a⟩ ⟨b⟩
  simp only [ULift.up_inj, InvImage]
  exact IsTrichotomous.trichotomous a b

instance ULift.isTrans {α : Type u} {r : α → α → Prop} [IsTrans α r] :
    IsTrans (ULift.{v} α) (InvImage r ULift.down) := by
  constructor
  rintro ⟨a⟩ ⟨b⟩ ⟨c⟩
  simp only [InvImage]
  exact IsTrans.trans a b c

instance ULift.isWellOrder {α : Type u} {r : α → α → Prop} [IsWellOrder α r] :
    IsWellOrder (ULift.{v} α) (InvImage r ULift.down) :=
  ⟨⟩

/-!
## The additive structure on the set of ordinals below a cardinal
-/

theorem card_Iio (o : Ordinal.{u}) : #(Set.Iio o) = Cardinal.lift.{u + 1} o.card := by
  sorry

instance {o : Ordinal.{u}} : LtWellOrder (Set.Iio o) where

variable {c : Cardinal.{u}} (h : ℵ₀ ≤ c)

theorem add_lt_ord (h : ℵ₀ ≤ c) {x y : Ordinal.{u}}
    (hx : x < c.ord) (hy : y < c.ord) : x + y < c.ord := by
  sorry

def iioAdd : Add (Set.Iio c.ord) where
  add x y := ⟨x + y, add_lt_ord h x.prop y.prop⟩

def iioSub (o : Ordinal) : Sub (Set.Iio o) where
  sub x y := ⟨x - y, (sub_le_self x y).trans_lt x.prop⟩

theorem ord_pos (h : ℵ₀ ≤ c) : 0 < c.ord := by
  sorry

def iioZero : Zero (Set.Iio c.ord) where
  zero := ⟨0, ord_pos h⟩

@[simp]
theorem iioAdd_def (x y : Set.Iio c.ord) :
    letI := iioAdd h
    ((x + y : Set.Iio c.ord) : Ordinal) = x + y := by
  sorry

def iioAddMonoid : AddMonoid (Set.Iio c.ord) where
  add_assoc x y z := by
    apply Subtype.val_injective
    rw [iioAdd_def, iioAdd_def, add_assoc]
    rfl
  zero_add x := by
    apply Subtype.val_injective
    rw [iioAdd_def]
    exact zero_add x.val
  add_zero x := by
    apply Subtype.val_injective
    rw [iioAdd_def]
    exact add_zero x.val
  nsmul := nsmulRec
  __ := iioAdd h
  __ := iioZero h

theorem nat_lt_ord (h : ℵ₀ ≤ c) (n : ℕ) : n < c.ord := by
  sorry

def iioOfNat (n : ℕ) : OfNat (Set.Iio c.ord) n where
  ofNat := ⟨n, nat_lt_ord h n⟩

theorem iio_noMaxOrder (h : ℵ₀ ≤ c) : NoMaxOrder (Set.Iio c.ord) := by
  sorry

end Ordinal
