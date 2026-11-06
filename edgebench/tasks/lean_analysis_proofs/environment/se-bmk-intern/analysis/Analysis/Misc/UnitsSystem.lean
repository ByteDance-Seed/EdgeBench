import Mathlib.Tactic
import Mathlib.Algebra.Group.InjSurj
import Mathlib.Order.Defs.PartialOrder
import Mathlib.Algebra.Order.Module.Defs

set_option doc.verso.suggestions false

/-! A framework to formalize units (such as length, time, mass, velocity, etc.) in Lean.
-/

/- Dimensions of units are measured by an additive group `Dimensions`, which will typically be a
free module inan group on a finite number of generators, representing fundamental units such as length,
mass, and time.  We bundle this together in a class `UnitsSystem`.  To use this system, we create
an instance of it, allowing in particular the additive group `Dimensions` to be accessed freely
within the `UnitsSystem` namespace.

I am no longer actively maintaining this code, and others are welcome to incorporate it into their own units implementations.  Existing units implications in Lean include

- https://github.com/ATOMSLab/LeanDimensionalAnalysis/tree/main
- https://github.com/ecyrbe/lean-units
- https://github.com/HEPLean/PhysLean/tree/master/PhysLean/Units

and a general discussion of how to implement units can be found at

https://leanprover.zulipchat.com/#narrow/channel/479953-PhysLean/topic/physical.20units
-/

class UnitsSystem where
  Dimensions: Type*
  addCommGroup: AddCommGroup Dimensions

/- The additive group structure of `Dimensions` needs to be explicitly registered as an instance. -/
attribute [instance] UnitsSystem.addCommGroup

namespace UnitsSystem

variable [UnitsSystem]

/-- The two key types here are `Formal` and `Scalar d`.  `Scalar d` is the space of scalar
quantities whose units are given by `d : Dimensions`.  Collectively, they generate a graded commutative
 ring `Formal`, which can be conveniently described using the existing Mathlib structure
 `AddMonoidAlgebra`.  Algebraic manipulations of scalar quantities will be most conveniently
 handled by casting these quantities into the commutative ring `Formal`, where one can use
 standard Mathlib tactics such as {name (full := Mathlib.Tactic.RingNF.ring)}`ring`.

In principle one could also develop vector-valued quantities with dimension, but for now we
restrict attention to scalar quantities only.
-/
abbrev Formal := AddMonoidAlgebra ℝ Dimensions

/-- The data `Scalar.val` of a `Scalar` quantity can be interpreted as the numerical value of that
quantity with respect to some standard set of units (e.g., SI units). -/
@[ext]
structure Scalar (d:Dimensions) where
  val : ℝ

theorem Scalar.val_injective (d : Dimensions) : Function.Injective (Scalar.val (d := d)) := by
  sorry

/- One has the option to `work in coordinates` in a given calculation by using `simp [←val_inj]` (or `simp [←cast_eq]` below, if casting is required).  Or one can adopt
a `coordinate-free` approach in which any tool directly accessing `val` is avoided.
This library allows for both approaches to be employed. -/
theorem Scalar.val_inj {d:Dimensions} (q₁ q₂:Scalar d) :
  q₁.val = q₂.val ↔ q₁ = q₂ := by
  sorry

/-- {given -show}`d, d', d₁, d₂` We will encounter a technical issue with Lean's type system, namely that the type {lean}`Scalar d`
and {lean}`Scalar d'` are not identical if `d'` and `d` are merely propositionally equal (as opposed
to definitionally equal); for instance, {lean}`Scalar (d₁+d₂)` and {lean}`Scalar (d₂+d₁)` are distinct types.
Technically, this renders multiplication on scalar types noncommutative. To get around this, we
create a casting operator, where the propositional equality is attempted to be resolved by the Lean
tactic {tactic}`module` whenever possible.  Unfortunately, the casting operator from {lean}`Scalar d` to {lean}`Scalar d'`
cannot be captured by standard Lean coercion classes such as `Coe` or `CoeOut` as each of the types
here contain parameters not present in the other. -/
def Scalar.cast {d d':Dimensions}  (q: Scalar d) (_ : d' = d := by module) : Scalar d' :=
  ⟨q.val⟩

