import Mathlib

open Classical
open scoped BigOperators

-- 1. Define the main claim

/-- “Color-`col` monochromatic star of size `k`”: there is a center {given}`x` and a set
    {given (type := "Finset V")}`S` of `k` distinct neighbors of `x` such that every
    edge {given -show}`y` {lean}`s(x, y)` with {lean}`y ∈ S` is present in {lean}`G` and colored
    `col`.  (No restriction on edges inside `S`.) -/
def hasMonoStar {V:Type*} (G : SimpleGraph V) (color : Sym2 V → Fin 2)
    (col : Fin 2) (k : ℕ) : Prop :=
  ∃ (x : V) (S : Finset V),
    S.card = k ∧
    x ∉ S ∧
    ∀ ⦃y : V⦄, y ∈ S → G.Adj x y ∧ color (s(x, y)) = col

/--
{given -show}`a, b, c : V`
“Color-`col` monochromatic triangle”: there exist `a`, `b`, `c` with all three edges
present in {lean}`G` and colored `col`.  (Adjacency already forces distinctness.)
-/
def hasMonoTriangle {V:Type*} (G : SimpleGraph V) (color : Sym2 V → Fin 2)
    (col : Fin 2) : Prop :=
  ∃ a b c : V,
    G.Adj a b ∧ G.Adj b c ∧ G.Adj a c ∧
    color (s(a, b)) = col ∧
    color (s(b, c)) = col ∧
    color (s(a, c)) = col

/-- **Statement (n = 5 case of Pikhurko’s counterexample).**
There exists a simple graph on {lean}`16` vertices with exactly {lean}`44` edges such that
for *every* 2‑coloring of unordered pairs, either color {lean (type := "Fin 2")}`0` contains a $`K_{1,5}`
(a 5‑edge star) or color {lean (type := "Fin 2")}`1` contains a $`K₃` (a triangle).

This only *states* the claim (as a {lean}`Prop`).  You can later prove it from the
explicit construction, or assume it as an axiom while you develop the rest. -/
def Pikhurko_n5_statement : Prop :=
  ∃ (V:Type) (G : SimpleGraph V),
    G.edgeSet.ncard = 44 ∧
    ∀ (color : Sym2 V → Fin 2),
      hasMonoStar G color 0 5 ∨ hasMonoTriangle G color 1

-- 2. Construct the graph

namespace PikhurkoN5

/-- Vertex type with 2 + 5 + 3 + 5 + 1 = 16 vertices. -/
inductive V
| A1 (i : Fin 2)  -- the K₂ part of P_{2,5}
| B1 (j : Fin 5)  -- the independent part of P_{2,5}
| A2 (i : Fin 3)  -- the K₃ part of P_{3,5}
| B2 (j : Fin 5)  -- the independent part of P_{3,5}
| apex            -- the universal vertex
deriving DecidableEq, Repr

open V

/-- Adjacency relation for the Pikhurko n=5 counterexample.

* Inside `A1` and inside `A2`: cliques.
* Between `A1`–`B1` and `A2`–`B2`: complete bipartite.
* Inside `B1` and `B2`: no edges.
* No edges between the two blocks `A1`/`B1` and `A2`/`B2`.
* `apex` is connected to every non-`apex` vertex. -/
def GAdj : V → V → Prop
| apex, apex => False
| apex, _    => True
| _,    apex => True
| A1 i, A1 j => i ≠ j
| A2 i, A2 j => i ≠ j
| A1 _, B1 _ => True
| B1 _, A1 _ => True
| A2 _, B2 _ => True
| B2 _, A2 _ => True
| _,    _    => False

/-- The graph `G` on 16 vertices used for the n=5 counterexample. -/
def G : SimpleGraph V where
  Adj := GAdj
  symm := by
    intro u v h
    cases u <;> cases v <;> grind [GAdj]
  loopless := ⟨by intro v; cases v <;> simp [GAdj]⟩

/-!
Convenience simp lemmas. These are optional but help when you start proving
properties about colorings later on.
-/
@[simp] lemma adj_apex_left {v : V} : G.Adj V.apex v ↔ v ≠ V.apex := by
  sorry

@[simp] lemma adj_apex_right {v : V} : G.Adj v V.apex ↔ v ≠ V.apex := by
  sorry

@[simp] lemma adj_A1A1 {i j} : G.Adj (A1 i) (A1 j) ↔ i ≠ j := by
  sorry

@[simp] lemma adj_A2A2 {i j} : G.Adj (A2 i) (A2 j) ↔ i ≠ j := by
  sorry

@[simp] lemma adj_A1B1 {i j} : G.Adj (A1 i) (B1 j) := by
  sorry

@[simp] lemma adj_B1A1 {i j} : G.Adj (B1 i) (A1 j) := by
  sorry

@[simp] lemma adj_A2B2 {i j} : G.Adj (A2 i) (B2 j) := by
  sorry

@[simp] lemma adj_B2A2 {i j} : G.Adj (B2 j) (A2 i)  := by
  sorry

@[simp] lemma no_adj_B1B1 {j j'} : ¬ G.Adj (B1 j) (B1 j') := by
  sorry

