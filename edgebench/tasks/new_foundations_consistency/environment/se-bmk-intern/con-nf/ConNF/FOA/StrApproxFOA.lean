import ConNF.FOA.StrApprox

/-!
# Freedom of action for structural permutations

In this file, we state and prove the freedom of action theorem for structural permutations.

## Main declarations

* `ConNF.StrApprox.Approximates`: A structural approximation approximates an allowable permutation
    if it agrees with it wherever it is defined.
* `ConNF.StrApprox.ExactlyApproximates`: A structural approximation exactly approximates an
    allowable permutation if it approximates the permutation and every undefined atom is
    "typical" in a suitable sense.
* `ConNF.StrApprox.FreedomOfAction`: Freedom of action for structural approximations:
    every coherent approximation exactly approximates some allowable permutation.
* `ConNF.StrApprox.freedomOfAction`: The proof of freedom of action for structural permutations.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}]

namespace StrApprox

variable [Level] [CoherentData] {β : TypeIndex} [LeLevel β]

def Approximates (ψ : StrApprox β) (ρ : AllPerm β) : Prop :=
  ∀ A, (ψ A).Approximates (ρᵁ A)

def ExactlyApproximates (ψ : StrApprox β) (ρ : AllPerm β) : Prop :=
  ∀ A, (ψ A).ExactlyApproximates (ρᵁ A)

theorem Approximates.mono {ψ χ : StrApprox β} {ρ : AllPerm β} (hχ : χ.Approximates ρ) (h : ψ ≤ χ) :
    ψ.Approximates ρ := by
  sorry

def FreedomOfAction (β : TypeIndex) [LeLevel β] : Prop :=
  ∀ ψ : StrApprox β, ψ.Coherent → ∃ ρ, ψ.ExactlyApproximates ρ

theorem smul_nearLitter_mem_dom_of_approximates {ψ : StrApprox β} {ρ : AllPerm β}
    (h : ψ.Approximates ρ) {A : β ↝ ⊥} {N : NearLitter} (hN : N ∈ (ψ A)ᴺ.dom) :
    ρᵁ A • N ∈ (ψ A)ᴺ.dom := by
  sorry

theorem inv_smul_nearLitter_mem_dom_of_approximates {ψ : StrApprox β} {ρ : AllPerm β}
    (h : ψ.Approximates ρ) {A : β ↝ ⊥} {N : NearLitter} (hN : N ∈ (ψ A)ᴺ.dom) :
    (ρᵁ A)⁻¹ • N ∈ (ψ A)ᴺ.dom := by
  sorry

theorem zsmul_nearLitter_mem_dom_of_approximates {ψ : StrApprox β} {ρ : AllPerm β}
    (h : ψ.Approximates ρ) {A : β ↝ ⊥} {N : NearLitter} (hN : N ∈ (ψ A)ᴺ.dom) (n : ℤ) :
    (ρᵁ A) ^ n • N ∈ (ψ A)ᴺ.dom := by
  sorry

theorem zsmul_nearLitter_mem_dom_iff_of_approximates {ψ : StrApprox β} {ρ : AllPerm β}
    (h : ψ.Approximates ρ) {A : β ↝ ⊥} {N : NearLitter} (n : ℤ) :
    (ρᵁ A) ^ n • N ∈ (ψ A)ᴺ.dom ↔ N ∈ (ψ A)ᴺ.dom := by
  sorry

theorem smul_support_eq_smul_of_approximates {ψ : StrApprox β} {ρ : AllPerm β}
    (h : ψ.Approximates ρ) {S : Support β}
    (hSA : ∀ A, ∀ a ∈ (S ⇘. A)ᴬ, a ∈ (ψ A)ᴬ.dom)
    (hSN : ∀ A, ∀ N ∈ (S ⇘. A)ᴺ, N ∈ (ψ A)ᴺ.dom) :
    ψ • S = ρᵁ • S := by
  sorry

/-- Add a flexible litter to this approximation. -/
def addFlexible (ψ : StrApprox β) (A : β ↝ ⊥) (L : Litter) (hLψ : L ∉ (ψ A)ᴸ.dom) :
    StrApprox β :=
  ψ.addOrbit A (λ _ ↦ L) (λ _ _ _ ↦ id) (λ _ ↦ hLψ)

theorem addFlexible_coherent {ψ : StrApprox β} {A : β ↝ ⊥} {L : Litter} {hLψ : L ∉ (ψ A)ᴸ.dom}
    (hψ : ψ.Coherent) (hL : ¬Inflexible A L) :
    (ψ.addFlexible A L hLψ).Coherent := by
  sorry

theorem addInflexible_aux (P : InflexiblePath β) (t : Tangle P.δ) (ρ : AllPerm P.δ) :
    ∀ m n k : ℤ, fuzz P.hδε (ρ ^ m • t) = fuzz P.hδε (ρ ^ n • t) →
      fuzz P.hδε (ρ ^ (m + k) • t) = fuzz P.hδε (ρ ^ (n + k) • t) := by
  sorry

def addInflexible' (ψ : StrApprox β) {A : β ↝ ⊥}
    (P : InflexiblePath β) (t : Tangle P.δ) (ρ : AllPerm P.δ)
    (hL : ∀ n : ℤ, fuzz P.hδε (ρ ^ n • t) ∉ (ψ A)ᴸ.dom) :
    StrApprox β :=
  ψ.addOrbit A (λ n ↦ fuzz P.hδε (ρ ^ n • t)) (addInflexible_aux P t ρ) hL

