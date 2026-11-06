# Formalization of a generalized Carleson's theorem
A formalized proof of a generalized Carleson's theorem in the [Lean interactive theorem prover](https://lean-lang.org/).

## Links

* [Zulip channel](https://leanprover.zulipchat.com/#narrow/stream/442935-Carleson) for coordination
* [Webpage](https://florisvandoorn.com/carleson/)
* [Blueprint](https://florisvandoorn.com/carleson/blueprint/)
* [Blueprint as pdf](https://florisvandoorn.com/carleson/blueprint.pdf)
* [Dependency graph](https://florisvandoorn.com/carleson/blueprint/dep_graph_document.html)
* [Documentation pages for this repository](https://florisvandoorn.com/carleson/docs/)


## What is Carleson's theorem?

Carleson's theorem is a statement about Fourier analysis: given a continuous periodic function $f\colon ℝ\to ℝ$, its Fourier converges to $f$ point-wise at almost every point.
More precisely, let $f\colon\mathbb{R}\to \mathbb{C}$ be a $2\pi$-periodic bounded Borel measurable function.
For each integer $n\in\mathbb{Z}$, define the $n$-th Fourier coefficient as
```math
\widehat{f}_n := \frac{1}{2\pi} \int_0^{2\pi} f(x) e^{- i nx} dx.
```
For $N\geq 0$, define the partial Fourier sum as
```math
s_Nf(x):=\sum_{n=-N}^N \widehat{f}_n e^{i nx}.
```
Then Carleson's theorem states $\lim_{N\to\infty} s_N f(x) = f(x)$ for almost all $x\in\mathbb{R}$.

Despite being simple to state, its proof is very hard. (It is also quite subtle: for instance, asking for point-wise convergence *everywhere* makes this false.)
The precise English statement statement can be found [as Theorem 1.0.1](https://florisvandoorn.com/carleson/blueprint/sect0001.html#classical-carleson),
the corresponding Lean statement is [here](https://florisvandoorn.com/carleson/docs/find/?pattern=ClassicalCarleson#doc),
and the Lean proof [here](https://florisvandoorn.com/carleson/docs/find/?pattern=classical_carleson#doc).

### Metric space Carleson theorem

In this project, we deduce this statement from the boundedness of a certain linear operator, the so-called *Carleson operator*.
This boundedness holds in much greater generality: we formalise a new generalisation (due to the harmonic analysis group in Bonn) to [doubling metric measure spaces](Carleson/Defs.lean#L40).
The precise technical result we prove is the **metric spaces Carleson theorem** ([Theorem 1.1.1](https://florisvandoorn.com/carleson/blueprint/sect0001.html#metric-space-Carleson), [Lean statement](https://florisvandoorn.com/carleson/docs/find/?pattern=MetricSpaceCarleson#doc), [Lean proof](https://florisvandoorn.com/carleson/docs/find/?pattern=metric_carleson#doc)).

We also prove a **linearised metric space Carleson theorem** ([Theorem 1.1.2](https://florisvandoorn.com/carleson/blueprint/sect0001.html#linearised-metric-Carleson), [Lean statement](https://florisvandoorn.com/carleson/docs/find/?pattern=LinearizedMetricCarleson#doc), [Lean proof](https://florisvandoorn.com/carleson/docs/find/?pattern=linearized_metric_carleson#doc)),
which allows proving a generalisation of Carleson's theorem to [Walsh functions](https://en.wikipedia.org/wiki/Walsh_function).

The new definitions needed to verify the *statements* of these theorems are in the file [`Carleson.Defs`](Carleson/Defs.lean)

## Verifying the formalisation

This proof has been formalised in the Lean theorem prover.
To confirm the correctness and completeness yourself, follow these steps.
1. Make sure you have [installed Lean](https://leanprover-community.github.io/get_started.html).
2. Download the repository using `git clone https://github.com/fpvandoorn/carleson.git`.
3. Open the directory where you downloaded the repository (but not any further sub-directory). Open a terminal in this directory and run `lake exe cache get!` to download built dependencies.
4. Determine which Lean statement you want to verify: the Lean statements of the main theorems above are `classical_carleson`, `metric_carleson` and `linearized_metric_carleson`, respectively.
Open the file `Carleson.lean` in a text editor of your choice. Add the end of the file, add a line `#print axioms linearized_metric_carleson` (or similar). This will tell Lean to verify that the proof of this result was completed correctly.
5. In the terminal from step 3, run `lake build` to build all files in this repository. This will likely take 5-30 minutes.
When the process is complete, at the very end of the output, you will see a line `'linearized_metric_carleson' depends on axioms: [propext, Classical.choice, Quot.sound]` (followed by `Build completed successfully`).
This shows the proof is complete and correct. Had the build failed or the output included `sorryAx`, this would have indicated an error resp. an incomplete proof.
(For the experts: this shows which axioms Lean used in the course of the proof. These three axioms are built into Lean's type theory.)

## Contribute

### Locally

1. Make sure you have [installed Lean](https://leanprover-community.github.io/get_started.html).
2. Download the repository using `git clone https://github.com/fpvandoorn/carleson.git`.
3. Run `lake exe cache get!` to download built dependencies (this speeds up the build process).
4. Run `lake build` to build all files in this repository.

See the README of [Floris van Doorn's course repository](https://github.com/fpvandoorn/LeanCourse24) for more detailed instructions.

### In github codespaces

If you prefer, you can use online development environment:

<a href="https://codespaces.new/fpvandoorn/carleson"><img src="https://github.com/codespaces/badge.svg"/></a>

To make changes to this repository, please make a pull request. There are more tips in the file [Contributing.md](https://github.com/fpvandoorn/carleson/blob/master/CONTRIBUTING.md). To push your changes, the easiest method is to use the `Source Control` panel in VSCode.
Feel free to make pull requests with code that is work in progress, but make sure that the file(s)
you've worked have no errors (having `sorry`'s is fine of course).

## Build the blueprint

To test the Blueprint locally, you can compile `print.tex` using XeLaTeX (i.e. `xelatex print.tex` in the folder `blueprint/src`). If you have the Python package `invoke` you can also run `inv bp` which puts the output in `blueprint/print/print.pdf`.
If you want to build the web version of the blueprint locally, you need to install some packages by following the instructions [here](https://pypi.org/project/leanblueprint/). But if the pdf builds locally, you can also just make a pull request and use the online blueprint.