/-- This is a variant of `Scalar.val_inj` that handles casts. -/
theorem Scalar.cast_eq {d d':Dimensions} (q: Scalar d) (q': Scalar d') (h: d = d' := by module)
  : q.val = q'.val ↔ q = q'.cast h := by aesop

theorem Scalar.cast_eq_symm {d d':Dimensions} (q: Scalar d) (q': Scalar d') (h: d = d' := by module)
  : q = q'.cast h ↔ q' = q.cast h.symm := by aesop

@[simp]
theorem Scalar.cast_val {d d':Dimensions} (q: Scalar d) (h: d' = d := by module)
  : (q.cast h).val = q.val := by aesop

/-- The existing Mathlib method `AddMonoidAlgebra.single` is perfect for embedding each type of
`Scalar` into the formal graded ring `Formal`. -/
@[coe]
noncomputable def Scalar.toFormal {d:Dimensions} (q:Scalar d) : Formal :=
  AddMonoidAlgebra.single d q.val

noncomputable instance Scalar.instCoeFormal (d: Dimensions) : CoeOut (Scalar d) Formal where
  coe := toFormal

/-- Many identities involving several types of `Scalar`s can be dealt with by applying
{syntax tactic}`simp [←toFormal_inj]` to move everything to `Formal`.  A large number of further {tactic}`simp` lemmas
in this file are then designed to simplify such `Formal` expressions, often by pushing casting
operators inward back to the `Scalar` types.  As such, there will be significant overlap between
the {tactic}`simp` and {tactic}`norm_cast` tags. -/
@[simp]
theorem Scalar.toFormal_inj {d: Dimensions} (q₁ q₂:Scalar d) :
  (q₁:Formal) = (q₂:Formal) ↔ q₁ = q₂ := by
  sorry

/-- Conveniently, casts from one scalar to another will automatically disappear when moving to
`Formal`. -/
@[simp]
theorem Scalar.toFormal_cast {d d': Dimensions} (q:Scalar d) (h:d' = d := by module) :
  ((q.cast h):Formal) = (q:Formal) := by
  subst h
  simp_all only [cast]

instance Scalar.instZero {d:Dimensions} : Zero (Scalar d) where
  zero := ⟨ 0 ⟩

@[simp]
theorem Scalar.val_zero {d:Dimensions} : (0:Scalar d).val = 0 := by
  sorry

/-- We will use the `NeZero` class to tag some scalars as non-zero; this becomes relevant when
using such scalars as units.  One could also introduce API to tag some scalars as positive, but
we currently are not implementing this. -/
theorem Scalar.neZero_iff {d:Dimensions} (q:Scalar d) : NeZero q ↔ q.val ≠ 0 := by
  sorry

@[simp, norm_cast]
theorem Scalar.toFormal_zero {d:Dimensions} : ((0:Scalar d):Formal) = 0 := by
  sorry

/-- In the next few lines of code we give {lean}`Scalar d` the structure of a real vector space,
which is of course compatible with the real vector space structure on `Formal`.  -/
instance Scalar.instAdd {d:Dimensions} : Add (Scalar d) where
  add q₁ q₂ := ⟨q₁.val + q₂.val⟩

@[simp]
theorem Scalar.val_add {d:Dimensions} (q₁ q₂:Scalar d) : (q₁ + q₂).val = q₁.val + q₂.val := by
  sorry

/-- Note how the {tactic}`simp` lemma is in the direction of pushing coercions inward. -/
@[simp,norm_cast]
theorem Scalar.toFormal_add {d:Dimensions} (q₁ q₂:Scalar d) : ((q₁ + q₂:Scalar d):Formal) = (q₁:Formal) + (q₂:Formal) := by
  sorry

instance Scalar.instNeg {d:Dimensions} : Neg (Scalar d) where
  neg q := ⟨-q.val⟩