theorem smul_support_zpow {ψ : StrApprox β} {ρ : AllPerm β} (h : ψ.Approximates ρ)
    (t : Tangle β) {n : ℤ}
    (hLA : ∀ B, ∀ a ∈ (t.support ⇘. B)ᴬ, a ∈ (ψ B)ᴬ.dom)
    (hLN : ∀ B, ∀ N ∈ (t.support ⇘. B)ᴺ, N ∈ (ψ B)ᴺ.dom) :
    ψ • (ρ ^ n • t).support = ρᵁ • (ρ ^ n • t).support := by
  sorry

theorem addInflexible'_coherent {ψ : StrApprox β} {A : β ↝ ⊥}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.)
    {ρ : AllPerm P.δ} (hρ : Approximates (ψ ⇘ P.A ↘ P.hδ) ρ)
    {hL : ∀ n : ℤ, fuzz P.hδε (ρ ^ n • t) ∉ (ψ A)ᴸ.dom}
    (hψ : ψ.Coherent)
    (hLA : ∀ B, ∀ a ∈ (t.support ⇘. B)ᴬ, a ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴬ.dom)
    (hLN : ∀ B, ∀ N ∈ (t.support ⇘. B)ᴺ, N ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴺ.dom) :
    (ψ.addInflexible' P t ρ hL).Coherent := by
  sorry

theorem mem_dom_of_inflexible {ψ : StrApprox β} {A : β ↝ ⊥} {L : Litter}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.) (ht : L = fuzz P.hδε t)
    {ρ : AllPerm P.δ} (hρ : Approximates (ψ ⇘ P.A ↘ P.hδ) ρ)
    {n : ℤ} (hL : fuzz P.hδε (ρ ^ n • t) ∈ (ψ A)ᴸ.dom)
    (hψ : ψ.Coherent)
    (hLA : ∀ B, ∀ a ∈ (t.support ⇘. B)ᴬ, a ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴬ.dom)
    (hLN : ∀ B, ∀ N ∈ (t.support ⇘. B)ᴺ, N ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴺ.dom) :
    L ∈ (ψ A)ᴸ.dom := by
  sorry

open scoped Classical in
def addInflexible (ψ : StrApprox β) (A : β ↝ ⊥)
    (P : InflexiblePath β) (t : Tangle P.δ) (ρ : AllPerm P.δ) : StrApprox β :=
  if hL : ∀ n : ℤ, fuzz P.hδε (ρ ^ n • t) ∉ (ψ A)ᴸ.dom then ψ.addInflexible' P t ρ hL else ψ

theorem le_addInflexible (ψ : StrApprox β) (A : β ↝ ⊥)
    (P : InflexiblePath β) (t : Tangle P.δ) (ρ : AllPerm P.δ) :
    ψ ≤ ψ.addInflexible A P t ρ := by
  sorry

theorem addInflexible_coherent {ψ : StrApprox β} {A : β ↝ ⊥}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.)
    {ρ : AllPerm P.δ} (hρ : Approximates (ψ ⇘ P.A ↘ P.hδ) ρ)
    (hψ : ψ.Coherent)
    (hLA : ∀ B, ∀ a ∈ (t.support ⇘. B)ᴬ, a ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴬ.dom)
    (hLN : ∀ B, ∀ N ∈ (t.support ⇘. B)ᴺ, N ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴺ.dom) :
    (ψ.addInflexible A P t ρ).Coherent := by
  sorry

theorem mem_addInflexible_dom {ψ : StrApprox β} {A : β ↝ ⊥} {L : Litter}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.) (hL : L = fuzz P.hδε t)
    {ρ : AllPerm P.δ} (hρ : Approximates (ψ ⇘ P.A ↘ P.hδ) ρ)
    (hψ : ψ.Coherent)
    (hLA : ∀ B, ∀ a ∈ (t.support ⇘. B)ᴬ, a ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴬ.dom)
    (hLN : ∀ B, ∀ N ∈ (t.support ⇘. B)ᴺ, N ∈ (ψ (P.A ↘ P.hδ ⇘ B))ᴺ.dom) :
    L ∈ (ψ.addInflexible A P t ρ A)ᴸ.dom := by
  sorry

theorem exists_extension_of_minimal (ψ : StrApprox β) (A : β ↝ ⊥) (L : Litter) (hψ : ψ.Coherent)
    (foa : ∀ δ < β, [LeLevel δ] → FreedomOfAction δ)
    (hLA : ∀ B, ∀ a, pos a < pos L → a ∈ (ψ B)ᴬ.dom)
    (hLN : ∀ B, ∀ N, pos N < pos L → N ∈ (ψ B)ᴺ.dom) :
    ∃ χ ≥ ψ, χ.Coherent ∧ L ∈ (χ A)ᴸ.dom := by
  sorry

theorem exists_extension_of_minimal' (ψ : StrApprox β) (A : β ↝ ⊥)
    (L : Litter) (hL : L ∉ (ψ A)ᴸ.dom) (hψ : ψ.Coherent)
    (foa : ∀ δ < β, [LeLevel δ] → FreedomOfAction δ)
    (hL' : ∀ B L', pos L' < pos L → L' ∈ (ψ B)ᴸ.dom) :
    ∃ χ > ψ, χ.Coherent := by
  sorry

theorem exists_total (ψ : StrApprox β) (hψ : ψ.Coherent)
    (foa : ∀ δ < β, [LeLevel δ] → FreedomOfAction δ) :
    ∃ χ ≥ ψ, χ.Coherent ∧ χ.Total := by
  sorry

theorem exists_exactlyApproximates_of_total (ψ : StrApprox β) (hψ₁ : ψ.Coherent) (hψ₂ : ψ.Total) :
    ∃ ρ, ψ.ExactlyApproximates ρ := by
  sorry

theorem freedomOfAction : FreedomOfAction β := by
  sorry

end StrApprox

end ConNF
