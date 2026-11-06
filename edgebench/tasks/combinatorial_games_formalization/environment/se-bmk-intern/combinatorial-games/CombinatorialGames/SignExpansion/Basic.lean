/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu, Violeta Hernández Palacios
-/
module

public import CombinatorialGames.NatOrdinal.Basic
public import Mathlib.Algebra.Group.Pointwise.Set.Basic
public import Mathlib.Data.Fintype.Order
public import Mathlib.Data.Sign.Defs
public import Mathlib.Order.CompleteLattice.PiLex

/-!
# Sign expansions

In this repository we define the type of `Surreal` numbers following Conway's theory of games. A
popular alternative is to instead define the surreals as potentially infinite "expansions of signs",
setting for instance `+ = 1`, `- = -1`, `+- = ½`, etc.

This file defines the type `SignExpansion` and constructs its basic instances. We do not yet link it
to the development of surreal numbers.
-/

universe u

@[expose] public section

/-! ### For Mathlib -/

attribute [grind =] Pi.toLex_apply

instance : ZeroLEOneClass SignType where
  zero_le_one := by decide

@[local simp← ]
theorem Set.preimage_neg {α ι : Type*} [InvolutiveNeg α] (f : ι → α) {s : Set α} :
    f ⁻¹' (-s) = (-f) ⁻¹' s := by
  sorry

@[simp]
theorem Pi.Lex.neg_apply {α β : Type*} [Neg β] (x : Lex (α → β)) (i : α) : (-x) i = -x i := by
  sorry

-- TODO: we're missing an `AntitoneNeg` typeclass to express the following theorems generally.

theorem Pi.Lex.neg_lt_neg {α : Type*} [LinearOrder α] {x y : Lex (α → SignType)} (h : x < y) :
    -y < -x := by
  sorry

@[simp]
theorem Pi.Lex.neg_lt_neg_iff {α : Type*} [LinearOrder α] {x y : Lex (α → SignType)} :
    -x < -y ↔ y < x := by
  sorry

@[simp]
theorem Pi.Lex.neg_le_neg_iff {α : Type*} [LinearOrder α] [WellFoundedLT α]
    {x y : Lex (α → SignType)} : -x ≤ -y ↔ y ≤ x := by
  sorry

theorem Pi.Lex.neg_lt_iff {α : Type*} [LinearOrder α] {x y : Lex (α → SignType)} :
    -x < y ↔ -y < x := by
  sorry

theorem Pi.Lex.lt_neg_iff {α : Type*} [LinearOrder α] {x y : Lex (α → SignType)} :
    x < -y ↔ y < -x := by
  sorry

theorem Pi.Lex.neg_le_iff {α : Type*} [LinearOrder α] [WellFoundedLT α]
    {x y : Lex (α → SignType)} : -x ≤ y ↔ -y ≤ x := by
  sorry

theorem Pi.Lex.le_neg_iff {α : Type*} [LinearOrder α] [WellFoundedLT α]
    {x y : Lex (α → SignType)} : x ≤ -y ↔ y ≤ -x := by
  sorry

/-! ### Sign expansions -/

noncomputable section

/-- A sign expansion is a an ordinal indexed sequence of `1`s and `-1`s, followed by `0`s. -/
structure SignExpansion : Type (u + 1) where
  /-- The sequence defining the sign expansion. -/
  sign : NatOrdinal.{u} → SignType
  /-- Every sign after the first `0` is also `0`.

  Do not use directly, use `isUpperSet_preimage_singleton_zero` instead. -/
  isUpperSet_preimage_singleton_zero' : IsUpperSet (sign ⁻¹' {0})

namespace SignExpansion
open Order

instance : FunLike SignExpansion NatOrdinal SignType where
  coe := sign
  coe_injective' a b hab := by cases a; cases b; cases hab; rfl

