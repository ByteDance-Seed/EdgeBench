import Mathlib.Tactic
import Mathlib.Topology.Instances.Irrational
import Analysis.Section_11_6

set_option doc.verso.suggestions false

/-!
# Analysis I, Section 11.8: The Riemann-Stieltjes integral

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- Definition of `α_length`.
- The piecewise constant Riemann-Stieltjes integral.
- The full Riemann-Stieltjes integral.

{open Set}

Technical notes:
- In Lean it is more convenient to make definitions such as `α_length` and the Riemann-Stieltjes
  integral totally defined, thus assigning "junk" values to the cases where the definition is
  not intended to be applied. For the definition of `α_length`, the definition is intended to be
  applied in contexts where left and right limits exist, and the function is extended by
  constants to the left and right of its intended domain of definition; for instance, if a
  function `x` `f` is defined on {lean}`Icc 0 1`, then it is intended that `f x = f 1` for all `x ≥ 1`
  and `f x = f 0` for all `x ≤ 0`; in particular, at a right endpoint, the value of a function
  is intended to agree with its right limit, and similarly for the left endpoint, although we
  do not enforce this in our definition of `α_length`. (For functions defined on open intervals,
  the extension is immaterial.)
- The notion of `α_length` and piecewise constant Riemann-Stieltjes integral is intended for
  situations where left and right limits exist, such as for monotone functions or continuous
  functions, though technically they make sense without these hypotheses. The full Riemann-Stieltjes
  integral is intended for functions that are of bounded variation, though we shall restrict
  attention to the special case of monotone increasing functions for the most part.
-/

namespace Chapter11

open BoundedInterval Chapter9

open Topology in
/-- If `f` is a filter, then `Filter.lim f` is a limit of the filter, if it exists. -/
noncomputable def Filter.lim  {X : Type*} [TopologicalSpace X] [Nonempty X] (f : Filter X) : X :=
  Classical.epsilon fun x => f ≤ 𝓝 x

/-- Left and right limits. A junk value is assigned if the limit does not exist. -/
noncomputable abbrev right_lim (f: ℝ → ℝ) (x₀:ℝ) : ℝ := Filter.lim ((nhdsWithin x₀ (.Ioi x₀)).map f)

noncomputable abbrev left_lim (f: ℝ → ℝ) (x₀:ℝ) : ℝ := Filter.lim ((nhdsWithin x₀ (.Iio x₀)).map f)

noncomputable abbrev jump (f: ℝ → ℝ) (x₀:ℝ) : ℝ :=
  right_lim f x₀ - left_lim f x₀

theorem jump_of_monotone {f: ℝ → ℝ} (x₀:ℝ) (hf: Monotone f) :
  0 ≤ jump f x₀  := by
  sorry

theorem right_lim_le_left_lim_of_monotone {f:ℝ → ℝ} {a b:ℝ} (hab: a < b)
  (hf: Monotone f) :
  right_lim f a ≤ left_lim f b := by
  sorry

/-- Definition 11.8.1 -/
noncomputable abbrev α_length (α: ℝ → ℝ) (I: BoundedInterval) : ℝ := match I with
| Icc a b => if a ≤ b then (right_lim α b) - (left_lim α a) else 0
| Ico a b => if a ≤ b then (left_lim α b) - (left_lim α a) else 0
| Ioc a b => if a ≤ b then (right_lim α b) - (right_lim α a) else 0
| Ioo a b => if a < b then (left_lim α b) - (right_lim α a) else 0

syntax:max term "[" term "]ₗ" : term
macro_rules | `($α[$I]ₗ) => `(α_length $α $I)

/-- Example 11.8.2-/
example : (fun x ↦ x^2)[Icc 2 3]ₗ = 5 := by
  sorry

example : (fun x ↦ x^2)[Icc 2 2]ₗ = 0 := by
  sorry

example : (fun x ↦ x^2)[Ioo 2 2]ₗ = 0 := by
  sorry

