import ConNF.Model.Hailperin

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal ConNF.TSet

namespace ConNF

variable [Params.{u}] {α β γ δ ε ζ : Λ} (hβ : (β : TypeIndex) < α) (hγ : (γ : TypeIndex) < β)
  (hδ : (δ : TypeIndex) < γ) (hε : (ε : TypeIndex) < δ) (hζ : (ζ : TypeIndex) < ε)

theorem ext (x y : TSet α) :
    (∀ z : TSet β, z ∈' x ↔ z ∈' y) → x = y := by
  sorry

theorem ext_iff (x y : TSet α) :
    (∀ z : TSet β, z ∈' x ↔ z ∈' y) ↔ x = y := by
  sorry

def inter (x y : TSet α) : TSet α :=
  (TSet.exists_inter hβ x y).choose

notation:69 x:69 " ⊓[" h "] " y:69 => _root_.ConNF.inter h x y
notation:69 x:69 " ⊓' " y:69 => x ⊓[by assumption] y

@[simp]
theorem mem_inter_iff (x y : TSet α) :
    ∀ z : TSet β, z ∈' x ⊓' y ↔ z ∈' x ∧ z ∈' y := by
  sorry

def compl (x : TSet α) : TSet α :=
  (TSet.exists_compl hβ x).choose

notation:1024 x:1024 " ᶜ[" h "]" => _root_.ConNF.compl h x
notation:1024 x:1024 " ᶜ'" => xᶜ[by assumption]

@[simp]
theorem mem_compl_iff (x : TSet α) :
    ∀ z : TSet β, z ∈' xᶜ' ↔ ¬z ∈' x := by
  sorry

notation:1024 "{" x "}[" h "]" => _root_.ConNF.singleton h x
notation:1024 "{" x "}'" => {x}[by assumption]

@[simp]
theorem mem_singleton_iff (x y : TSet β) :
    y ∈' {x}' ↔ y = x := by
  sorry

notation:1024 "{" x ", " y "}[" h "]" => _root_.ConNF.TSet.up h x y
notation:1024 "{" x ", " y "}'" => {x, y}[by assumption]

@[simp]
theorem mem_up_iff (x y z : TSet β) :
    z ∈' {x, y}' ↔ z = x ∨ z = y := by
  sorry

notation:1024 "⟨" x ", " y "⟩[" h ", " h' "]" => _root_.ConNF.TSet.op h h' x y
notation:1024 "⟨" x ", " y "⟩'" => ⟨x, y⟩[by assumption, by assumption]

theorem op_def (x y : TSet γ) :
    (⟨x, y⟩' : TSet α) = { {x}', {x, y}' }' := by
  sorry

def singletonImage' (x : TSet β) : TSet α :=
  (TSet.exists_singletonImage hβ hγ hδ hε x).choose

@[simp]
theorem singletonImage'_spec (x : TSet β) :
    ∀ z w,
    ⟨ {z}', {w}' ⟩' ∈' singletonImage' hβ hγ hδ hε x ↔ ⟨z, w⟩' ∈' x := by
  sorry

def insertion2' (x : TSet γ) : TSet α :=
  (TSet.exists_insertion2 hβ hγ hδ hε hζ x).choose

@[simp]
theorem insertion2'_spec (x : TSet γ) :
    ∀ a b c, ⟨ { {a}' }', ⟨b, c⟩' ⟩' ∈' insertion2' hβ hγ hδ hε hζ x ↔
    ⟨a, c⟩' ∈' x := by
  sorry

def insertion3' (x : TSet γ) : TSet α :=
  (TSet.exists_insertion3 hβ hγ hδ hε hζ x).choose

theorem insertion3'_spec (x : TSet γ) :
    ∀ a b c, ⟨ { {a}' }', ⟨b, c⟩' ⟩' ∈' insertion3' hβ hγ hδ hε hζ x ↔
    ⟨a, b⟩' ∈' x := by
  sorry

def vCross (x : TSet γ) : TSet α :=
  (TSet.exists_cross hβ hγ hδ x).choose

@[simp]
theorem mem_vCross_iff (x : TSet γ) :
    ∀ a, a ∈' vCross hβ hγ hδ x ↔ ∃ b c, a = ⟨b, c⟩' ∧ c ∈' x := by
  sorry

def typeLower (x : TSet α) : TSet δ :=
  (TSet.exists_typeLower hβ hγ hδ hε x).choose

@[simp]
theorem mem_typeLower_iff (x : TSet α) :
    ∀ a, a ∈' typeLower hβ hγ hδ hε x ↔ ∀ b, ⟨ b, {a}' ⟩' ∈' x := by
  sorry

def converse' (x : TSet α) : TSet α :=
  (TSet.exists_converse hβ hγ hδ x).choose

@[simp]
theorem converse'_spec (x : TSet α) :
    ∀ a b, ⟨a, b⟩' ∈' converse' hβ hγ hδ x ↔ ⟨b, a⟩' ∈' x := by
  sorry

def cardinalOne : TSet α :=
  (TSet.exists_cardinalOne hβ hγ).choose

@[simp]
theorem mem_cardinalOne_iff :
    ∀ a : TSet β, a ∈' cardinalOne hβ hγ ↔ ∃ b, a = {b}' := by
  sorry

def subset' : TSet α :=
  (TSet.exists_subset hβ hγ hδ hε).choose

theorem subset'_spec :
    ∀ a b : TSet δ, ⟨a, b⟩' ∈' subset' hβ hγ hδ hε ↔ a ⊆[TSet ε] b := by
  sorry

end ConNF