/-- Every sign after the first `0` is also `0`. -/
theorem isUpperSet_preimage_singleton_zero (x : SignExpansion) : IsUpperSet (x ⁻¹' {0}) := by
  sorry

/-- Adjust definitional equalities of a sign expansion. -/
def copy (x : SignExpansion) (sign : NatOrdinal → SignType)
    (h : sign = x) : SignExpansion where
  sign
  isUpperSet_preimage_singleton_zero' := h ▸ isUpperSet_preimage_singleton_zero x

@[simp]
theorem copy_eq (x : SignExpansion) (sign : NatOrdinal → SignType)
    (h : sign = x) : x.copy sign h = x := by
  sorry

@[simp] theorem coe_mk (f h) : mk f h = f := by
  sorry
@[simp] theorem sign_eq_coe (x : SignExpansion) : x.sign = ⇑x := by
  sorry

@[ext]
protected theorem ext {x y : SignExpansion} (hxy : ∀ o, x o = y o) : x = y := by
  sorry

theorem mk_eq_mk {f g h₁ h₂} : mk f h₁ = mk g h₂ ↔ f = g := by
  sorry

theorem apply_eq_zero_of_le {x : SignExpansion} {o o' : NatOrdinal}
    (hoo' : o ≤ o') (ho : x o = 0) : x o' = 0 := by
  sorry

/-- The length of a sign expansion is the smallest ordinal at which it equals zero,
or `⊤` is no such ordinal exists. -/
@[no_expose]
def length (x : SignExpansion) : WithTop NatOrdinal :=
  sInf ((↑) '' (x ⁻¹' {0}))

theorem apply_of_length_le {x : SignExpansion} {o : NatOrdinal} (h : x.length ≤ o) : x o = 0 := by
  sorry

theorem apply_eq_zero {x : SignExpansion} {o : NatOrdinal} : x o = 0 ↔ x.length ≤ o := by
  sorry

theorem length_eq_top {x : SignExpansion} : x.length = ⊤ ↔ ∀ o, x o ≠ 0 := by
  sorry

/-! ### Basic sign expansions -/

/-- The constant sign expansion `sss...` -/
def const (s : SignType) : SignExpansion where
  sign _ := s
  isUpperSet_preimage_singleton_zero' := by aesop

instance : Zero SignExpansion where
  zero := const 0

@[simp] theorem coe_zero : ⇑(0 : SignExpansion) = 0 := by
  sorry
theorem zero_apply (o : NatOrdinal) : (0 : SignExpansion) o = 0 := by
  sorry

@[simp]
theorem length_zero : length 0 = 0 := by
  sorry

instance : Bot SignExpansion where
  bot := const (-1)

@[simp] theorem coe_bot : ⇑(⊥ : SignExpansion) = -1 := by
  sorry
theorem bot_apply (o : NatOrdinal) : (⊥ : SignExpansion) o = -1 := by
  sorry

@[simp]
theorem length_bot : length ⊥ = ⊤ := by
  sorry

instance : Top SignExpansion where
  top := const 1

@[simp] theorem coe_top : ⇑(⊤ : SignExpansion) = 1 := by
  sorry
theorem top_apply (o : NatOrdinal) : (⊤ : SignExpansion) o = 1 := by
  sorry

@[simp]
theorem length_top : length ⊤ = ⊤ := by
  sorry

instance : Neg SignExpansion where
  neg e := ⟨-e, by simpa using e.2⟩

@[simp] theorem coe_neg (x : SignExpansion) : ⇑(-x : SignExpansion) = -⇑x := by
  sorry
theorem neg_apply (x : SignExpansion) (o : NatOrdinal) : (-x) o = -x o := by
  sorry
@[simp] theorem neg_mk (f h) : -mk f h = mk (-f) (by simpa) := by
  sorry

@[simp] theorem neg_zero : -(0 : SignExpansion) = 0 := by
  sorry
@[simp] theorem neg_bot : -(⊥ : SignExpansion) = ⊤ := by
  sorry
@[simp] theorem neg_top : -(⊤ : SignExpansion) = ⊥ := by
  sorry

instance : InvolutiveNeg SignExpansion where
  neg_neg x := by ext; simp

-- TODO: why is this needed all of a sudden?
instance : DecidableLT (WithTop NatOrdinal) :=
  Classical.decRel _

/-- Cut off the part of a sign expansion after an ordinal `o`, by filling it in with zeros. -/
def restrict (x : SignExpansion) (o : WithTop NatOrdinal) : SignExpansion where
  sign i := if i < o then x i else 0
  isUpperSet_preimage_singleton_zero' a b hab ha := by
    rw [← WithTop.coe_le_coe] at hab
    simp only [Set.mem_preimage, Set.mem_singleton_iff, ite_eq_right_iff, apply_eq_zero] at ha ⊢
    exact fun hb ↦ (ha (hab.trans_lt hb)).trans hab

@[inherit_doc] scoped notation x:70 " ↾ " o:70 => restrict x o
recommended_spelling "restrict" for "↾" in [«term_↾_»]

@[aesop simp]
theorem coe_restrict (x : SignExpansion) (o : WithTop NatOrdinal) :
    ⇑(x ↾ o) = fun i : NatOrdinal ↦ if i < o then x i else 0 := by
  sorry

@[simp]
theorem neg_restrict (x : SignExpansion) (o : WithTop NatOrdinal) : -x ↾ o = (-x) ↾ o := by
  sorry

theorem restrict_apply_of_coe_lt {x : SignExpansion} {o₁ : WithTop NatOrdinal}
    {o₂ : NatOrdinal} (h : o₂ < o₁) : (x ↾ o₁) o₂ = x o₂ := by
  sorry

theorem restrict_apply_of_le_coe {x : SignExpansion} {o₁ : WithTop NatOrdinal}
    {o₂ : NatOrdinal} (h : o₁ ≤ o₂) : (x ↾ o₁) o₂ = 0 := by
  sorry

@[simp]
theorem length_restrict (x : SignExpansion) (o : WithTop NatOrdinal) :
    (x ↾ o).length = min x.length o := by
  sorry

@[simp]
theorem restrict_of_length_le {x : SignExpansion} {o : WithTop NatOrdinal}
    (ho : x.length ≤ o) : x ↾ o = x := by
  sorry

@[simp, grind =]
theorem restrict_restrict_eq {x : SignExpansion} {o₁ o₂ : WithTop NatOrdinal} :
    (x ↾ o₁) ↾ o₂ = x ↾ min o₁ o₂ := by
  sorry

@[simp]
theorem restrict_zero_left (o : WithTop NatOrdinal) : 0 ↾ o = 0 := by
  sorry

@[simp]
theorem restrict_zero_right (x : SignExpansion) : x ↾ 0 = 0 := by
  sorry

theorem restrict_top_right {x : SignExpansion} : x ↾ ⊤ = x := by
  sorry

/-! ### Subset relation -/

/-- We write `x ⊆ y` when `x = y ↾ o` for some `o`. In the literature, this is written as
`x ≤ₛ y` or `x ⊑ y`. -/
instance : HasSubset SignExpansion where
  Subset x y := y ↾ x.length = x

/-- We write `x ⊂ y` when `x ⊆ y` and `x ≠ y`. In the literature, this is written as
`x <ₛ y` or `x ⊏ y`. -/
instance : HasSSubset SignExpansion where
  SSubset x y := x ⊆ y ∧ ¬ y ⊆ x

theorem subset_def {x y : SignExpansion} : x ⊆ y ↔ y ↾ x.length = x := by
  sorry
theorem ssubset_def {x y : SignExpansion} : x ⊂ y ↔ x ⊆ y ∧ ¬ y ⊆ x := by
  sorry

alias ⟨eq_of_subset, _⟩ := subset_def

@[simp]
theorem restrict_subset (x : SignExpansion) (o : WithTop NatOrdinal) : x ↾ o ⊆ x := by
  sorry

@[simp]
theorem zero_subset (x : SignExpansion) : 0 ⊆ x := by
  sorry

theorem eq_or_length_lt_of_subset {x y : SignExpansion} (h : x ⊆ y) :
    x = y ∨ x.length < y.length := by
  sorry

instance : @Std.Refl SignExpansion (· ⊆ ·) where
  refl _ := restrict_of_length_le le_rfl

instance : IsTrans SignExpansion (· ⊆ ·) where
  trans := by grind [subset_def]

instance : @Std.Antisymm SignExpansion (· ⊆ ·) where
  antisymm x y h₁ h₂ := by
    have := eq_or_length_lt_of_subset h₁
    have := eq_or_length_lt_of_subset h₂
    grind

instance : IsNonstrictStrictOrder SignExpansion (· ⊆ ·) (· ⊂ ·) where
  right_iff_left_not_left _ _ := .rfl

@[gcongr]
theorem length_le_of_subset {x y : SignExpansion} (h : x ⊆ y) : x.length ≤ y.length := by
  sorry

@[gcongr]
theorem length_lt_of_ssubset {x y : SignExpansion} (h : x ⊂ y) : x.length < y.length := by
  sorry

/-! ### Order structure -/

-- This has deliberately not been upstreamed to Mathlib.
instance : CompleteLinearOrder SignType := Fintype.toCompleteLinearOrder _

instance : LinearOrder SignExpansion :=
  LinearOrder.lift' (toLex ⇑·) (by simp [Function.Injective])

theorem le_iff_toLex {x y : SignExpansion} : x ≤ y ↔ toLex ⇑x ≤ toLex ⇑y := by
  sorry
theorem lt_iff_toLex {x y : SignExpansion} : x < y ↔ toLex ⇑x < toLex ⇑y := by
  sorry

instance : BoundedOrder SignExpansion where
  le_top _ := le_iff_toLex.2 le_top
  bot_le _ := le_iff_toLex.2 bot_le

protected theorem neg_lt_neg {x y : SignExpansion} (h : x < y) : -y < -x := by
  sorry

@[simp]
protected theorem neg_lt_neg_iff {x y : SignExpansion} : -x < -y ↔ y < x := by
  sorry

@[simp]
protected theorem neg_le_neg_iff {x y : SignExpansion} : -x ≤ -y ↔ y ≤ x := by
  sorry

protected theorem neg_le {x y : SignExpansion} : -x ≤ y ↔ -y ≤ x := by
  sorry

protected theorem le_neg {x y : SignExpansion} : x ≤ -y ↔ y ≤ -x := by
  sorry

protected theorem neg_lt {x y : SignExpansion} : -x < y ↔ -y < x := by
  sorry

protected theorem lt_neg {x y : SignExpansion} : x < -y ↔ y < -x := by
  sorry

/-! #### Floor function -/

open Classical in
/-- The floor function on a function `NatOrdinal → SignType` "rounds" it downwards to the nearest
valid `SignExpansion`. -/
@[no_expose]
def floor (f : NatOrdinal → SignType) : SignExpansion :=
  if hf : IsUpperSet (f ⁻¹' {0}) then ⟨f, hf⟩ else
    let a := sInf (f ⁻¹' {0})
    haveI ha b : b < a → f b ≠ 0 := notMem_of_lt_csInf'
    { sign c := if c < a then f c else
        if f (sInf {b | a < b ∧ f b ≠ 0}) = -1 then
          if c = a then -1 else 1
        else 0
      isUpperSet_preimage_singleton_zero' := by
        by_cases h : f (sInf {b | a < b ∧ f b ≠ 0}) = -1
        · convert isUpperSet_empty
          aesop
        · convert isUpperSet_Ici a
          aesop }

private theorem floor_of_eq_neg_one {f : NatOrdinal → SignType} (hf : ¬ IsUpperSet (f ⁻¹' {0}))
    (hf' : f (sInf {b | sInf (f ⁻¹' {0}) < b ∧ f b ≠ 0}) = -1) (c : NatOrdinal) :
    floor f c = if c < sInf (f ⁻¹' {0}) then f c else if c = sInf (f ⁻¹' {0}) then -1 else 1 := by
  sorry

private theorem floor_of_eq_one {f : NatOrdinal → SignType} (hf : ¬ IsUpperSet (f ⁻¹' {0}))
    (hf' : f (sInf {b | sInf (f ⁻¹' {0}) < b ∧ f b ≠ 0}) = 1) (c : NatOrdinal) :
    floor f c = if c < sInf (f ⁻¹' {0}) then f c else 0 := by
  sorry

private theorem nonempty_of_not_isUpperSet {f : NatOrdinal → SignType}
    (hf : ¬ IsUpperSet (f ⁻¹' {0})) :
    (f ⁻¹' {0}).Nonempty ∧ {b | sInf (f ⁻¹' {0}) < b ∧ f b ≠ 0}.Nonempty := by
  sorry

theorem floor_of_isUpperSet {f : NatOrdinal → SignType} (hf : IsUpperSet (f ⁻¹' {0})) :
    floor f = ⟨f, hf⟩ := by
  sorry

@[simp]
theorem floor_coe (x : SignExpansion) : floor x = x := by
  sorry

theorem floor_apply_of_lt_sInf {f : NatOrdinal → SignType} {a : NatOrdinal}
    (hf : a < sInf (f ⁻¹' {0})) : floor f a = f a := by
  sorry

theorem floor_lt_of_not_isUpperSet {f : NatOrdinal → SignType} (hf : ¬ IsUpperSet (f ⁻¹' {0})) :
    toLex ⇑(floor f) < toLex f := by
  sorry

theorem floor_le (f : NatOrdinal → SignType) : toLex ⇑(floor f) ≤ toLex f := by
  sorry

theorem floor_lt {f : NatOrdinal → SignType} {x : SignExpansion} :
    floor f < x ↔ toLex f < toLex ⇑x := by
  sorry

theorem le_floor {f : NatOrdinal → SignType} {x : SignExpansion} :
    x ≤ floor f ↔ toLex ⇑x ≤ toLex f := by
  sorry

theorem gc_coe_floor : GaloisConnection (toLex ∘ (⇑·) : SignExpansion → _) (floor ∘ ofLex) := by
  sorry

/-- `floor` as a Galois coinsertion. -/
def gciFloor : GaloisCoinsertion (toLex ∘ (⇑·) : SignExpansion → _) (floor ∘ ofLex) where
  gc := gc_coe_floor
  u_l_le := by simp
  choice x h := (floor (ofLex x)).copy (ofLex x) (toLex_inj.1 (h.antisymm (gc_coe_floor.l_u_le x)))
  choice_eq x h := copy_eq ..

/-! #### Ceiling function -/

/-- The ceiling function on a function `NatOrdinal → SignType` "rounds" it upwards to the nearest
valid `SignExpansion`. -/
@[no_expose]
def ceil (f : NatOrdinal → SignType) : SignExpansion :=
  -floor (-f)

theorem ceil_of_isUpperSet {f : NatOrdinal → SignType} (hf : IsUpperSet (f ⁻¹' {0})) :
    ceil f = ⟨f, hf⟩ := by
  sorry

@[simp]
theorem ceil_coe (x : SignExpansion) : ceil x = x := by
  sorry

theorem ceil_apply_of_lt_sInf {f : NatOrdinal → SignType} {a : NatOrdinal}
    (hf : a < sInf (f ⁻¹' {0})) : ceil f a = f a := by
  sorry

theorem lt_ceil_of_not_isUpperSet {f : NatOrdinal → SignType} (h : ¬ IsUpperSet (f ⁻¹' {0})) :
    toLex f < toLex ⇑(ceil f) := by
  sorry

theorem le_ceil (f : NatOrdinal → SignType) : toLex f ≤ toLex ⇑(ceil f) := by
  sorry

theorem lt_ceil {f : NatOrdinal → SignType} {x : SignExpansion} :
    x < ceil f ↔ toLex ⇑x < toLex f := by
  sorry

theorem ceil_le {f : NatOrdinal → SignType} {x : SignExpansion} :
    ceil f ≤ x ↔ toLex f ≤ toLex ⇑x := by
  sorry

theorem gc_ceil_coe : GaloisConnection (ceil ∘ ofLex) (toLex ∘ (⇑·) : SignExpansion → _) := by
  sorry

/-- `ceil` as a Galois insertion. -/
def giCeil : GaloisInsertion (ceil ∘ ofLex) (toLex ∘ (⇑·) : SignExpansion → _) where
  gc := gc_ceil_coe
  le_l_u := by simp
  choice x h := (ceil (ofLex x)).copy (ofLex x) (toLex_inj.1 ((gc_ceil_coe.le_u_l x).antisymm h))
  choice_eq x h := copy_eq ..

@[simp]
theorem floor_neg (f : NatOrdinal → SignType) : floor (-f) = -ceil f := by
  sorry

@[simp]
theorem ceil_neg (f : NatOrdinal → SignType) : ceil (-f) = -floor f := by
  sorry

theorem floor_le_ceil (f : NatOrdinal → SignType) : floor f ≤ ceil f := by
  sorry

theorem floor_lt_ceil_of_not_isUpperSet {f : NatOrdinal → SignType} (h : ¬ IsUpperSet (f ⁻¹' {0})) :
    floor f < ceil f := by
  sorry

/-! #### Complete linear order instance -/

instance : CompleteLattice SignExpansion :=
  fast_instance%
  { __ := instLinearOrder.toBiheytingAlgebra _
    __ := giCeil.liftCompleteLattice.toCompleteSemilatticeInf
    __ := gciFloor.liftCompleteLattice.toCompleteSemilatticeSup }

instance : CompleteLinearOrder SignExpansion where
  __ := LinearOrder.toBiheytingAlgebra _
  __ := instCompleteLattice
  __ := instLinearOrder

theorem coe_sInf (s : Set SignExpansion) :
    sInf s = ofLex (sInf ((fun x : SignExpansion ↦ toLex ⇑x) '' s)) := by
  sorry

theorem coe_iInf {ι} (f : ι → SignExpansion) :
    ⨅ i, f i = ofLex (⨅ i : ι, toLex (⇑(f i))) := by
  sorry

theorem sInf_apply (s : Set SignExpansion) (i : NatOrdinal) :
    sInf s i = ⨅ x : {x : SignExpansion // x ∈ s ∧ ∀ j < i, x j = sInf s j}, x.1 i := by
  sorry

theorem coe_sSup (s : Set SignExpansion) :
    sSup s = ofLex (sSup ((fun x : SignExpansion ↦ toLex ⇑x) '' s)) := by
  sorry

theorem coe_iSup {ι} (f : ι → SignExpansion) :
    ⨆ i, f i = ofLex (⨆ i : ι, toLex (⇑(f i))) := by
  sorry

theorem sSup_apply (s : Set SignExpansion) (i : NatOrdinal) :
    sSup s i = ⨆ x : {x : SignExpansion // x ∈ s ∧ ∀ j < i, x j = sSup s j}, x.1 i := by
  sorry

end SignExpansion

/-! ### Cast from ordinals -/

namespace NatOrdinal
open SignExpansion

variable {o₁ o₂ : NatOrdinal}

/-- Returns the sign expansion with the corresponding number of `1`s. -/
def toSignExpansion : NatOrdinal ↪o SignExpansion :=
  .ofStrictMono (⊤ ↾ ·) fun x y h ↦ by
    use x
    aesop (add apply unsafe [lt_trans])

instance : Coe NatOrdinal SignExpansion where
  coe x := x.toSignExpansion

@[aesop simp]
theorem coe_toSignExpansion (o : NatOrdinal) :
    ⇑(o : SignExpansion) = fun i : NatOrdinal ↦ if i < o then 1 else 0 := by
  sorry

@[simp] theorem top_restrict (o : NatOrdinal) : ⊤ ↾ o = o := by
  sorry
@[simp] theorem bot_restrict (o : NatOrdinal) : ⊥ ↾ o = -o := by
  sorry

@[simp]
theorem length_toSignExpansion (o : NatOrdinal) : length o = o := by
  sorry

theorem toSignExpansion_apply_of_lt (h : o₂ < o₁) : toSignExpansion o₁ o₂ = 1 := by
  sorry

theorem toSignExpansion_apply_of_le (h : o₁ ≤ o₂) : toSignExpansion o₁ o₂ = 0 := by
  sorry

theorem toSignExpansion_subset_toSignExpansion_of_le (h : o₁ ≤ o₂) :
    (o₁ : SignExpansion) ⊆ o₂ := by
  sorry

theorem toSignExpansion_ssubset_toSignExpansion_of_lt (h : o₁ < o₂) :
    (o₁ : SignExpansion) ⊂ o₂ := by
  sorry

@[simp]
theorem toSignExpansion_subset_toSignExpansion_iff : (o₁ : SignExpansion) ⊆ o₂ ↔ o₁ ≤ o₂ := by
  sorry

@[simp]
theorem toSignExpansion_ssubset_toSignExpansion_iff : (o₁ : SignExpansion) ⊂ o₂ ↔ o₁ < o₂ := by
  sorry

end NatOrdinal
