import Mathlib

/-! Formalizing a proof (the prime case of) Erdos problem \#707 recently proven by Alexeev, ChatGPT, Lean, and Mixon at https://borisalexeev.com/papers/erdos707.html, following Theorem 8 proven on page 5 -/

/-- A perfect difference set is a set where every nonzero element is uniquely representable as a difference of two elements of the set. -/
def IsPerfectDifferenceSet {N: ℕ} (B: Finset (ZMod N)) := ∀ d: ZMod N, d ≠ 0 → ∃! b: B × B, b.1.val - b.2.val = d

def IsPerfectDifferenceSet.map {N: ℕ} (B: Finset (ZMod N)) (p: (B × B) ⊕ Unit) : ZMod N ⊕ B := match p with
| Sum.inl p => if p.1 = p.2 then Sum.inr p.1 else Sum.inl (p.1.val - p.2.val)
| Sum.inr _ => Sum.inl 0

namespace Mainstep

/-- We will show that the following hypotheses are inconsistent; this is the bulk of the proof of Theorem 8. -/
class Hypotheses where
  p : ℕ
  hp : Nat.Prime p
  N : ℕ
  hN : N = p^2 + p + 1
  B: Finset (ZMod N)
  hdiff: IsPerfectDifferenceSet B
  embed : ({1,2,4,8}: Finset ℕ) → B
  h_embed : ∀ n, (embed n).val = n
  h_inj : Function.Injective embed

export Hypotheses (p hp N  hN B hdiff embed h_embed h_inj)

variable [Hypotheses]

lemma h1 : 1 ∈ B := by
  sorry

lemma h2 : 2 ∈ B := by
  sorry

lemma h4 : 4 ∈ B := by
  sorry

lemma h8 : 8 ∈ B := by
  sorry

lemma odd_P : Odd p := by
  sorry

/--
{given -show}`b, c, d`
Given a perfect difference set `B` and an element `a` not in `B`, the function
{lean}`f (a := a)` maps each {lean}`b ∈ B` to the unique {lean}`c ∈ B` such that {lean}`a - b = c -
d` for some {lean}`d ∈ B`.
-/
noncomputable def f {a:ZMod N} (ha: a ∉ B) (b:B): B :=
    (hdiff (a-b.val) (by grind)).choose.1

/--
{given -show}`d`
Though not defined in Theorem 8, it is convenient to also introduce the companion function {lean}`g (a := a)`, defined to be the `d` element such that {lean}`a - b = f (a := a) ha b - d`.
-/
noncomputable def g {a:ZMod N} (ha: a ∉ B) (b:B): B :=
    (hdiff (a-b.val) (by grind)).choose.2

/-- {lean}`f (a := a)` is an involution. -/
lemma f_inv {a:ZMod N} (ha: a ∉ B) : Function.Involutive (f ha) := by
  sorry

noncomputable def z2_vact {a:ZMod N} (ha: a ∉ B) : AddAction (ZMod 2) B :=
{
  vadd i b := if i=1 then f ha b else b
  zero_vadd b := by
    change (if (0: ZMod 2) = 1 then f ha b else b) = b
    simp
  add_vadd i j b := by
    change (if i + j = 1 then f ha b else b) = if i = 1 then f ha (if j = 1 then f ha b else b) else (if j = 1 then f ha b else b)
    fin_cases i <;> fin_cases j <;> dsimp only <;> first | rfl | exact (f_inv ha b).symm
}

lemma two_mul_sub_one_notin {x:B} (hx: x.val ≠ 2) : 2 * (x.val - 1) ∉ B := by
  sorry

lemma second_fixed {x:B} (hx: x.val ≠ 2) : ∃ b, b ≠ x ∧ f (two_mul_sub_one_notin hx) b = b := by
  sorry

noncomputable def b (x:B) := if hx: x.val = 2 then ⟨ 2, h2 ⟩ else (second_fixed hx).choose

noncomputable def d (x:B) := if hx: x.val = 2 then ⟨ 2, h2 ⟩ else g (two_mul_sub_one_notin hx) (second_fixed hx).choose

lemma b_neq {x:B} (hx: x.val ≠ 2) : b x ≠ x := by
  sorry

lemma bd_ident (x:B) : 2 * (b x).val = 2 * (x.val - 1) + (d x).val := by
  sorry

lemma d_injective : Function.Injective d := by
  sorry

lemma d_surjective : Function.Surjective d := by
  sorry

lemma d1_eq_4 : d ⟨ 1, h1 ⟩ = ⟨ 4, h4 ⟩ := by
  sorry

lemma d1_eq_8 : d ⟨ 1, h1 ⟩ = ⟨ 8, h8 ⟩ := by
  sorry

lemma contradiction : False := by
  sorry

end Mainstep
