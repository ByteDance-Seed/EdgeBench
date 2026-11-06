/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.NatOrdinal.Basic

/-!
# Extra lemmas on WithTop
-/

universe u
open Set NatOrdinal WithTop

public section

instance {α : Type*} [PartialOrder α] [Add α] [One α] [SuccAddOrder α] [NoMaxOrder α]
    [∀ a : α, Decidable (Order.succ a = a)] : SuccAddOrder (WithTop α) where
  succ_eq_add_one := by
    rintro (x | x)
    · rfl
    · apply succ_coe.trans
      rw [Order.succ_eq_add_one]
      rfl

theorem WithTop.coe_add_one {α} [Add α] [One α] (x : α) : WithTop.some (x + 1) = x + 1 := by
  sorry

theorem small_of_image {α β} {f : α → β} {s : Set α} (hf : InjOn f s)
    [Small.{u} (f '' s)] : Small.{u} s := by
  sorry

theorem small_image_iff {α β} {f : α → β} {s : Set α} (hf : InjOn f s) :
    Small.{u} (f '' s) ↔ Small.{u} s := by
  sorry

-- TODO: PR these into Mathlib as lemmas on `Ordinal`.

namespace NatOrdinal

theorem withTop_iSup_coe_lt {ι} [Small.{u} ι] (f : ι → NatOrdinal.{u}) :
    ⨆ i, WithTop.some (f i) < ⊤ := by
  sorry

theorem withTop_sSup_coe_lt (s : Set NatOrdinal.{u}) [Small.{u} s] :
    sSup (WithTop.some '' s) < ⊤ := by
  sorry

theorem withTop_iSup_lt_top_iff_of_forall_lt {ι} {f : ι → WithTop NatOrdinal.{u}}
    (h : ∀ i, f i < ⊤) : ⨆ i, f i < ⊤ ↔ Small.{u} (range f) := by
  sorry

theorem withTop_sSup_lt_top_iff_of_forall_lt {s : Set (WithTop NatOrdinal.{u})}
    (h : ∀ x ∈ s, x < ⊤) : sSup s < ⊤ ↔ Small.{u} s := by
  sorry

@[simp]
theorem withTop_iSup_lt_top {ι} [Small.{u} ι] {f : ι → WithTop NatOrdinal.{u}} :
    ⨆ i, f i < ⊤ ↔ ∀ i, f i < ⊤ := by
  sorry

@[simp]
theorem withTop_sSup_lt_top {s : Set (WithTop NatOrdinal.{u})} [Small.{u} s] :
    sSup s < ⊤ ↔ ∀ x ∈ s, x < ⊤ := by
  sorry

end NatOrdinal
end
