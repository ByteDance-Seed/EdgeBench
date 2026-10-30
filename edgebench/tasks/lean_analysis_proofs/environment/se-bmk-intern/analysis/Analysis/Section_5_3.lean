import Mathlib.Tactic
import Analysis.Section_5_2
import Mathlib.Algebra.Group.MinimalAxioms

/-!
# Analysis I, Section 5.3: The construction of the real numbers

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:

- Notion of a formal limit of a Cauchy sequence.
- Construction of a real number type `Chapter5.Real`.
- Basic arithmetic operations and properties.

## Tips from past users

Users of the companion who have completed the exercises in this section are welcome to send their tips for future users in this section as PRs.

- (Add tip here)

-/

namespace Chapter5

/-- A class of Cauchy sequences that start at zero. -/
@[ext]
class CauchySequence extends Sequence where
  zero : n₀ = 0
  cauchy : toSequence.IsCauchy

theorem CauchySequence.ext' {a b: CauchySequence} (h: a.seq = b.seq) : a = b := by
  sorry

/-- A sequence starting at zero that is Cauchy, can be viewed as a `CauchySequence`. -/
abbrev CauchySequence.mk' {a:ℕ → ℚ} (ha: (a:Sequence).IsCauchy) : CauchySequence where
  n₀ := 0
  seq := (a:Sequence).seq
  vanish := by aesop
  zero := rfl
  cauchy := ha

