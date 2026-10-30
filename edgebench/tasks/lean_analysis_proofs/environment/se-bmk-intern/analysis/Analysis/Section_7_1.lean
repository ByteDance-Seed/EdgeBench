import Mathlib.Tactic

set_option doc.verso.suggestions false

/-!
# Analysis I, Section 7.1: Finite series

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Technical note: it is convenient in Lean to extend finite sequences (usually by zero) to be
functions on the entire integers.

Main constructions and results of this section:
-/

-- This makes available the convenient notation `∑ n ∈ A, f n` to denote summation of `f n` for
-- `n` ranging over a finite set `A`.
open BigOperators

/-!
- API for summation over finite sets (encoded using Mathlib's `Finset` type), using the
  `Finset.sum` method and the `∑ n ∈ A, f n` notation.
- Fubini's theorem for finite series

We do not attempt to replicate the full API for `Finset.sum` here, but in subsequent sections we
shall make liberal use of this API.

-/

-- This is a technical device to avoid Mathlib's insistence on decidable equality for finite sets.
open Classical

namespace Finset

-- We use `Finset.Icc` to describe finite intervals in the integers. `Finset.mem_Icc` is the
-- standard Mathlib tool for checking membership in such intervals.
#check mem_Icc

/-- Definition 7.1.1 -/
theorem sum_of_empty {n m:ℤ} (h: n < m) (a: ℤ → ℝ) : ∑ i ∈ Icc m n, a i = 0 := by
  sorry

example (a: ℤ → ℝ) (m:ℤ) : ∑ i ∈ Icc m (m-2), a i = 0 := by
  sorry

example (a: ℤ → ℝ) (m:ℤ) : ∑ i ∈ Icc m (m-1), a i = 0 := by
  sorry

example (a: ℤ → ℝ) (m:ℤ) : ∑ i ∈ Icc m m, a i = a m := by
  sorry

example (a: ℤ → ℝ) (m:ℤ) : ∑ i ∈ Icc m (m+1), a i = a m + a (m+1) := by
  sorry

example (a: ℤ → ℝ) (m:ℤ) : ∑ i ∈ Icc m (m+2), a i = a m + a (m+1) + a (m+2) := by
  sorry

/-- Remark 7.1.3 -/
example (a: ℤ → ℝ) (m n:ℤ) : ∑ i ∈ Icc m n, a i = ∑ j ∈ Icc m n, a j := by
  sorry

/-- Lemma 7.1.4(c) / Exercise 7.1.1 -/
theorem finite_series_add {m n:ℤ} (a b: ℤ → ℝ) :
  ∑ i ∈ Icc m n, (a i + b i) = ∑ i ∈ Icc m n, a i + ∑ i ∈ Icc m n, b i := by
  sorry

/-- Lemma 7.1.4(d) / Exercise 7.1.1 -/
theorem finite_series_const_mul {m n:ℤ} (a: ℤ → ℝ) (c:ℝ) :
  ∑ i ∈ Icc m n, c * a i = c * ∑ i ∈ Icc m n, a i := by
  sorry

/-- Lemma 7.1.4(e) / Exercise 7.1.1 -/
theorem abs_finite_series_le {m n:ℤ} (a: ℤ → ℝ) :
  |∑ i ∈ Icc m n, a i| ≤ ∑ i ∈ Icc m n, |a i| := by
  sorry

/-- Lemma 7.1.4(f) / Exercise 7.1.1 -/
theorem finite_series_of_le {m n:ℤ}  {a b: ℤ → ℝ} (h: ∀ i, m ≤ i → i ≤ n → a i ≤ b i) :
  ∑ i ∈ Icc m n, a i ≤ ∑ i ∈ Icc m n, b i := by
  sorry

#check sum_congr

set_option maxHeartbeats 210000 in
/--
  Proposition 7.1.8.
-/
theorem finite_series_of_rearrange {n:ℕ} {X':Type*} (X: Finset X') (hcard: X.card = n)
  (f: X' → ℝ) (g h: Icc (1:ℤ) n → X) (hg: Function.Bijective g) (hh: Function.Bijective h) :
    ∑ i ∈ Icc (1:ℤ) n, (if hi:i ∈ Icc (1:ℤ) n then f (g ⟨ i, hi ⟩) else 0)
    = ∑ i ∈ Icc (1:ℤ) n, (if hi: i ∈ Icc (1:ℤ) n then f (h ⟨ i, hi ⟩) else 0) := by
  sorry

/--
  This fact ensures that Definition 7.1.6 would be well-defined even if we did not appeal to the
  existing `Finset.sum` method.
-/
theorem exist_bijection {n:ℕ} {Y:Type*} (X: Finset Y) (hcard: X.card = n) :
    ∃ g: Icc (1:ℤ) n → X, Function.Bijective g := by
  sorry

/-- Definition 7.1.6 -/
theorem finite_series_eq {n:ℕ} {Y:Type*} (X: Finset Y) (f: Y → ℝ) (g: Icc (1:ℤ) n → X)
  (hg: Function.Bijective g) :
    ∑ i ∈ X, f i = ∑ i ∈ Icc (1:ℤ) n, (if hi:i ∈ Icc (1:ℤ) n then f (g ⟨ i, hi ⟩) else 0) := by
  sorry

/-- Proposition 7.1.11(a) / Exercise 7.1.2 -/
theorem finite_series_of_empty {X':Type*} (f: X' → ℝ) : ∑ i ∈ ∅, f i = 0 := by
  sorry

-- Proposition 7.1.11(d) is `rfl` in our formalism and is therefore omitted.

/-- Proposition 7.1.11(f) / Exercise 7.1.2 -/
theorem finite_series_of_add {X':Type*} (f g: X' → ℝ) (X: Finset X') :
    ∑ x ∈ X, (f + g) x = ∑ x ∈ X, f x + ∑ x ∈ X, g x := by
  sorry

/-- Proposition 7.1.11(g) / Exercise 7.1.2 -/
theorem finite_series_of_const_mul {X':Type*} (f: X' → ℝ) (X: Finset X') (c:ℝ) :
    ∑ x ∈ X, c * f x = c * ∑ x ∈ X, f x := by
  sorry

/-- Proposition 7.1.11(h) / Exercise 7.1.2 -/
theorem finite_series_of_le' {X':Type*} (f g: X' → ℝ) (X: Finset X') (h: ∀ x ∈ X, f x ≤ g x) :
    ∑ x ∈ X, f x ≤ ∑ x ∈ X, g x := by
  sorry

/-- Proposition 7.1.11(i) / Exercise 7.1.2 -/
theorem abs_finite_series_le' {X':Type*} (f: X' → ℝ) (X: Finset X') :
    |∑ x ∈ X, f x| ≤ ∑ x ∈ X, |f x| := by
  sorry

theorem finite_series_comm {XX YY:Type*} (X: Finset XX) (Y: Finset YY) (f: XX × YY → ℝ) :
    ∑ x ∈ X, ∑ y ∈ Y, f (x, y) = ∑ y ∈ Y, ∑ x ∈ X, f (x, y) := by
  sorry

-- Exercise 7.1.3 : develop as many analogues as you can of the above theory for finite products
-- instead of finite sums.

#check Nat.factorial_zero
#check Nat.factorial_succ

/--
  Exercise 7.1.4. Note: there may be some technicalities passing back and forth between natural
  numbers and integers. Look into the tactics {tactic}`zify`, {tactic}`norm_cast`, and {tactic}`omega`
-/
theorem binomial_theorem (x y:ℝ) (n:ℕ) :
    (x + y)^n
    = ∑ j ∈ Icc (0:ℤ) n,
    n.factorial / (j.toNat.factorial * (n-j).toNat.factorial) * x^j * y^(n - j) := by
  sorry

/-- Exercise 7.1.5 -/
theorem lim_of_finite_series {X:Type*} [Fintype X] (a: X → ℕ → ℝ) (L : X → ℝ)
  (h: ∀ x, Filter.atTop.Tendsto (a x) (nhds (L x))) :
    Filter.atTop.Tendsto (fun n ↦ ∑ x, a x n) (nhds (∑ x, L x)) := by
  sorry

/-- Exercise 7.1.6 -/
theorem sum_union_disjoint {n : ℕ} {S : Type*} [Fintype S]
    (E : Fin n → Finset S)
    (disj : ∀ i j : Fin n, i ≠ j → Disjoint (E i) (E j))
    (cover : ∀ s : S, ∃ i, s ∈ E i)
    (f : S → ℝ) :
    ∑ s, f s = ∑ i, ∑ s ∈ E i, f s := by
  sorry

/-- {given}`aᵢ` Exercise 7.1.7. Uses {lean}`Fin m` (so {lean}`aᵢ < m`) instead of the book's {lean}`aᵢ ≤ m`;
  the bound is baked into the type, and {kw (of := «term_<_»)}`<` replaces {kw (of := «term_≤_»)}`≤` to match the 0-indexed shift. -/
theorem sum_finite_col_row_counts {n m : ℕ} (a : Fin n → Fin m) :
    ∑ i, (a i : ℕ) = ∑ j : Fin m, {i : Fin n | j < a i}.toFinset.card := by
  sorry

end Finset
