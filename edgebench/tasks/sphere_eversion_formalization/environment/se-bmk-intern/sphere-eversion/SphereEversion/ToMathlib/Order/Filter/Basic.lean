import Mathlib.Order.Filter.Basic

theorem Filter.EventuallyEq.eventuallyEq_ite {X Y : Type*} {l : Filter X} {f g : X → Y}
    {P : X → Prop} [DecidablePred P] (h : f =ᶠ[l] g) :
    (fun x ↦ if P x then f x else g x) =ᶠ[l] f := by
  sorry
