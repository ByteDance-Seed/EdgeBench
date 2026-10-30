import Mathlib.Tactic

/-! Some finite probability theory -/

namespace ProbabilityTheory

class FinitelyAdditive (A:Type*) [BooleanAlgebra A] where
  prob : A → ℝ
  prob_top : prob ⊤ = 1
  prob_nonneg (E:A) : 0 ≤ prob E
  prob_disj_sup {E F:A} (hEF: Disjoint E F) : prob (E ⊔ F) = prob E + prob F

namespace FinitelyAdditive

instance instFunLike (A:Type*) [BooleanAlgebra A] : FunLike (FinitelyAdditive A) A ℝ where
  coe ℙ := ℙ.prob
  coe_injective' f g h := by { cases f; cases g; congr }

variable {A:Type*} [BooleanAlgebra A] (ℙ: FinitelyAdditive A)
         {A':Type*} [BooleanAlgebra A'] (ℙ': FinitelyAdditive A')

@[simp]
theorem bot : ℙ ⊥ = 0 := by
  sorry

theorem le_one (E:A) : ℙ E ≤ 1 := by
  sorry

theorem mono {E F:A} (hEF: E ≤ F) : ℙ E ≤ ℙ F := by
  sorry

theorem sup_le_add (E F:A) : ℙ (E ⊔ F) ≤ ℙ E + ℙ F := by
  sorry

-- Some API for extending a finitely additive probability space

def _root_.BoundedLatticeHom.preserves (f: BoundedLatticeHom A A') : Prop := ∀ E:A, ℙ' (f E) = ℙ E

@[simp]
theorem _root_.BoundedLatticeHom.preserves.map {f: BoundedLatticeHom A A'} (hf: f.preserves ℙ ℙ') (E:A) : ℙ' (f E) = ℙ E := by
  sorry

-- an example of how a probability space can be extended while preserving various properties

class ExampleProb {A:Type*} [BooleanAlgebra A] (ℙ: FinitelyAdditive A) where
  E : A
  F : A
  G : A
  prob_E : ℙ E = 0.5
  prob_EF : ℙ (E ⊔ F) = 0.75
  prob_EF' : ℙ (E ⊓ F) = 0.25
  prob_EG : ℙ (E \ G) = 0.4
  prob_G : ℙ Gᶜ = 0.3

def ExampleProb.map {Ω: ExampleProb ℙ} {f: BoundedLatticeHom A A'} (hf: f.preserves ℙ ℙ') : ExampleProb ℙ' where
  E := f Ω.E
  F := f Ω.F
  G := f Ω.G
  prob_E := by simp [hf, Ω.prob_E]
  prob_EF := by simp [hf, Ω.prob_EF, ←map_sup]
  prob_EF' := by simp [hf, Ω.prob_EF', ←map_inf]
  prob_EG := by simp [hf, Ω.prob_EG, ←map_sdiff']
  prob_G := by simp [hf, Ω.prob_G, ←map_compl']

end FinitelyAdditive
end ProbabilityTheory
