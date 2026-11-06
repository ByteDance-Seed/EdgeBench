import ConNF.ModelData.CoherentData

/-!
# Codes

In this file, we define codes and clouds.

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level]

class TypedNearLitters (α : Λ) [ModelData α] [Position (Tangle α)] where
  typed : NearLitter → TSet α
  typed_injective : Function.Injective typed
  pos_le_pos_of_typed (N : NearLitter) (t : Tangle α) : t.set = typed N → pos N ≤ pos t
  smul_typed (ρ : AllPerm α) (N : NearLitter) : ρ • typed N = typed (ρᵁ ↘. • N)

export TypedNearLitters (typed)

@[ext]
class LtData where
  [data : (β : TypeIndex) → [LtLevel β] → ModelData β]
  [positions : (β : TypeIndex) → [LtLevel β] → Position (Tangle β)]
  [typedNearLitters : (β : Λ) → [LtLevel β] → TypedNearLitters β]

instance [LtData] : (β : TypeIndex) → [LtLevel β] → ModelData β :=
  LtData.data

instance [LtData] : (β : TypeIndex) → [LtLevel β] → Position (Tangle β) :=
  LtData.positions

instance [LtData] : (β : Λ) → [LtLevel β] → TypedNearLitters β :=
  LtData.typedNearLitters

variable [LtData]

structure Code : Type u where
  β : TypeIndex
  [hβ : LtLevel β]
  s : Set (TSet β)
  hs : s.Nonempty

instance (c : Code) : LtLevel c.β :=
  c.hβ

theorem cloud_aux (β : TypeIndex) [LtLevel β] (γ : Λ) [LtLevel γ] (hβγ : β ≠ γ)
    (s : Set (TSet β)) (hs : s.Nonempty) :
    (typed '' {N | ∃ t : Tangle β, t.set ∈ s ∧ Nᴸ = fuzz hβγ t} : Set (TSet γ)).Nonempty := by
  sorry

inductive Cloud : Rel Code Code
  | mk (β : TypeIndex) [LtLevel β] (γ : Λ) [LtLevel γ] (hβγ : β ≠ γ)
      (s : Set (TSet β)) (hs : s.Nonempty) :
      Cloud
        ⟨β, s, hs⟩
        ⟨γ, typed '' {N | ∃ t : Tangle β, t.set ∈ s ∧ Nᴸ = fuzz hβγ t}, cloud_aux β γ hβγ s hs⟩

def Code.positions (c : Code) : Set μ :=
  pos '' {t : Tangle c.β | t.set ∈ c.s}

theorem Code.positions_nonempty (c : Code) : c.positions.Nonempty := by
  sorry

def Code.pos (c : Code) : μ :=
  WellFounded.min (inferInstanceAs (WellFoundedLT μ)).wf
    c.positions c.positions_nonempty

mutual
  @[mk_iff]
  inductive Code.Even : Code → Prop
    | mk (c : Code) : (∀ d, Cloud d c → d.Odd) → c.Even

  @[mk_iff]
  inductive Code.Odd : Code → Prop
    | mk (c d : Code) : Cloud d c → d.Even → c.Odd
end

@[simp]
theorem not_even (c : Code) : ¬c.Even ↔ c.Odd := by
  sorry

@[simp]
theorem not_odd (c : Code) : ¬c.Odd ↔ c.Even := by
  sorry

inductive Represents : Rel Code Code
  | refl (c : Code) : c.Even → Represents c c
  | cloud (c d : Code) : c.Even → Cloud c d → Represents c d

theorem represents_cofunctional : Represents.Cofunctional := by
  sorry

def Code.members (c : Code) (β : TypeIndex) [LtLevel β] : Set (TSet β) :=
  {x | ∃ (s : Set (TSet β)) (hs : s.Nonempty), x ∈ s ∧ Represents c ⟨β, s, hs⟩}

theorem Code.ext {c d : Code} (hc : c.Even) (hd : d.Even) (β : Λ) [LtLevel β]
    (h : c.members β = d.members β) : c = d := by
  sorry

theorem Code.ext' {c d : Code} (hc : c.Even) (hd : d.Even)
    (h : ∀ (β : TypeIndex) [LtLevel β], c.members β = d.members β) :
    c = d := by
  sorry

end ConNF
