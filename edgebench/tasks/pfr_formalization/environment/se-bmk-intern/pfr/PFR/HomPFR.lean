module

public import Mathlib.Algebra.Field.ZMod
public import Mathlib.Data.Set.Card
public import PFR.Mathlib.LinearAlgebra.Basis.VectorSpace
public import PFR.RhoFunctional

/-!
# The homomorphism form of PFR

Here we apply (improved) PFR to show that approximate homomorphisms f from a 2-group to a 2-group
are close to actual homomorphisms. Here, approximate is in the sense that f(x+y)-f(x)-f(y) takes
few values.

## Main results

* `goursat`: A convenient description of the subspaces of $G \times G'$ when $G, G'$ are elementary
  abelian 2-groups.
* `homomorphism_pfr` : If $f : G → G'$ is a map between finite abelian elementary 2-groups such
  that $f(x+y)-f(x)-f(y)$ takes at most $K$ values, then there is a homomorphism $\phi: G \to G'$
  such that $f(x)-\phi(x)$ takes at most $K^{10}$ values.
-/

public section

open Set
open scoped Pointwise

variable {G G' : Type*} [AddCommGroup G] [AddCommGroup G'] [Module (ZMod 2) G] [Module (ZMod 2) G']

/-- Let $H_0$ be a subgroup of $G$. Then every homomorphism $\phi: H_0 \to G'$ can be extended to a
homomorphism $\tilde \phi: G \to G'$. -/
lemma hahn_banach (H₀ : AddSubgroup G) (φ : H₀ →+ G') : ∃ (φ' : G →+ G'), ∀ x : H₀, φ x = φ' x := by
  sorry

variable [Finite G] [Finite G']

open Set Fintype

/-- Let $f: G \to G'$ be a function, and let $S$ denote the set
$$ S := \{ f(x+y)-f(x)-f(y): x,y \in G \}.$$
Then there exists a homomorphism $\phi: G \to G'$ such that
$$ |\{f(x) - \phi(x)\}| \leq |S|^{10}. $$ -/
theorem homomorphism_pfr (f : G → G') (S : Set G') (hS : ∀ x y : G, f (x+y) - (f x) - (f y) ∈ S) :
    ∃ (φ : G →+ G') (T : Set G'), Nat.card T ≤ Nat.card S ^ 10 ∧ ∀ x : G, (f x) - (φ x) ∈ T := by
  sorry
