import ConNF.ModelData.CoherentData
import ConNF.FOA.BaseApprox

/-!
# Structural approximations

In this file, we define structural approximations, which are trees of base approximations.

## Main declarations

* `ConNF.StrApprox`: The type of structural approximations.
* `ConNF.InflexiblePath`: A pair of paths starting at `β` that describe a particular way to use
    a `fuzz` map.
* `ConNF.Inflexible`: A litter is said to be inflexible along a path if it can be obtained by
    applying a `fuzz` map along this path.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] {β : TypeIndex}

abbrev StrApprox : TypeIndex → Type u :=
  Tree BaseApprox

namespace StrApprox

section addOrbit

open scoped Classical in
def addOrbit (ψ : StrApprox β) (A : β ↝ ⊥) (f : ℤ → Litter)
    (hf : ∀ m n k, f m = f n → f (m + k) = f (n + k)) (hfψ : ∀ n, f n ∉ (ψ A)ᴸ.dom) : StrApprox β :=
  λ B ↦ if h : A = B then (ψ B).addOrbit f hf (h ▸ hfψ) else ψ B

variable {ψ : StrApprox β} {A : β ↝ ⊥} {f : ℤ → Litter}
    {hf : ∀ m n k, f m = f n → f (m + k) = f (n + k)} {hfψ : ∀ n, f n ∉ (ψ A)ᴸ.dom}

end addOrbit

/-- An upper bound for a chain of approximations. -/
def upperBound (c : Set (StrApprox β)) (hc : IsChain (· ≤ ·) c) : StrApprox β :=
  λ A ↦ BaseApprox.upperBound ((· A) '' c) (hc.image _ _ _ (λ _ _ h ↦ h A))

theorem upperBound_exceptions (c : Set (StrApprox β)) (hc : IsChain (· ≤ ·) c)
    (A : β ↝ ⊥) (a₁ a₂ : Atom) :
    (upperBound c hc A).exceptions a₁ a₂ ↔ ∃ ψ ∈ c, (ψ A).exceptions a₁ a₂ := by
  sorry

theorem upperBound_litters (c : Set (StrApprox β)) (hc : IsChain (· ≤ ·) c)
    (A : β ↝ ⊥) (L₁ L₂ : Litter) :
    (upperBound c hc A)ᴸ L₁ L₂ ↔ ∃ ψ ∈ c, (ψ A)ᴸ L₁ L₂ := by
  sorry

theorem upperBound_typical (c : Set (StrApprox β)) (hc : IsChain (· ≤ ·) c)
    (A : β ↝ ⊥) (a₁ a₂ : Atom) :
    (upperBound c hc A).typical a₁ a₂ ↔ ∃ ψ ∈ c, (ψ A).typical a₁ a₂ := by
  sorry

theorem upperBound_atoms (c : Set (StrApprox β)) (hc : IsChain (· ≤ ·) c)
    (A : β ↝ ⊥) (a₁ a₂ : Atom) :
    (upperBound c hc A)ᴬ a₁ a₂ ↔ ∃ ψ ∈ c, (ψ A)ᴬ a₁ a₂ := by
  sorry

/-! TODO: Many of the previous lemmas are not actually needed! -/

def Total (ψ : StrApprox β) : Prop :=
  ∀ A, (ψ A).Total

theorem smul_support_eq_smul_mono
    {ξ χ : StrApprox β} {S : Support β} {π : StrPerm β}
    (hξ : ξ • S = π • S) (hξχ : ξ ≤ χ) :
    χ • S = π • S := by
  sorry

variable [Level] [CoherentData]

theorem coherentAt_mono [LeLevel β] {ψ χ : StrApprox β} {A : β ↝ ⊥} {L₁ L₂ : Litter}
    (h : CoherentAt ψ A L₁ L₂) (hψχ : ψ ≤ χ) : CoherentAt χ A L₁ L₂ := by
  sorry

def Coherent [LeLevel β] (ψ : StrApprox β) : Prop :=
  ∀ A L₁ L₂, (ψ A)ᴸ L₁ L₂ → CoherentAt ψ A L₁ L₂

theorem addOrbit_coherent [LeLevel β] {ψ : StrApprox β} {A : β ↝ ⊥} {f : ℤ → Litter}
    {hf : ∀ m n k, f m = f n → f (m + k) = f (n + k)} {hfψ : ∀ n, f n ∉ (ψ A)ᴸ.dom}
    (hψ : ψ.Coherent) (hfc : ∀ n, CoherentAt ψ A (f n) (f (n + 1))) :
    (ψ.addOrbit A f hf hfψ).Coherent := by
  sorry

theorem Coherent.deriv [LeLevel β] {ψ : StrApprox β} (hψ : ψ.Coherent)
    {γ : TypeIndex} [LeLevel γ] (A : β ↝ γ) :
    Coherent (ψ ⇘ A) := by
  sorry

theorem upperBound_coherent [LeLevel β] (c : Set (StrApprox β)) (hc₁ : IsChain (· ≤ ·) c)
    (hc₂ : ∀ ψ ∈ c, ψ.Coherent) :
    (upperBound c hc₁).Coherent := by
  sorry

theorem exists_maximal_coherent [LeLevel β] (ψ : StrApprox β) (hψ : ψ.Coherent) :
    ∃ χ ≥ ψ, Maximal {χ | χ.Coherent} χ := by
  sorry

end StrApprox

end ConNF
