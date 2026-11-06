---
title: The sphere eversion project
---

This project is a formalization of the proof of existence of
[sphere eversions](https://www.youtube.com/watch?v=wO61D9x6lNY)
using the [Lean theorem prover](https://leanprover.github.io/),
mainly developed at [Microsoft Research](https://www.microsoft.com/en-us/research/)
by [Leonardo de Moura](https://leodemoura.github.io/).
More precisely we formalized the full *h*-principle for open and
ample first order differential relations, and deduce existence of sphere
eversions as a corollary.

The main motivations are:

* Demonstrating the proof assistant can handle geometric topology, and
  not only algebra or abstract nonsense. Note that Fabian Immler and
  Yong Kiam Tan already pioneered this direction by formalizing
  Poincaré-Bendixon, but this project has much larger scale.
* Exploring new infrastructure for collaborations on formalization
  projects, using the [interactive blueprint](blueprint/index.html).
* Producing a bilingual informal/formal document by keeping the
  blueprint and the formalization in sync.

The main statements that we formalized appear in [main.lean](https://github.com/leanprover-community/sphere-eversion/blob/master/src/main.lean). In particular the sphere eversion statement is:

```lean
theorem Smale :
  -- There exists a family of functions `f t` indexed by `ℝ` going from `𝕊²` to `ℝ³` such that
  ∃ f : ℝ → 𝕊² → ℝ³,
    -- it is smooth in both variables (for the obvious smooth structures on `ℝ × 𝕊²` and `ℝ³`) and
    (cont_mdiff (𝓘(ℝ, ℝ).prod (𝓡 2)) 𝓘(ℝ, ℝ³) ∞ ↿f) ∧
    -- `f 0` is the inclusion map, sending `x` to `x` and
    (f 0 = λ x, x) ∧
    -- `f 1` is the antipodal map, sending `x` to `-x` and
    (f 1 = λ x, -x) ∧
    -- every `f t` is an immersion.
    ∀ t, immersion (𝓡 2) 𝓘(ℝ, ℝ³) (f t)
```
