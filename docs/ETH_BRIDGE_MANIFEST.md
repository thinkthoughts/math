# ETH bridge manifest

**Upstream (unchanged):** `openai/math` `7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a`
(tree `f806cbcc16dfed1010abe0a7457651c008ae346c`).
**Canonical verified snapshot (VPS):** `eth-bridge/component-B` at
`81ec97cd23d21675cee4ee76768fffba33a61e17` (milestone C2).
**Final theorem:** `OAI.Bridges.ETH.not_positiveRateETH : ¬ OAI.ParityWL.Complexity.PositiveRateETH`,
axioms `[propext, Classical.choice, Quot.sound]`.

## Modules

All paths are under `lean/OAI/Bridges/ETH/`. "Final closure" marks modules imported, directly or
transitively, by `FinalImplication.lean`, and so rebuilt by the final VPS build.

| Milestone | Module | Key declarations | Final closure | Status |
|---|---|---|---|---|
| A | `RuntimeAsymptotics.lean` | `runtimeFactor_expBound` | yes | verified |
| B1a | `CanonicalCNF.lean` | `bitCanonical_satisfiable`, `bitCanonical_width`, `bitCanonical_varBound_le` | yes | verified |
| B1b | `CanonicalWord.lean` | `canonicalWord`, `canonicalWord_eq`, `canonicalWord_bridge` | yes | verified |
| B2.0 | `ConverterInterface.lean` | `no_polyProgram_canonicalWord` | **no** | verified at B2.0 only |
| B2.1 | `SortProgram.lean` | `sortByProgram`, `sortBy_eq_insertionSort`, `natSortProgram` | yes | verified |
| B2.2 | `LexProgram.lean` | `listLe_iff`, `lexLeProgram`, `clauseListSortProgram` | yes | verified |
| B2.3 | `DecodeProgram.lean` | `decodeProgram`, `decodeProgram_time`, `decodeProgram_rbeval` | yes | verified |
| B2.4 | `SerializeProgram.lean` | `wordProgram`, `wordProgram_spec`, `cnfBody_length_le` | yes | verified |
| B2.5a | `Converter.lean` | `canonicalWordProgram`, `canonicalWordProgram_run`, `canonicalWordProgram_encodeCNF` | yes | verified |
| B2.5b.1 | `ConverterSize.lean` | `inputSize_le`, `pairsSize_le` | yes | verified |
| B2.5b.2 | `ConverterTime.lean` | `mapProgram_time_le`, `formulaPairsProgram_time_le` | yes | verified |
| B2.5b.3 | `ConverterPoly.lean` | `convTime_expBound`, `canonicalWordProgram_time_poly`, `converter_seq` | yes | verified |
| C0 | `MachineInterface.lean` | `PrimitiveSimulation`, `SimulationHypothesis`, `not_positiveRateETH_of_decider` | yes | verified |
| C1a | `MachineTranslation.lean` | `toParityMachine`, `step_rep`, `emits_of_outputsInTime` | yes | verified |
| C1b.1 | `MachineRunner.lean` | `primitiveRunner`, `primitiveRunner_correct`, `primitiveRunner_rbeval` | yes | verified |
| C1b.2 | `MachineRunnerCost.lean` | `primitiveRunner_poly`, `simulationHypothesis_proved`, `not_positiveRateETH_of_mainTheorem` | yes | verified |
| C2 | `FinalImplication.lean` | `not_positiveRateETH` | yes | verified on VPS only (see report §6) |

"Verified" means built with Lean 4.34.1 with every `#print axioms` a subset of
`propext`, `Classical.choice`, `Quot.sound`, and re-audited on the VPS after `git am`.

## Commit correspondence

Claude produced each milestone as a commit in its own checkout and delivered it with
`git format-patch`; the VPS applied the patches with `git am`. `git am` records a new committer and
commit date, so commit hashes differ between the two repositories. The **tree hash** depends only
on file content and is the same wherever the same files are committed; it is the cross-check.