/-- Example 11.8.3-/
@[simp]
theorem α_len_of_id (I: BoundedInterval) : (fun x ↦ x)[I]ₗ = |I|ₗ := by
  sorry

/-- An improved version of `BoundedInterval.joins` that also controls `α_length`. -/
abbrev BoundedInterval.joins' (K I J: BoundedInterval) : Prop :=  K.joins I J ∧ ∀ α:ℝ → ℝ, α[K]ₗ = α[I]ₗ + α[J]ₗ

theorem BoundedInterval.join_Icc_Ioc' {a b c:ℝ} (hab: a ≤ b) (hbc: b ≤ c) : (Icc a c).joins' (Icc a b) (Ioc b c) := by
  sorry

theorem BoundedInterval.join_Icc_Ioo' {a b c:ℝ} (hab: a ≤ b) (hbc: b < c) : (Ico a c).joins' (Icc a b) (Ioo b c) := by
  sorry

theorem BoundedInterval.join_Ioc_Ioc' {a b c:ℝ} (hab: a ≤ b) (hbc: b ≤ c) : (Ioc a c).joins' (Ioc a b) (Ioc b c) := by
  sorry

theorem BoundedInterval.join_Ioc_Ioo' {a b c:ℝ} (hab: a ≤ b) (hbc: b < c) : (Ioo a c).joins' (Ioc a b) (Ioo b c) := by
  sorry

theorem BoundedInterval.join_Ico_Icc' {a b c:ℝ} (hab: a ≤ b) (hbc: b ≤ c) : (Icc a c).joins' (Ico a b) (Icc b c) := by
  sorry

theorem BoundedInterval.join_Ico_Ico' {a b c:ℝ} (hab: a ≤ b) (hbc: b ≤ c) : (Ico a c).joins' (Ico a b) (Ico b c) := by
  sorry

theorem BoundedInterval.join_Ioo_Icc' {a b c:ℝ} (hab: a < b) (hbc: b ≤ c) : (Ioc a c).joins' (Ioo a b) (Icc b c) := by
  sorry

theorem BoundedInterval.join_Ioo_Ico' {a b c:ℝ} (hab: a < b) (hbc: b ≤ c) : (Ioo a c).joins' (Ioo a b) (Ico b c) := by
  sorry

/-- Definition 11.8.5 (Piecewise constant RS integral)-/
noncomputable abbrev PiecewiseConstantWith.RS_integ (f:ℝ → ℝ) {I: BoundedInterval} (P: Partition I) (α: ℝ → ℝ)   :
  ℝ := ∑ J ∈ P.intervals, constant_value_on f (J:Set ℝ) * α[J]ₗ

/-- Example 11.8.6 -/
noncomputable abbrev f_11_8_6 (x:ℝ) : ℝ := if x < 2 then 4 else 2

noncomputable abbrev P_11_8_6 : Partition (Icc 1 3) :=
  (⊥: Partition (Ico 1 2)).join (⊥ : Partition (Icc 2 3))
  (join_Ico_Icc (by norm_num) (by norm_num) )

theorem f_11_8_6_RS_integ : PiecewiseConstantWith.RS_integ f_11_8_6 P_11_8_6 (fun x ↦ x) = 22 := by
  sorry

/-- Example 11.8.7 -/
theorem PiecewiseConstantWith.RS_integ_eq_integ {f:ℝ → ℝ} {I: BoundedInterval} (P: Partition I) :RS_integ f P (fun x ↦ x) = integ f P := by
  sorry

open Classical in
noncomputable abbrev PiecewiseConstantOn.RS_integ (f:ℝ → ℝ) (I: BoundedInterval) (α:ℝ → ℝ):
  ℝ := if h: PiecewiseConstantOn f I then PiecewiseConstantWith.RS_integ f h.choose α else 0