@[simp] lemma no_adj_B2B2 {j j'} : ¬ G.Adj (B2 j) (B2 j') := by
  sorry

@[simp] lemma no_cross_blocks_A1B2 {i j} : ¬ G.Adj (A1 i) (B2 j) := by
  sorry

@[simp] lemma no_cross_blocks_A2B1 {i j} : ¬ G.Adj (A2 i) (B1 j) := by
  sorry

@[simp] lemma no_cross_blocks_B1A2 {i j} : ¬ G.Adj (B1 j) (A2 i)  := by
  sorry

@[simp] lemma no_cross_blocks_B1B2 {i j} : ¬ G.Adj (B1 j) (B2 i)  := by
  sorry

@[simp] lemma no_cross_blocks_A2A1 {i j} : ¬ G.Adj (A2 j) (A1 i)  := by
  sorry

end PikhurkoN5

-- 3.  Count edges

namespace PikhurkoN5

open V

/- We’ll need `Fintype` on `V` for `univ`, sums, etc. -/
deriving instance Fintype for V

/-- An explicit equivalence showing `V` has 2+5+3+5+1 = 16 elements. -/
def VEquiv :
    V ≃ ((((Fin 2 ⊕ Fin 5) ⊕ Fin 3) ⊕ Fin 5) ⊕ Unit) where
  toFun
  | A1 i  => Sum.inl (Sum.inl (Sum.inl (Sum.inl i)))
  | B1 j  => Sum.inl (Sum.inl (Sum.inl (Sum.inr j)))
  | A2 i  => Sum.inl (Sum.inl (Sum.inr i))
  | B2 j  => Sum.inl (Sum.inr j)
  | apex  => Sum.inr ()
  invFun
  | Sum.inl (Sum.inl (Sum.inl (Sum.inl i))) => A1 i
  | Sum.inl (Sum.inl (Sum.inl (Sum.inr j))) => B1 j
  | Sum.inl (Sum.inl (Sum.inr i))            => A2 i
  | Sum.inl (Sum.inr j)                      => B2 j
  | Sum.inr ()                               => apex
  left_inv v := by cases v <;> grind
  right_inv w := by cases w <;> grind

/-! # Degree computations

We compute the degree of each vertex *kind*. We’ll use your {attr}`@[simp]` adjacency
lemmas from Approach A:
- `adj_apex_left`, `adj_A1A1`, `adj_A2A2`, `adj_A1B1`, `adj_A2B2`,
  and the corresponding “no edge” lemmas across blocks.
-/

/-!
# Edge count via the handshaking lemma
We now sum the degrees and divide by 2.
-/
theorem edge_count_44 : G.edgeSet.ncard = 44 := by
  sorry

end PikhurkoN5

-- 4. Show red neighbors of apex are ≥ 11 if no blue K_{1,5}

namespace PikhurkoN5
open V

/-! # Small utilities -/

/- Pick a `k`-subset of a finset `s` when `k ≤ s.card`. -/
namespace Finset
variable {α : Type*}

end Finset

/-- In {lean}`Fin 2`, saying “equals {lean (type := "Fin 2")}`1`” is the same as “not equal to {lean (type := "Fin 2")}`0`”. -/
lemma fin2_eq_one_iff_ne_zero (a : Fin 2) : (a = 1) ↔ a ≠ 0 := by
  sorry

/-! # Red neighbors of the apex are ≥ 11 if there is no blue star `K_{1,5}` -/

/-- The set of blue neighbors of `apex` in color class {lean (type := "Fin 2")}`0`. -/
noncomputable def blueNeighbors (color : Sym2 V → Fin 2) : Finset V :=
  (G.neighborFinset apex).filter (fun v => color (s(apex, v)) = 0)

/-- The set of red neighbors of `apex` in color class {lean (type := "Fin 2")}`1`. -/
noncomputable def redNeighbors (color : Sym2 V → Fin 2) : Finset V :=
  (G.neighborFinset apex).filter (fun v => color (s(apex, v)) = 1)

end PikhurkoN5

-- 5. Pigeonhole: one block gets ≥ 6 red edges from apex
namespace PikhurkoN5
open V

/-- Membership in the first block `A1`/`B1`. -/
def inBlock1 : V → Prop
| A1 _ => True
| B1 _ => True
| _    => False

noncomputable instance : DecidablePred inBlock1 := by
  intro v; cases v <;> infer_instance

/-- Red neighbors of `apex` that lie in the first block `A1`/`B1`. -/
noncomputable def redBlock1 (color : Sym2 V → Fin 2) : Finset V :=
  (redNeighbors color).filter (fun v => inBlock1 v)

/-- Red neighbors of `apex` that lie in the second block `A2`/`B2`.

We implement this as the *complement* of `inBlock1` inside `redNeighbors`.
Since `apex` is not in `redNeighbors`, this is exactly the `A2`/`B2` part. -/
noncomputable def redBlock2 (color : Sym2 V → Fin 2) : Finset V :=
  (redNeighbors color).filter (fun v => ¬ inBlock1 v)