| Milestone | Claude commit | Tree | VPS commit |
|---|---|---|---|
| A | `673baee02a7d9b640d08161d24d61bded1ae24d4` | `3f60a4bff5ee4d11d3497d7f193be2e0c500c77a` | `02ff4b35f…` (abbreviated, as reported) |
| B1a | `7928b8a63941232924b42c445b8a26081bdedfbe` | `73b3cd577b7e0f2f9567eea88be6fb90cf252229` | `c4dfd2e2e…` (abbreviated, as reported) |
| B1b | `e0729932cc5a16159d3f90dd6b5d3cf0c343cb7d` | `302ba857ebcbff661df497044dee677ac8c01197` | not recorded here |
| B2.0 | `86c1ea7e8b0307db8ab33a53dd8ee6f995f77aa0` | `d2f32d73eeb52674917ccb60176fe898f8e3692f` | not recorded here |
| B2.1 | `9d212e0389a7b24548a93cc5ac0abe635231e361` | `1b76bb190ab3085b557a251e454e5d33b202e0b2` | not recorded here |
| B2.2 | `21043b4fa19c5b00cdae0145c49c5d8a341a5969` | `929fb790394a5a1c84fd19be495aa45456c46ea3` | not recorded here |
| B2.3 | `c9b1bc63624fd6c9ca9f937117afbe117d9eb23d` | `495747cfe1e77e0f1adb96edae367bc15992e553` | not recorded here |
| B2.4 | `dd090ad8006d291e2e1ff94921dc780249ae536d` | `5492cff4366080d55e8c88dfc8663409c473d97e` | not recorded here |
| B2.5a | `88dab33f2d78723ecde24500ee51fb043b3ffb58` | `6a9a81819a22d372105c350a42d7777c01c8c254` | not recorded here |
| B2.5b.1 | `3e11a8b0d730645ba3b74f8fa64c6f6260563072` | `f9070f13dce9fcd810e44001b60952f030743e32` | not recorded here |
| B2.5b.2 | `39d1b08982d658f6f5e20d8d5fcafa691ac2cd26` | `420d54831fd31d2845de32f647f16adc41309d77` | not recorded here |
| B2.5b.3 | `ca7fdc78e0a76b1c4549edf717470aa8425b5086` | `6658afcbb93579d803fdccb23b3366159c213d73` | not recorded here |
| C0 | `69a907f245e1b065b21f310b6e811adf4a013191` | `7bf71579838858e7ee8bbd0dadf4543652ff0d62` | not recorded here |
| C1a | `8895698b0065cc46ab329d7f613e519a62da8348` | `14abf5df6fe329e40fafbe5c7bf5c79ac7449f5a` | not recorded here |
| C1b.1 | `fb4b72be14509c6239a724a72401fd2c696ef70a` | `99dfd4698afe3a69bfc7f15d791b7a7c54c8ebdc` | not recorded here |
| C1b.2 | `ce3e0c9a38d5afc6802d2d2702548986e1d424f6` | `ae1dfc8cdf9b4421240044318eac34e98f05d5de` | not recorded here |
| C2 | `fac349c48348b807fe1d1f03ca77b04e0fe5bb44` | `1637f35b64e7f9f5d8f3c4e44e28007812a74f72` | `81ec97cd23d21675cee4ee76768fffba33a61e17` |

To fill in and check the VPS column:

```bash
git log --reverse --format='%H %T %s' 7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a..HEAD
```

Each `%T` should equal the tree in the table; in particular
`git rev-parse 81ec97cd23d21675cee4ee76768fffba33a61e17^{tree}` should print
`1637f35b64e7f9f5d8f3c4e44e28007812a74f72`. This assumes the VPS applied the patches onto
`7ef5c0c` without other changes; a different base or extra files would change the tree.

## Commit-message note

The C2 commit message reads "final instantiation (NOT built in this environment)". That was
accurate in Claude's checkout, which could not compile OpenAI's 2,569-module proof. The module was
later built on the VPS (2026-11-01, 11,600 jobs, exit 0, axioms `[propext, Classical.choice,
Quot.sound]`). The message is kept as written; this note and the report's §6 are the record.