@[simp]
theorem Scalar.val_neg {d:Dimensions} (q:Scalar d) : (-q).val = -q.val := by
  sorry

instance Scalar.instNeZero_neg {d:Dimensions} (q:Scalar d) [h:NeZero q] : NeZero (-q) := by
  rw [neZero_iff] at h ⊢
  simp [h]

@[simp,norm_cast]
theorem Scalar.toFormal_neg {d:Dimensions} (q:Scalar d) : ((-q:Scalar d):Formal) = -(q:Formal) := by
  sorry

instance Scalar.instSub {d:Dimensions} : Sub (Scalar d) where
  sub q₁ q₂ := ⟨q₁.val - q₂.val⟩

@[simp]
theorem Scalar.val_sub {d:Dimensions} (q₁ q₂ : Scalar d) : (q₁ - q₂).val = q₁.val - q₂.val := by
  sorry

@[simp,norm_cast]
theorem Scalar.toFormal_sub {d:Dimensions} (q₁ q₂ :Scalar d) : ((q₁ - q₂ :Scalar d):Formal) = (q₁:Formal) - q₂ := by
  sorry

instance Scalar.instSMul {α} {d:Dimensions} [SMul α ℝ] : SMul α (Scalar d) where
  smul c q := ⟨c • q.val⟩

@[simp]
theorem Scalar.val_smul {α} {d:Dimensions} [SMul α ℝ] (a : α) (q:Scalar d) : (a • q).val = a • q.val := by
  sorry

instance Scalar.instAddGroup {d:Dimensions} : AddGroup (Scalar d) :=
  val_injective _ |>.addGroup _ val_zero val_add val_neg val_sub (Function.swap val_smul) (Function.swap val_smul)

instance Scalar.instAddCommGroup {d:Dimensions} : AddCommGroup (Scalar d) :=
  val_injective _ |>.addCommGroup _ val_zero val_add val_neg val_sub (Function.swap val_smul) (Function.swap val_smul)

/-- The dimensionless scalars {lean}`Scalar 0` can be identified with real numbers.  -/
@[coe]
def Scalar.ofReal (r:ℝ) : Scalar 0 := ⟨ r ⟩

instance Scalar.instCoeReal : Coe ℝ (Scalar 0) where
  coe := ofReal

@[simp]
theorem Scalar.coe_val (r:ℝ) : (r:Scalar 0).val = r := by
  sorry

@[norm_cast,simp]
theorem Scalar.coe_zero : ((0:ℝ):Scalar 0) = 0 := by
  sorry

theorem Scalar.neZero_coe_iff {r:ℝ} : NeZero (r:Scalar 0) ↔ r ≠ 0 := by
  sorry

@[simp]
theorem Scalar.coe_inj {r s:ℝ} : (r:Scalar 0) = (s:Scalar 0) ↔ r = s := by
  sorry

@[norm_cast,simp]
theorem Scalar.coe_add (r s:ℝ) : ((r+s:ℝ):Scalar 0) = (r:Scalar 0) + (s:Scalar 0) := by
  sorry

@[norm_cast,simp]
theorem Scalar.coe_neg (r:ℝ) : ((-r:ℝ):Scalar 0) = -(r:Scalar 0) := by
  sorry

@[norm_cast,simp]
theorem Scalar.coe_sub (r s:ℝ) : ((r-s:ℝ):Scalar 0) = (r:Scalar 0) - (s:Scalar 0) := by
  sorry

/-- It is convenient to view the real numbers as a subring of the `Formal` ring, thus identifying
`Scalar` multiplication with ordinary multiplication. -/
noncomputable instance Formal.instCoeReal : Coe ℝ Formal where
  coe r := ((r:Scalar 0):Formal)

@[norm_cast,simp]
theorem Formal.coe_zero : ((0:ℝ):Formal) = 0 := by
  sorry

@[norm_cast,simp]
theorem Formal.coe_one : ((1:ℝ):Formal) = 1 := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_smul {d:Dimensions} (c:ℝ) (q:Scalar d)
  : ((c • q:Scalar d):Formal) = (c:Formal) * (q:Formal) := by
  sorry

