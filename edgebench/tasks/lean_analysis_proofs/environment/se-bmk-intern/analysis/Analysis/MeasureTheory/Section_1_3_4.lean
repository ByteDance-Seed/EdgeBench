import Analysis.MeasureTheory.Section_1_3_3

/-!
# Introduction to Measure Theory, Section 1.3.4: Absolute integrability

A companion to (the introduction to) Section 1.3.4 of the book "An introduction to Measure Theory".

-/

-- It is probably possible to unify the real and complex theory here using the `RCLike` class in Mathlib, but we will adopt the more pedestrian approach of duplicating definitions in the real and complex cases.

/-- Definition 1.3.17 -/

def UnsignedAbsolutelyIntegrable {d:ℕ} (f: EuclideanSpace' d → EReal) : Prop := UnsignedMeasurable f ∧ UnsignedLebesgueIntegral f < ⊤

def ComplexAbsolutelyIntegrable {d:ℕ} (f: EuclideanSpace' d → ℂ) : Prop := ComplexMeasurable f ∧ UnsignedLebesgueIntegral (EReal.abs_fun f) < ⊤

def RealAbsolutelyIntegrable {d:ℕ} (f: EuclideanSpace' d → ℝ) : Prop := RealMeasurable f ∧ UnsignedLebesgueIntegral (EReal.abs_fun f) < ⊤

lemma ComplexAbsolutelyIntegrable.abs {d:ℕ} (f: EuclideanSpace' d → ℂ) (hf: ComplexAbsolutelyIntegrable f) : UnsignedAbsolutelyIntegrable (EReal.abs_fun f) := by
  sorry

lemma RealAbsolutelyIntegrable.abs {d:ℕ} (f: EuclideanSpace' d → ℝ) (hf: RealAbsolutelyIntegrable f) : UnsignedAbsolutelyIntegrable (EReal.abs_fun f) := by
  sorry

lemma RealAbsolutelyIntegrable.iff {d:ℕ} (f: EuclideanSpace' d → ℝ) : RealAbsolutelyIntegrable f ↔ ComplexAbsolutelyIntegrable (fun x ↦ (f x:ℂ)) := by
  sorry

lemma ComplexAbsolutelyIntegrable.re {d:ℕ} (f: EuclideanSpace' d → ℂ) (hf: ComplexAbsolutelyIntegrable f) : RealAbsolutelyIntegrable (Complex.re_fun f) := by
  sorry

lemma ComplexAbsolutelyIntegrable.im {d:ℕ} (f: EuclideanSpace' d → ℂ) (hf: ComplexAbsolutelyIntegrable f) : RealAbsolutelyIntegrable (Complex.im_fun f) := by
  sorry

lemma ComplexAbsolutelyIntegrable.iff {d:ℕ} (f: EuclideanSpace' d → ℂ) : ComplexAbsolutelyIntegrable f ↔ RealAbsolutelyIntegrable (Complex.re_fun f) ∧ RealAbsolutelyIntegrable (Complex.im_fun f) := by
  sorry

noncomputable def UnsignedAbsolutelyIntegrable.integ {d:ℕ} (f: EuclideanSpace' d → EReal) (_: UnsignedAbsolutelyIntegrable f) : ℝ := (UnsignedLebesgueIntegral f).toReal

noncomputable def ComplexAbsolutelyIntegrable.norm {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) : ℝ := hf.abs.integ

noncomputable def RealAbsolutelyIntegrable.norm {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) : ℝ := hf.abs.integ

def RealMeasurable.measurable_pos {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealMeasurable f) : UnsignedMeasurable (EReal.pos_fun f) := by
  constructor
  · -- Unsigned: ∀ x, EReal.pos_fun f x ≥ 0
    intro x
    simp only [EReal.pos_fun]
    exact EReal.coe_nonneg.mpr (le_max_right _ _)
  · -- Exists approximating unsigned simple functions
    obtain ⟨g, hg_simple, hg_conv⟩ := hf
    use fun n => EReal.pos_fun (g n)
    constructor
    · intro n; exact (hg_simple n).pos
    · intro x
      simp only [EReal.pos_fun]
      have hcont : Continuous (fun y : ℝ => (max y 0).toEReal) :=
        continuous_coe_real_ereal.comp (continuous_max.comp (continuous_id.prodMk continuous_const))
      exact hcont.continuousAt.tendsto.comp (hg_conv x)

def RealMeasurable.measurable_neg {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealMeasurable f) : UnsignedMeasurable (EReal.neg_fun f) := by
  constructor
  · -- Unsigned: ∀ x, EReal.neg_fun f x ≥ 0
    intro x
    simp only [EReal.neg_fun]
    exact EReal.coe_nonneg.mpr (le_max_right _ _)
  · -- Exists approximating unsigned simple functions
    obtain ⟨g, hg_simple, hg_conv⟩ := hf
    use fun n => EReal.neg_fun (g n)
    constructor
    · intro n; exact (hg_simple n).neg
    · intro x
      simp only [EReal.neg_fun]
      have hcont : Continuous (fun y : ℝ => (max (-y) 0).toEReal) :=
        continuous_coe_real_ereal.comp (continuous_max.comp (continuous_neg.prodMk continuous_const))
      exact hcont.continuousAt.tendsto.comp (hg_conv x)

def RealAbsolutelyIntegrable.pos {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) : UnsignedAbsolutelyIntegrable (EReal.pos_fun f) := by
  constructor
  · exact hf.1.measurable_pos
  · -- UnsignedLebesgueIntegral (pos_fun f) ≤ UnsignedLebesgueIntegral (abs_fun f) < ⊤
    have h_le : ∀ x, EReal.pos_fun f x ≤ EReal.abs_fun f x := fun x => by
      simp only [EReal.pos_fun, EReal.abs_fun]
      apply EReal.coe_le_coe_iff.mpr
      rw [Real.norm_eq_abs, max_le_iff]
      exact ⟨le_abs_self _, abs_nonneg _⟩
    have h_mono : UnsignedLebesgueIntegral (EReal.pos_fun f) ≤ UnsignedLebesgueIntegral (EReal.abs_fun f) := by
      apply LowerUnsignedLebesgueIntegral.mono
      · exact hf.1.measurable_pos
      · exact hf.abs.1
      · exact AlmostAlways.ofAlways h_le
    exact lt_of_le_of_lt h_mono hf.2

def RealAbsolutelyIntegrable.neg {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) : UnsignedAbsolutelyIntegrable (EReal.neg_fun f) := by
  constructor
  · exact hf.1.measurable_neg
  · -- UnsignedLebesgueIntegral (neg_fun f) ≤ UnsignedLebesgueIntegral (abs_fun f) < ⊤
    have h_le : ∀ x, EReal.neg_fun f x ≤ EReal.abs_fun f x := fun x => by
      simp only [EReal.neg_fun, EReal.abs_fun]
      apply EReal.coe_le_coe_iff.mpr
      rw [Real.norm_eq_abs, max_le_iff]
      exact ⟨neg_le_abs _, abs_nonneg _⟩
    have h_mono : UnsignedLebesgueIntegral (EReal.neg_fun f) ≤ UnsignedLebesgueIntegral (EReal.abs_fun f) := by
      apply LowerUnsignedLebesgueIntegral.mono
      · exact hf.1.measurable_neg
      · exact hf.abs.1
      · exact AlmostAlways.ofAlways h_le
    exact lt_of_le_of_lt h_mono hf.2

noncomputable def RealAbsolutelyIntegrable.integ {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) : ℝ := hf.pos.integ - hf.neg.integ

noncomputable def ComplexAbsolutelyIntegrable.integ {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) : ℂ := hf.re.integ + Complex.I * hf.im.integ

open Classical in
noncomputable def RealLebesgueIntegral {d:ℕ} (f: EuclideanSpace' d → ℝ) : ℝ  := if hf: RealAbsolutelyIntegrable f then hf.integ else 0

open Classical in
noncomputable def ComplexLebesgueIntegral {d:ℕ} (f: EuclideanSpace' d → ℂ) : ℂ  := if hf: ComplexAbsolutelyIntegrable f then hf.integ else 0

def RealSimpleFunction.absolutelyIntegrable_iff' {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) : hf.AbsolutelyIntegrable ↔ RealAbsolutelyIntegrable f := by
  constructor
  · -- Forward: hf.AbsolutelyIntegrable → RealAbsolutelyIntegrable f
    intro hfi
    constructor
    · -- RealMeasurable f: use constant sequence
      exact ⟨fun _ => f, fun _ => hf, fun _ => tendsto_const_nhds⟩
    · -- UnsignedLebesgueIntegral (EReal.abs_fun f) < ⊤
      rw [UnsignedLebesgueIntegral, LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf.abs]
      exact hfi
  · -- Backward: RealAbsolutelyIntegrable f → hf.AbsolutelyIntegrable
    intro ⟨_, hf_integ⟩
    rw [RealSimpleFunction.AbsolutelyIntegrable, ← LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf.abs]
    exact hf_integ

def ComplexSimpleFunction.absolutelyIntegrable_iff' {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) : hf.AbsolutelyIntegrable ↔ ComplexAbsolutelyIntegrable f := by
  constructor
  · -- Forward: hf.AbsolutelyIntegrable → ComplexAbsolutelyIntegrable f
    intro hfi
    constructor
    · -- ComplexMeasurable f: use constant sequence
      exact ⟨fun _ => f, fun _ => hf, fun _ => tendsto_const_nhds⟩
    · -- UnsignedLebesgueIntegral (EReal.abs_fun f) < ⊤
      rw [UnsignedLebesgueIntegral, LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf.abs]
      exact hfi
  · -- Backward: ComplexAbsolutelyIntegrable f → hf.AbsolutelyIntegrable
    intro ⟨_, hf_integ⟩
    rw [ComplexSimpleFunction.AbsolutelyIntegrable, ← LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf.abs]
    exact hf_integ

def RealSimpleFunction.AbsolutelyIntegrable.integ_eq {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealSimpleFunction f) (hfi: hf.AbsolutelyIntegrable) : hf.integ = (hf.absolutelyIntegrable_iff'.mp hfi).integ := by
  -- hf.integ = (hf.pos).integ.toReal - (hf.neg).integ.toReal
  -- (hf.absolutelyIntegrable_iff'.mp hfi).integ = (UnsignedLebesgueIntegral (pos_fun f)).toReal - (UnsignedLebesgueIntegral (neg_fun f)).toReal
  simp only [RealSimpleFunction.integ, RealAbsolutelyIntegrable.integ, UnsignedAbsolutelyIntegrable.integ]
  congr 1
  · -- (hf.pos).integ.toReal = (UnsignedLebesgueIntegral (pos_fun f)).toReal
    rw [UnsignedLebesgueIntegral, LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf.pos]
  · -- (hf.neg).integ.toReal = (UnsignedLebesgueIntegral (neg_fun f)).toReal
    rw [UnsignedLebesgueIntegral, LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf.neg]

def ComplexSimpleFunction.AbsolutelyIntegrable.integ_eq {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexSimpleFunction f) (hfi: hf.AbsolutelyIntegrable) : hf.integ = (hf.absolutelyIntegrable_iff'.mp hfi).integ := by
  -- Both sides are defined as re.integ + I * im.integ
  simp only [ComplexSimpleFunction.integ, ComplexAbsolutelyIntegrable.integ]
  -- The key is that the re and im of the complex absolutely integrable give the same integral as the real simple function integrals
  have hf_re : RealSimpleFunction (Complex.re_fun f) := ComplexSimpleFunction.re hf
  have hf_im : RealSimpleFunction (Complex.im_fun f) := ComplexSimpleFunction.im hf
  congr 1
  · -- hf.re.integ = (hf.absolutelyIntegrable_iff'.mp hfi).re.integ
    have hre_fi : hf_re.AbsolutelyIntegrable := by
      rw [RealSimpleFunction.AbsolutelyIntegrable]
      have h := ComplexAbsolutelyIntegrable.re f (hf.absolutelyIntegrable_iff'.mp hfi)
      rw [RealAbsolutelyIntegrable, UnsignedLebesgueIntegral, LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf_re.abs] at h
      exact h.2
    have heq := RealSimpleFunction.AbsolutelyIntegrable.integ_eq hf_re hre_fi
    simp only [heq]
  · -- hf.im.integ = (hf.absolutelyIntegrable_iff'.mp hfi).im.integ
    have him_fi : hf_im.AbsolutelyIntegrable := by
      rw [RealSimpleFunction.AbsolutelyIntegrable]
      have h := ComplexAbsolutelyIntegrable.im f (hf.absolutelyIntegrable_iff'.mp hfi)
      rw [RealAbsolutelyIntegrable, UnsignedLebesgueIntegral, LowerUnsignedLebesgueIntegral.eq_simpleIntegral hf_im.abs] at h
      exact h.2
    have heq := RealSimpleFunction.AbsolutelyIntegrable.integ_eq hf_im him_fi
    simp only [heq]

theorem RealAbsolutelyIntegrable.add {d:ℕ} {f g: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) (hg: RealAbsolutelyIntegrable g) : RealAbsolutelyIntegrable (f + g) := by
  sorry

theorem ComplexAbsolutelyIntegrable.add {d:ℕ} {f g: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) (hg: ComplexAbsolutelyIntegrable g) : ComplexAbsolutelyIntegrable (f + g) := by
  sorry

theorem RealAbsolutelyIntegrable.sub {d:ℕ} {f g: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) (hg: RealAbsolutelyIntegrable g) : RealAbsolutelyIntegrable (f - g) := by
  sorry

theorem ComplexAbsolutelyIntegrable.sub {d:ℕ} {f g: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) (hg: ComplexAbsolutelyIntegrable g) : ComplexAbsolutelyIntegrable (f - g) := by
  sorry

theorem RealAbsolutelyIntegrable.smul {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) (c:ℝ) : RealAbsolutelyIntegrable (c • f) := by
  sorry

theorem ComplexAbsolutelyIntegrable.smul {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) (c:ℂ) : ComplexAbsolutelyIntegrable (c • f) := by
  sorry

theorem RealAbsolutelyIntegrable.of_neg {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) : RealAbsolutelyIntegrable (-f) := by
  sorry

theorem ComplexAbsolutelyIntegrable.of_neg {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) : ComplexAbsolutelyIntegrable (-f) := by
  sorry

theorem ComplexAbsolutelyIntegrable.conj {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) : ComplexAbsolutelyIntegrable (Complex.conj_fun f) := by
  sorry

@[ext]
structure PreL1 (d:ℕ) where
  f : EuclideanSpace' d → ℂ
  integrable : ComplexAbsolutelyIntegrable f

noncomputable def PreL1.norm {d:ℕ} {X:Type*} [RCLike X] (f: EuclideanSpace' d → X) := UnsignedLebesgueIntegral (EReal.abs_fun f)

def ComplexAbsolutelyIntegrable.to_PreL1 {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) : PreL1 d := ⟨ f, hf ⟩

def PreL1.conj {d:ℕ} (F: PreL1 d) : PreL1 d := ⟨ Complex.conj_fun F.f, F.integrable.conj ⟩

lemma ComplexAbsolutelyIntegrable.zero {d:ℕ} : ComplexAbsolutelyIntegrable (0 : EuclideanSpace' d → ℂ) := by
  sorry

-- Helper lemma: the norm of zero is zero
lemma ComplexAbsolutelyIntegrable.norm_zero {d:ℕ} : (ComplexAbsolutelyIntegrable.zero (d:=d)).norm = 0 := by
  sorry

instance PreL1.inst_AddZeroClass {d:ℕ} : AddZeroClass (PreL1 d) := {
  zero := ⟨ 0, ComplexAbsolutelyIntegrable.zero ⟩
  add F G := ⟨ F.f + G.f, F.integrable.add G.integrable ⟩
  zero_add := fun F => by
    apply PreL1.ext
    funext x
    -- Goal: (0 + F).f x = F.f x
    -- (0 + F).f = (⟨0, _⟩ + F).f = (0 : EuclideanSpace' d → ℂ) + F.f
    -- So goal is: (0 + F.f) x = F.f x, i.e., 0 x + F.f x = F.f x
    show (0 : EuclideanSpace' d → ℂ) x + F.f x = F.f x
    simp only [Pi.zero_apply, zero_add]
  add_zero := fun F => by
    apply PreL1.ext
    funext x
    show F.f x + (0 : EuclideanSpace' d → ℂ) x = F.f x
    simp only [Pi.zero_apply, add_zero]
}

instance PreL1.inst_addCommMonoid {d:ℕ} : AddCommMonoid (PreL1 d) := {
  add_assoc := fun F G H => by
    apply PreL1.ext
    funext x
    show (F.f + G.f) x + H.f x = F.f x + (G.f + H.f) x
    simp only [Pi.add_apply, add_assoc]
  add_comm := fun F G => by
    apply PreL1.ext
    funext x
    show F.f x + G.f x = G.f x + F.f x
    ring
  nsmul := nsmulRec
}

instance PreL1.inst_Neg {d:ℕ} : Neg (PreL1 d) := {
  neg F := ⟨ -F.f, F.integrable.of_neg ⟩
}

instance PreL1.inst_Sub {d:ℕ} : Sub (PreL1 d) := {
  sub F G := ⟨ F.f - G.f, F.integrable.sub G.integrable ⟩
}

instance PreL1.inst_module {d:ℕ} : Module ℂ (PreL1 d) := {
  smul c F := ⟨ c • F.f, F.integrable.smul c ⟩
  zero_smul := fun F => by
    apply PreL1.ext
    funext x
    show (0 : ℂ) • F.f x = (0 : EuclideanSpace' d → ℂ) x
    simp only [zero_smul, Pi.zero_apply]
  smul_zero := fun c => by
    apply PreL1.ext
    funext x
    show c • (0 : EuclideanSpace' d → ℂ) x = (0 : EuclideanSpace' d → ℂ) x
    simp only [Pi.zero_apply, smul_zero]
  one_smul := fun F => by
    apply PreL1.ext
    funext x
    show (1 : ℂ) • F.f x = F.f x
    simp only [one_smul]
  mul_smul := fun a b F => by
    apply PreL1.ext
    funext x
    show (a * b) • F.f x = a • (b • F.f x)
    simp only [mul_smul]
  smul_add := fun c F G => by
    apply PreL1.ext
    funext x
    show c • (F.f + G.f) x = (c • F.f + c • G.f) x
    simp only [Pi.add_apply, Pi.smul_apply, smul_add]
  add_smul := fun a b F => by
    apply PreL1.ext
    funext x
    show (a + b) • F.f x = (a • F.f + b • F.f) x
    simp only [Pi.add_apply, Pi.smul_apply, add_smul]
}

-- Helper: integral of the zero simple function is zero
lemma UnsignedSimpleFunction.integ_zero {d:ℕ} :
    let h_simple : UnsignedSimpleFunction (0 : EuclideanSpace' d → EReal) := by
      use 0, fun i => Fin.elim0 i, fun i => Fin.elim0 i
      exact ⟨fun i => Fin.elim0 i, by funext x; simp [Finset.univ_eq_empty]⟩
    h_simple.integ = 0 := by
  sorry

-- Helper: integral of unsigned measurable function is nonnegative
lemma UnsignedLebesgueIntegral.nonneg {d:ℕ} {f: EuclideanSpace' d → EReal} (hf: UnsignedMeasurable f) :
    0 ≤ UnsignedLebesgueIntegral f := by
  sorry

noncomputable instance PreL1.inst_seminormedAddCommGroup {d:ℕ} : SeminormedAddCommGroup (PreL1 d) := {
  norm F := F.integrable.norm
  neg F := ⟨ -F.f, F.integrable.of_neg ⟩
  zsmul := zsmulRec
  neg_add_cancel := fun F => by
    apply PreL1.ext
    funext x
    show (-F.f + F.f) x = (0 : EuclideanSpace' d → ℂ) x
    simp only [Pi.add_apply, Pi.neg_apply, Pi.zero_apply, neg_add_cancel]
  dist_self := fun F => by
    -- dist F F = ‖-F + F‖ where (-F + F).f = -F.f + F.f
    -- The goal after simp has { f := -F.f, ... } + F which is syntactically different from -F + F
    -- We use convert to bridge the gap
    suffices h : ComplexAbsolutelyIntegrable.zero.norm = 0 from by
      convert h using 2
      funext x
      show (F.f-F.f) x = (0 : EuclideanSpace' d → ℂ) x
      simp only [Pi.sub_apply, sub_self, Pi.ofNat_apply]
    exact ComplexAbsolutelyIntegrable.norm_zero
  dist_comm := fun F G => by
    -- dist F G = ‖-F+G‖, dist G F = ‖-G+F‖
    simp only [ComplexAbsolutelyIntegrable.norm, UnsignedAbsolutelyIntegrable.integ]
    congr 1; congr 1; funext x; simp only [EReal.abs_fun]; congr 1
    show ‖(F.f - G.f) x‖ = ‖(G.f - F.f) x‖
    simp only [Pi.sub_apply]
    rw [norm_sub_rev]
  dist_triangle := fun F G H => by
    -- dist F H ≤ dist F G + dist G H
    -- All use ‖-X + Y‖ form. We need to avoid simp expanding things.
    -- The norm of a PreL1 P is P.integrable.norm = (UnsignedLebesgueIntegral (EReal.abs_fun P.f)).toReal
    -- dist X Y = ‖-X + Y‖ = (-X + Y).integrable.norm
    -- Let's set up abbreviations that will definitionally match the goal
    let FH : PreL1 d := F - H
    let FG : PreL1 d := F - G
    let GH : PreL1 d := G - H
    -- The goal is: FH.integrable.norm ≤ FG.integrable.norm + GH.integrable.norm
    show FH.integrable.norm ≤ FG.integrable.norm + GH.integrable.norm
    simp only [ComplexAbsolutelyIntegrable.norm, UnsignedAbsolutelyIntegrable.integ]
    have h_eq : FH.f = FG.f + GH.f := by
      show (F.f - H.f) = (F.f - G.f) + (G.f - H.f)
      funext x; simp only [Pi.sub_apply, Pi.add_apply, sub_add_sub_cancel]
    have h_le : ∀ x, EReal.abs_fun FH.f x ≤ (EReal.abs_fun FG.f + EReal.abs_fun GH.f) x := fun x => by
      rw [h_eq]; simp only [EReal.abs_fun, Pi.add_apply]
      rw [← EReal.coe_add]
      exact EReal.coe_le_coe_iff.mpr (norm_add_le (FG.f x) (GH.f x))
    have hfg_abs := FG.integrable.abs
    have hgh_abs := GH.integrable.abs
    have hfh_abs := FH.integrable.abs
    have h_mono : UnsignedLebesgueIntegral (EReal.abs_fun FH.f) ≤
                  UnsignedLebesgueIntegral (EReal.abs_fun FG.f + EReal.abs_fun GH.f) := by
      apply LowerUnsignedLebesgueIntegral.mono hfh_abs.1 (UnsignedMeasurable.add hfg_abs.1 hgh_abs.1)
      exact AlmostAlways.ofAlways h_le
    have h_add : UnsignedLebesgueIntegral (EReal.abs_fun FG.f + EReal.abs_fun GH.f) =
                 UnsignedLebesgueIntegral (EReal.abs_fun FG.f) + UnsignedLebesgueIntegral (EReal.abs_fun GH.f) := by
      apply LowerUnsignedLebesgueIntegral.add hfg_abs.1 hgh_abs.1 (UnsignedMeasurable.add hfg_abs.1 hgh_abs.1)
    have h_ineq : UnsignedLebesgueIntegral (EReal.abs_fun FH.f) ≤
                  UnsignedLebesgueIntegral (EReal.abs_fun FG.f) + UnsignedLebesgueIntegral (EReal.abs_fun GH.f) := by
      rw [← h_add]; exact h_mono
    have h_finite_fh : UnsignedLebesgueIntegral (EReal.abs_fun FH.f) < ⊤ := hfh_abs.2
    have h_finite_fg : UnsignedLebesgueIntegral (EReal.abs_fun FG.f) < ⊤ := hfg_abs.2
    have h_finite_gh : UnsignedLebesgueIntegral (EReal.abs_fun GH.f) < ⊤ := hgh_abs.2
    have h_nonneg_fh : UnsignedLebesgueIntegral (EReal.abs_fun FH.f) ≠ ⊥ := by
      exact ne_of_gt (lt_of_lt_of_le EReal.bot_lt_zero (UnsignedLebesgueIntegral.nonneg hfh_abs.1))
    have h_nonneg_fg : UnsignedLebesgueIntegral (EReal.abs_fun FG.f) ≠ ⊥ := by
      exact ne_of_gt (lt_of_lt_of_le EReal.bot_lt_zero (UnsignedLebesgueIntegral.nonneg hfg_abs.1))
    have h_nonneg_gh : UnsignedLebesgueIntegral (EReal.abs_fun GH.f) ≠ ⊥ := by
      exact ne_of_gt (lt_of_lt_of_le EReal.bot_lt_zero (UnsignedLebesgueIntegral.nonneg hgh_abs.1))
    have h_sum_ne_top : UnsignedLebesgueIntegral (EReal.abs_fun FG.f) + UnsignedLebesgueIntegral (EReal.abs_fun GH.f) ≠ ⊤ :=
      (EReal.add_lt_top h_finite_fg.ne_top h_finite_gh.ne_top).ne_top
    rw [← EReal.toReal_add h_finite_fg.ne_top h_nonneg_fg h_finite_gh.ne_top h_nonneg_gh]
    exact EReal.toReal_le_toReal h_ineq h_nonneg_fh h_sum_ne_top
}

instance PreL1.inst_normedSpace {d:ℕ} : NormedSpace ℂ (PreL1 d) := {
  norm_smul_le := fun a F => by
    -- Goal: ‖a • F‖ ≤ ‖a‖ * ‖F‖
    -- ‖F‖ = F.integrable.norm for PreL1
    show (a • F).integrable.norm ≤ ‖a‖ * F.integrable.norm
    simp only [ComplexAbsolutelyIntegrable.norm, UnsignedAbsolutelyIntegrable.integ]
    -- Key fact: EReal.abs_fun (a • F.f) x = ‖a‖ * EReal.abs_fun F.f x
    have h_eq : ∀ x, EReal.abs_fun (a • F).f x = ‖a‖.toEReal * EReal.abs_fun F.f x := fun x => by
      simp only [EReal.abs_fun]
      -- Show ‖(a • F).f x‖ = ‖a‖ * ‖F.f x‖
      show (‖(a • F).f x‖ : EReal) = ‖a‖.toEReal * ‖F.f x‖.toEReal
      rw [show (a • F).f x = a * F.f x from rfl, norm_mul, EReal.coe_mul]
    have hf_abs := ComplexAbsolutelyIntegrable.abs F.f F.integrable
    have h_smul_eq : EReal.abs_fun (a • F).f = (fun x => ‖a‖.toEReal * EReal.abs_fun F.f x) := by
      funext x; exact h_eq x
    rw [h_smul_eq]
    have h_scale : UnsignedLebesgueIntegral (fun x => ‖a‖.toEReal * EReal.abs_fun F.f x) =
                   ‖a‖.toEReal * UnsignedLebesgueIntegral (EReal.abs_fun F.f) := by
      have h_eq' : (fun x => ‖a‖.toEReal * EReal.abs_fun F.f x) = (‖a‖.toEReal : EReal) • EReal.abs_fun F.f := by
        funext x; simp only [Pi.smul_apply, smul_eq_mul]
      rw [h_eq', UnsignedLebesgueIntegral]
      exact LowerUnsignedLebesgueIntegral.hom hf_abs.1 (norm_nonneg a)
    rw [h_scale]
    -- Now we have: (‖a‖.toEReal * UnsignedLebesgueIntegral (EReal.abs_fun F.f)).toReal ≤ ‖a‖ * (UnsignedLebesgueIntegral (EReal.abs_fun F.f)).toReal
    -- We actually have equality
    have h_finite : UnsignedLebesgueIntegral (EReal.abs_fun F.f) < ⊤ := hf_abs.2
    have h_nonneg : 0 ≤ UnsignedLebesgueIntegral (EReal.abs_fun F.f) := UnsignedLebesgueIntegral.nonneg hf_abs.1
    have h_ne_bot : UnsignedLebesgueIntegral (EReal.abs_fun F.f) ≠ ⊥ :=
      ne_of_gt (lt_of_lt_of_le EReal.bot_lt_zero h_nonneg)
    rw [EReal.toReal_mul]
    simp only [EReal.toReal_coe, le_refl]
}

theorem PreL1.dist_eq {d:ℕ} (F G: PreL1 d) : dist F G = ‖F-G‖ := by
  sorry

noncomputable abbrev L1 (d:ℕ) := SeparationQuotient (PreL1 d)

@[coe]
noncomputable def PreL1.toL1 {d:ℕ} (F: PreL1 d) : L1 d := SeparationQuotient.mk F

noncomputable instance PreL1.inst_coeL1 {d:ℕ} : Coe (PreL1 d) (L1 d) := ⟨ PreL1.toL1 ⟩

noncomputable def ComplexAbsolutelyIntegrable.toL1 {d:ℕ} {f:EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) : L1 d := SeparationQuotient.mk hf.to_PreL1

theorem L1.dist_eq {d:ℕ} (f g: EuclideanSpace' d → ℂ) (hf: ComplexAbsolutelyIntegrable f) (hg: ComplexAbsolutelyIntegrable g) : dist hf.toL1 hg.toL1 = (hf.sub hg).norm := by
  sorry

theorem L1.dist_eq_zero {d:ℕ} (f g: EuclideanSpace' d → ℂ) (hf: ComplexAbsolutelyIntegrable f) (hg: ComplexAbsolutelyIntegrable g) : dist hf.toL1 hg.toL1 = 0 ↔ AlmostEverywhereEqual f g := by
  sorry

/-- Exercise 1.3.19 (Integration is linear) -/
noncomputable def L1.integ {d:ℕ} : L1 d →ₗ[ℂ] ℂ := {
  toFun := Quotient.lift (fun F ↦ F.integrable.integ) (by sorry)
  map_smul' := by sorry
  map_add' := by sorry
}

noncomputable def L1.conj {d:ℕ} : L1 d → L1 d := Quotient.lift (fun F ↦ (F.conj : L1 d)) (by sorry)

theorem L1.integ_conj {d:ℕ} (F: L1 d) : L1.integ (L1.conj F) = starRingEnd ℂ (L1.integ F) := by
  sorry

/-- Exercise 1.3.20 (Translation invariance)-/
theorem RealAbsolutelyIntegrable.trans {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) (a: EuclideanSpace' d) : RealAbsolutelyIntegrable (fun x ↦ f (x + a)) := by
  sorry

theorem RealAbsolutelyIntegrable.integ_trans {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) (a: EuclideanSpace' d) : (hf.trans a).integ = hf.integ  := by
  sorry

theorem ComplexAbsolutelyIntegrable.trans {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) (a: EuclideanSpace' d) : ComplexAbsolutelyIntegrable (fun x ↦ f (x + a)) := by
  sorry

theorem ComplexAbsolutelyIntegrable.integ_trans {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) (a: EuclideanSpace' d) : (hf.trans a).integ = hf.integ  := by
  sorry

/-- Exercise 1.3.20 (Linear change of variables)-/
theorem RealAbsolutelyIntegrable.comp_linear {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) {A: EuclideanSpace' d →ₗ[ℝ] EuclideanSpace' d} (hA: A.det ≠ 0) :
    RealAbsolutelyIntegrable (fun x ↦ f (A x)) := by
  sorry

theorem RealAbsolutelyIntegrable.integ_comp_linear {d:ℕ} {f: EuclideanSpace' d → ℝ} (hf: RealAbsolutelyIntegrable f) {A: EuclideanSpace' d →ₗ[ℝ] EuclideanSpace' d} (hA: A.det ≠ 0) :
    (hf.comp_linear hA).integ = |A.det|⁻¹ * hf.integ := by
  sorry

theorem ComplexAbsolutelyIntegrable.comp_linear {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) {A: EuclideanSpace' d →ₗ[ℝ] EuclideanSpace' d} (hA: A.det ≠ 0) :
    ComplexAbsolutelyIntegrable (fun x ↦ f (A x)) := by
  sorry

theorem ComplexAbsolutelyIntegrable.integ_comp_linear {d:ℕ} {f: EuclideanSpace' d → ℂ} (hf: ComplexAbsolutelyIntegrable f) {A: EuclideanSpace' d →ₗ[ℝ] EuclideanSpace' d} (hA: A.det ≠ 0) :
    (hf.comp_linear hA).integ = |A.det|⁻¹ * hf.integ := by
  sorry

/-- Exercise 1.3.20 (Compatibility with the Riemann integral)-/
theorem RiemannIntegrableOn.realAbsolutelyIntegrable {I: BoundedInterval} {f: ℝ → ℝ} (hf: RiemannIntegrableOn f I) : RealAbsolutelyIntegrable ((fun x ↦ (f x) * (I.toSet.indicator' x)) ∘ EuclideanSpace'.equiv_Real) := by
  sorry

theorem RiemannIntegral.eq_integ {I: BoundedInterval} {f: ℝ → ℝ} (hf: RiemannIntegrableOn f I) :
    riemannIntegral f I  = hf.realAbsolutelyIntegrable.integ := by
  sorry

/-- Exercise 1.3.21 (Absolute summability is a special case of absolute integrability)-/
theorem AbsolutelySummable.realAbsolutelyIntegrable_iff {a: ℤ → ℝ} : ∑' n, |a n|.toEReal < ⊤ ↔ RealAbsolutelyIntegrable (fun x ↦ a ⌊EuclideanSpace'.equiv_Real x⌋) := by
  sorry

theorem AbsolutelySummable.complexAbsolutelyIntegrable_iff {a: ℤ → ℂ} : ∑' n, ‖a n‖.toEReal < ⊤ ↔ ComplexAbsolutelyIntegrable (fun x ↦ a ⌊EuclideanSpace'.equiv_Real x⌋) := by
  sorry

def ComplexAbsolutelyIntegrableOn {d:ℕ} (f: EuclideanSpace' d → ℂ) (E: Set (EuclideanSpace' d)) : Prop := ComplexAbsolutelyIntegrable (f * Complex.indicator E)

noncomputable def ComplexAbsolutelyIntegrableOn.integ {d:ℕ} {f: EuclideanSpace' d → ℂ} {E: Set (EuclideanSpace' d)} (hf: ComplexAbsolutelyIntegrableOn f E) : ℂ :=
  ComplexAbsolutelyIntegrable.integ hf

/-- Exercise 1.3.22 -/
theorem ComplexAbsolutelyIntegrableOn.glue {d:ℕ} {f: EuclideanSpace' d → ℂ} {E F: Set (EuclideanSpace' d)} (hdisj: Disjoint E F) (hf: ComplexAbsolutelyIntegrableOn f (E ∪ F)) : ∃ hE : ComplexAbsolutelyIntegrableOn f E, ∃ hF: ComplexAbsolutelyIntegrableOn f F, hf.integ = hE.integ + hF.integ := by
  sorry

def ComplexAbsolutelyIntegrableOn.restrict {d:ℕ} {f: EuclideanSpace' d → ℂ} {E F: Set (EuclideanSpace' d)} (hf: ComplexAbsolutelyIntegrableOn f E) (hF: LebesgueMeasurable F): ComplexAbsolutelyIntegrableOn (f * Complex.indicator F) E := by sorry

def ComplexAbsolutelyIntegrableOn.mono {d:ℕ} {f: EuclideanSpace' d → ℂ} {E F: Set (EuclideanSpace' d)} (hf: ComplexAbsolutelyIntegrableOn f E) (hE: LebesgueMeasurable E) (hF: LebesgueMeasurable F) (hsub: F ⊆ E): ComplexAbsolutelyIntegrableOn f F := by sorry

theorem ComplexAbsolutelyIntegrableOn.integ_restrict {d:ℕ} {f: EuclideanSpace' d → ℂ} {E F: Set (EuclideanSpace' d)} (hE: LebesgueMeasurable E) (hF: LebesgueMeasurable F) (hsub: F ⊆ E) (hf: ComplexAbsolutelyIntegrableOn f E) : (hf.mono hE hF hsub).integ = (hf.restrict hF).integ:= by
  sorry

/-- Lemma 1.3.19 (Triangle inequality) -/

-- Helper: |∫f| ≤ ∫|f| for real absolutely integrable functions
lemma RealAbsolutelyIntegrable.abs_integ_le {d:ℕ} {f: EuclideanSpace' d → ℝ}
    (hf: RealAbsolutelyIntegrable f) : |hf.integ| ≤ hf.abs.integ := by
  sorry

-- Helper: ∫|Re(f)| ≤ ∫|f| for complex absolutely integrable functions
lemma ComplexAbsolutelyIntegrable.re_abs_integ_le {d:ℕ} {f: EuclideanSpace' d → ℂ}
    (hf: ComplexAbsolutelyIntegrable f) : hf.re.abs.integ ≤ hf.abs.integ := by
  sorry

-- Key identity for pos/neg parts under addition
-- (f+g)⁺ + f⁻ + g⁻ = f⁺ + g⁺ + (f+g)⁻

-- Key lemmas about pos_fun and neg_fun under scaling

-- Helper: scalar multiplication linearity for real integral
lemma RealAbsolutelyIntegrable.integ_smul' {d:ℕ} {f: EuclideanSpace' d → ℝ}
    (hf: RealAbsolutelyIntegrable f) (c: ℝ) : (hf.smul c).integ = c * hf.integ := by
  sorry

-- Helper: addition linearity for real integral
lemma RealAbsolutelyIntegrable.integ_add' {d:ℕ} {f g: EuclideanSpace' d → ℝ}
    (hf: RealAbsolutelyIntegrable f) (hg: RealAbsolutelyIntegrable g) :
    (hf.add hg).integ = hf.integ + hg.integ := by
  sorry

-- Helper: subtraction linearity for real integral
lemma RealAbsolutelyIntegrable.integ_sub' {d:ℕ} {f g: EuclideanSpace' d → ℝ}
    (hf: RealAbsolutelyIntegrable f) (hg: RealAbsolutelyIntegrable g) :
    (hf.sub hg).integ = hf.integ - hg.integ := by
  sorry

-- Helper: scalar multiplication linearity for complex integral
lemma ComplexAbsolutelyIntegrable.integ_smul {d:ℕ} {f: EuclideanSpace' d → ℂ}
    (hf: ComplexAbsolutelyIntegrable f) (c: ℂ) : (hf.smul c).integ = c * hf.integ := by
  sorry

-- Helper: |u*f| integral equals |f| integral when |u| = 1

-- Helper: integ.re = re.integ for complex absolutely integrable functions
lemma ComplexAbsolutelyIntegrable.integ_re_eq_re_integ {d:ℕ} {f: EuclideanSpace' d → ℂ}
    (hf: ComplexAbsolutelyIntegrable f) : hf.integ.re = hf.re.integ := by
  sorry

-- Main theorem: ‖∫f‖ ≤ ∫|f| for complex absolutely integrable functions
theorem ComplexAbsolutelyIntegrable.abs_le {d:ℕ} {f: EuclideanSpace' d → ℂ}
    (hf: ComplexAbsolutelyIntegrable f) : ‖hf.integ‖ ≤ hf.abs.integ := by
  sorry