/-- `α_length` non-negative when α monotone -/
theorem α_length_nonneg_of_monotone {α:ℝ → ℝ}  (hα: Monotone α) (I: BoundedInterval):
  0 ≤ α[I]ₗ := by
  sorry

/-- Analogue of Theorem 11.2.16 (a) (Laws of integration) / Exercise 11.8.3 -/
theorem PiecewiseConstantOn.RS_integ_add {f g: ℝ → ℝ} {I: BoundedInterval}
  (hf: PiecewiseConstantOn f I) (hg: PiecewiseConstantOn g I) {α:ℝ → ℝ} (hα: Monotone α):
  RS_integ (f + g) I α = RS_integ f I α + RS_integ g I α := by
  sorry

/-- Analogue of Theorem 11.2.16 (b) (Laws of integration) / Exercise 11.8.3 -/
theorem PiecewiseConstantOn.RS_integ_smul {f: ℝ → ℝ} {I: BoundedInterval} (c:ℝ)
  (hf: PiecewiseConstantOn f I) {α:ℝ → ℝ} (hα: Monotone α) :
  RS_integ (c • f) I α = c * RS_integ f I α
   := by
  sorry

/-- Theorem 11.8.8 (c) (Laws of RS integration) / Exercise 11.8.8 -/
theorem PiecewiseConstantOn.RS_integ_sub {f g: ℝ → ℝ} {I: BoundedInterval}
  {α:ℝ → ℝ} (hα: Monotone α)
  (hf: PiecewiseConstantOn f I) (hg: PiecewiseConstantOn g I) :
  RS_integ (f - g) I α = RS_integ f I α - RS_integ g I α := by
  sorry

/-- Theorem 11.8.8 (d) (Laws of RS integration) / Exercise 11.8.8 -/
theorem PiecewiseConstantOn.RS_integ_of_nonneg {f: ℝ → ℝ} {I: BoundedInterval}
  {α:ℝ → ℝ} (hα: Monotone α)
  (h: ∀ x ∈ I, 0 ≤ f x) (hf: PiecewiseConstantOn f I) :
  0 ≤ RS_integ f I α := by
  sorry

/-- Theorem 11.8.8 (f) (Laws of RS integration) / Exercise 11.8.8 -/
theorem PiecewiseConstantOn.RS_integ_const' {f:ℝ → ℝ} {I: BoundedInterval}
  {α:ℝ → ℝ} (hα: Monotone α) (h: ConstantOn f I) :
  RS_integ f I α = (constant_value_on f I) * α[I]ₗ := by
  sorry

open Classical in
/-- Theorem 11.8.8 (g) (Laws of RS integration) / Exercise 11.8.8 -/
theorem PiecewiseConstantOn.RS_of_extend {I J: BoundedInterval} (hIJ: I ⊆ J)
  {f: ℝ → ℝ} (h: PiecewiseConstantOn f I) {α:ℝ → ℝ} (hα: Monotone α):
  PiecewiseConstantOn (fun x ↦ if x ∈ I then f x else 0) J := by
  sorry

open Classical in
/-- Theorem 11.8.8 (g) (Laws of RS integration) / Exercise 11.8.8 -/
theorem PiecewiseConstantOn.RS_integ_of_extend {I J: BoundedInterval} (hIJ: I ⊆ J)
  {f: ℝ → ℝ} (h: PiecewiseConstantOn f I) {α:ℝ → ℝ} (hα: Monotone α):
  RS_integ (fun x ↦ if x ∈ I then f x else 0) J α = RS_integ f I α := by
  sorry