@[simp]
theorem Formal.smul_eq_mul (c:ℝ) (x:Formal) : c • x = (c:Formal) * x := by
  sorry

@[simp]
theorem Formal.smul_eq_mul' (c:ℕ) (x:Formal) : c • x = (c:Formal) * x := by
  sorry

@[simp]
theorem Formal.smul_eq_mul'' (c:ℤ) (x:Formal) : c • x = (c:Formal) * x := by
  sorry

@[norm_cast,simp]
theorem Scalar.coe_mul (r s:ℝ) : ((r*s:ℝ):Scalar 0) = r • (s:Scalar 0) := by
  sorry

/-- We are finally able to view {lean}`Scalar d` as a vector space over {lean}`ℝ` as promised. -/
instance Scalar.instModule {d:Dimensions} : Module ℝ (Scalar d) where
  smul_add c q₁ q₂ := by simp [←toFormal_inj]; ring
  add_smul c1 c2 q := by simp [←toFormal_inj]; ring
  one_smul q := by simp [←toFormal_inj]
  zero_smul q := by simp [←toFormal_inj]
  mul_smul c1 c2 q := by simp [←toFormal_inj]; ring
  smul_zero c := by simp [←toFormal_inj]

@[simp]
theorem Scalar.val_smul' {d:Dimensions} (c:ℕ) (q:Scalar d) : (c • q).val = c * q.val := by
  sorry

@[simp]
theorem Scalar.val_smul'' {d:Dimensions} (c:ℤ) (q:Scalar d) : (c • q).val = c * q.val := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_smul' {d:Dimensions} (c:ℕ) (q:Scalar d)
  : ((c • q:Scalar d):Formal) = (c:Formal) * (q:Formal) := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_smul'' {d:Dimensions} (c:ℤ) (q:Scalar d)
  : ((c • q:Scalar d):Formal) = (c:Formal) * (q:Formal) := by
  sorry

/-- One can multiply a {lean}`Scalar d₁` and {lean}`Scalar d₂` quantities to obtain a {lean}`Scalar (d₁+d₂)` quantity,
in a manner compatible with multiplication in `Formal`. -/
instance Scalar.instHMul {d₁ d₂:Dimensions} : HMul (Scalar d₁) (Scalar d₂) (Scalar (d₁ + d₂)) where
  hMul q₁ q₂ := ⟨q₁.val * q₂.val⟩

@[simp]
theorem Scalar.val_hMul {d₁ d₂:Dimensions} (q₁:Scalar d₁) (q₂:Scalar d₂) :
  (q₁ * q₂).val = q₁.val * q₂.val := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_hMul {d₁ d₂:Dimensions} (q₁:Scalar d₁) (q₂:Scalar d₂) :
  ((q₁ * q₂:Scalar _):Formal) = (q₁:Formal) * (q₂:Formal) := by
  sorry

/-- Similarly, one can raise a {lean}`Scalar d` quantity to a natural number power `n` to obtain a {lean}`Scalar (n • d)` quantity.  One could also implement exponentiation to an integer, but I have elected
not to do this, implementing an inversion relation instead. -/
noncomputable def Scalar.pow {d:Dimensions} (q: Scalar d) (n:ℕ) : Scalar (n • d) := ⟨ q.val^n ⟩

/-- {given -show}`n : ℕ, d` One cannot use the Mathlib classes `Pow` or `HPow` here because the output type {lean}`Scalar (n • d)` depends on the input `n`.  As the symbol {kw (of := «term_^_»)}`^` is reserved for such classes, we use the symbol `**` instead.-/
infix:80 "**" => Scalar.pow

@[simp]
theorem Scalar.val_pow {d:Dimensions} (q:Scalar d) (n:ℕ) :
  (q ** n).val = q.val ^ n := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_pow {d:Dimensions} (q:Scalar d) (n:ℕ) :
  ((q ** n):Formal) = (q:Formal) ^ n := by
  sorry

