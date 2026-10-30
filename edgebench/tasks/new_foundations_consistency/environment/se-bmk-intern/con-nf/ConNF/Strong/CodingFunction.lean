import ConNF.ModelData.CoherentData

/-!
# Coding functions

In this file, we define coding functions.

## Main declarations

* `ConNF.CodingFunction`: The type of coding functions.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData] {β : TypeIndex} [LeLevel β]

def Support.orbitRel : Rel (Support β) (Support β) :=
  λ S T ↦ ∃ ρ : AllPerm β, ρᵁ • S = T

theorem Support.orbitRel_isEquivalence :
    Equivalence (orbitRel (β := β)) := by
  sorry

instance Support.setoid (β : TypeIndex) [LeLevel β] : Setoid (Support β) where
  r := orbitRel
  iseqv := orbitRel_isEquivalence

def SupportOrbit (β : TypeIndex) [LeLevel β] : Type u :=
  Quotient (Support.setoid β)

def Support.orbit (S : Support β) : SupportOrbit β :=
  Quotient.mk (Support.setoid β) S

@[simp]
theorem Support.smul_orbit {S : Support β} {ρ : AllPerm β} :
    (ρᵁ • S).orbit = S.orbit := by
  sorry

structure CodingFunction (β : TypeIndex) [LeLevel β] where
  rel : Rel (Support β) (TSet β)
  rel_coinjective : rel.Coinjective
  rel_dom_nonempty : rel.dom.Nonempty
  supports_of_rel {S : Support β} {x : TSet β} : rel S x → S.Supports x
  orbit_eq_of_mem_dom {S T : Support β} : S ∈ rel.dom → T ∈ rel.dom → S.orbit = T.orbit
  smul_rel {S : Support β} {x : TSet β} (h : rel S x) (ρ : AllPerm β) : rel (ρᵁ • S) (ρ • x)

namespace CodingFunction

end CodingFunction

def Tangle.code (t : Tangle β) : CodingFunction β where
  rel S x := ∃ ρ : AllPerm β, ρᵁ • t.support = S ∧ ρ • t.set = x
  rel_coinjective := by
    constructor
    rintro x₁ x₂ S ⟨ρ₁, hρ₁, rfl⟩ ⟨ρ₂, rfl, rfl⟩
    exact t.support_supports.smul_eq_smul hρ₁
  rel_dom_nonempty := by
    refine ⟨t.support, t.set, 1, ?_⟩
    simp only [allPermForget_one, one_smul, and_self]
  supports_of_rel := by
    rintro _ _ ⟨ρ, rfl, rfl⟩
    exact t.support_supports.smul ρ
  orbit_eq_of_mem_dom := by
    rintro _ _ ⟨_, ρ₁, rfl, rfl⟩ ⟨_, ρ₂, rfl, rfl⟩
    simp only [Support.smul_orbit]
  smul_rel := by
    rintro _ _ ⟨ρ₁, rfl, rfl⟩ ρ₂
    use ρ₂ * ρ₁
    simp only [allPermForget_mul, mul_smul, and_self]

end ConNF
