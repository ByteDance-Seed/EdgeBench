/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu, Violeta Hernández Palacios, Yuyang Zhao
-/
module

public import CombinatorialGames.Game.Player
public import Mathlib.Data.QPF.Univariate.Basic

import Mathlib.Logic.Small.Set

/-!
# Game functor

The type of games `IGame` is an inductive type, with a single constructor `ofSets` taking in two
small sets of games (one for each player) and outputting a new game. This suggests the definition:

```
inductive IGame : Type (u + 1)
  | ofSets (st : Player → Set IGame) [∀ p, Small.{u} (st p)] : IGame.{u}
```

However, the kernel does not accept this, as `Set IGame = IGame → Prop` contains a non-positive
occurence of `IGame` (see [counterexamples.org](https://counterexamples.org/strict-positivity.html)
for an explanation of what this is and why it's disallowed). We can get around this technical
limitation using the machinery of `QPF`s (quotients of polynomial functors). We define a functor
`GameFunctor` by

```
def GameFunctor (α : Type (u + 1)) : Type (u + 1) :=
  {st : Player → Set α // Small.{u} (st left) ∧ Small.{u} (st right)}
```

We can prove that this is a `QPF`, which then allows us to build its initial algebra through
`QPF.Fix`, which is exactly the inductive type `IGame`. As a bonus, we're able to describe the
coinductive type of loopy games `LGame` as the final coalgebra `QPF.Cofix` of the exact same
functor.
-/

universe u

@[expose] public section

/-! ### Game Functor -/

/-- The functor from a type into the subtype of small pairs of sets in that type.

This is the quotient of a polynomial functor. The type `IGame` of well-founded games is defined as
the initial algebra of that `QPF`, while the type `LGame` of loopy games is defined as its final
coalgebra.

In other words, `IGame` and `LGame` have the following descriptions (which don't work verbatim due
to various Lean limitations):

```
inductive IGame : Type (u + 1)
  | ofSets (st : Player → Set IGame) [∀ p, Small.{u} (st p)] : IGame.{u}

coinductive LGame : Type (u + 1)
  | ofSets (st : Player → Set IGame) [∀ p, Small.{u} (st p)] : LGame.{u}
```
-/
def GameFunctor (α : Type (u + 1)) : Type (u + 1) :=
  {s : Player → Set α // ∀ p, Small.{u} (s p)}

namespace GameFunctor

@[ext] theorem ext {α : Type (u + 1)} {x y : GameFunctor α} : x.1 = y.1 → x = y := by
  sorry

instance {α : Type (u + 1)} (x : GameFunctor α) (p : Player) : Small.{u} (x.1 p) := x.2 p

instance : Functor GameFunctor where
  map f s := ⟨(f '' s.1 ·), fun _ ↦ by infer_instance⟩

theorem map_def {α β} (f : α → β) (s : GameFunctor α) :
    f <$> s = ⟨(f '' s.1 ·), fun _ ↦ by infer_instance⟩ := by
  sorry

noncomputable instance : QPF GameFunctor where
  P := ⟨Player → Type u, fun x ↦ Σ p, PLift (x p)⟩
  abs x := ⟨fun p ↦ Set.range (x.2 ∘ .mk p ∘ PLift.up), fun _ ↦ by infer_instance⟩
  repr x := ⟨fun p ↦ Shrink (x.1 p), Sigma.rec (fun _ y ↦ ((equivShrink _).symm y.1).1)⟩
  abs_repr x := by ext; simp [← (equivShrink _).exists_congr_right]
  abs_map f := by intro ⟨x, f⟩; ext; simp [PFunctor.map, map_def]

end GameFunctor