/-- We cannot use Mathlib's `Inv` class here or the associated {kw (of := «term_⁻¹»)}`⁻¹` notation because `Inv` requires the output to be of the same type as the input. -/
noncomputable def Scalar.inv {d:Dimensions} (q:Scalar d) : Scalar (-d) := ⟨ q.val⁻¹ ⟩

@[simp]
theorem Scalar.val_inv {d:Dimensions} (q:Scalar d) :
  q.inv.val = q.val⁻¹ := by
  sorry

instance Scalar.instNeg_inv {d:Dimensions} (q:Scalar d) [h: NeZero q] : NeZero q.inv := by
  rw [neZero_iff] at h ⊢
  simp [h]

@[simp]
theorem Scalar.inv_mul_self {d:Dimensions} (q:Scalar d) [h:NeZero q] :  (q.inv:Formal) * (q:Formal) = 1 := by
  sorry

@[simp]
theorem Scalar.inv_coe (r:ℝ) :  ((r:Scalar 0).inv:Formal) = ((r⁻¹:ℝ):Scalar 0) := by
  sorry

@[simp]
theorem Scalar.mul_inv {d₁ d₂:Dimensions} (q₁:Scalar d₁) (q₂:Scalar d₂) : (q₁ * q₂).inv = ((q₁.inv) * (q₂.inv)).cast := by
  sorry

@[simp]
theorem Scalar.pow_inv {d:Dimensions} (q:Scalar d) (n:ℕ) : (q ** n).inv = (q.inv ** n).cast := by
  sorry

/-- Multiplication and inversion combine to give division in the usual fashion.-/
noncomputable instance Scalar.instHDiv {d₁ d₂:Dimensions} : HDiv (Scalar d₁) (Scalar d₂) (Scalar (d₁ - d₂)) where
  hDiv q₁ q₂ := ⟨q₁.val / q₂.val⟩

@[simp]
theorem Scalar.val_hDiv {d₁ d₂:Dimensions} (q₁:Scalar d₁) (q₂:Scalar d₂) :
  (q₁ / q₂).val = q₁.val / q₂.val := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_hDiv {d₁ d₂:Dimensions} (q₁:Scalar d₁) (q₂:Scalar d₂) :
  ((q₁ / q₂:Scalar _):Formal) = (q₁:Formal) * (q₂.inv:Formal) := by
  sorry

noncomputable instance Scalar.instHDiv' {d:Dimensions} : HDiv (Scalar d) ℝ  (Scalar d) where
  hDiv q r := ⟨q.val / r⟩

noncomputable instance Scalar.instHDiv'' {d:Dimensions} : HDiv (Scalar d) ℕ (Scalar d) where
  hDiv q n := q / (n:ℝ)

noncomputable instance Scalar.instHDiv''' {d:Dimensions} : HDiv (Scalar d) ℤ (Scalar d) where
  hDiv q n := q / (n:ℝ)

@[simp]
theorem Scalar.val_hDiv' {d:Dimensions} (q:Scalar d) (r:ℝ) :
  (q / r).val = q.val / r := by
  sorry

@[simp]
theorem Scalar.val_hDiv'' {d:Dimensions} (q:Scalar d) (n:ℕ) :
  (q / n).val = q.val / n := by
  sorry

@[simp]
theorem Scalar.val_hDiv''' {d:Dimensions} (q:Scalar d) (n:ℤ) :
  (q / n).val = q.val / n := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_hDiv' {d:Dimensions} (q:Scalar d) (r:ℝ) :
  ((q / r:Scalar _):Formal) = (q:Formal) * ((r⁻¹:ℝ):Formal) := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_hDiv'' {d:Dimensions} (q:Scalar d) (n:ℕ) :
  ((q / n:Scalar _):Formal) = (q:Formal) * (((n:ℝ)⁻¹:ℝ):Formal) := by
  sorry