@[simp]
theorem CauchySequence.coe_eq {a:ℕ → ℚ} (ha: (a:Sequence).IsCauchy) :
    (mk' ha).toSequence = (a:Sequence) := by
  sorry

instance CauchySequence.instCoeFun : CoeFun CauchySequence (fun _ ↦ ℕ → ℚ) where
  coe a n := a.toSequence (n:ℤ)

@[simp]
theorem CauchySequence.coe_to_sequence (a: CauchySequence) :
    ((a:ℕ → ℚ):Sequence) = a.toSequence := by
  sorry

@[simp]
theorem CauchySequence.coe_coe {a:ℕ → ℚ} (ha: (a:Sequence).IsCauchy) : mk' ha = a := by
  sorry

/-- Proposition 5.3.3 / Exercise 5.3.1 -/
instance CauchySequence.instSetoid : Setoid CauchySequence where
  r := fun a b ↦ Sequence.Equiv a b
  iseqv := {
     refl := sorry
     symm := sorry
     trans := sorry
  }

/-- Every constant sequence is Cauchy. -/
theorem Sequence.IsCauchy.const (a:ℚ) : ((fun _:ℕ ↦ a):Sequence).IsCauchy := by
  sorry

instance CauchySequence.instZero : Zero CauchySequence where
  zero := CauchySequence.mk' (a := fun _: ℕ ↦ 0) (Sequence.IsCauchy.const (0:ℚ))

abbrev Real := Quotient CauchySequence.instSetoid

open Classical in
/--
  It is convenient in Lean to assign the "dummy" value of {lean}`0` to {lean}`LIM a` when {lean}`a` is not Cauchy.
  This requires classical logic, because the property of being Cauchy is not computable or
  decidable.
-/
noncomputable abbrev LIM (a:ℕ → ℚ) : Real :=
  Quotient.mk _ (if h : (a:Sequence).IsCauchy then CauchySequence.mk' h else (0:CauchySequence))

/-- Definition 5.3.1 (Real numbers) -/
theorem Real.LIM_eq_LIM {a b:ℕ → ℚ} (ha: (a:Sequence).IsCauchy) (hb: (b:Sequence).IsCauchy) :
  LIM a = LIM b ↔ Sequence.Equiv a b := by
  sorry

/--Lemma 5.3.6 (Sum of Cauchy sequences is Cauchy)-/
theorem Sequence.IsCauchy.add {a b:ℕ → ℚ}  (ha: (a:Sequence).IsCauchy) (hb: (b:Sequence).IsCauchy) :
    (a + b:Sequence).IsCauchy := by
  sorry

/--Lemma 5.3.7 (Sum of equivalent sequences is equivalent)-/
theorem Sequence.add_equiv {a b a' b':ℕ → ℚ} (haa': Equiv a a')
  (hbb': Equiv b b') :
    Equiv (a + b) (a' + b') := by
  sorry

/-- Definition 5.3.4 (Addition of reals) -/
noncomputable instance Real.add_inst : Add Real where
  add := fun x y ↦
    Quotient.liftOn₂ x y (fun a b ↦ LIM (a + b)) (by
      intro a b a' b' _ _
      change LIM ((a:ℕ → ℚ) + (b:ℕ → ℚ)) = LIM ((a':ℕ → ℚ) + (b':ℕ → ℚ))
      rw [LIM_eq_LIM]
      . solve_by_elim [Sequence.add_equiv]
      all_goals apply Sequence.IsCauchy.add <;> rw [CauchySequence.coe_to_sequence] <;> convert @CauchySequence.cauchy ?_
      )

/-- Definition 5.3.4 (Addition of reals) -/
theorem Real.LIM_add {a b:ℕ → ℚ} (ha: (a:Sequence).IsCauchy) (hb: (b:Sequence).IsCauchy) :
  LIM a + LIM b = LIM (a + b) := by
  sorry

/-- Proposition 5.3.10 (Product of Cauchy sequences is Cauchy) -/
theorem Sequence.IsCauchy.mul {a b:ℕ → ℚ}  (ha: (a:Sequence).IsCauchy) (hb: (b:Sequence).IsCauchy) :
    (a * b:Sequence).IsCauchy := by
  sorry

/--Proposition 5.3.10 (Product of equivalent sequences is equivalent) / Exercise 5.3.2 -/
theorem Sequence.mul_equiv
  {a b a' b':ℕ → ℚ}
  (ha : (a:Sequence).IsCauchy)
  (hb' : (b':Sequence).IsCauchy)
  (haa': Equiv a a')
  (hbb': Equiv b b') : Equiv (a * b) (a' * b') := by
  sorry

/-- Definition 5.3.9 (Product of reals) -/
noncomputable instance Real.mul_inst : Mul Real where
  mul := fun x y ↦
    Quotient.liftOn₂ x y (fun a b ↦ LIM (a * b)) (by
      intro a b a' b' haa' hbb'
      change LIM ((a:ℕ → ℚ) * (b:ℕ → ℚ)) = LIM ((a':ℕ → ℚ) * (b':ℕ → ℚ))
      rw [LIM_eq_LIM]
      . exact Sequence.mul_equiv (by rw [CauchySequence.coe_to_sequence]; exact a.cauchy) (by rw [CauchySequence.coe_to_sequence]; exact b'.cauchy) haa' hbb'
      all_goals apply Sequence.IsCauchy.mul <;> rw [CauchySequence.coe_to_sequence] <;> convert @CauchySequence.cauchy ?_
      )

instance Real.instRatCast : RatCast Real where
  ratCast := fun q ↦
    Quotient.mk _ (CauchySequence.mk' (a := fun _ ↦ q) (Sequence.IsCauchy.const q))

/-- Exercise 5.3.3 -/
@[simp]
theorem Real.ratCast_inj (q r:ℚ) : (q:Real) = (r:Real) ↔ q = r := by
  sorry

instance Real.instOfNat {n:ℕ} : OfNat Real n where
  ofNat := ((n:ℚ):Real)

instance Real.instNatCast : NatCast Real where
  natCast n := ((n:ℚ):Real)

@[simp]
theorem Real.LIM.zero : LIM (fun _ ↦ (0:ℚ)) = 0 := by
  sorry

instance Real.instIntCast : IntCast Real where
  intCast n := ((n:ℚ):Real)

/-- {name (full := RatCast.ratCast)}`ratCast` distributes over addition -/
theorem Real.ratCast_add (a b:ℚ) : (a:Real) + (b:Real) = (a+b:ℚ) := by
  sorry

/-- {name (full := RatCast.ratCast)}`ratCast` distributes over multiplication -/
theorem Real.ratCast_mul (a b:ℚ) : (a:Real) * (b:Real) = (a*b:ℚ) := by
  sorry

noncomputable instance Real.instNeg : Neg Real where
  neg x := ((-1:ℚ):Real) * x

/-- {name (full := RatCast.ratCast)}`ratCast` commutes with negation -/
theorem Real.neg_ratCast (a:ℚ) : -(a:Real) = (-a:ℚ) := by
  sorry

/-- It may be possible to omit the {name (full := Sequence.IsCauchy)}`IsCauchy` hypothesis here. -/
theorem Real.neg_LIM (a:ℕ → ℚ) (ha: (a:Sequence).IsCauchy) : -LIM a = LIM (-a) := by
  sorry

theorem Sequence.IsCauchy.neg (a:ℕ → ℚ) (ha: (a:Sequence).IsCauchy) :
    ((-a:ℕ → ℚ):Sequence).IsCauchy := by
  sorry

/-- Proposition 5.3.11 (laws of algebra) -/
noncomputable instance Real.addGroup_inst : AddGroup Real :=
  AddGroup.ofLeftAxioms (by sorry) (by sorry) (by sorry)

theorem Real.sub_eq_add_neg (x y:Real) : x - y = x + (-y) := by
  sorry

/-- `LIM` distributes over subtraction -/
theorem Real.LIM_sub {a b:ℕ → ℚ} (ha: (a:Sequence).IsCauchy) (hb: (b:Sequence).IsCauchy) :
  LIM a - LIM b = LIM (a - b) := by
  sorry

/-- {name (full := RatCast.ratCast)}`ratCast` distributes over subtraction -/
theorem Real.ratCast_sub (a b:ℚ) : (a:Real) - (b:Real) = (a-b:ℚ) := by
  sorry

/-- Proposition 5.3.11 (laws of algebra) -/
noncomputable instance Real.instAddCommGroup : AddCommGroup Real where
  add_comm := by sorry

/-- Proposition 5.3.11 (laws of algebra) -/
noncomputable instance Real.instCommMonoid : CommMonoid Real where
  mul_comm := by sorry
  mul_assoc := by sorry
  one_mul := by sorry
  mul_one := by sorry

/-- Proposition 5.3.11 (laws of algebra) -/
noncomputable instance Real.instCommRing : CommRing Real where
  left_distrib := by sorry
  right_distrib := by sorry
  zero_mul := by sorry
  mul_zero := by sorry
  mul_assoc := by sorry
  natCast_succ := by sorry
  intCast_negSucc := by sorry

abbrev Real.ratCast_hom : ℚ →+* Real where
  toFun := RatCast.ratCast
  map_zero' := by sorry
  map_one' := by sorry
  map_add' := by sorry
  map_mul' := by sorry

/--
  Definition 5.3.12 (sequences bounded away from zero). Sequences are indexed to start from zero
  as this is more convenient for Mathlib purposes.
-/
abbrev BoundedAwayZero (a:ℕ → ℚ) : Prop :=
  ∃ (c:ℚ), c > 0 ∧ ∀ n, |a n| ≥ c

/-- Examples 5.3.13 -/
example : BoundedAwayZero (fun n ↦ (-1)^n) := by
  sorry

/-- Examples 5.3.13 -/
example : ¬ BoundedAwayZero (fun n ↦ 10^(-(n:ℤ)-1)) := by
  sorry

/-- Examples 5.3.13 -/
example : ¬ BoundedAwayZero (fun n ↦ 1 - 10^(-(n:ℤ))) := by
  sorry

/-- Examples 5.3.13 -/
example : BoundedAwayZero (fun n ↦ 10^(n+1)) := by
  sorry

/-- Examples 5.3.13 -/
example : ¬ ((fun (n:ℕ) ↦ (10:ℚ)^(n+1)):Sequence).IsBounded := by
  sorry

/-- Lemma 5.3.14 -/
theorem Real.boundedAwayZero_of_nonzero {x:Real} (hx: x ≠ 0) :
    ∃ a:ℕ → ℚ, (a:Sequence).IsCauchy ∧ BoundedAwayZero a ∧ x = LIM a := by
  sorry

/-- Lemma 5.3.17 (Reciprocation is well-defined) -/
theorem Real.inv_of_equiv {a b:ℕ → ℚ} (ha: BoundedAwayZero a)
  (ha_cauchy: (a:Sequence).IsCauchy) (hb: BoundedAwayZero b)
  (hb_cauchy: (b:Sequence).IsCauchy) (hlim: LIM a = LIM b) :
    LIM a⁻¹ = LIM b⁻¹ := by
  sorry

open Classical in
/--
  Definition 5.3.16 (Reciprocation of real numbers).  Requires classical logic because we need to
  assign a "junk" value to the inverse of 0.
-/
noncomputable instance Real.instInv : Inv Real where
  inv x := if h: x ≠ 0 then LIM (boundedAwayZero_of_nonzero h).choose⁻¹ else 0

theorem Real.inv_def {a:ℕ → ℚ} (h: BoundedAwayZero a) (hc: (a:Sequence).IsCauchy) :
    (LIM a)⁻¹ = LIM a⁻¹ := by
  sorry

@[simp]
theorem Real.inv_zero : (0:Real)⁻¹ = 0 := by
  sorry

theorem Real.self_mul_inv {x:Real} (hx: x ≠ 0) : x * x⁻¹ = 1 := by
  sorry

theorem Real.inv_mul_self {x:Real} (hx: x ≠ 0) : x⁻¹ * x = 1 := by
  sorry

theorem Real.inv_ratCast (q:ℚ) : (q:Real)⁻¹ = (q⁻¹:ℚ) := by
  sorry

/-- Default definition of division. -/
noncomputable instance Real.instDivInvMonoid : DivInvMonoid Real where

theorem Real.div_eq (x y:Real) : x/y = x * y⁻¹ := by
  sorry

noncomputable instance Real.instField : Field Real where
  exists_pair_ne := by sorry
  mul_inv_cancel := by sorry
  inv_zero := by sorry
  ratCast_def := by sorry
  qsmul := _
  nnqsmul := _

theorem Real.mul_right_cancel₀ {x y z:Real} (hz: z ≠ 0) (h: x * z = y * z) : x = y := by
  sorry

theorem Real.mul_right_nocancel : ¬ ∀ (x y z:Real), (hz: z = 0) → (x * z = y * z) → x = y := by
  sorry

/-- Exercise 5.3.4 -/
theorem Real.IsBounded.equiv {a b:ℕ → ℚ} (ha: (a:Sequence).IsBounded) (hab: Sequence.Equiv a b) :
    (b:Sequence).IsBounded := by
  sorry

end Chapter5
