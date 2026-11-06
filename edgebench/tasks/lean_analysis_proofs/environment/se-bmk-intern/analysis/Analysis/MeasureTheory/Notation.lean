import Mathlib.Tactic

/-!
# Introduction to Measure Theory, Chapter 0: Notation

A companion to Chapter 0 of the book "An introduction to Measure Theory".

We use existing Mathlib constructions, such as `Set.indicator`, `EuclideanSpace`, `ENNReal`,
and `tsum` to describe the concepts defined in Chapter 0.

-/

/-- A version of `Set.indicator` suitable for this text. -/
noncomputable abbrev Set.indicator' {X: Type*} (E: Set X) := indicator E (fun _ ↦ (1:ℝ))

theorem Set.indicator'_of_mem {X: Type*} {E:Set X} {x:X} (h: x ∈ E) : indicator' E x = 1 := by
  sorry

theorem Set.indicator'_of_notMem {X: Type*} {E:Set X} {x:X} (h: x ∉ E) : indicator' E x = 0 := by
  sorry

/-- A version of `EuclideanSpace` suitable for this text. -/
noncomputable abbrev EuclideanSpace' (n: ℕ) := EuclideanSpace ℝ (Fin n)

abbrev EuclideanSpace'.equiv_Real : EuclideanSpace' 1 ≃ ℝ where
  toFun x := x ⟨ 0, by simp ⟩
  invFun x := .toLp 2 (fun _ ↦ x)
  left_inv x := by
    apply PiLp.ext; intro ⟨i, hi⟩; have : i = 0 := by omega
    subst this; rfl
  right_inv x := by rfl

abbrev Real.equiv_EuclideanSpace' : ℝ ≃ EuclideanSpace' 1 := EuclideanSpace'.equiv_Real.symm

instance EuclideanSpace'.inst_coeReal : Coe ℝ (EuclideanSpace' 1) := ⟨Real.equiv_EuclideanSpace'⟩

abbrev EuclideanSpace'.toReal (x: EuclideanSpace' 1) : ℝ := EuclideanSpace'.equiv_Real x
abbrev Real.toEuclideanSpace' (x: ℝ) : EuclideanSpace' 1 := Real.equiv_EuclideanSpace' x

infix:100 " ⬝ " => inner ℝ

theorem EuclideanSpace'.dot_apply {n:ℕ} (x y: EuclideanSpace' n) : x ⬝ y = ∑ i, (x i)*(y i) := by
  sorry

#check top_add
#check add_top
#check ENNReal.top_mul
#check ENNReal.mul_top
#check lt_top_iff_ne_top

def EuclideanSpace'.prod_equiv (d₁ d₂:ℕ) : EuclideanSpace' (d₁ + d₂) ≃ EuclideanSpace' d₁ × EuclideanSpace' d₂ where
  toFun x :=
    (.toLp 2 (fun ⟨i, hi⟩ => x ⟨i, by omega⟩),
     .toLp 2 (fun ⟨i, hi⟩ => x ⟨i + d₁, by omega⟩))
  invFun x := .toLp 2 (fun ⟨i, hi⟩ =>
    if h : i < d₁ then x.1 ⟨i, h⟩ else x.2 ⟨i - d₁, by omega⟩)
  left_inv x := by
    apply PiLp.ext; intro ⟨i, hi⟩
    simp only
    split
    · rfl
    next h =>
      have := Nat.sub_add_cancel (Nat.not_lt.mp h)
      simp only [this]
  right_inv x := by
    ext ⟨i, hi⟩
    · simp [dif_pos hi]
    · simp [show ¬(i + d₁ < d₁) by omega]

def EuclideanSpace'.prod {d₁ d₂:ℕ} (E₁: Set (EuclideanSpace' d₁)) (E₂: Set (EuclideanSpace' d₂)) : Set (EuclideanSpace' (d₁+d₂)) := (EuclideanSpace'.prod_equiv d₁ d₂).symm '' (E₁ ×ˢ E₂)

open Filter

theorem ENNReal.upward_continuous {x y:ℕ → ENNReal} (hx: Monotone x) (hy: Monotone y)
 {x₀ y₀ : ENNReal} (hx_lim: atTop.Tendsto x (nhds x₀))
 (hy_lim: atTop.Tendsto y (nhds y₀)) :
  atTop.Tendsto (fun n ↦ x n * y n) (nhds (x₀ * y₀)) := by
  sorry

example : ∃ (x y:ℕ → ENNReal) (_hx: Antitone x) (_hy: Antitone y)
 (x₀ y₀:ENNReal) (_hx_lim: atTop.Tendsto x (nhds x₀))
 (_hy_lim: atTop.Tendsto y (nhds y₀)), ¬ atTop.Tendsto (fun n ↦ x n * y n) (nhds (x₀ * y₀)) := by
  sorry

#check ENNReal.tendsto_nat_tsum

#check ENNReal.tsum_eq_iSup_sum

#check Equiv.tsum_eq

/-- Exercise 0.0.1 -/
example {A:Type} {x : A → ENNReal} (hx: ∑' α, x α < ⊤) :
  ∃ E: Set A, Countable E ∧ ∀ α ∉ E, x α = 0 := by
  sorry

/-- Theorem 0.0.2 -/
theorem ENNReal.tsum_of_tsum' (x: ℕ → ℕ → ENNReal) : ∑' p:ℕ × ℕ, x p.1 p.2 = ∑' m, ∑' n, x n m := by
  sorry

#check ENNReal.tsum_comm

/-- Exercise 0.0.2 (Tonelli's theorem for series over arbitrary sets)-/
example {A B:Type*} (x: A → B → ENNReal) : ∑' p:A × B, x p.1 p.2 = ∑' a, ∑' b, x a b := by
  sorry

example {A B:Type*} (x: A → B → ENNReal) : ∑' p:A × B, x p.1 p.2 = ∑' b, ∑' a, x a b := by
  sorry

noncomputable instance EReal.inst_posPart : PosPart EReal where
  posPart := fun x ↦ if x ≥ 0 then x else 0

noncomputable instance EReal.inst_negPart : NegPart EReal where
  negPart := fun x ↦ if x ≤ 0 then -x else 0

/-- Axiom 0.0.4 (Axiom of choice)-/
noncomputable def Set.choose {A: Type*} {E: A → Type*} (hE: ∀ n, Nonempty (E n)) :
∀ n, E n := fun n ↦ (hE n).some

/-- Corollary 0.0.5 (Axiom of countable choice) -/
noncomputable def Countable.choose {E: ℕ → Type*} (hE: ∀ n, Nonempty (E n)) :
∀ n, E n := Set.choose hE
