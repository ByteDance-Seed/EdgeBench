module

public import Mathlib.Data.FunLike.Fintype
public import Mathlib.Data.Int.Lemmas
public import PFR.HomPFR

import AddCombi.BSG

/-!
# The approximate homomorphism form of PFR

Here we apply PFR to show that almost homomorphisms f from a 2-group to a 2-group often coincide
with a (shifted) actual homomorphisms. Here, approximate is in the sense that f(x+y)=f(x)+f(y)
is true for a positive proportion of x,y.

## Main result

* `approx_hom_pfr` : If $f: G → G'$ is a map between finite abelian elementary 2-groups such that
  $f(x+y)=f(x)+f(y)$ for at least $|G|/K$ values, then then there is a homomorphism $\phi: G \to G'$
  and a constant $c$ such that $f(x)=\phi(x)+c$ for a substantial set of values.
-/

public section

open Finset Module
open scoped Pointwise Combinatorics.Additive'

variable {G G' : Type*} [AddCommGroup G] [Fintype G] [DecidableEq G'] [AddCommGroup G'] [Finite G']
  [Module (ZMod 2) G] [Module (ZMod 2) G'] (A : Finset G)

/-- Let $G, G'$ be finite abelian $2$-groups.
Let $f : G \to G'$ be a function, and suppose that there is a proportion of at least
$K^{-1}$ pairs $(x,y) \in G^2$ such that $$ f(x+y) = f(x) + f(y).$$
Then there exists a homomorphism $\phi : G \to G'$ and a constant $c \in G'$ such that
$f(x) = \phi(x)+c$ for at least $|G| / (2 ^ {144} * K ^ {122})$ values of $x \in G$. -/
theorem approx_hom_pfr (f : G → G') (K : ℝ) (hK : K > 0)
    (hf : K⁻¹ ≤ Finset.dens {x : G × G | f (x.1 + x.2) = f x.1 + f x.2}) :
    ∃ (φ : G →+ G') (c : G'), Nat.card {x | f x = φ x + c} ≥ Nat.card G / (2 ^ 144 * K ^ 122) := by
  sorry

/-- Non canonical isomorphism between a finite 2-torsion group and its dual into `ZMod 2`. -/
noncomputable def dual_iso : G ≃+ (G →+ ZMod 2) := by
  -- By definition of dual space, we know that $G^*$ is isomorphic to
  -- $\text{Hom}(G, \mathbb{Z}/2\mathbb{Z})$.
  have hdual_iso_hom : (G →+ ZMod 2) ≃+ Module.Dual (ZMod 2) G :=
    AddMonoidHom.toZModLinearMapEquiv 2;
  -- Since $G$ is a finite-dimensional vector space over $\mathbb{Z}/2\mathbb{Z}$, it is isomorphic
  -- to its dual space.
  have h_dual_iso_self : G ≃ₗ[ZMod 2] Module.Dual (ZMod 2) G :=
    (Basis.linearEquiv_dual_iff_finiteDimensional.mpr inferInstance).some
  exact h_dual_iso_self.toAddEquiv.trans hdual_iso_hom.symm

theorem approx_hom_pfr' [Finite G] (f : G → G') (K : ℝ) (hK : K > 0)
    (hf : K⁻¹ ≤ Finset.dens {x : G × G | f (x.1 + x.2) = f x.1 + f x.2}) :
    ∃ (φ'' : G →+ G'), Nat.card {x | f x = φ'' x} ≥ (Nat.card G / (2 ^ 144 * K ^ 122) - 1)/2 := by
  sorry
