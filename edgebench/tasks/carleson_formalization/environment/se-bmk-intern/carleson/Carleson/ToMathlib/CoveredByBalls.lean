module

public import Carleson.ToMathlib.Misc

@[expose] public section

-- Upstreaming status: ready to go; two lemmas need to move to different files
-- and the remainder could go into a new file

open Metric Finset
open scoped NNReal

variable {X : Type*} [PseudoMetricSpace X]
  {s t : Set X} {n m : ℕ} {r r' r₁ r₂ r₃ : ℝ}

set_option linter.unusedVariables false in
/-- `s` can be covered by at most `N` balls with radius `r`. -/
@[mk_iff]
class inductive CoveredByBalls (s : Set X) (n : ℕ) (r : ℝ) : Prop where
  | mk (balls : Finset X)
    (card_balls : balls.card ≤ n)
    (union_balls : s ⊆ ⋃ x ∈ balls, ball x r) : CoveredByBalls s n r

namespace CoveredByBalls

/- Good first project: prove the following basic properties about `CoveredByBalls`.
Feel free to state some more properties. -/

lemma mono_set (h : CoveredByBalls t n r) (h2 : s ⊆ t) : CoveredByBalls s n r := by
  sorry

lemma mono_nat (h : CoveredByBalls s n r) (h2 : n ≤ m) : CoveredByBalls s m r := by
  sorry

lemma mono_real (h : CoveredByBalls s n r) (h2 : r ≤ r') :
    CoveredByBalls s n r' := by
  sorry

@[simp]
protected lemma empty : CoveredByBalls (∅ : Set X) n r := by
  sorry

@[simp]
lemma zero_left : CoveredByBalls s 0 r ↔ s = ∅ := by
  sorry

@[simp]
lemma zero_right : CoveredByBalls s n 0 ↔ s = ∅ := by
  sorry

protected lemma ball (x : X) (r : ℝ) : CoveredByBalls (ball x r) 1 r := by
  sorry

end CoveredByBalls

variable (X) in
/-- Balls of radius `r` in `X` are covered by `n` balls of radius `r'` -/
def BallsCoverBalls (r r' : ℝ) (n : ℕ) : Prop := ∀ x : X, CoveredByBalls (ball x r) n r'

lemma CoveredByBalls.trans (h : CoveredByBalls s n r)
    (h2 : BallsCoverBalls X r r' m) : CoveredByBalls s (n * m) r' := by
  sorry

namespace BallsCoverBalls

lemma mono (h : BallsCoverBalls X r₂ r₃ n) (h2 : r₁ ≤ r₂) :
    BallsCoverBalls X r₁ r₃ n := by
  sorry

lemma trans (h1 : BallsCoverBalls X r₁ r₂ n) (h2 : BallsCoverBalls X r₂ r₃ m) :
    BallsCoverBalls X r₁ r₃ (n * m) := by
  sorry

lemma zero : BallsCoverBalls X 0 r n := by
  sorry

lemma nonpos (hr' : r' ≤ 0) : BallsCoverBalls X r' r n := by
  sorry

end BallsCoverBalls

variable (X) in
/-- For all `r`, balls of radius `r` in `X` are covered by `n` balls of radius `a * r` -/
def AllBallsCoverBalls (a : ℝ) (n : ℕ) : Prop := ∀ r : ℝ, BallsCoverBalls X (a * r) r n

namespace AllBallsCoverBalls

/-- Prove `AllBallsCoverBalls` only for balls of positive radius. -/
lemma mk {a : ℝ} (ha : 0 ≤ a) (h : ∀ r > 0, BallsCoverBalls X (a * r) r n) :
    AllBallsCoverBalls X a n := by
  sorry

lemma pow {a : ℝ} {k : ℕ} (h : AllBallsCoverBalls X a n) :
    AllBallsCoverBalls X (a ^ k) (n ^ k) := by
  sorry

lemma ballsCoverBalls_pow {a : ℝ} {k : ℕ} (h : AllBallsCoverBalls X a n) :
    BallsCoverBalls X (a ^ k) 1 (n ^ k) := by
  sorry

lemma ballsCoverBalls {a : ℝ} (h : AllBallsCoverBalls X a n)
    (h2 : 1 < a) (hr : 0 < r) :
    BallsCoverBalls X r' r (n ^ ⌈Real.logb a (r' / r)⌉₊) := by
  sorry

end AllBallsCoverBalls

-- todo: move near `secondCountable_of_almost_dense_set`
/-- A pseudometric space is second countable if, for every `ε > 0` and every ball `B`
with natural number radius around a given point `x₀`,
there is a countable set which is `ε`-dense in `B`. -/
theorem Metric.secondCountableTopology_of_almost_dense_set_balls_nat
    {α} [PseudoMetricSpace α] (x₀ : α)
    (H : ∀ ε > (0 : ℝ), ∀ (n : ℕ),
    ∃ s : Set α, s.Countable ∧ ∀ x ∈ ball x₀ n, ∃ y ∈ s, dist x y ≤ ε) :
    SecondCountableTopology α := by
  sorry

-- todo: move near `secondCountable_of_almost_dense_set`
/-- A pseudometric space is second countable if, for every `ε > 0` and every ball `B`,
there is a countable set which is `ε`-dense in `B`. -/
theorem Metric.secondCountableTopology_of_almost_dense_set_balls
    {α} [PseudoMetricSpace α]
    (H : ∀ (x₀ : α), ∀ ε > (0 : ℝ), ∀ r,
    ∃ s : Set α, s.Countable ∧ ∀ x ∈ ball x₀ r, ∃ y ∈ s, dist x y ≤ ε) :
    SecondCountableTopology α := by
  sorry

/-- A pseudometric space is second countable if, for every `ε > 0` and every ball `B` is covered
by finitely many balls of radius `ε`. -/
theorem BallsCoverBalls.secondCountableTopology
    (H : ∀ ε > (0 : ℝ), ∀ r, ∃ n, BallsCoverBalls X r ε n) :
    SecondCountableTopology X := by
  sorry

/-- A pseudometric space is second countable if every ball of radius `a * r` is covered by
`b` many balls of radius `r`. -/
lemma AllBallsCoverBalls.secondCountableTopology {a : ℝ} (h : AllBallsCoverBalls X a n)
    (h2 : 1 < a) : SecondCountableTopology X := by
  sorry
