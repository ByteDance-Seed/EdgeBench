import SphereEversion.Notations
import SphereEversion.ToMathlib.Equivariant
import SphereEversion.ToMathlib.MeasureTheory.ParametricIntervalIntegral

/-!
# Basic definitions and properties of loops
-/

open Set Function FiniteDimensional Int TopologicalSpace

open scoped Topology unitInterval

noncomputable section

variable {K X X' Y Z : Type*}

-- variable [TopologicalSpace X'] [TopologicalSpace Y] [TopologicalSpace Z]
variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {F : Type*} [NormedAddCommGroup F]
  [NormedSpace ℝ F] {F' : Type*} [NormedAddCommGroup F'] [NormedSpace ℝ F']

/-! ## Definition and periodicity lemmas -/

variable (X)

/-- A loop is a function with domain `ℝ` and is periodic with period 1. -/
structure Loop where
  toFun : ℝ → X
  per' : ∀ t, toFun (t + 1) = toFun t

attribute [coe] Loop.toFun

instance : CoeFun (Loop X) fun _ ↦ ℝ → X :=
  ⟨fun γ ↦ γ.toFun⟩

initialize_simps_projections Loop (toFun → apply)

/-- Any function `φ : α → loop X` can be seen as a function `α × ℝ → X`. -/
instance hasUncurryLoop {α : Type*} : HasUncurry (α → Loop X) (α × ℝ) X :=
  ⟨fun φ p ↦ φ p.1 p.2⟩

variable {X}

namespace Loop

protected theorem coe_mk {γ : ℝ → X} (h : ∀ t, γ (t + 1) = γ t) : ⇑(⟨γ, h⟩ : Loop X) = γ := by
  sorry

@[ext]
protected theorem ext : ∀ {γ₁ γ₂ : Loop X}, (γ₁ : ℝ → X) = γ₂ → γ₁ = γ₂
  := by
  sorry

/-- The constant loop. -/
@[simps]
def const (f : X) : Loop X :=
  ⟨fun _ ↦ f, fun _ ↦ rfl⟩

instance Zero [Zero X] : Zero (Loop X) :=
  ⟨const 0⟩

@[simp]
theorem zero_fun [_root_.Zero X] : ((0 : Loop X) : ℝ → X) = (0 : ℝ → X) := by
  sorry

-- unused
@[simp]
theorem const_zero [_root_.Zero X] : const (0 : X) = (0 : Loop X) := by
  sorry

instance [Inhabited X] : Inhabited (Loop X) :=
  ⟨Loop.const default⟩

/-- Periodicity of loops restated in terms of the function coercion. -/
theorem per (γ : Loop X) : ∀ t, γ (t + 1) = γ t := by
  sorry

-- unused
theorem add_nat_eq (γ : Loop X) (t : ℝ) : ∀ n : ℕ, γ (t + n) = γ t
  := by
  sorry

/-- Transforming a loop by applying function `f`. -/
@[simps]
def transform (γ : Loop X) (f : X → X') : Loop X' :=
  ⟨fun t ↦ f (γ t), fun t ↦ by dsimp only; rw [γ.per]⟩

/-- Adding two loops pointwise. -/
@[simps]
instance Add [Add X] : Add (Loop X) :=
  ⟨fun γ₁ γ₂ ↦ ⟨fun t ↦ γ₁ t + γ₂ t, fun t ↦ by simp_rw [Loop.per]⟩⟩

@[simps]
instance Neg [Neg X] : Neg (Loop X) :=
  ⟨fun γ ↦ ⟨fun t ↦ -γ t, fun t ↦ by simp_rw [Loop.per]⟩⟩

instance [AddCommGroup X] : AddCommGroup (Loop X) :=
  { Loop.Add, Loop.Zero, Loop.Neg with
    add_assoc := fun γ₁ γ₂ γ₃ ↦ by ext t; apply add_assoc
    add_comm := fun γ₁ γ₂ ↦ by ext t; apply add_comm
    zero_add := fun γ ↦ by ext t; apply zero_add
    add_zero := fun γ ↦ by ext t; apply add_zero
    neg_add_cancel := fun γ ↦ by ext t; apply neg_add_cancel
    nsmul := nsmulRec
    zsmul := zsmulRec }

/-- Shifting a loop, or equivalently, adding a constant value to a loop. -/
instance [_root_.Add X] : VAdd X (Loop X) :=
  ⟨fun x γ ↦ γ.transform fun y ↦ x + y⟩

@[simp]
theorem vadd_apply [_root_.Add X] {x : X} {γ : Loop X} {t : ℝ} : (x +ᵥ γ) t = x + γ t := by
  sorry

/-- Multiplying a loop by a scalar value. -/
instance [SMul K X] : SMul K (Loop X) :=
  ⟨fun k γ ↦ γ.transform fun y ↦ k • y⟩

instance [Semiring K] [AddCommGroup X] [Module K X] : Module K (Loop X) where
  one_smul γ := by ext t; apply one_smul
  mul_smul k₁ k₂ γ := by ext t; apply mul_smul
  smul_zero k := by ext; apply smul_zero
  smul_add k γ₁ γ₂ := by ext t; apply smul_add
  add_smul k₁ k₂ γ := by ext t; apply add_smul
  zero_smul γ := by ext t; apply zero_smul

@[simp]
theorem smul_apply [SMul K X] {k : K} {γ : Loop X} {t : ℝ} : (k • γ) t = k • γ t := by
  sorry

/-- Reparametrizing loop `γ` using an equivariant map `φ`. -/
@[simps +simpRhs]
def reparam {F : Type*} (γ : Loop F) (φ : EquivariantMap) : Loop F where
  toFun := γ ∘ φ
  per' t := by rw [comp_apply, φ.eqv, γ.per]; rfl

/-! ## Support of a loop family -/

/-- A loop is constant if it takes the same value at every time.
See also `Loop.isConst_iff_forall_avg` and `Loop.isConst_iff_const_avg` for characterizations in
terms of average values. -/
def IsConst (γ : Loop X) :=
  ∀ t s, γ t = γ s

variable [TopologicalSpace X] [TopologicalSpace X'] [TopologicalSpace Y] [TopologicalSpace Z]

/-- The support of a loop family is the closure of the set of parameters where
the loop is not constant. -/
def support (γ : X → Loop X') : Set X :=
  closure {x | ¬(γ x).IsConst}

omit [TopologicalSpace X'] in

/-! ## From paths to loops -/

/-- Turn a path into a loop. -/
@[simps]
noncomputable def ofPath {x : X} (γ : Path x x) : Loop X where
  toFun t := γ.extend (fract t)
  per' t := by rw [fract_add_one]

/-! ## Round trips -/

/-- The round-trip defined by `γ` is `γ` followed by `γ⁻¹`. -/
def roundTrip {x y : X} (γ : Path x y) : Loop X :=
  ofPath (γ.trans γ.symm)

/-- The round trip loop family associated to a path `γ`. For each parameter `t`,
the loop `roundTripFamily γ t` backtracks at `γ t`. -/
noncomputable def roundTripFamily {x y : X} (γ : Path x y) : ℝ → Loop X :=
  have key : ∀ {t}, x = γ.extend (min 0 t) := (γ.extend_of_le_zero <| min_le_left _ _).symm
  fun t ↦ roundTrip ((γ.truncate 0 t).cast key rfl)

attribute [fun_prop] Path.trans_continuous_family

/-! ## Average value of a loop -/
section Average

/-- The average value of a loop. -/
noncomputable def average (γ : Loop F) : F :=
  ∫ x in (0 : ℝ)..1, γ x

-- unused
@[simp]
theorem zero_average : average (0 : Loop F) = 0 := by
  sorry

open MeasureTheory

omit [NormedAddCommGroup F] [NormedSpace ℝ F] in

/-- The normalization of a loop `γ` is the loop `γ - γ.average`. -/
def normalize (γ : Loop F) : Loop F where
  toFun t := γ t - γ.average
  per' t := by simp [γ.per]

@[simp]
theorem normalize_apply (γ : Loop F) (t : ℝ) : Loop.normalize γ t = γ t - γ.average := by
  sorry

end Average

end Loop

section C1

/-! ## Differentiation of loop families -/

@[inherit_doc] local notation "∂₁" => partialFDerivFst ℝ

variable (π : E → ℝ) (N : ℝ) (γ : E → Loop F) (hγ : IsCompact (Loop.support γ))

/-- Differential of a loop family with respect to the parameter. -/
def Loop.diff (γ : E → Loop F) (e : E) : Loop (E →L[ℝ] F) where
  toFun t := ∂₁ (fun e t ↦ γ e t) e t
  per' t := by simp only [partialFDerivFst, Loop.per]

@[simp]
theorem Loop.diff_apply (γ : E → Loop F) (e : E) (t : ℝ) :
    Loop.diff γ e t = ∂₁ (fun e t ↦ γ e t) e t := by
  sorry

variable [FiniteDimensional ℝ F]

variable [FiniteDimensional ℝ E]

theorem Loop.average_diff {γ : E → Loop F} (hγ_diff : 𝒞 1 ↿γ) (e : E) :
    (Loop.diff γ e).average = D (fun e ↦ (γ e).average) e := by
  sorry

attribute [fun_prop] contDiff_parametric_integral_of_contDiff
theorem ContDiff.loop_average {γ : E → Loop F} {n : ℕ∞} (hγ_diff : 𝒞 n ↿γ) :
    𝒞 n fun e ↦ (γ e).average := by
  sorry

theorem Loop.diff_normalize {γ : E → Loop F} (hγ_diff : 𝒞 1 ↿γ) (e : E) :
    (Loop.diff γ e).normalize = Loop.diff (fun e ↦ (γ e).normalize) e := by
  sorry

variable {γ}

theorem contDiff_average {n : ℕ∞} (hγ_diff : 𝒞 n ↿γ) : 𝒞 n fun x ↦ (γ x).average := by
  sorry

theorem contDiff_sub_average {n : ℕ∞} (hγ_diff : 𝒞 n ↿γ) :
    𝒞 n ↿fun (x : E) (t : ℝ) ↦ (γ x) t - (γ x).average := by
  sorry

end C1
