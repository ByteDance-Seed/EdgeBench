---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

# layout: home
usemathjax: true
---

{% include mathjax.html %}

# Formalization of a generalized Carleson's theorem

A formalized proof of a generalized Carleson's theorem in Lean.

* [Zulip channel](https://leanprover.zulipchat.com/#narrow/stream/442935-Carleson) for coordination
* [Blueprint](https://florisvandoorn.com/carleson/blueprint/)
* [Blueprint as pdf](https://florisvandoorn.com/carleson/blueprint.pdf)
* [Dependency graph](https://florisvandoorn.com/carleson/blueprint/dep_graph_document.html)
* [Doc pages for this repository](https://florisvandoorn.com/carleson/docs/)

## Carleson's theorem

The classical statement of [Carleson's theorem](https://en.wikipedia.org/wiki/Carleson%27s_theorem) is easy. One phrasing is that if you have a continuous periodic function `f : ℝ → ℝ` then the Fourier series of `f` converges pointwise to `f` almost everywhere. However, the proof is very hard! In this project we will prove this theorem, from a much more general theorem, which was recently proved by Christoph Thiele and his group (it has not been published yet at the moment). This generalization proves the boundedness of a generalized Carleson operator on [doubling metric measure spaces](https://florisvandoorn.com/carleson/docs/Carleson/DoublingMeasure.html#DoublingMeasure).

## Contribute

To get the repository, make sure you have [installed Lean](https://leanprover-community.github.io/get_started.html). Then get the repository using `git clone https://github.com/fpvandoorn/carleson.git` and run `lake exe cache get!` inside the repository. Run `lake build` to build all files in this repository. See the README of [my course repository](https://github.com/fpvandoorn/LeanCourse23) for more detailed instructions.

To make changes to this repository, please make a pull request. There are more tips in the file [Contributing.md](https://github.com/fpvandoorn/carleson/blob/master/CONTRIBUTING.md)

To push your changes, the easiest method is to use the `Source Control` panel in VSCode.
Feel free to make pull requests with code that is work in progress, but make sure that the file(s)
you've worked have no errors (having `sorry`'s is fine of course).

## Build the blueprint

To test the Blueprint locally, you can compile `print.tex` using XeLaTeX (i.e. `xelatex print.tex` in the folder `blueprint/src`). If you have the Python package `invoke` you can also run `inv bp` which puts the output in `blueprint/print/print.pdf`.
If you want to build the web version of the blueprint locally, you need to install some packages by following the instructions [here](https://pypi.org/project/leanblueprint/). But if the pdf builds locally, you can also just make a pull request and use the online blueprint.
