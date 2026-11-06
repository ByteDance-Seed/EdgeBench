/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu, Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Player
public import Mathlib.Algebra.BigOperators.Group.Multiset.Defs
public import Mathlib.Algebra.Group.Pointwise.Set.Small

import CombinatorialGames.Game.Functor
import CombinatorialGames.Mathlib.Small
import Mathlib.Algebra.BigOperators.Group.Multiset.Basic
import Mathlib.Algebra.Ring.Defs
import Mathlib.Data.Countable.Small

/-!
# Loopy games

The standard notion of a game studied in combinatorial game theory is that of a terminating game,
meaning that there exists no infinite sequence of moves. Loopy games relax this condition by
allowing "self-refential" games, with the basic examples being `on = {on | }`, `off = { | off}`, and
`dud = {dud | dud}`.

In the literature, loopy games are defined as rooted directed graphs up to isomorphism. However,
it's simpler to define `LGame` as the coinductive type for the single constructor:

```
  | ofSets (st : Player → Set LGame.{u}) [∀ p, Small.{u} (st p)] : LGame.{u}
```

(The inductive type for this same constructor would be `IGame`.) This gives us a powerful
corecursion principle `LGame.corec`, which can be interpreted as saying "for any graph we can draw
on a type `α`, as long as the amount of branches per node is `u`-small, there's an `LGame`
isomorphic to it".

Although extensionality still holds, it's not always sufficient to prove two games equal. For
instance, if `x = !{x | x}` and `y = !{y | y}`, then `x = y`, but trying to use extensionality to
prove this just leads to a cyclic argument. Instead, we can use `LGame.eq_of_bisim`, which can
roughly be interpreted as saying "if two games have the same shape, they're equal". In this case,
the relation `r a b ↔ a = x ∧ b = y` is a bisimulation between both games, which proves their
equality.
-/

open Set

universe u v w

variable {α : Type v} {β : Type w}

/-! ### For Mathlib -/

theorem Set.forall_mem_union {P : α → Prop} {s t : Set α} :
    (∀ x ∈ s ∪ t, P x) ↔ (∀ x ∈ s, P x) ∧ (∀ x ∈ t, P x) := by
  sorry

-- This is problematic as an instance.
theorem small_succ' (α : Type u) [Small.{v} α] : Small.{v + 1} α := by
  sorry

-- TODO: PR to Mathlib, together with the analogous `QPF.Fix.unique`.
theorem QPF.Cofix.unique {F : Type u → Type u} [QPF F] {α : Type u}
    (a : α → F α) (f g : α → QPF.Cofix F)
    (hf : QPF.Cofix.dest ∘ f = Functor.map f ∘ a)
    (hg : QPF.Cofix.dest ∘ g = Functor.map g ∘ a) : f = g := by
  sorry

public noncomputable section

/-! ### Game moves -/

/-- The type of loopy games.

Most games studied within game theory are terminating, which means that the `Subposition` relation
is well-founded. A loopy game relaxes this constraint. Thus, `LGame` contains all normal `IGame`s,
but it also contains games such as `on = {on | }`, `off = { | off}`, and `dud = {dud | dud}`.

See the module docstring for guidance on how to make use of this type. -/
def LGame := QPF.Cofix GameFunctor

namespace LGame
export Player (left right)

instance : DecidableEq LGame := Classical.decEq _

/-- The set of moves of the game. -/
def moves (p : Player) (x : LGame.{u}) : Set LGame.{u} := x.dest.1 p

/-- The set of left moves of the game. -/
scoped notation:max x:max "ᴸ" => moves left x

/-- The set of right moves of the game. -/
scoped notation:max x:max "ᴿ" => moves right x

instance small_moves (p : Player) (x : LGame.{u}) : Small.{u} (x.moves p) := x.dest.2 p

/-- A (proper) subposition is any game reachable a nonempty sequence of
(not necessarily alternating) left and right moves. -/
def Subposition : LGame → LGame → Prop :=
  Relation.TransGen fun a b => a ∈ ⋃ p, b.moves p

@[aesop unsafe apply 50%]
theorem Subposition.of_mem_moves {p} {x y : LGame} (h : x ∈ y.moves p) : Subposition x y := by
  sorry

theorem Subposition.trans {x y z : LGame} (h₁ : Subposition x y) (h₂ : Subposition y z) :
    Subposition x z := by
  sorry

