---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

# layout: home
---

# New Foundations is consistent

In 1937, Quine proposed a set theory called "New Foundations", and since 2010, Randall Holmes has claimed to have a proof of its consistency.
In this repository, we use the interactive theorem prover Lean to verify the difficult part of his proof, thus proving that New Foundations is indeed consistent.
The proof is now complete, and the theorem statements can be found in `ConNF/Model/Result.lean` ([source](https://github.com/leanprover-community/con-nf/blob/main/ConNF/Model/Result.lean), [docs](https://leanprover-community.github.io/con-nf/doc/ConNF/Model/Result.html)).

See [our website](https://leanprover-community.github.io/con-nf/) for more information, the [documentation of our Lean code](https://leanprover-community.github.io/con-nf/doc/), and the [deformalisation paper](https://zeramorphic.github.io/con-nf-paper/main.l.pdf) that translates the Lean definitions into English.
You can also read the [blueprint](https://leanprover-community.github.io/con-nf/blueprint/) that contains a human-readable version of the proof following the Lean code, with links to the formalisations of each statement.

To run our code locally, install [elan](https://github.com/leanprover/elan), clone the repository, and run the following command in a terminal in the repository's root directory.
```
lake exe cache get
```
The code can then be viewed in an editor such as Visual Studio Code, or compiled directly from the command-line using `lake build`.

## Objective

It is known that New Foundations is consistent if and only if a theory called Tangled Type Theory (TTT) is consistent (see theorem 1 [here](https://randall-holmes.github.io/Papers/tangled.pdf)).
We have formally constructed a model of TTT in Lean, thus proving (on paper) that New Foundations is consistent, or in short, Con(NF).
We are working from various versions of the paper proof by Holmes:

- [untangled.pdf](https://randall-holmes.github.io/Nfproof/untangled.pdf);
- [retangled.pdf](https://randall-holmes.github.io/Nfproof/retangled.pdf);
- [newnfdoc.pdf](https://randall-holmes.github.io/Nfproof/newnfdoc.pdf);
- [maybedetangled.pdf](https://randall-holmes.github.io/Nfproof/maybedetangled.pdf),

but many alterations and additions have been made to make the proof compatible with Lean's type theory.

This project depends on [mathlib](https://github.com/leanprover-community/mathlib4), the community mathematical library written in Lean.
This allows us to use familiar results about things like cardinals and groups without having to prove them ourselves.

Every definition and theorem in mathlib and this project have been checked by Lean's trusted kernel, which computationally verifies that the proofs we have constructed are indeed correct.
However, Lean cannot check that the statements of the definitions and theorems match their intended English equivalents, so when drawing conclusions from the code in this project, translation to and from English must be done with care.

## Tangled type theory

TTT is a many-sorted set theory with equality "=" and the membership relation "∈".
The sorts are indexed by a limit ordinal λ, and elements of λ are called type indices.
A formula "x = y" is well-formed if x and y have the same type, and a formula "x ∈ y" is well-formed if x has any type less than y.

One of the axioms of tangled type theory is extensionality, which stipulates that a set of type α is uniquely determined by its elements of *any* type β < α.
This is strange: for example, if two sets of type α differ, they have different type β elements for *every* β < α.
This property makes it difficult to construct models of TTT.

## Strategy

Our construction of the model uses the following rough strategy.

### Construction of the base type

Let λ be a limit ordinal, κ > λ be a regular ordinal, and μ > κ be a strong limit cardinal with cofinality at least κ.
Sets of size less than κ are called *small*.

We first construct an auxiliary type at level -1, called the *base type*, below all types that will eventually become part of the model.
Elements of this type are called atoms (although they are not atoms in the ZFU or NFU sense, for instance).
There are μ atoms, partitioned into *litters* of size κ.

### Constructing each type

At each type level α, we will produce a collection of model elements for our intended model of TTT, which we will sometimes call *t-sets*.
We also produce a group of permutations, called *allowable permutations*, which act on the t-sets.
The membership relation is preserved under the action of allowable permutations.
Each t-set is stipulated to have a *support* under the action of allowable permutations; this is a small set of objects called *addresses*, such that whenever an allowable permutation fixes all elements of a support, it also fixes the t-set.

Each t-set at level α will be given a preferred extension of some type β < α, and we can recover from a t-set's elements which extension it prefers.
The extensions of such a t-set in other lower types can be deduced from its β-extension.
This allows us to satisfy TTT's extensionality axiom.

### Controlling the size of each type

Each type α can only be constructed under the assumption that all types β < α are of size exactly μ (among other hypotheses).
It is easy to prove that the collection of t-sets at level α has cardinality at least μ, so we need to show that there are at most μ elements of this set.
We do this by showing that there are not that many fundamentally different descriptions of tangles under the action of allowable permutations.
This requires the [freedom of action theorem](https://leanprover-community.github.io/con-nf/doc/ConNF/FOA/Result.html#ConNF.StructApprox.freedom_of_action), which is a technical lemma that allows us to construct allowable permutations.
The main result of this section is [here](https://leanprover-community.github.io/con-nf/doc/ConNF/Counting/Conclusions.html#ConNF.mk_tSet).

### Finishing the induction

We can then run the above process recursively to produce the types of tangles at all type levels α.
This is an easy step to perform in set theory, but requires a lot of work in type theory because of the interconnectedness of the various inductive hypotheses we need.
We then check that our construction indeed produces a model of TTT by checking that it satisfies a finite axiomatisation of the theory.
We have chosen to convert Hailperin's finite axiomatisation of NF's comprehension scheme into a finite axiomatisation of TTT, which we present in our [results file](https://leanprover-community.github.io/con-nf/doc/ConNF/Model/Result.html).
Note, however, that this choice is arbitrary, and any other finite axiomatisation can be easily proven with the infrastructure already in place.

## Dependency graph

[![dependency graph](https://leanprover-community.github.io/con-nf/depgraph.png)](https://leanprover-community.github.io/con-nf/depgraph.pdf)
