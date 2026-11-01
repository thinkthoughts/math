# Reproducing the ETH bridge verification

## Pinned inputs

| Item | Value |
|---|---|
| Upstream repository | `openai/math` |
| Upstream revision | `7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a` |
| Toolchain | `leanprover/lean4:v4.34.1` (`lean/lean-toolchain`) |
| Mathlib | `d13f23b723b8a846827a245b89c10fc7d3f11612` (`lean/lake-manifest.json`) |
| Bridge branch | `eth-bridge/component-B` |
| Verified bridge HEAD (VPS) | `81ec97cd23d21675cee4ee76768fffba33a61e17` |
| Verified bridge tree (C2) | `1637f35b64e7f9f5d8f3c4e44e28007812a74f72` |
| Final theorem | `OAI.Bridges.ETH.not_positiveRateETH` |
| Expected axioms | `[propext, Classical.choice, Quot.sound]` |

The tree hash identifies file content independently of commit metadata. A checkout of the bridge
built from the patch series should satisfy:

```bash
git rev-parse HEAD^{tree}     # expect 1637f35b64e7f9f5d8f3c4e44e28007812a74f72 at C2
```

(The documentation commit changes the tree; check the C2 commit itself, `HEAD~1` after it.)

## 1. Source integrity

From the repository root:

```bash
# Only bridge files differ from the pinned upstream revision (docs/ excepted).
git diff --name-only 7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a HEAD -- . ':!lean/OAI/Bridges/ETH' ':!docs'
# expected: no output

# No placeholders, added axioms or trusted-code escapes in bridge files.
grep -nE '\bsorry\b|\badmit\b|^\s*axiom\b|native_decide|\bunsafe\b|implemented_by|extern' \
  lean/OAI/Bridges/ETH/*.lean
# expected: no output (grep exit status 1)
```

## 2. Build the final theorem

```bash
cd lean
lake exe cache get                                   # Mathlib build cache
LEAN_NUM_THREADS=2 lake build OAI.Bridges.ETH.FinalImplication
```

If your Lake version reads the argument as a library target rather than a module, use the module
form `lake build +OAI.Bridges.ETH.FinalImplication`.

The module ends with `#print axioms OAI.Bridges.ETH.not_positiveRateETH`, so a successful build log
contains the line

```
info: OAI/Bridges/ETH/FinalImplication.lean:27:0: 'OAI.Bridges.ETH.not_positiveRateETH' depends on axioms: [propext, Classical.choice, Quot.sound]
```

**Fresh versus warm builds.** A fresh build compiles OpenAI's `SqrtLogSpace.Final` closure (about
2,569 `OAI` modules) on top of Mathlib; this dominates the cost. A warm build replays cached
`.olean` files and is fast. The reference VPS build reported 11,600 jobs; job counts and durations
depend on the cache state, Lake version and machine, and will differ elsewhere.

`ConverterInterface.lean` (milestone B2.0, the `PolyProgram` obstruction) is outside the final
theorem's import closure. Build it separately to check it:

```bash
lake build +OAI.Bridges.ETH.ConverterInterface
```

To build every bridge module:

```bash
lake build $(for f in OAI/Bridges/ETH/*.lean; do echo "+$(echo ${f%.lean} | tr / .)"; done)
```

## 3. Inspect the theorem

Create `lean/Check.lean` (scratch file, outside the repository's libraries):

```lean
import OAI.Bridges.ETH.FinalImplication

#print OAI.Bridges.ETH.not_positiveRateETH
#print axioms OAI.Bridges.ETH.not_positiveRateETH
#check @OAI.ParityWL.Complexity.PositiveRateETH
#print OAI.ParityWL.Complexity.PositiveRateETH
#print OAI.ParityWL.Complexity.SATTimeBound
```

and run, after step 2:

```bash
lake env lean Check.lean
```

Expected: the theorem's type is `¬OAI.ParityWL.Complexity.PositiveRateETH` with no binders, its
value is `not_positiveRateETH_of_mainTheorem …original_sat_main`, and the axiom list is
`[propext, Classical.choice, Quot.sound]`. Delete `Check.lean` afterwards.

## 4. Optional: OpenAI's theorem and Comparator (historical checks)

These reproduce checks performed before the bridge existed; they are independent of the C3
verification above.

```bash
cd lean
LEAN_NUM_THREADS=2 lake build OAI.Algorithms.SubexponentialSAT.Main
```

`SqrtLogSpace/Final.lean` ends with `#print axioms` for `compiled_exact_count_and_sat`,
`exact_count_and_sat`, `exact_count_eth`, `sat_polynomial_space` and `original_sat_main`.

OpenAI's Comparator configuration is `lean/ComparatorChallenges/SubexponentialSAT.json`
(challenge module `ComparatorChallenges.SubexponentialSAT`, solution module
`OAI.Algorithms.SubexponentialSAT.Main`, theorem `…SqrtLogSpace.exact_count_and_sat`, permitted
axioms `propext`, `Quot.sound`, `Classical.choice`, `enable_nanoda: false`). Run it with your
Comparator installation as its documentation describes. Note that Comparator checks
`exact_count_and_sat`; the bridge uses `original_sat_main`, which the kernel checks in step 2.
