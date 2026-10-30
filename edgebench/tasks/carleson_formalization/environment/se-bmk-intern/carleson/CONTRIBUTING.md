Contributions are welcome!

If you start formalizing any of the results mentioned in the blueprint, please announce this on Zulip first, in the [Carleson channel](https://leanprover.zulipchat.com/#narrow/channel/442935-Carleson/). Small fixes are always welcome, and need not be discussed in advance. Simply make a pull request with a change.

Note: the html blueprint has some rendering issues with certain equations and references. Consult the pdf if you see this on the html page.

Some remarks:
* Some statements will be missing hypotheses. Don't hesitate adding hypotheses to a result, especially if it is already assumed elsewhere. Assuming that functions are measurable is always fine.
* Please add small additional lemmas liberally.
* Some statements might need to be modified, or additional lemmas added. E.g. some estimates about norms or `ENNReal.toReal` will need a separate statement that the value is (almost everywhere) finite.
* Feel free to change definitions/theorem statements to more convenient versions. Especially when deciding to put (in)equalities in `ℝ≥0∞`, `ℝ≥0` or `ℝ`, it is hard to know what is most convenient in advance.
* With suprema, it's probably most convenient to take suprema over `ℝ≥0∞`, and potentially apply `ENNReal.toReal` afterwards.
* Many inequalities are up to some constant factor (depending on `a` and `q`).
  We put these constants in a separate definition, so that the proofs hopefully break slighlty less easily.
  *If you prove a theorem with a constant used other theorems with constants, it is **encouraged**
  to define your constant in terms of the other constants, and to not unfold the constants of the other theorems*.

  Feel free to improve these constants:
  - either just write a comment in the Lean file that the constant can be improved to X
  - or improve the constant in Lean with a comment that this has to be incorporated in the blueprint
  - or improve the constant both in Lean and the TeX file, making sure you also fix all downstream uses of the lemma.
* If you are writing lemma statements yourself, make sure to look at the class [`ProofData`](https://florisvandoorn.com/carleson/docs/Carleson/Defs.html#ProofData), which contains a lot of the common data/assumptions used throughout sections 2-8.

Below, I will try to give a translation of some notation/conventions. We use mathcal/mathfrak unicode characters liberally to make the Lean look similar to the blueprint.

| Blueprint | Lean       | Remarks |
| --------- | ---------- | ------- |
| `⊂`       | `⊆`       |         |
| `\dot{\bigcup}` |  `⋃ ...` and `PairwiseDisjoint` separately | notation for disjoint union
| `𝔓(𝔓')`   | `lowerCubes 𝔓'` |         |
| `λp ≲ λ'p'`   | `smul l p ≤ smul l' p' ` |         |
| `p ≲ p'`   | `smul 1 p ≤ smul 1 p' ` | Beware that this is not the same as `p ≤ p'`. |
| `d_B(f,g)`   | `dist_{x, r} f g` | Assuming `B = B(x,r)` is the ball with center `x` and radius `r`. Lean also has the variants `nndist_` and `ball_`. |
| `d_{Iᵒ}(f,g)`   | `dist_{I} f g` |  |
| `d_{𝔭}(f,g)`   | `dist_(𝔭) f g` | `d_{𝔭}(f,g) = d_{𝓘(p)ᵒ}(f,g)`. |
| `Kₛ(x, y)`       | `Ks s x y`       |         |
| `T_* f(x)`       | `nontangentialOperator K f x`       | The associated nontangential Calderon Zygmund operator |
| `T_Q^θ f(x)`       | `linearizedNontangentialOperator Q θ K f x`       | The linearized associated nontangential Calderon Zygmund operator |
| `T f(x)`       | `carlesonOperator K f x` | The generalized Carleson operator        |
| `T_Q f(x)`       | `linearizedCarlesonOperator Q K f x` | The linearized generalized Carleson operator        |
| `T_𝓝^θ f(x)`       | `nontangentialMaximalFunction θ f x` |   |
| `Tₚ f(x)`       | `carlesonOn p f x`       |         |
| `T_ℭ f(x)`       | `carlesonSum ℭ f x`       | The sum of Tₚ f(x) for p ∈ ℭ. In the blueprint only used in chapter 7, but in the formalization we will use it more.        |
| `Tₚ* f(x)`       | `adjointCarleson p f x`       |         |
| `T_r g(x)` | `czOperator K r g x` |
| `T_*^r g(x)` | `simpleNontangentialOperator K r g x` |
| `e(x)`       | `Complex.exp (Complex.I * x)` |         |
| `𝔓(I)`       | `𝓘 ⁻¹' {I}` |         |
| `I ⊆ J`         | `I ≤ J`      | We noticed recently that we cannot (easily) assume that the coercion `Grid X → Set X` is injective. Therefore, Lean introduces two orders on `Grid X`: `I ⊆ J` means that the underlying sets satisfy this relation, and `I ≤ J` means *additionally* that `s I ≤ s J`. The order is what you should use in (almost?) all cases. |
| `𝓓`         | `Grid`      | The unicode characters were causing issues with Overleaf and leanblueprint (on Windows) |
| `𝔓_{G\G'}`       | `𝔓pos` |         |
| `𝔓₂`       | `𝔓₁ᶜ` |         |
| `M_{𝓑, p} f(x)` | `maximalFunction μ 𝓑 c r p f x` |     |
| `M_𝓑 f(x)` | `MB μ 𝓑 c r f x`       | equals `M_{𝓑, 1}`    |
| `M`        | `globalMaximalFunction volume 1` |     |
| `I_i(x)`        | `cubeOf i x` |     |
| `R_Q(θ, x)`        | `upperRadius Q θ x` |     |
| `S_{1,𝔲} f(x)`        | `boundaryOperator t u f x` |     |
| `S_{2,𝔲} g(x)`        | `adjointBoundaryOperator t u g x` |     |
| `𝔘`        | `t` | `t` is the (implicit) forest, sometimes `(t : Set (𝔓 X))` is required. It is equivalent to `t.𝔘` |
| `u ∈ 𝔘`        | `u ∈ t` | `t` is the (implicit) forest, and this notation is equivalent to `u ∈ t.𝔘` |
| `𝔗(u)`        | `t u` | `t` is the (implicit) forest, and this notation is equivalent to `t.𝔗 u`  |
| `𝔘ⱼ`        | `rowDecomp t j` | sometimes `(rowDecomp t j : Set (𝔓 X))`    |
| `𝔗ⱼ(u)`        | `rowDecomp t j u` |     |
| `E`        | `E` |     |
| `Eⱼ`        | `rowSupport t j` |     |
| `M_n`        | `modulationOperator n` |     |
| `L_N`        | `approxHilbertTransform N` |     |
| `k_r`        | `niceKernel r` |     |
