import ConNF.Background.ReflTransGen
import ConNF.FOA.Inflexible

/-!
# Strong supports

In this file, we define strong supports.

## Main declarations

* `ConNF.Support.Strong`: The property that a support is strong.
-/

noncomputable section
universe u

open Cardinal Ordinal
open scoped symmDiff

namespace ConNF

variable [Params.{u}] {β : TypeIndex}

structure BaseSupport.Closed (S : BaseSupport) : Prop where
  interference_subset {N₁ N₂ : NearLitter} :
    N₁ ∈ Sᴺ → N₂ ∈ Sᴺ → ∀ a ∈ interference N₁ N₂, a ∈ Sᴬ

namespace Support

variable [Level] [CoherentData] [LeLevel β]

structure PreStrong (S : Support β) : Prop where
  support_le {A : β ↝ ⊥} {N : NearLitter} (h : N ∈ (S ⇘. A)ᴺ)
    (P : InflexiblePath β) (t : Tangle P.δ)
    (hA : A = P.A ↘ P.hε ↘.) (ht : Nᴸ = fuzz P.hδε t) :
    t.support ≤ S ⇘ (P.A ↘ P.hδ)

structure Closed (S : Support β) : Prop where
  closed : ∀ A, (S ⇘. A).Closed

structure Strong (S : Support β) : Prop extends PreStrong S, Closed S

theorem PreStrong.smul {S : Support β} (hS : S.PreStrong) (ρ : AllPerm β) : (ρᵁ • S).PreStrong := by
  sorry

theorem Strong.smul {S : Support β} (hS : S.Strong) (ρ : AllPerm β) : (ρᵁ • S).Strong := by
  sorry

omit [Level] [CoherentData] [LeLevel β] in
theorem Closed.scoderiv {γ : TypeIndex} {S : Support γ} (hS : S.Closed) (hγ : γ < β) :
    (S ↗ hγ).Closed := by
  sorry

def Constrains : Rel (β ↝ ⊥ × NearLitter) (β ↝ ⊥ × NearLitter) :=
  λ x y ↦ ∃ (P : InflexiblePath β) (t : Tangle P.δ) (B : P.δ ↝ ⊥),
    x.1 = P.A ↘ P.hδ ⇘ B ∧ x.2 ∈ (t.support ⇘. B)ᴺ ∧ y.1 = P.A ↘ P.hε ↘. ∧ y.2ᴸ = fuzz P.hδε t

theorem constrains_wf : WellFounded (Constrains (β := β)) := by
  sorry

theorem reflTransGen_constrains_small (s : Set (β ↝ ⊥ × NearLitter)) (hs : Small s) :
    Small {x | ∃ y ∈ s, Relation.ReflTransGen Constrains x y} := by
  sorry

/-- A support that contains all of the near-litters that transitively constrain something in `S`. -/
def constrainsNearLitters (S : Support β) : Support β :=
  ⟨.empty, .ofSet _ (reflTransGen_constrains_small Sᴺ Sᴺ.coe_small)⟩

theorem mem_constrainsNearLitters_nearLitters (S : Support β) (A : β ↝ ⊥) (N : NearLitter) :
    N ∈ (S.constrainsNearLitters ⇘. A)ᴺ ↔
    ∃ B N', N' ∈ (S ⇘. B)ᴺ ∧ Relation.ReflTransGen Constrains (A, N) (B, N') := by
  sorry

theorem constrainsNearLitters_atoms (S : Support β) (A : β ↝ ⊥) :
    (S.constrainsNearLitters ⇘. A)ᴬ = .empty := by
  sorry

-- TODO: Fix this in the blueprint

def ConstrainsAtom (S : Support β) (a : β ↝ ⊥ × Atom) : Prop :=
  ∃ (P : InflexiblePath β) (t : Tangle P.δ) (B : P.δ ↝ ⊥) (A : β ↝ ⊥) (N : NearLitter),
    a.1 = P.A ↘ P.hδ ⇘ B ∧ a.2 ∈ (t.support ⇘. B)ᴬ ∧
    A = P.A ↘ P.hε ↘. ∧ Nᴸ = fuzz P.hδε t ∧ N ∈ (S ⇘. A)ᴺ

theorem constrainsAtoms_small (S : Support β) :
    Small {a | ConstrainsAtom S a} := by
  sorry

/-- A support that contains all the atoms that constrain something in `S`. -/
def constrainsAtoms (S : Support β) : Support β :=
  ⟨.ofSet _ S.constrainsAtoms_small, .empty⟩

theorem constrainsAtoms_nearLitters (S : Support β) (A : β ↝ ⊥) :
    (S.constrainsAtoms ⇘. A)ᴺ = .empty := by
  sorry

def preStrong (S : Support β) : Support β :=
  (S + S.constrainsNearLitters) + (S + S.constrainsNearLitters).constrainsAtoms

theorem subsupport_preStrong (S : Support β) :
    S.Subsupport S.preStrong := by
  sorry

theorem preStrong_atoms (S : Support β) (A : β ↝ ⊥) :
    (S.preStrong ⇘. A)ᴬ = (S ⇘. A)ᴬ + ((S + S.constrainsNearLitters).constrainsAtoms ⇘. A)ᴬ := by
  sorry

theorem preStrong_nearLitters (S : Support β) (A : β ↝ ⊥) :
    (S.preStrong ⇘. A)ᴺ = (S ⇘. A)ᴺ + (S.constrainsNearLitters ⇘. A)ᴺ := by
  sorry

theorem preStrong_preStrong (S : Support β) : S.preStrong.PreStrong := by
  sorry

omit [Level] [CoherentData] [LeLevel β] in
theorem interference_small (S : Support β) :
    Small {a : β ↝ ⊥ × Atom |
      ∃ N₁ N₂, N₁ ∈ (S ⇘. a.1)ᴺ ∧ N₂ ∈ (S ⇘. a.1)ᴺ ∧ a.2 ∈ interference N₁ N₂} := by
  sorry

def interferenceSupport (S : Support β) : Support β :=
  ⟨.ofSet _ S.interference_small, .empty⟩

omit [Level] [CoherentData] [LeLevel β] in

omit [Level] [CoherentData] [LeLevel β] in

def close (S : Support β) : Support β :=
  S + S.interferenceSupport

omit [Level] [CoherentData] [LeLevel β] in

omit [Level] [CoherentData] [LeLevel β] in

omit [Level] [CoherentData] [LeLevel β] in

omit [Level] [CoherentData] [LeLevel β] in

def strong (S : Support β) : Support β :=
  S.preStrong.close

theorem preStrong_subsupport_strong (S : Support β) :
    S.preStrong.Subsupport S.strong := by
  sorry

theorem subsupport_strong (S : Support β) :
    S.Subsupport S.strong := by
  sorry

theorem strong_strong (S : Support β) :
    S.strong.Strong := by
  sorry

end Support
end ConNF
