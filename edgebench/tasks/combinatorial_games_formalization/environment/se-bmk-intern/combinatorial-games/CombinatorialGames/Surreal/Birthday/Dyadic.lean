/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Surreal.Birthday.Basic
public import CombinatorialGames.Surreal.Dyadic

import CombinatorialGames.Surreal.Birthday.Cut

/-!
# Birthday of dyadic rationals

We prove that a surreal number has a finite birthday iff it's a dyadic number.
-/

public section

local notation "ω" => NatOrdinal.of Ordinal.omega0

@[simp]
theorem Game.birthday_ratCast (x : ℚ) : Game.birthday x = Surreal.birthday x := by
  sorry

theorem Surreal.birthday_dyadic_lt_omega0 (x : Dyadic) : Surreal.birthday x < ω := by
  sorry

theorem Surreal.birthday_lt_omega0_iff {x : Surreal} :
    x.birthday < ω ↔ x ∈ Set.range ((↑) : Dyadic → _) := by
  sorry

-- `Dyadic.toIGame` is canonical, so it minimizes the birthday in its equivalence class.
proof_wanted Surreal.birthday_dyadic (x : Dyadic) :
    Surreal.birthday x = IGame.birthday x

-- It's actually possible to explicitly compute the birthday of a dyadic number.
proof_wanted IGame.birthday_dyadic (x : Dyadic) :
    IGame.birthday x = ⌈x.num.natAbs⌉₊ + Nat.log2 x.den

end