/-- **Pigeonhole step.** If there is no blue `K_{1,5}`, then
one of the two blocks receives at least six red edges from `apex`. -/
lemma exists_block_receives_at_least_6_red
    (color : Sym2 V → Fin 2)
    (hNoBlueStar : ¬ hasMonoStar G color 0 5) :
    (redBlock1 color).card ≥ 6 ∨ (redBlock2 color).card ≥ 6 := by
  sorry

end PikhurkoN5

-- 6. demonstrate a red neighbor in the clique side

namespace PikhurkoN5
open V

/-! # Part / block predicates -/

/-- Recognizes the clique side `A1`. -/
def isA1 : V → Prop
| A1 _ => True | _ => False

/-- Recognizes the independent side `B1`. -/
def isB1 : V → Prop
| B1 _ => True | _ => False

/-- Recognizes the clique side `A2`. -/
def isA2 : V → Prop
| A2 _ => True | _ => False

/-- Recognizes the independent side `B2`. -/
def isB2 : V → Prop
| B2 _ => True | _ => False

/-- Second block `A2`/`B2`. -/
def inBlock2 : V → Prop
| A2 _ => True | B2 _ => True | _ => False

noncomputable instance : DecidablePred isA1 := by intro v; cases v <;> infer_instance
noncomputable instance : DecidablePred isB1 := by intro v; cases v <;> infer_instance
noncomputable instance : DecidablePred isA2 := by intro v; cases v <;> infer_instance
noncomputable instance : DecidablePred isB2 := by intro v; cases v <;> infer_instance
noncomputable instance : DecidablePred inBlock1 := by intro v; cases v <;> infer_instance
noncomputable instance : DecidablePred inBlock2 := by intro v; cases v <;> infer_instance

@[simp] lemma inBlock1_iff (v : V) : inBlock1 v ↔ (isA1 v ∨ isB1 v) := by
  sorry

@[simp] lemma inBlock2_iff (v : V) : inBlock2 v ↔ (isA2 v ∨ isB2 v) := by
  sorry

@[simp] lemma not_isA1_and_isB1 (v : V) : ¬ (isA1 v ∧ isB1 v) := by
  sorry

@[simp] lemma not_isA2_and_isB2 (v : V) : ¬ (isA2 v ∧ isB2 v) := by
  sorry

/-! # Splitting the `apex` red neighbors by parts -/

-- These came from the previous step you have:
-- def redNeighbors (color : Sym2 V → Fin 2) : Finset V := ...

/-- Further refine `redBlock1` into its `A1` and `B1` parts. -/
noncomputable def redBlock1A1 (color : Sym2 V → Fin 2) : Finset V :=
  (redNeighbors color).filter (fun v => isA1 v)

noncomputable def redBlock1B1 (color : Sym2 V → Fin 2) : Finset V :=
  (redNeighbors color).filter (fun v => isB1 v)

/-- Further refine `redBlock2` into its `A2` and `B2` parts. -/
noncomputable def redBlock2A2 (color : Sym2 V → Fin 2) : Finset V :=
  (redNeighbors color).filter (fun v => isA2 v)

noncomputable def redBlock2B2 (color : Sym2 V → Fin 2) : Finset V :=
  (redNeighbors color).filter (fun v => isB2 v)

/-! # Bounding the {lit}`B`-parts by {lean}`5` -/

/-- All `B1`-vertices as a finset (image of {lean}`Fin 5`). -/
def B1Set : Finset V := (Finset.univ.image fun j : Fin 5 => B1 j)

/-- All `B2`-vertices as a finset (image of {lean}`Fin 5`). -/
def B2Set : Finset V := (Finset.univ.image fun j : Fin 5 => B2 j)

/-! # Existence of a red neighbor in the clique parts `A1` / `A2` -/

/-- Corollary: under the “no blue star” hypothesis, there is a red neighbor of `apex`
in the appropriate clique `A1` or `A2`. -/
lemma exists_red_clique_neighbor
    (color : Sym2 V → Fin 2)
    (hNoBlueStar : ¬ hasMonoStar G color 0 5) :
    (∃ i : Fin 2, G.Adj apex (A1 i) ∧ color (s(apex, A1 i)) = 1) ∨
    (∃ i : Fin 3, G.Adj apex (A2 i) ∧ color (s(apex, A2 i)) = 1) := by
  sorry

end PikhurkoN5

-- 7. triangle-or-star from the clique vertex

namespace PikhurkoN5
open V

/-! # Helpers: the chosen clique vertex lies in the corresponding red block -/

/-! # Triangle-or-star from Block 1 -/

/-! # Triangle-or-star from Block 2 (same proof pattern) -/

/-! # Final step: no blue `K_{1,5}` ⇒ a red triangle -/

/-- **Main step (n=5):** If there is no blue `K_{1,5}`, then the red color class contains a triangle. -/
theorem red_triangle_of_no_blue_star
    (color : Sym2 V → Fin 2)
    (hNoBlueStar : ¬ hasMonoStar G color 0 5) :
    hasMonoTriangle G color 1 := by
  sorry

end PikhurkoN5

-- Final statement

namespace PikhurkoN5

theorem main : Pikhurko_n5_statement := by
  sorry
