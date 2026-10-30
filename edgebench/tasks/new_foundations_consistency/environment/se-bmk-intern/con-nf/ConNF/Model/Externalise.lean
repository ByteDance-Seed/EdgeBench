import ConNF.Model.RunInduction

/-!
# Externalisation

In this file, we convert many of our *internal* results (i.e. inside the induction) to *external*
ones (i.e. defined using the global `TSet`/`AllPerm` definitions).

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal WithBot

namespace ConNF

variable [Params.{u}]

instance globalModelData : {α : TypeIndex} → ModelData α
  | (α : Λ) => (motive α).data
  | ⊥ => botModelData

instance globalPosition : {α : TypeIndex} → Position (Tangle α)
  | (α : Λ) => (motive α).pos
  | ⊥ => botPosition

instance globalTypedNearLitters {α : Λ} : TypedNearLitters α :=
  (motive α).typed

instance globalLtData [Level] : LtData where

instance globalLeData [Level] : LeData where

theorem globalLtData_eq [Level] :
    globalLtData = ltData (λ β _ ↦ motive β) := by
  sorry

theorem globalLeData_eq [Level] :
    globalLeData = leData (λ β _ ↦ motive β) := by
  sorry

instance globalPreCoherentData [Level] : PreCoherentData where
  allPermSderiv h := cast (by rw [globalLeData_eq])
    ((preCoherentData (λ β _ ↦ motive β) (λ β _ ↦ hypothesis β)).allPermSderiv h)
  singleton h := cast (by rw [globalLeData_eq])
    ((preCoherentData (λ β _ ↦ motive β) (λ β _ ↦ hypothesis β)).singleton h)

omit [Params] in
@[simp]
theorem heq_cast_eq_iff {α β γ : Type _} {x : α} {y : β} {h : α = γ} :
    HEq (cast h x) y ↔ HEq x y := by
  sorry

theorem globalPreCoherentData_eq [Level] :
    globalPreCoherentData = preCoherentData (λ β _ ↦ motive β) (λ β _ ↦ hypothesis β) := by
  sorry

instance globalCoherentData [Level] : CoherentData where
  allPermSderiv_forget := globalPreCoherentData_eq ▸ (coherentData _ _).allPermSderiv_forget
  pos_atom_lt_pos := globalPreCoherentData_eq ▸ (coherentData _ _).pos_atom_lt_pos
  pos_nearLitter_lt_pos := globalPreCoherentData_eq ▸ (coherentData _ _).pos_nearLitter_lt_pos
  smul_fuzz := globalPreCoherentData_eq ▸ (coherentData _ _).smul_fuzz
  allPerm_of_basePerm := globalPreCoherentData_eq ▸ (coherentData _ _).allPerm_of_basePerm
  allPerm_of_smulFuzz := globalPreCoherentData_eq ▸ (coherentData _ _).allPerm_of_smulFuzz
  tSet_ext := globalPreCoherentData_eq ▸ (coherentData _ _).tSet_ext
  typedMem_singleton_iff := globalPreCoherentData_eq ▸ (coherentData _ _).typedMem_singleton_iff

end ConNF