instance (x : LGame.{u}) : Small.{u} {y // Subposition y x} :=
  small_transGen' _ x

@[elab_as_elim]
theorem Subposition.head_induction {y : LGame} {motive : (x : LGame) → Subposition x y → Prop}
    (of_mem_moves : ∀ p x hx, motive x (@Subposition.of_mem_moves p x y hx))
    (trans : ∀ p x z hx hz, motive z hz →
      motive x (.trans (@Subposition.of_mem_moves p x z hx) hz))
    (x : LGame) (hx : Subposition x y) : motive x hx := by
  sorry

@[elab_as_elim]
theorem Subposition.tail_induction {x : LGame} {motive : (y : LGame) → Subposition x y → Prop}
    (of_mem_moves : ∀ p y hy, motive y (@Subposition.of_mem_moves p x y hy))
    (trans : ∀ p y z hy hz, motive z hz →
      motive y (.trans hz (@Subposition.of_mem_moves p z y hy)))
    (y : LGame) (hy : Subposition x y) : motive y hy := by
  sorry

@[elab_as_elim]
theorem Subposition.trans_induction {motive : (x y : LGame) → Subposition x y → Prop}
    (of_mem_moves : ∀ p x y hxy, motive x y (@Subposition.of_mem_moves p x y hxy))
    (trans : ∀ x y z hx hy, motive x z hx → motive z y hy → motive x y (.trans hx hy))
    (x y : LGame) (hxy : Subposition x y) : motive x y hxy := by
  sorry

/-- Two loopy games are equal when there exists a bisimulation between them.

A way to think about this is that `r` defines a pairing between nodes of the game trees, which then
shows that the trees are isomorphic. -/
theorem eq_of_bisim (r : LGame → LGame → Prop)
    (H : ∀ x y, r x y → ∀ p, (∃ s : Set (LGame × LGame),
      Prod.fst '' s = x.moves p ∧ Prod.snd '' s = y.moves p ∧ ∀ z ∈ s, r z.1 z.2))
    {x y : LGame.{u}} (hxy : r x y) : x = y := by
  sorry

/-- Two `LGame`s are equal when their move sets are.

This is not always sufficient to prove that two games are equal. For instance, if `x = !{x | x}` and
`y = !{y | y}`, then `x = y`, but trying to use extensionality to prove this just leads to a cyclic
argument. For these situations, you can use `eq_of_bisim` instead. -/
@[ext]
protected theorem ext {x y : LGame.{u}}
    (h : ∀ p, x.moves p = y.moves p) : x = y := by
  sorry

-- The default corecursion principle we get from `QPF` has inconvenient type universes, so we prove
-- a more general version.
section corec
variable {α : Type v}

/-- A node `α` is reachable from `init` when it can be formed by applying
`moves` finitely many times. -/
private def Reachable (mov : Player → α → Set α) (init : α) (a : α) : Prop :=
  Relation.ReflTransGen (fun x y ↦ x ∈ mov left y ∪ mov right y) a init

variable (p : Player) (mov : Player → α → Set α)
  [∀ a, Small.{u} (mov left a)] [∀ a, Small.{u} (mov right a)] (init : α)

attribute [local instance] small_succ' in
private instance : Small.{u + 1} (Subtype (Reachable mov init)) :=
  small_reflTransGen' ..

/-- Destructor for the subtype of reachable positions. -/
@[simp]
private def dest (x : Shrink (Subtype (Reachable mov init))) :
    GameFunctor (Shrink (Subtype (Reachable mov init))) :=
  have hx := ((equivShrink _).symm x).2
  ⟨fun
    | left => equivShrink _ '' range (inclusion fun _y hy ↦ .trans (.single (.inl hy)) hx)
    | right => equivShrink _ '' range (inclusion fun _y hy ↦ .trans (.single (.inr hy)) hx),
    fun | left | right => inferInstance⟩

private theorem unique (f g : Subtype (Reachable mov init) → LGame.{u})
    (hf : QPF.Cofix.dest ∘ f ∘ (equivShrink _).symm =
      Functor.map (f ∘ (equivShrink _).symm) ∘ dest mov init)
    (hg : QPF.Cofix.dest ∘ g ∘ (equivShrink _).symm =
      Functor.map (g ∘ (equivShrink _).symm) ∘ dest mov init) (x) : f x = g x := by
  sorry

/-- The corecursor on the subtype of reachable nodes. -/
private def corec' (x : Subtype (Reachable mov init)) :=
  QPF.Cofix.corec (dest _ _) (equivShrink _ x)

/-- The corecursor on `LGame`.

You can use this in order to define an arbitrary `LGame` by "drawing" its move graph on some other
type. As an example, `on = !{on | }` is defined as `corec (Player.cases ⊤ ⊥) ()`. -/
def corec : LGame.{u} :=
  corec' mov init ⟨_, .refl⟩

private theorem corec'_trans {x} (hx : Reachable mov init x)
  (y : Subtype (Reachable mov x)) :
    corec' _ x y = corec' _ init (inclusion (fun _z hz ↦ .trans hz hx) y) := by
  sorry

private theorem corec'_aux {a} (ha : a ∈ mov left init ∪ mov right init) {x : LGame} :
    (∃ ha : Reachable mov init a, corec' _ init ⟨a, ha⟩ = x) ↔
    corec mov a = x := by
  sorry

@[simp]
theorem moves_corec : (corec mov init).moves p = corec mov '' mov p init := by
  sorry

theorem moves_comp_corec :
    moves p ∘ corec mov = image (corec mov) ∘ mov p := by
  sorry

theorem hom_unique_apply {mov : Player → α → Set α}
    [∀ a, Small.{u} (mov left a)] [∀ a, Small.{u} (mov right a)] (f g : α → LGame.{u})
    (hf : ∀ p, moves p ∘ f = image f ∘ mov p)
    (hg : ∀ p, moves p ∘ g = image g ∘ mov p) (x) : f x = g x := by
  sorry

theorem hom_unique {mov : Player → α → Set α}
    [∀ a, Small.{u} (mov left a)] [∀ a, Small.{u} (mov right a)] (f g : α → LGame.{u})
    (hf : ∀ p, moves p ∘ f = image f ∘ mov p)
    (hg : ∀ p, moves p ∘ g = image g ∘ mov p) : f = g := by
  sorry

-- We make no use of `LGame`'s definition from a `QPF` after this point.
attribute [irreducible] LGame

end corec

theorem corec_comp_hom
    {movα : Player → α → Set α} {movβ : Player → β → Set β}
    [∀ a, Small.{u} (movα left a)] [∀ a, Small.{u} (movα right a)]
    [∀ b, Small.{u} (movβ left b)] [∀ b, Small.{u} (movβ right b)] (f : α → β)
    (hf : ∀ p, movβ p ∘ f = Set.image f ∘ movα p) :
    corec movβ ∘ f = corec movα := by
  sorry

theorem corec_comp_hom_apply
    {movα : Player → α → Set α} {movβ : Player → β → Set β}
    [∀ a, Small.{u} (movα left a)] [∀ a, Small.{u} (movα right a)]
    [∀ b, Small.{u} (movβ left b)] [∀ b, Small.{u} (movβ right b)] (f : α → β)
    (hf : ∀ p, movβ p ∘ f = Set.image f ∘ movα p) (x : α) :
    corec movβ (f x) = corec movα x := by
  sorry

@[simp]
theorem corec_moves : corec moves = id := by
  sorry

theorem corec_moves_apply (x : LGame) : corec moves x = x := by
  sorry

/-- Construct an `LGame` from its left and right sets.

It's not possible to create a non-well-founded game through this constructor alone. For that,
see `LGame.corec`. -/
@[no_expose]
instance : OfSets LGame.{u} fun _ ↦ True where
  ofSets lr _ :=
    have this (p) : ∀ (a : Option LGame),
        Small.{u} ((a.elim (some '' lr p) (some '' moves p ·)) : Set _) := by
      cases p <;> simpa [Option.forall] using ⟨inferInstance, inferInstance⟩
    corec (fun p ↦ (·.elim (some '' lr p) (some '' moves p ·))) none

@[simp]
theorem moves_ofSets (p : Player) (lr : Player → Set LGame.{u})
    [Small.{u} (lr left)] [Small.{u} (lr right)] : !{lr}.moves p = lr p := by
  sorry

theorem leftMoves_ofSets (l r : Set LGame) [Small.{u} l] [Small.{u} r] :
    !{l | r}ᴸ = l := by
  sorry

theorem rightMoves_ofSets (l r : Set LGame) [Small.{u} l] [Small.{u} r] :
    !{l | r}ᴿ = r := by
  sorry

/-! ### Basic games -/

/-- The game `0 = !{∅ | ∅}`. -/
instance : Zero LGame := ⟨!{fun _ ↦ ∅}⟩

theorem zero_def : (0 : LGame) = !{fun _ ↦ ∅} := by
  sorry

@[simp] theorem moves_zero (p : Player) : moves p 0 = ∅ := by
  sorry

instance : Inhabited LGame := ⟨0⟩

/-- The game `1 = !{{0} | ∅}`. -/
instance : One LGame := ⟨!{{0} | ∅}⟩

theorem one_def : (1 : LGame) = !{{0} | ∅} := by
  sorry

@[simp] theorem leftMoves_one : 1ᴸ = {0} := by
  sorry
@[simp] theorem rightMoves_one : 1ᴿ = ∅ := by
  sorry

/-- The game `on = !{{on} | ∅}`. -/
def on : LGame := corec (Player.cases ⊤ ⊥) ()

@[simp] theorem leftMoves_on : onᴸ = {on} := by
  sorry
@[simp] theorem rightMoves_on : onᴿ = ∅ := by
  sorry
theorem on_eq : on = !{{on} | ∅} := by
  sorry

theorem eq_on {x : LGame} : x = on ↔ xᴸ = {x} ∧ xᴿ = ∅ := by
  sorry

/-- The game `off = !{∅ | {off}}`. -/
def off : LGame := corec (Player.cases ⊥ ⊤) ()

@[simp] theorem leftMoves_off : offᴸ = ∅ := by
  sorry
@[simp] theorem rightMoves_off : offᴿ = {off} := by
  sorry
theorem off_eq : off = !{∅ | {off}} := by
  sorry

theorem eq_off {x : LGame} : x = off ↔ xᴸ = ∅ ∧ xᴿ = {x} := by
  sorry

/-- The game `dud = !{{dud} | {dud}}`. -/
def dud : LGame := corec (Player.cases ⊤ ⊤) ()

@[simp] theorem moves_dud (p : Player) : dud.moves p = {dud} := by
  sorry
theorem dud_eq : dud = !{{dud} | {dud}} := by
  sorry

theorem eq_dud {x : LGame} : x = dud ↔ xᴸ = {x} ∧ xᴿ = {x} := by
  sorry

/-- The game `tis = !{{tisn} | ∅}`, where `tisn = !{∅ | {tis}}`. -/
def tis : LGame := corec (Player.cases (Bool.rec ∅ {false}) (Bool.rec {true} ∅)) true
/-- The game `tisn = !{∅ | {tis}}`, where `tis = !{{tisn} | ∅}`. -/
def tisn : LGame := corec (Player.cases (Bool.rec ∅ {false}) (Bool.rec {true} ∅)) false

@[simp] theorem leftMoves_tis : tisᴸ = {tisn} := by
  sorry
@[simp] theorem rightMoves_tis : tisᴿ = ∅ := by
  sorry
theorem tis_eq : tis = !{{tisn} | ∅} := by
  sorry

@[simp] theorem leftMoves_tisn : tisnᴸ = ∅ := by
  sorry
@[simp] theorem rightMoves_tisn : tisnᴿ = {tis} := by
  sorry
theorem tisn_eq : tisn = !{∅ | {tis}} := by
  sorry

/-! ### Negation -/

/-- The negative of a game is defined by `-!{s | t} = !{-t | -s}`. -/
@[no_expose]
instance : Neg LGame where
  neg := corec fun p ↦ moves (-p)

@[simp] theorem corec_moves_neg : corec (fun p ↦ moves (-p)) = (- ·) := by
  sorry
theorem corec_moves_neg_apply (x : LGame) : corec (fun p ↦ moves (-p)) x = -x := by
  sorry

theorem neg_corec (mov : Player → α → Set α)
    [∀ x, Small.{u} (mov left x)] [∀ x, Small.{u} (mov right x)] :
    -corec mov = corec fun p ↦ mov (-p) := by
  sorry

theorem neg_corec_apply (mov : Player → α → Set α)
    [∀ x, Small.{u} (mov left x)] [∀ x, Small.{u} (mov right x)] (init : α) :
    -corec mov init = corec (fun p ↦ mov (-p)) init := by
  sorry

instance : InvolutiveNeg LGame where
  neg_neg _ := by exact (neg_corec_apply ..).trans (corec_moves_apply ..)

@[simp]
theorem moves_neg (p : Player) (x : LGame) : (-x).moves p = -x.moves (-p) := by
  sorry

@[simp]
theorem neg_ofSets (s t : Set LGame.{u}) [Small.{u} s] [Small.{u} t] : -!{s | t} = !{-t | -s} := by
  sorry

theorem neg_ofSets' (st : Player → Set LGame) [Small (st left)] [Small (st right)] :
    -!{st} = !{fun p ↦ -st (-p)} := by
  sorry

@[simp]
theorem neg_ofSets_const (s : Set LGame) [Small s] :
    -!{fun _ ↦ s} = !{fun _ ↦ -s} := by
  sorry

instance : NegZeroClass LGame where
  neg_zero := by simp [zero_def]

@[simp] theorem neg_on : -on = off := by
  sorry
@[simp] theorem neg_off : -off = on := by
  sorry
@[simp] theorem neg_dud : -dud = dud := by
  sorry

@[simp]
theorem neg_tis : -tis = tisn := by
  sorry

@[simp]
theorem neg_tisn : -tisn = tis := by
  sorry

/-! ### Addition -/

/-- The sum of `x = !{s₁ | t₁}` and `y = !{s₂ | t₂}` is `!{s₁ + y, x + s₂ | t₁ + y, x + t₂}`. -/
@[no_expose]
instance : Add LGame where
  add x y := corec
    (fun p x ↦ (fun y ↦ (y, x.2)) '' moves p x.1 ∪ (fun y ↦ (x.1, y)) '' moves p x.2)
    (x, y)

theorem corec_add_corec
    {movα : Player → α → Set α} {movβ : Player → β → Set β}
    [∀ x, Small.{u} (movα left x)] [∀ x, Small.{u} (movα right x)]
    [∀ x, Small.{u} (movβ left x)] [∀ x, Small.{u} (movβ right x)] (initα : α) (initβ : β) :
    corec movα initα + corec movβ initβ =
    corec
      (fun p x ↦ (fun y ↦ (y, x.2)) '' movα p x.1 ∪ (fun y ↦ (x.1, y)) '' movβ p x.2)
      (initα, initβ) := by
  sorry

@[simp]
theorem moves_add (p : Player) (x y : LGame) :
    (x + y).moves p = (· + y) '' x.moves p ∪ (x + ·) '' y.moves p := by
  sorry

@[simp]
theorem add_eq_zero_iff {x y : LGame} : x + y = 0 ↔ x = 0 ∧ y = 0 := by
  sorry

private theorem add_zero' (x : LGame) : x + 0 = x := by
  sorry

private theorem add_comm' (x y : LGame) : x + y = y + x := by
  sorry

private theorem add_assoc' (x y z : LGame) : x + y + z = x + (y + z) := by
  sorry

instance : AddCommMonoid LGame where
  add_zero := by exact add_zero'
  zero_add _ := by exact add_comm' .. ▸ add_zero' _
  add_comm := by exact add_comm'
  add_assoc := by exact add_assoc'
  nsmul := nsmulRec

@[simp]
theorem on_add_off : on + off = dud := by
  sorry

@[simp]
theorem off_add_on : off + on = dud := by
  sorry

@[simp]
theorem add_dud (x : LGame) : x + dud = dud := by
  sorry

@[simp]
theorem dud_add (x : LGame) : dud + x = dud := by
  sorry

theorem moves_sum (p : Player) (m : Multiset LGame) : m.sum.moves p =
    ⋃ y ∈ m, (· + (m.erase y).sum) '' y.moves p := by
  sorry

/-- The subtraction of `x` and `y` is defined as `x + (-y)`. -/
instance : SubNegMonoid LGame where
  zsmul := zsmulRec

theorem corec_sub_corec
    {movα : Player → α → Set α} {movβ : Player → β → Set β}
    [∀ x, Small.{u} (movα left x)] [∀ x, Small.{u} (movα right x)]
    [∀ x, Small.{u} (movβ left x)] [∀ x, Small.{u} (movβ right x)] (initα : α) (initβ : β) :
    corec movα initα - corec movβ initβ =
    corec
      (fun p x ↦ (fun y ↦ (y, x.2)) '' movα p x.1 ∪ (fun y ↦ (x.1, y)) '' movβ (-p) x.2)
      (initα, initβ) := by
  sorry

@[simp]
theorem moves_sub (p : Player) (x y : LGame) :
    (x - y).moves p = (· - y) '' x.moves p ∪ (x + ·) '' (-y.moves (-p)) := by
  sorry

private theorem neg_add' (x y : LGame) : -(x + y) = -x + -y := by
  sorry

instance : SubtractionCommMonoid LGame where
  neg_neg := neg_neg
  neg_add_rev x y := by rw [neg_add', add_comm]
  neg_eq_of_add := by simp
  add_comm := add_comm

@[simp]
theorem on_sub_on : on - on = dud := by
  sorry

@[simp]
theorem off_sub_off : off - off = dud := by
  sorry

@[simp]
theorem sub_dud (x : LGame) : x - dud = dud := by
  sorry

/-! ### Multiplication -/

/-- Given two game graphs drawn on types `α` and `β`, the graph for the product can be drawn on the
type `Multiset (Player × α × β)`. Each term corresponds to a sum `Σ ±aᵢ * bᵢ`, where `aᵢ` and `bᵢ`
are terms of `α` and `β` respectively, and the attached player represents each term's sign. -/
abbrev MulTy (α β : Type*) :=
  Multiset (Player × α × β)

namespace MulTy

/-- Inverts the sign of all entries. -/
instance : InvolutiveNeg (MulTy α β) where
  neg x := x.map (fun y ↦ (-y.1, y.2))
  neg_neg x := by simp

theorem neg_def (x : MulTy α β) : -x = Multiset.map (fun y ↦ (-y.1, y.2)) x := by
  sorry

@[simp]
theorem mem_neg {x : Player × α × β} {y : MulTy α β} : x ∈ -y ↔ (-x.1, x.2) ∈ y := by
  sorry

@[simp]
theorem neg_zero : -(0 : MulTy α β) = 0 := by
  sorry

@[simp]
theorem neg_singleton (a : Player × α × β) : -({a} : MulTy α β) = {(-a.1, a.2)} := by
  sorry

@[simp]
theorem neg_cons (a : Player × α × β) (x : MulTy α β) : -(a ::ₘ x) = (-a.1, a.2) ::ₘ -x := by
  sorry

@[simp]
theorem neg_add (x y : MulTy α β) : -(x + y) = -x + -y := by
  sorry

@[simp]
theorem neg_erase [DecidableEq α] [DecidableEq β] (x : MulTy α β) (a : Player × α × β) :
    -x.erase a = (-x).erase (-a.1, a.2) := by
  sorry

/-- Swaps the entries in all pairs. -/
@[expose]
def swap (x : MulTy α β) : MulTy β α :=
  x.map (fun a ↦ (a.1, a.2.swap))

theorem swap_def (x : MulTy α β) : x.swap = x.map (fun a ↦ (a.1, a.2.swap)) := by
  sorry

@[simp]
theorem mem_swap {x : Player × β × α} {y : MulTy α β} : x ∈ y.swap ↔ (x.1, x.2.swap) ∈ y := by
  sorry

@[simp]
theorem swap_zero : swap (0 : MulTy α β) = 0 := by
  sorry

@[simp]
theorem swap_singleton (a : Player × α × β) : swap {a} = {(a.1, a.2.swap)} := by
  sorry

@[simp]
theorem swap_cons (a : Player × α × β) (x : MulTy α β) :
    swap (a ::ₘ x) = (a.1, a.2.swap) ::ₘ x.swap := by
  sorry

@[simp]
theorem swap_add (x y : MulTy α β) : swap (x + y) = x.swap + y.swap := by
  sorry

@[simp]
theorem swap_erase [DecidableEq α] [DecidableEq β] (x : MulTy α β) (a : Player × α × β) :
    swap (x.erase a) = x.swap.erase (a.1, a.2.swap) := by
  sorry

/-- The general form of an option of `x * y` is `a * y + x * b - a * b`.

If the player argument is left, all signs are flipped. -/
@[expose]
def mulOption (p : Player) (x : α × β) (y : α × β) : MulTy α β :=
  {(p, y.1, x.2), (p, x.1, y.2), (-p, y.1, y.2)}

@[simp]
theorem neg_mulOption (p : Player) (x : α × β) (y : α × β) :
    -mulOption p x y = mulOption (-p) x y := by
  sorry

@[simp]
theorem swap_mulOption (p : Player) (x : α × β) (y : α × β) :
    swap (mulOption p x y) = mulOption p x.swap y.swap := by
  sorry

theorem mulOption_eq_add (p : Player) (x : α × β) (y : α × β) :
    mulOption p x y = {(p, y.1, x.2)} + {(p, x.1, y.2)} + {(-p, y.1, y.2)} := by
  sorry

variable (p : Player) (movα : Player → α → Set α) (movβ : Player → β → Set β)

/-- The set of pairs `α × β` used in `movesSingle`. -/
def movesSet (x : Player × α × β) : Set (α × β) :=
  (p * x.1).cases
    (movα left x.2.1 ×ˢ movβ right x.2.2 ∪ movα right x.2.1 ×ˢ movβ left x.2.2)
    (movα left x.2.1 ×ˢ movβ left x.2.2 ∪ movα right x.2.1 ×ˢ movβ right x.2.2)

theorem movesSet_neg (x : Player × α × β) :
    movesSet p movα movβ (-x.1, x.2) = movesSet (-p) movα movβ x := by
  sorry

theorem movesSet_neg' (x : Player × LGame × LGame) :
    movesSet p moves moves (x.1, -x.2.1, x.2.2) =
    (fun y ↦ (-y.1, y.2)) '' movesSet (-p) moves moves x := by
  sorry

theorem movesSet_swap (x : Player × α × β) :
    movesSet p movβ movα (x.1, x.2.swap) = Prod.swap '' movesSet p movα movβ x := by
  sorry

/-- The left or right moves of `±x * y` are left or right moves of `x * y` if the sign is positive,
or the negatives of right or left moves of `x * y` if the sign is negative. -/
def movesSingle (x : Player × α × β) : Set (MulTy α β) :=
  mulOption x.1 x.2 '' movesSet p movα movβ x

theorem movesSingle_neg (x : Player × α × β) :
    movesSingle p movα movβ (-x.1, x.2) = -movesSingle (-p) movα movβ x := by
  sorry

theorem movesSingle_neg' (x : Player × LGame × LGame) :
    movesSingle p moves moves (x.1, -x.2.1, x.2.2) =
    (Multiset.map fun y ↦ (y.1, -y.2.1, y.2.2)) '' movesSingle (-p) moves moves x := by
  sorry

theorem movesSingle_swap (x : Player × α × β) :
    movesSingle p movβ movα (x.1, x.2.swap) = swap '' movesSingle p movα movβ x := by
  sorry

variable [Hα : DecidableEq α] [Hβ : DecidableEq β]

/-- The set of left or right moves of `Σ ±xᵢ * yᵢ` are `zᵢ + Σ ±xⱼ * yⱼ` for all `i`, where `cᵢ` is
a left or right move of `±xᵢ * yᵢ`, and the summation is taken over indices `j ≠ i`. -/
protected def moves (x : MulTy α β) : Set (MulTy α β) :=
  ⋃ y ∈ x, (x.erase y + ·) '' movesSingle p movα movβ y

-- TODO: upstream?
theorem _root_.Multiset.iUnion_map {α β γ} (m : Multiset α) (f : α → β) (g : β → Set γ) :
    ⋃ x ∈ m.map f, g x = ⋃ x ∈ m, g (f x) := by
  sorry

theorem moves_neg (x : MulTy α β) :
    (-x).moves p movα movβ = -x.moves (-p) movα movβ := by
  sorry

theorem moves_neg' (x : MulTy LGame LGame) :
    MulTy.moves p moves moves (Multiset.map (fun y ↦ (y.1, -y.2.1, y.2.2)) x) =
    (Multiset.map fun y ↦ (y.1, -y.2.1, y.2.2)) '' x.moves (-p) moves moves := by
  sorry

theorem moves_swap (x : MulTy α β) :
    x.swap.moves p movβ movα = swap '' x.moves p movα movβ := by
  sorry

variable {α₁ β₁ α₂ β₂ : Type*}
  {movα₁ : Player → α₁ → Set α₁} {movβ₁ : Player → β₁ → Set β₁}
  {movα₂ : Player → α₂ → Set α₂} {movβ₂ : Player → β₂ → Set β₂}
  (f : α₁ → α₂) (g : β₁ → β₂)

/-- Map `MulTy α₁ β₁` to `MulTy α₂ β₂` using `f : α₁ → α₂` and `g : β₁ → β₂` in the natural way. -/
def map : MulTy α₁ β₁ → MulTy α₂ β₂ :=
  Multiset.map (Prod.map id (Prod.map f g))

@[simp]
theorem map_add (x y) : map f g (x + y) = map f g x + map f g y := by
  sorry

theorem map_erase [DecidableEq α₁] [DecidableEq β₁] [DecidableEq α₂] [DecidableEq β₂]
    {x : MulTy α₁ β₁} {y} (hy : y ∈ x) :
    map f g (x.erase y) = (map f g x).erase (y.1, f y.2.1, g y.2.2) := by
  sorry

@[simp, grind =]
theorem map_mulOption (b x y) :
    map f g (mulOption b x y) = mulOption b (Prod.map f g x) (Prod.map f g y) := by
  sorry

variable {p f g}

theorem movesSingle_comp_prodMap
    (hf : ∀ p, movα₂ p ∘ f = Set.image f ∘ movα₁ p)
    (hg : ∀ p, movβ₂ p ∘ g = Set.image g ∘ movβ₁ p) :
    movesSingle p movα₂ movβ₂ ∘ Prod.map id (Prod.map f g) =
    image (map f g) ∘ movesSingle p movα₁ movβ₁ := by
  sorry

variable [Hα₁ : DecidableEq α₁] [Hβ₁ : DecidableEq β₁] [Hα₂ : DecidableEq α₂] [Hβ₂ : DecidableEq β₂]

theorem moves_comp_map
    (hf : ∀ p, movα₂ p ∘ f = Set.image f ∘ movα₁ p)
    (hg : ∀ p, movβ₂ p ∘ g = Set.image g ∘ movβ₁ p) :
    MulTy.moves p movα₂ movβ₂ ∘ map f g = image (map f g) ∘ MulTy.moves p movα₁ movβ₁ := by
  sorry

variable (p)
    [∀ x, Small.{u} (movα left x)] [∀ x, Small.{u} (movα right x)]
    [∀ x, Small.{u} (movβ left x)] [∀ x, Small.{u} (movβ right x)]

private instance (x : Player × α × β) :
    Small.{u} (movesSet p movα movβ x) := by
  obtain ⟨(_ | _), _⟩ := x <;> cases p <;> exact small_union ..

instance (x : Player × α × β) :
    Small.{u} (movesSingle p movα movβ x) :=
  small_image ..

instance (x : MulTy α β) :
    Small.{u} (x.moves p movα movβ) := by
  simp_rw [MulTy.moves, ← Multiset.mem_toFinset]
  exact small_biUnion.{u} (ι := Player × α × β) (Multiset.toFinset x) _

/-- The game `±xᵢ * yᵢ`. -/
abbrev toLGame (x : Player × α × β) : LGame :=
  corec (MulTy.moves · movα movβ) {x}

theorem moves_toLGame (x : Player × α × β) :
    (toLGame movα movβ x).moves p =
    corec (MulTy.moves · movα movβ) '' movesSingle p movα movβ x := by
  sorry

@[simp]
theorem corec_zero : corec (MulTy.moves · movα movβ) 0 = 0 := by
  sorry

theorem corec_neg (init : MulTy α β) :
    corec (MulTy.moves · movα movβ) (-init) = -corec (MulTy.moves · movα movβ) init := by
  sorry

theorem corec_add (init₁ init₂ : MulTy α β) :
    corec (MulTy.moves · movα movβ) (init₁ + init₂) =
    corec (MulTy.moves · movα movβ) init₁ + corec (MulTy.moves · movα movβ) init₂ := by
  sorry

theorem corec_mulOption (p : Player) (x y : α × β) :
    corec (MulTy.moves · movα movβ) (mulOption p x y) =
    toLGame movα movβ (p, y.1, x.2) +
    toLGame movα movβ (p, x.1, y.2) -
    toLGame movα movβ (p, y.1, y.2) := by
  sorry

theorem _root_.LGame.corec_mulTy (x : MulTy α β) :
    corec (MulTy.moves · movα movβ) x =
    (Multiset.map (toLGame movα movβ) x).sum := by
  sorry

theorem corec_swap (x : MulTy α β) :
    corec (MulTy.moves · movβ movα) x.swap = corec (MulTy.moves · movα movβ) x := by
  sorry

/-- The product of `x = !{s₁ | t₁}` and `y = !{s₂ | t₂}` is
`!{a₁ * y + x * b₁ - a₁ * b₁ | a₂ * y + x * b₂ - a₂ * b₂}`, where `(a₁, b₁) ∈ s₁ ×ˢ s₂ ∪ t₁ ×ˢ t₂`
and `(a₂, b₂) ∈ s₁ ×ˢ t₂ ∪ t₁ ×ˢ s₂`.

Using `LGame.mulOption`, this can alternatively be written as
`x * y = !{mulOption x y a₁ b₁ | mulOption x y a₂ b₂}`. -/
@[no_expose]
instance _root_.LGame.instMul : Mul LGame where
  mul x y := toLGame moves moves (right, x, y)

theorem _root_.LGame.corec_mul_corec (initα : α) (initβ : β) :
    corec movα initα * corec movβ initβ =
    toLGame movα movβ (right, initα, initβ) := by
  sorry

end MulTy

/-- The general option of `x * y` looks like `a * y + x * b - a * b`, for `a` and `b` options of
`x` and `y`, respectively. -/
@[pp_nodot, expose]
def mulOption (x y a b : LGame) : LGame :=
  a * y + x * b - a * b

@[simp]
theorem moves_mul (p : Player) (x y : LGame) :
    (x * y).moves p = (fun a ↦ mulOption x y a.1 a.2) ''
      (xᴸ ×ˢ y.moves p ∪ xᴿ ×ˢ y.moves (-p)) := by
  sorry

@[simp]
theorem moves_mulOption (p : Player) (x y a b : LGame) :
    (mulOption x y a b).moves p = (a * y + x * b - a * b).moves p := by
  sorry

instance : CommMagma LGame where
  mul_comm _ _ := by exact (MulTy.corec_swap ..).symm

instance : MulZeroClass LGame where
  zero_mul x := by ext p; cases p <;> simp
  mul_zero x := by ext p; cases p <;> simp

private theorem one_mul' (x : LGame) : 1 * x = x := by
  sorry

instance : MulOneClass LGame where
  one_mul := private one_mul'
  mul_one x := private mul_comm x _ ▸ one_mul' x

private theorem neg_mul' (x y : LGame) : -x * y = -(x * y) := by
  sorry

instance : HasDistribNeg LGame where
  neg_mul := private neg_mul'
  mul_neg _ _ := by rw [mul_comm, neg_mul', mul_comm]

/-! ### Stoppers -/

/-- A game is a stopper for player `p` when an alternating sequence of moves starting with said
player always terminates. -/
@[mk_iff]
inductive StopperFor : Player → LGame → Prop
  | mk {p : Player} {x : LGame} : (∀ y ∈ x.moves p, StopperFor (-p) y) → StopperFor p x

theorem StopperFor.of_mem_moves {p : Player} {x y : LGame} (h : StopperFor p x)
    (hy : y ∈ x.moves p) : StopperFor (-p) y := by
  sorry

theorem StopperFor.neg {p : Player} {x : LGame} (h : StopperFor p x) : StopperFor (-p) (-x) := by
  sorry

@[simp]
theorem stopperFor_neg_iff {p : Player} {x : LGame} : StopperFor p (-x) ↔ StopperFor (-p) x := by
  sorry

/-- A game is a stopper when it's `StopperFor` for both players. -/
@[expose]
def Stopper (x : LGame) : Prop :=
  ∀ p, StopperFor p x

@[simp]
theorem Stopper.stopperFor (p : Player) {x : LGame} (h : Stopper x) : StopperFor p x := by
  sorry

/-- A game is a stopper when all its options are stoppers.

Note that this is not an iff, as e.g. `{ | { | dud}}` is a stopper, but `{ | dud}` isn't. -/
theorem Stopper.mk {x : LGame} (H : ∀ p, ∀ y ∈ x.moves p, Stopper y) : Stopper x := by
  sorry

theorem Stopper.neg {x : LGame} (h : Stopper x) : Stopper (-x) := by
  sorry

@[simp]
theorem stopper_neg_iff {x : LGame} : Stopper (-x) ↔ Stopper x := by
  sorry

@[simp]
theorem stopper_zero : Stopper 0 := by
  sorry

@[simp]
theorem stopper_one : Stopper 1 := by
  sorry

@[simp]
theorem stopper_on : Stopper.{u} on := by
  sorry

@[simp]
theorem stopper_off : Stopper off := by
  sorry

@[simp]
theorem not_stopperFor_dud (p : Player) : ¬ StopperFor p dud := by
  sorry

@[simp] theorem not_stopper_dud : ¬ Stopper dud := by
  sorry

@[simp] theorem stopperFor_right_tis : StopperFor right tis := by
  sorry
@[simp] theorem stopperFor_left_tisn : StopperFor left tisn := by
  sorry

@[simp]
theorem not_stopperFor_left_tis : ¬ StopperFor left tis := by
  sorry

@[simp]
theorem not_stopperFor_right_tisn : ¬ StopperFor right tisn := by
  sorry

@[simp] theorem not_stopper_tis : ¬ Stopper tis := by
  sorry
@[simp] theorem not_stopper_tisn : ¬ Stopper tisn := by
  sorry

end LGame