/-- Theorem 11.8.8 (h) (Laws of RS integration) / Exercise 11.8.8 -/
theorem PiecewiseConstantOn.RS_integ_of_join {I J K: BoundedInterval} (hIJK: K.joins' I J)
  {f: ℝ → ℝ} (h: PiecewiseConstantOn f K) {α:ℝ → ℝ} (hα: Monotone α):
  RS_integ f K α = RS_integ f I α + RS_integ f J α := by
  sorry

/-- Analogue of Definition 11.3.2 (Uppper and lower Riemann integrals )-/
noncomputable abbrev upper_RS_integral (f:ℝ → ℝ) (I: BoundedInterval) (α: ℝ → ℝ): ℝ :=
  sInf ((PiecewiseConstantOn.RS_integ · I α) '' {g | MajorizesOn g f I ∧ PiecewiseConstantOn g I})

noncomputable abbrev lower_RS_integral (f:ℝ → ℝ) (I: BoundedInterval) (α: ℝ → ℝ): ℝ :=
  sSup ((PiecewiseConstantOn.RS_integ · I α) '' {g | MinorizesOn g f I ∧ PiecewiseConstantOn g I})

lemma le_lower_RS_integral {f:ℝ → ℝ} {I: BoundedInterval} {M:ℝ} (h: ∀ x ∈ (I:Set ℝ), |f x| ≤ M)
  {α:ℝ → ℝ} (hα: Monotone α) :
  -M * α[I]ₗ ≤ lower_RS_integral f I α := by
  sorry

lemma RS_upper_integral_le {f:ℝ → ℝ} {I: BoundedInterval} {M:ℝ} (h: ∀ x ∈ (I:Set ℝ), |f x| ≤ M)
  {α:ℝ → ℝ} (hα: Monotone α) :
  upper_RS_integral f I α ≤ M * α[I]ₗ := by
  sorry

/-- Analogue of Definition 11.3.4 -/
noncomputable abbrev RS_integ (f:ℝ → ℝ) (I: BoundedInterval) (α:ℝ → ℝ) : ℝ := upper_RS_integral f I α

noncomputable abbrev RS_IntegrableOn (f:ℝ → ℝ) (I: BoundedInterval) (α: ℝ → ℝ) : Prop :=
  BddOn f I ∧ lower_RS_integral f I α = upper_RS_integral f I α

/-- Analogue of various components of Lemma 11.3.3 -/
theorem upper_RS_integral_eq_upper_integral (f:ℝ → ℝ) (I: BoundedInterval) :
  upper_RS_integral f I (fun x ↦ x) = upper_integral f I := by
  sorry

theorem lower_RS_integral_eq_lower_integral (f:ℝ → ℝ) (I: BoundedInterval) :
  lower_RS_integral f I (fun x ↦ x) = lower_integral f I := by
  sorry

theorem RS_integ_eq_integ (f:ℝ → ℝ) (I: BoundedInterval) :
  RS_integ f I (fun x ↦ x) = integ f I := by
  sorry

theorem RS_IntegrableOn_iff_IntegrableOn (f:ℝ → ℝ) (I: BoundedInterval) :
  RS_IntegrableOn f I (fun x ↦ x) ↔ IntegrableOn f I := by
  sorry

/-- Exercise 11.8.4 -/
theorem RS_integ_of_uniform_cts {I: BoundedInterval} {f:ℝ → ℝ} (hf: UniformContinuousOn f I)
 {α:ℝ → ℝ} (hα: Monotone α):
  RS_IntegrableOn f I α := by
  sorry

/-- Exercise 11.8.5 -/
theorem RS_integ_with_sign (f:ℝ → ℝ) (hf: ContinuousOn f (.Icc (-1) 1)) : RS_IntegrableOn f (Icc (-1) 1) Real.sign ∧ RS_integ f (Icc (-1) 1) (fun x ↦ -Real.sign x) = 2 * f 0 := by
  sorry

/-- Analogue of Lemma 11.3.7 -/
theorem RS_integ_of_piecewise_const {f:ℝ → ℝ} {I: BoundedInterval} (hf: PiecewiseConstantOn f I)
  {α: ℝ → ℝ} (hα: Monotone α):
  RS_IntegrableOn f I α ∧ RS_integ f I α = PiecewiseConstantOn.RS_integ f I α := by
  sorry

end Chapter11
