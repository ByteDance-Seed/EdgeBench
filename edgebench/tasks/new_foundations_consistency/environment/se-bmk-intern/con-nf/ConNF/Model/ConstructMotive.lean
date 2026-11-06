import ConNF.Model.InductionStatement
import ConNF.Construction.NewModelData
import ConNF.Counting.Conclusions

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal WithBot

namespace ConNF

variable [Params.{u}] {α : Λ} (M : (β : Λ) → (β : TypeIndex) < α → Motive β)

def ltData :
    letI : Level := ⟨α⟩; LtData :=
  letI : Level := ⟨α⟩
  letI data : (β : TypeIndex) → [LtLevel β] → ModelData β :=
    λ β hβ ↦ β.recBotCoe (λ _ ↦ botModelData)
      (λ β hβ ↦ (M β hβ.elim).data) hβ
  letI positions : (β : TypeIndex) → [LtLevel β] → Position (Tangle β) :=
    λ β hβ ↦ β.recBotCoe (λ _ ↦ botPosition)
      (λ β hβ ↦ (M β hβ.elim).pos) hβ
  letI typedNearLitters : (β : Λ) → [LtLevel β] → TypedNearLitters β :=
    λ β hβ ↦ (M β hβ.elim).typed
  LtData.mk (data := data) (positions := positions) (typedNearLitters := typedNearLitters)

def newModelData' :
    letI : Level := ⟨α⟩; ModelData α :=
  letI : Level := ⟨α⟩
  letI : LtData := ltData M
  newModelData

