import ConNF.External.Basic

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal ConNF.TSet
open scoped InitialSeg

namespace ConNF

variable [Params.{u}] {α β γ δ ε ζ : Λ} (hβ : (β : TypeIndex) < α) (hγ : (γ : TypeIndex) < β)
  (hδ : (δ : TypeIndex) < γ) (hε : (ε : TypeIndex) < δ) (hζ : (ζ : TypeIndex) < ε)

/-- A set in our model that is a well-order. Internal well-orders are exactly external well-orders,
so we externalise the definition for convenience. -/
def InternalWellOrder (r : TSet α) : Prop :=
  IsWellOrder (ExternalRel hβ hγ hδ r).field
    (InvImage (ExternalRel hβ hγ hδ r) Subtype.val)

def InternallyWellOrdered (x : TSet γ) : Prop :=
  {y : TSet δ | y ∈' x}.Subsingleton ∨ (∃ r, InternalWellOrder hβ hγ hδ r ∧ x = field hβ hγ hδ r)

@[simp]
theorem externalRel_smul (r : TSet α) (ρ : AllPerm α) :
    ExternalRel hβ hγ hδ (ρ • r) =
      InvImage (ExternalRel hβ hγ hδ r) ((ρ ↘ hβ ↘ hγ ↘ hδ)⁻¹ • ·) := by
  sorry

theorem exists_common_support_of_internallyWellOrdered' {x : TSet δ}
    (h : InternallyWellOrdered hγ hδ hε x) :
    ∃ S : Support β, ∀ y, y ∈' x → S.Supports { { {y}' }' }[hγ] := by
  sorry

include hγ in
theorem Support.Supports.ofSingleton {S : Support α} {x : TSet β}
    (h : S.Supports {x}') :
    letI : Level := ⟨α⟩
    letI : LeLevel α := ⟨le_rfl⟩
    (S.strong ↘ hβ).Supports x := by
  sorry

include hγ in
theorem supports_of_supports_singletons {S : Support α} {s : Set (TSet β)}
    (h : ∀ x ∈ s, S.Supports {x}') :
    ∃ S : Support β, ∀ x ∈ s, S.Supports x := by
  sorry

theorem exists_common_support_of_internallyWellOrdered {x : TSet δ}
    (h : InternallyWellOrdered hγ hδ hε x) :
    ∃ S : Support δ, ∀ y, y ∈' x → S.Supports {y}' := by
  sorry

theorem internallyWellOrdered_of_common_support_of_nontrivial {x : TSet γ}
    (hx : {y : TSet δ | y ∈' x}.Nontrivial)
    (S : Support δ) (hS : ∀ y : TSet δ, y ∈' x → S.Supports y) :
    InternallyWellOrdered hβ hγ hδ x := by
  sorry

theorem internallyWellOrdered_of_common_support {x : TSet γ}
    (S : Support δ) (hS : ∀ y : TSet δ, y ∈' x → S.Supports y) :
    InternallyWellOrdered hβ hγ hδ x := by
  sorry

theorem powerset_internallyWellOrdered {x : TSet δ} (h : InternallyWellOrdered hγ hδ hε x) :
    InternallyWellOrdered hβ hγ hδ (powerset hδ hε x) := by
  sorry

end ConNF