@[norm_cast,simp]
theorem Scalar.toFormal_hDiv''' {d:Dimensions} (q:Scalar d) (n:ℤ) :
  ((q / n:Scalar _):Formal) = (q:Formal) * (((n:ℝ)⁻¹:ℝ):Formal) := by
  sorry

instance Scalar.instLE (d:Dimensions) : LE (Scalar d) where
  le x y := x.val ≤ y.val

theorem Scalar.val_le {d:Dimensions} (x y:Scalar d) :
  x ≤ y ↔ x.val ≤ y.val := by
  sorry

noncomputable instance Scalar.instLinearOrder (d:Dimensions) : LinearOrder (Scalar d) where
  le_refl := by simp [val_le]
  le_trans := by simp [val_le]; intros; order
  lt_iff_le_not_ge := by simp [val_le]
  le_antisymm := by simp [val_le, ←val_inj]; intros; order
  le_total := by simp [val_le]; intros; apply LinearOrder.le_total
  toDecidableLE := Classical.decRel _

theorem Scalar.val_lt {d:Dimensions} (x y:Scalar d) :
  x < y ↔ x.val < y.val := by
  sorry

noncomputable instance Scalar.instPosSMulStrictMono (d:Dimensions) : PosSMulStrictMono ℝ (Scalar d) where
  smul_lt_smul_of_pos_left {_a} ha {_b₁ _b₂} hb := by
    simp only [val_lt, val_smul, smul_eq_mul] at *; exact mul_lt_mul_of_pos_left hb ha

noncomputable instance Scalar.instSMulPosStrictMono (d:Dimensions) : SMulPosStrictMono ℝ (Scalar d) where
  smul_lt_smul_of_pos_right {_b} hb {_a₁ _a₂} ha := by
    simp only [val_lt, val_smul, smul_eq_mul] at *; exact mul_lt_mul_of_pos_right ha hb

noncomputable instance Scalar.instIsStrictOrderedModule (d:Dimensions) : IsStrictOrderedModule ℝ (Scalar d) where

-- TODO: add in some `gcongr` lemmas for this order

/-- The standard unit of {lean}`Scalar d` is the quantity whose data `Scalar.val` is equal to {lean (type := "ℝ")}`1`. -/
def StandardUnit (d:Dimensions) : Scalar d := ⟨ 1 ⟩

@[simp]
theorem StandardUnit.val_eq (d:Dimensions) : (StandardUnit d).val = 1 := by
  sorry

instance StandardUnit.inst_NeZero (d:Dimensions) : NeZero (StandardUnit d) := by
  simp [Scalar.neZero_iff]

@[simp]
theorem StandardUnit.mul' (d₁ d₂:Dimensions) : (StandardUnit d₁:Formal) * (StandardUnit d₂:Formal) = StandardUnit (d₁+d₂) := by
  sorry

@[simp]
theorem StandardUnit.pow' (d:Dimensions) (n:ℕ) : (StandardUnit d:Formal)^n = StandardUnit (n • d) := by
  sorry

@[simp]
theorem StandardUnit.inv (d:Dimensions) : (StandardUnit d).inv = StandardUnit (-d) := by
  sorry

@[simp]
theorem StandardUnit.div (d₁ d₂:Dimensions) : StandardUnit d₁ / StandardUnit d₂ = StandardUnit (d₁-d₂) := by
  sorry

/-- {lean}`unit.in q` is {lean}`q : Scalar d` measured in terms of {lean}`unit : Scalar d`. -/
noncomputable def Scalar.in {d:Dimensions} (unit q:Scalar d) : ℝ := q.val / unit.val

@[simp]
theorem Scalar.val_in (d:Dimensions) (unit q:Scalar d) : unit.in q = q.val / unit.val := by
  sorry

theorem Scalar.in_def {d:Dimensions} (unit q:Scalar d) [h: NeZero unit] : q = (unit.in q) • unit := by
  sorry

@[simp]
theorem Scalar.in_smul {d:Dimensions} (c:ℝ) (unit q:Scalar d) : unit.in (c • q) = c * unit.in q := by
  sorry

theorem Scalar.in_inj {d:Dimensions} (unit q₁ q₂:Scalar d) [h: NeZero unit] : unit.in q₁ = unit.in q₂ ↔ q₁ = q₂ := by
  sorry

end UnitsSystem