def leData :
    letI : Level := ⟨α⟩; LeData :=
  letI : Level := ⟨α⟩
  letI data : (β : TypeIndex) → [LeLevel β] → ModelData β :=
    λ β hβ ↦ β.recBotCoe (λ _ ↦ botModelData)
      (λ β hβ ↦ if h : (β : TypeIndex) = α then
          cast (by rw [h]) (newModelData' M)
        else
          (M β (LeLevel.elim.lt_of_ne h)).data) hβ
  letI positions : (β : TypeIndex) → [LtLevel β] → Position (Tangle β) :=
    λ β hβ ↦ β.recBotCoe (λ _ ↦ botPosition)
      (λ β hβ ↦
        cast (by
          congr; unfold data; rw [recBotCoe_coe, dif_neg];
          exact (LtLevel.elim (β := β)).ne)
        (M β LtLevel.elim).pos) hβ
  LeData.mk (data := data) (positions := positions)

theorem leData_data_bot :
    (leData M).data ⊥ = botModelData := by
  sorry

theorem leData_data_lt {β : Λ} (hβ : (β : TypeIndex) < α) :
    (letI : Level := ⟨α⟩; letI : LeLevel β := ⟨hβ.le⟩; (leData M).data β) = (M β hβ).data := by
  sorry

theorem leData_data_eq :
    (letI : Level := ⟨α⟩; letI : LeLevel α := ⟨le_rfl⟩; (leData M).data α) = newModelData' M := by
  sorry

abbrev TSetLe (β : TypeIndex) (hβ : β ≤ α) : Type _ :=
    letI : Level := ⟨α⟩; letI := leData M; letI : LeLevel β := ⟨hβ⟩
    TSet β

abbrev AllPermLe (β : TypeIndex) (hβ : β ≤ α) : Type _ :=
    letI : Level := ⟨α⟩; letI := leData M; letI : LeLevel β := ⟨hβ⟩
    AllPerm β

abbrev TangleLe (β : TypeIndex) (hβ : β ≤ α) : Type _ :=
    letI : Level := ⟨α⟩; letI := leData M; letI : LeLevel β := ⟨hβ⟩
    Tangle β

def castTSetLeLt {β : Λ} (hβ : (β : TypeIndex) < α) :
    TSetLe M β hβ.le ≃ (M β hβ).data.TSet :=
  castTSet rfl (heq_of_eq <| leData_data_lt M hβ)

def castTSetLeEq {β : Λ} (hβ : (β : TypeIndex) = α) :
    TSetLe M β hβ.le ≃ (newModelData' M).TSet :=
  castTSet hβ (by cases hβ; exact heq_of_eq <| leData_data_eq M)

def castAllPermLeLt {β : Λ} (hβ : (β : TypeIndex) < α) :
    AllPermLe M β hβ.le ≃ (M β hβ).data.AllPerm :=
  castAllPerm rfl (heq_of_eq <| leData_data_lt M hβ)

def castAllPermLeEq {β : Λ} (hβ : (β : TypeIndex) = α) :
    AllPermLe M β hβ.le ≃ (newModelData' M).AllPerm :=
  castAllPerm hβ (by cases hβ; exact heq_of_eq <| leData_data_eq M)

def castTangleLeLt {β : Λ} (hβ : (β : TypeIndex) < α) :
    TangleLe M β hβ.le ≃ (letI := (M β hβ).data; Tangle β) :=
  castTangle rfl (heq_of_eq <| leData_data_lt M hβ)

def castTangleLeEq {β : Λ} (hβ : (β : TypeIndex) = α) :
    TangleLe M β hβ.le ≃ (letI := newModelData' M; Tangle α) :=
  castTangle hβ (by cases hβ; exact heq_of_eq <| leData_data_eq M)

theorem castTSetLeLt_forget {β : Λ} (hβ : (β : TypeIndex) < α) (x : TSetLe M β hβ.le) :
    (M β hβ).data.tSetForget (castTSetLeLt M hβ x) =
    letI : Level := ⟨α⟩; letI : LeLevel β := ⟨hβ.le⟩; ((leData M).data β).tSetForget x := by
  sorry

theorem castTSetLeEq_forget (x : TSetLe M α le_rfl) :
    (newModelData' M).tSetForget (castTSetLeEq M rfl x) =
    letI : Level := ⟨α⟩; letI : LeLevel α := ⟨le_rfl⟩; ((leData M).data α).tSetForget x := by
  sorry

theorem castAllPermLeLt_forget {β : Λ} (hβ : (β : TypeIndex) < α) (ρ : AllPermLe M β hβ.le) :
    (M β hβ).data.allPermForget (castAllPermLeLt M hβ ρ) =
    letI : Level := ⟨α⟩; letI : LeLevel β := ⟨hβ.le⟩; ((leData M).data β).allPermForget ρ := by
  sorry

theorem castAllPermLeEq_forget (ρ : AllPermLe M α le_rfl) :
    (newModelData' M).allPermForget (castAllPermLeEq M rfl ρ) =
    letI : Level := ⟨α⟩; letI : LeLevel α := ⟨le_rfl⟩; ((leData M).data α).allPermForget ρ := by
  sorry

theorem castTangleLeLt_support {β : Λ} (hβ : (β : TypeIndex) < α) (t : TangleLe M β hβ.le) :
    (letI := (M β hβ).data; (castTangleLeLt M hβ t).support) =
    letI : Level := ⟨α⟩; letI : LeLevel β := ⟨hβ.le⟩; letI := (leData M).data β; t.support := by
  sorry

theorem castAllPermLeLt_smul {β : Λ} (hβ : (β : TypeIndex) < α)
    (ρ : (M β hβ).data.AllPerm) (t : TangleLe M β hβ.le) :
    ρ • castTangleLeLt M hβ t = castTangleLeLt M hβ ((castAllPermLeLt M hβ).symm ρ • t) := by
  sorry

theorem castAllPermLeLt_smul' {β : Λ} (hβ : (β : TypeIndex) < α)
    (ρ : AllPermLe M β hβ.le) (t : TangleLe M β hβ.le) :
    castTangleLeLt M hβ (ρ • t) = castAllPermLeLt M hβ ρ • castTangleLeLt M hβ t := by
  sorry

theorem castAllPermLeLt_smul'' {β : Λ} (hβ : (β : TypeIndex) < α)
    (ρ : AllPermLe M β hβ.le) (t : letI := (M β hβ).data; Tangle β) :
    castAllPermLeLt M hβ ρ • t = castTangleLeLt M hβ (ρ • (castTangleLeLt M hβ).symm t) := by
  sorry

theorem castTangleLeLt_pos {β : Λ} (hβ : (β : TypeIndex) < α) (t : TangleLe M β hβ.le) :
    (M β hβ).pos.pos (castTangleLeLt M hβ t) =
    letI : Level := ⟨α⟩; letI : LtLevel β := ⟨hβ⟩; ((leData M).positions β).pos t := by
  sorry

theorem castTangleLeLt_fuzz {β : Λ} (hβ : (β : TypeIndex) < α) (t : TangleLe M β hβ.le)
    {γ : Λ} (hβγ : (β : TypeIndex) ≠ γ) :
    (letI := (M β hβ).data; letI := (M β hβ).pos; fuzz hβγ (castTangleLeLt M hβ t)) =
    letI : Level := ⟨α⟩; letI : LtLevel β := ⟨hβ⟩; letI := (leData M).data β; fuzz hβγ t := by
  sorry

variable (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h))

def preCoherentData :
    letI : Level := ⟨α⟩; PreCoherentData :=
  letI : Level := ⟨α⟩
  letI := leData M
  {
    allPermSderiv := λ {β γ} _ _ hγ ρ ↦
      β.recBotCoe (C := λ β ↦ [LeLevel β] → γ < β → AllPerm β → AllPerm γ)
        (λ hγ ↦ (not_lt_bot hγ).elim)
        (λ β _ hγ ρ ↦
          letI : LtLevel γ := ⟨hγ.trans_le LeLevel.elim⟩
          if h : (β : TypeIndex) = α then
            letI := ltData M
            γ.recBotCoe (C := λ γ ↦ [LtLevel γ] →
                ((ltData M).data γ).AllPerm → AllPermLe M γ LeLevel.elim)
              id (λ _γ _ ρ ↦ (castAllPermLeLt M _).symm ρ)
              ((castAllPermLeEq M h ρ).sderiv γ)
          else
            γ.recBotCoe (C := λ γ ↦ [LtLevel γ] → γ < β →
                ((leData M).data β).AllPerm → AllPermLe M γ LeLevel.elim)
              (λ _ ρ ↦ (H β (LeLevel.elim.lt_of_ne h)).allPermBotSderiv (castAllPermLeLt M _ ρ))
              (λ _γ _ hγ ρ ↦ (castAllPermLeLt M _).symm <|
                (H β (LeLevel.elim.lt_of_ne h)).allPermSderiv hγ (castAllPermLeLt M _ ρ))
              hγ ρ)
        hγ ρ
    singleton := λ {β γ} _ _ hγ x ↦
      letI : LtLevel γ := ⟨hγ.trans_le LeLevel.elim⟩
      if h : (β : TypeIndex) = α then
        letI := ltData M
        (castTSetLeEq M h).symm (Option.some (newSingleton (castTSetLeLt M _ x)))
      else
        (castTSetLeLt M _).symm ((H β (LeLevel.elim.lt_of_ne h)).singleton hγ (castTSetLeLt M _ x))
  }

theorem preCoherentData_allPermSderiv_forget {β γ : TypeIndex}
    [iβ : letI : Level := ⟨α⟩; LeLevel β] [iγ : letI : Level := ⟨α⟩; LeLevel γ]
    (hγ : γ < β) (ρ : AllPermLe M β iβ.elim) :
    ((leData M).data γ).allPermForget ((preCoherentData M H).allPermSderiv hγ ρ) =
    ((leData M).data β).allPermForget ρ ↘ hγ := by
  sorry

theorem preCoherentData_pos_atom_lt_pos
    (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h))
    {β : TypeIndex} [iβ : letI : Level := ⟨α⟩; LtLevel β] (t : TangleLe M β iβ.elim.le)
    (A : β ↝ ⊥) (a : Atom) (ha : a ∈ (letI := (leData M).data β; Tangle.support t ⇘. A)ᴬ) :
    pos a < ((leData M).positions β).pos t := by
  sorry

theorem preCoherentData_pos_nearLitter_lt_pos
    (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h))
    {β : TypeIndex} [iβ : letI : Level := ⟨α⟩; LtLevel β] (t : TangleLe M β iβ.elim.le)
    (A : β ↝ ⊥) (N : NearLitter) (hN : N ∈ (letI := (leData M).data β; Tangle.support t ⇘. A)ᴺ) :
    pos N < ((leData M).positions β).pos t := by
  sorry

theorem preCoherentData_smul_fuzz
    {β : Λ} {γ : TypeIndex} {δ : Λ} [iβ : letI : Level := ⟨α⟩; LeLevel β]
    [iγ : letI : Level := ⟨α⟩; LtLevel γ] [iδ : letI : Level := ⟨α⟩; LtLevel δ]
    (hγ : γ < β) (hδ : (δ : TypeIndex) < β) (hγδ : γ ≠ δ)
    (ρ : AllPermLe M β iβ.elim) (t : TangleLe M γ iγ.elim.le) :
    letI : Level := ⟨α⟩; letI := preCoherentData M H
    ((leData M).data β).allPermForget ρ ↘ hδ ↘. • fuzz hγδ t =
    fuzz hγδ ((preCoherentData M H).allPermSderiv hγ ρ • t) := by
  sorry

theorem preCoherentData_allPerm_of_smulFuzz
    {β : Λ} [iβ : letI : Level := ⟨α⟩; LeLevel β]
    (ρs : letI : Level := ⟨α⟩; {γ : TypeIndex} → [LtLevel γ] → γ < β → AllPermLe M γ LeLevel.elim)
    (hρs : letI : Level := ⟨α⟩; ∀ {γ : TypeIndex} {δ : Λ}
      [LtLevel γ] [LtLevel δ] (hγ : γ < β) (hδ : (δ : TypeIndex) < β) (hγδ : γ ≠ δ)
      (t : TangleLe M γ LeLevel.elim),
      letI := preCoherentData M H;
      ((leData M).data δ).allPermForget (ρs hδ) ↘. • fuzz hγδ t = fuzz hγδ (ρs hγ • t)) :
    letI : Level := ⟨α⟩
    ∃ ρ : AllPermLe M β LeLevel.elim, ∀ (γ : TypeIndex) [LtLevel γ] (hγ : γ < β),
      (preCoherentData M H).allPermSderiv hγ ρ = ρs hγ := by
  sorry

theorem preCoherent_tSet_ext
    (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h))
    {β γ : Λ} [iβ : letI : Level := ⟨α⟩; LeLevel β] [iγ : letI : Level := ⟨α⟩; LeLevel γ]
    (hγ : (γ : TypeIndex) < β) (x y : letI : Level := ⟨α⟩; TSetLe M β LeLevel.elim)
    (hxy : letI : Level := ⟨α⟩; ∀ (z : TSetLe M γ LeLevel.elim), z ∈[hγ] x ↔ z ∈[hγ] y) :
    x = y := by
  sorry

theorem typedMem_singleton_iff
    {β γ : Λ} [iβ : letI : Level := ⟨α⟩; LeLevel β] [iγ : letI : Level := ⟨α⟩; LeLevel γ]
    (hγ : (γ : TypeIndex) < β) (x y : letI : Level := ⟨α⟩; TSetLe M γ LeLevel.elim) :
    y ∈[hγ] (preCoherentData M H).singleton hγ x ↔ y = x := by
  sorry

def coherentData :
    letI : Level := ⟨α⟩; CoherentData :=
  letI : Level := ⟨α⟩
  letI := preCoherentData M H
  {
    allPermSderiv_forget := preCoherentData_allPermSderiv_forget M H
    pos_atom_lt_pos := preCoherentData_pos_atom_lt_pos M H
    pos_nearLitter_lt_pos := preCoherentData_pos_nearLitter_lt_pos M H
    smul_fuzz := preCoherentData_smul_fuzz M H
    allPerm_of_basePerm := λ π ↦ ⟨π, rfl⟩
    allPerm_of_smulFuzz := preCoherentData_allPerm_of_smulFuzz M H
    tSet_ext := preCoherent_tSet_ext M H
    typedMem_singleton_iff := typedMem_singleton_iff M H
  }

theorem newModelData_card_tangle_le
    (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h)) :
    #(letI := newModelData' M; Tangle α) ≤ #μ := by
  sorry

def constructMotive (α : Λ) (M : (β : Λ) → (β : TypeIndex) < α → Motive β)
    (H : (β : Λ) → (h : (β : TypeIndex) < α) → Hypothesis (M β h) λ γ h' ↦ M γ (h'.trans h)) :
    Motive α :=
  letI : Level := ⟨α⟩
  letI : LtData := ltData M
  letI := newModelData
  {
    data := newModelData,
    pos := newPosition (newModelData_card_tangle_le M H),
    typed := newTypedNearLitters (newModelData_card_tangle_le M H)
  }

end ConNF
