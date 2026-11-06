import ConNF.Strong.CodingFunction

/-!
# Recoding

In this file, we show that all coding functions of level `β > γ` can be expressed in terms of a set
of a particular class of `γ`-coding functions, called *raised* coding functions.

## Main declarations

* `ConNF.exists_combination_raisedSingleton`: Each coding function at a level `β > γ` can be
  expressed in terms of a set of `γ`-coding functions and a `β`-support orbit.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData] {β γ : Λ} [LeLevel β] [LeLevel γ]
    (hγ : (γ : TypeIndex) < β)

def Combination (x : TSet β) (S : Support β) (χs : Set (CodingFunction β)) : Prop :=
  ∀ y : TSet γ, y ∈[hγ] x ↔ ∃ χ ∈ χs, ∃ T z, χ.rel T z ∧ S.Subsupport T ∧ y ∈[hγ] z

inductive RaisedRel (s : Set (CodingFunction β)) (o : SupportOrbit β) : Rel (Support β) (TSet β)
  | mk : (S : Support β) → S.orbit = o → (x : TSet β) → Combination hγ x S s → RaisedRel s o S x

theorem raisedRel_coinjective (s : Set (CodingFunction β)) (o : SupportOrbit β) :
    (RaisedRel hγ s o).Coinjective := by
  sorry

theorem raisedRel_dom_nonempty {s : Set (CodingFunction β)} {o : SupportOrbit β}
    (hso : ∀ S, S.orbit = o → ∃ x, Combination hγ x S s ∧ S.Supports x) :
    (RaisedRel hγ s o).dom.Nonempty := by
  sorry

theorem supports_of_raisedRel {s : Set (CodingFunction β)} {o : SupportOrbit β}
    (hso : ∀ S, S.orbit = o → ∃ x, Combination hγ x S s ∧ S.Supports x)
    {S : Support β} {x : TSet β} :
    RaisedRel hγ s o S x → S.Supports x := by
  sorry

theorem orbit_eq_of_mem_dom_raisedRel (s : Set (CodingFunction β)) (o : SupportOrbit β)
    {S : Support β} (hS : S ∈ (RaisedRel hγ s o).dom) :
    S.orbit = o := by
  sorry

theorem smul_raisedRel (s : Set (CodingFunction β)) (o : SupportOrbit β)
    {S : Support β} {x : TSet β} (h : RaisedRel hγ s o S x) (ρ : AllPerm β) :
    RaisedRel hγ s o (ρᵁ • S) (ρ • x) := by
  sorry

def raisedCodingFunction (s : Set (CodingFunction β)) (o : SupportOrbit β)
    (hso : ∀ S, S.orbit = o → ∃ x, Combination hγ x S s ∧ S.Supports x) : CodingFunction β where
  rel := RaisedRel hγ s o
  rel_coinjective := raisedRel_coinjective hγ s o
  rel_dom_nonempty := raisedRel_dom_nonempty hγ hso
  supports_of_rel := supports_of_raisedRel hγ hso
  orbit_eq_of_mem_dom hS hT := (orbit_eq_of_mem_dom_raisedRel hγ s o hS).trans
    (orbit_eq_of_mem_dom_raisedRel hγ s o hT).symm
  smul_rel := smul_raisedRel hγ s o

theorem raisedSingleton_supports (S : Support β) (y : TSet γ) :
    (S + (exists_support y).choose ↗ hγ).Supports (singleton hγ y) := by
  sorry

theorem raisedSingleton_aux (S : Support β) (y : TSet γ) :
    ((S + (exists_support y).choose ↗ hγ)).Supports (singleton hγ y) := by
  sorry

def raisedSingleton (S : Support β) (y : TSet γ) : CodingFunction β :=
  (Tangle.mk (singleton hγ y) (S + (exists_support y).choose ↗ hγ)
    (raisedSingleton_aux hγ S y)).code

theorem combination_raisedSingleton (x : TSet β) (S : Support β) (hxS : S.Supports x) :
    Combination hγ x S (raisedSingleton hγ S '' {y | y ∈[hγ] x}) := by
  sorry

def RaisedSingleton : Type u :=
  { χ : CodingFunction β // ∃ S : Support β, ∃ y : TSet γ, χ = raisedSingleton hγ S y }

theorem exists_combination_raisedSingleton (χ : CodingFunction β) :
    ∃ s : Set (RaisedSingleton hγ), ∃ o : SupportOrbit β,
    ∃ hso : ∀ S, S.orbit = o → ∃ x, Combination hγ x S (Subtype.val '' s) ∧ S.Supports x,
      χ = raisedCodingFunction hγ (Subtype.val '' s) o hso := by
  sorry

structure RaisedSingletonData (β γ : Λ) [LeLevel β] [LeLevel γ] : Type u where
  ba : κ
  bN : κ
  o : SupportOrbit β
  χ : CodingFunction γ

def RaisedSingletonData.mk' (S : Support β) (y : TSet γ) :
    RaisedSingletonData β γ where
  ba := Sᴬ.bound
  bN := Sᴺ.bound
  o := (S + ((exists_support y).choose) ↗ hγ).orbit
  χ := Tangle.code ⟨y, (exists_support y).choose, (exists_support y).choose_spec⟩

theorem RaisedSingletonData.mk'_eq_mk'
    {S₁ S₂ : Support β} {y₁ y₂ : TSet γ}
    (h : RaisedSingletonData.mk' hγ S₁ y₁ = RaisedSingletonData.mk' hγ S₂ y₂) :
    raisedSingleton hγ S₁ y₁ = raisedSingleton hγ S₂ y₂ := by
  sorry

theorem card_raisedSingleton_lt' :
    #(RaisedSingleton hγ) ≤ #(RaisedSingletonData β γ) := by
  sorry

def raisedSingletonDataEquiv (β γ : Λ) [LeLevel β] [LeLevel γ] :
    RaisedSingletonData β γ ≃ κ × κ × SupportOrbit β × CodingFunction γ where
  toFun d := ⟨d.ba, d.bN, d.o, d.χ⟩
  invFun d := ⟨d.1, d.2.1, d.2.2.1, d.2.2.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

theorem card_raisedSingleton_lt (h₁ : #(SupportOrbit β) < #μ)
    (h₂ : ∀ δ < (β : TypeIndex), [LeLevel δ] → #(CodingFunction δ) < #μ) :
    #(RaisedSingleton hγ) < #μ := by
  sorry

end ConNF
