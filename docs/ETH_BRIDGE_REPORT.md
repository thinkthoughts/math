# A Lean bridge from OpenAI/math 378 to the ParityLifts ETH predicate

**Status:** kernel-checked, Lean 4.34.1.
**Upstream:** `openai/math` at `7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a`.
**Bridge:** `lean/OAI/Bridges/ETH/` (17 files, 3,328 added lines; no upstream file changed).
**Verified snapshot:** branch `eth-bridge/component-B`, HEAD `81ec97cd23d21675cee4ee76768fffba33a61e17`
(VPS canonical; see `ETH_BRIDGE_MANIFEST.md` for the hash correspondence).

---

## 1. Executive summary

Lean accepts the following theorem, with no hypotheses:

```lean
-- lean/OAI/Bridges/ETH/FinalImplication.lean:22
theorem OAI.Bridges.ETH.not_positiveRateETH : ¬ OAI.ParityWL.Complexity.PositiveRateETH
```

Its reported axioms are `[propext, Classical.choice, Quot.sound]` (VPS build, 11,600 jobs, exit 0;
§6).

The theorem connects two existing developments inside the pinned `openai/math` checkout:

* OpenAI's verified bounded-width SAT algorithm, `SqrtLogSpace.original_sat_main :
  SqrtLog.Statement.MainTheorem`, stated for a primitive multitape machine on a canonical CNF
  encoding;
* the ETH predicate `OAI.ParityWL.Complexity.PositiveRateETH` from the ParityLifts development,
  stated for a finite-alphabet multitape Turing machine on an ordinary 3-CNF encoding, where the
  repository uses it only as a hypothesis.

The bridge supplies everything in between: an exact input-format converter with a polynomial time
bound, a step-for-step machine translation, a fixed simulator with polynomial overhead, and the
rate argument.

**What the theorem is.** It refutes the named formal predicate `PositiveRateETH`. What that
predicate says is fixed by its Lean definition and the definitions it uses (§5). Whether it
coincides with a particular textbook formulation of the Exponential Time Hypothesis is a separate
mathematical judgment, discussed in §5.5; Lean's acceptance of the theorem does not settle it.

---

## 2. The two endpoints

### 2.1 OpenAI's main theorem

```lean
-- OAI/Algorithms/SubexponentialSAT/SqrtLog/StatementCanonical.lean
def DecidesWithBound (machine : PrimitiveMachine) (width : ℕ)
    (constant exponentConstant : ℝ) (degree : ℕ) : Prop :=          -- line 21
  ∀ (n : ℕ) (F : SAT.CNF (Fin n)), SAT.WidthAtMost width F →
    ∃ (answer : Bool) (time : ℕ),
      machine.OutputsInTime (Encoding.encodeCNF F) answer time ∧
      (answer = true ↔ SAT.Satisfiable F) ∧
      (time : ℝ) ≤ runtimeBound constant exponentConstant degree
        (Encoding.formulaBitLength F) n
def Feasible (width : ℕ) : Prop :=                                    -- line 31
  ∃ (machine : PrimitiveMachine) (constant exponentConstant : ℝ) (degree : ℕ),
    0 < constant ∧ 0 < exponentConstant ∧ 0 < degree ∧
      DecidesWithBound machine width constant exponentConstant degree
def MainTheorem : Prop := ∀ width : ℕ, 3 ≤ width → Feasible width     -- line 37

-- OAI/Algorithms/SubexponentialSAT/SqrtLogSpace/Final.lean:184
theorem original_sat_main : OAI.Algorithms.SubexponentialSAT.SqrtLog.Statement.MainTheorem
```

`PrimitiveMachine` (`Computation.lean:273`) has finitely many states and tapes; each cell holds
`Option Bool` on a Mathlib `Turing.Tape`; each state scans one tape. `OutputsInTime`
(`Computation.lean:311`) asserts a `RunsIn` trace of at most `time` steps from `init input` to a
state `Sum.inl answer`.

### 2.2 The ParityLifts ETH predicate

```lean
-- OAI/Combinatorics/ParityLifts/SATChoice.lean
def SATTimeBound (M : Machine) (B : ℕ → ℕ → ℝ) : Prop :=                -- line 25
  ∀ (N : ℕ) (F : Formula N), ∃ s b,
    Emits M (encodeFormula F) s b ∧ (b = true ↔ F.Satisfiable) ∧
    (s : ℝ) ≤ B N (encodeFormula F).length
def PositiveRateETH : Prop :=                                           -- line 32
  ∃ δ : ℝ, 0 < δ ∧ ¬ ∃ (M : Machine) (C : ℝ) (d : ℕ),
    0 < C ∧ SATTimeBound M (fun N L => C * (L + 1 : ℝ) ^ d * (2 : ℝ) ^ (δ * N))
```

`Formula N` (`SAT.lean:12`) is a list of clauses over `Fin N`, each a list of at most three
literals; repeated clauses and literals are allowed. `encodeFormula` (`SAT.lean:31`) writes `N`,
the clause count, and every clause in self-delimiting binary. `Machine` (`Machines.lean:25`) is a
deterministic multitape Turing machine with a finite alphabet (blank `0`, input bits `1`, `2`),
finitely many states, and heads moving at most one cell per step. `Emits M input s b`
(`Machines.lean:64`) says the machine is in an output state with answer `b` after `s` steps.

---

## 3. Verified theorem chain

Every signature below is copied from the Lean source at the verified snapshot.

### A — Runtime asymptotics (`RuntimeAsymptotics.lean`)

```lean
theorem runtimeFactor_expBound (K A : ℝ) (D : ℕ) (hK : 0 ≤ K) {r : ℝ} (hr : 0 < r) :
    ParityWL.Complexity.ExpBound
      (fun N => K * ((N : ℝ) + 1) ^ D * (2 : ℝ) ^ (A * runtimeScale N)) r
```

OpenAI's exponent `A · runtimeScale N` is absorbed into every positive rate `r`, through
`runtimeScale_ratio_tendsto` and `runtimeScale_eventually_le` (`runtimeScale n = o(n)`).

### B1 — Canonical CNF semantics and exact encoding (`CanonicalCNF.lean`, `CanonicalWord.lean`)

```lean
theorem bitCanonical_satisfiable {N : ℕ} (F : Formula N) :
    SAT.Satisfiable (canonicalCNF (bitCanonical F)) ↔ F.Satisfiable
theorem bitCanonical_width {N : ℕ} (F : Formula N) :
    SAT.WidthAtMost 3 (canonicalCNF (bitCanonical F))
theorem bitCanonical_varBound_le {N : ℕ} (F : Formula N) : varBound (bitCanonical F) ≤ N
def canonicalWord (G : BitFormula) : List Bool
theorem canonicalWord_eq (G : BitFormula) :
    canonicalWord G = Encoding.encodeCNF (canonicalCNF (decodeFormula G))
```

`bitCanonical F` is computed from `minimizeList F.bitList`, the value ParityLifts' front end
(`normalizeProgram`) hands to a decider. `canonicalWord` is an explicit list computation (decode,
OpenAI's literal code `2v + polarity`, deduplicate, insertion-sort, frame); `canonicalWord_eq` is
bit-for-bit equality with OpenAI's `encodeCNF`, for every `BitFormula`.

### B2 — Executable converter and polynomial overhead

| File | Key declarations |
|---|---|
| `ConverterInterface.lean` | `no_polyProgram_canonicalWord (P : PolyProgram BitFormula (List Bool) canonicalWord) : False` |
| `SortProgram.lean` | `sortByProgram`, `natSortProgram : PolyProgram (List ℕ) (List ℕ) (fun l => l.insertionSort (· ≤ ·))` |
| `LexProgram.lean` | `lexLeProgram : PolyProgram (List ℕ × List ℕ) Bool (fun x => decide (x.1 ≤ x.2))`, `clauseListSortProgram` |
| `DecodeProgram.lean` | `decodeProgram : TreeProgram (List Bool) ℕ decodeName`, `decodeProgram_time` |
| `SerializeProgram.lean` | `wordProgram`, `wordProgram_spec` |
| `Converter.lean` | `canonicalWordProgram : TreeProgram BitFormula (List Bool) canonicalWord`, `canonicalWordProgram_run`, `canonicalWordProgram_encodeCNF` |
| `ConverterSize.lean` | `inputSize_le`, `pairsSize_le` |
| `ConverterTime.lean` | `formulaPairsProgram_time_le` |
| `ConverterPoly.lean` | `convTime_expBound`, `canonicalWordProgram_time_poly`, `canonicalWordProgram_rbeval_uniform`, `converter_seq` |

```lean
theorem canonicalWordProgram_time_poly :
    ∃ C d : ℕ, ∀ (N : ℕ) (F : Formula N),
      canonicalWordProgram.time (minimizeList F.bitList) ≤ C * (N + 1) ^ d
theorem convTime_expBound : ExpBound (fun N => (convTime N : ℝ)) 0
theorem converter_seq {q : OAI.ParityWL.Complexity.FCode} {S : ℕ → ℝ} {b : DataTree} {N : ℕ}
    (F : Formula N)
    (hq : RBEval q (treeEncode (Encoding.encodeCNF (canonicalCNF (bitCanonical F)))) (S N) b) :
    RBEval (.seq canonicalWordProgram.code q) (treeEncode (minimizeList F.bitList))
      ((convTime N : ℝ) + S N + 1) b
```

`no_polyProgram_canonicalWord` explains the converter's interface: binary variable names decode to
unary numbers, so no program polynomial in input size alone computes `canonicalWord`. The
converter is therefore a `TreeProgram` whose time is bounded polynomially in `N` on the inputs
`minimizeList F.bitList` that actually occur. `ConverterInterface.lean` is outside the final
theorem's import closure (it justifies a design choice; the final theorem does not use it).

### C0 — Conditional reduction (`MachineInterface.lean`)

```lean
def PrimitiveSimulation (M : Computation.PrimitiveMachine) (q : FCode) (c e : ℕ) : Prop :=
  ∀ (w : List Bool) (b : Bool) (s : ℕ), M.OutputsInTime w b s →
    RBEval q (treeEncode w) ((c * (s + w.length + 1) ^ e : ℕ) : ℝ) (treeEncode b)
def SimulationHypothesis : Prop :=
  ∀ M : Computation.PrimitiveMachine, ∃ (q : FCode) (c e : ℕ), PrimitiveSimulation M q c e
theorem not_positiveRateETH_of_decider {M : Computation.PrimitiveMachine} {C A : ℝ} {d : ℕ}
    (hC : 0 ≤ C) (hdec : SqrtLog.Statement.DecidesWithBound M 3 C A d)
    {q : FCode} {c e : ℕ} (hsim : PrimitiveSimulation M q c e) :
    ¬ PositiveRateETH
theorem not_positiveRateETH_of_feasible_three_of_simulation
    (h : SqrtLog.Statement.Feasible 3) (hsim : SimulationHypothesis) : ¬ PositiveRateETH
```

`PrimitiveSimulation` and `SimulationHypothesis` are definitions (propositions), not axioms.

### C1a — Machine translation (`MachineTranslation.lean`)

```lean
@[reducible] def toParityMachine : Machine                 -- (M : Computation.PrimitiveMachine)
def TapeRep (T : Turing.Tape (Option Bool)) (h : ℤ) (f : ℤ → Fin 3) : Prop
def CfgRep (M : Computation.PrimitiveMachine) (c : M.Cfg)
    (x : Configuration (toParityMachine M)) : Prop
theorem init_rep (M : Computation.PrimitiveMachine) (w : List Bool) :
    CfgRep M (M.init w) (initialConfiguration (toParityMachine M) w)
theorem step_rep (M : Computation.PrimitiveMachine) {c c' : M.Cfg}
    {x : Configuration (toParityMachine M)} (h : CfgRep M c x) (hs : M.step c = some c') :
    CfgRep M c' (step (toParityMachine M) x)
theorem emits_of_outputsInTime (M : Computation.PrimitiveMachine) {w : List Bool} {b : Bool}
    {s : ℕ} (h : M.OutputsInTime w b s) : Emits (toParityMachine M) w s b
```

Cells `none / some false / some true ↦ 0 / 1 / 2`; OpenAI's input tape becomes ParityLifts tape 0;
one source step is one target step, so the time `s` is preserved exactly.

### C1b.1 — Executable runner (`MachineRunner.lean`)

```lean
noncomputable def primitiveRunner : FCode                  -- (M : Computation.PrimitiveMachine)
theorem primitiveRunner_correct (M : Computation.PrimitiveMachine) {w : List Bool} {b : Bool}
    {s : ℕ} (h : M.OutputsInTime w b s) :
    ∃ k ≤ s, BEval (primitiveRunner M) (treeEncode w) (runnerTime M w k) (treeEncode b)
```

A `.loop` over budgets `0, 1, 2, …` around ParityLifts' verified `PolyProgram.boundedAnswer`,
which reports the halt flag and the answer separately.

### C1b.2 — Polynomial runner cost (`MachineRunnerCost.lean`)

```lean
theorem runnerTime_le (M : Computation.PrimitiveMachine) (w : List Bool) (k : ℕ) :
    runnerTime M w k ≤ runnerPoly M (k + w.length + 1)
theorem primitiveRunner_poly (M : Computation.PrimitiveMachine) :
    ∃ c e : ℕ, PrimitiveSimulation M (primitiveRunner M) c e
theorem simulationHypothesis_proved : SimulationHypothesis
theorem not_positiveRateETH_of_feasible_three (h : SqrtLog.Statement.Feasible 3) :
    ¬ PositiveRateETH
theorem not_positiveRateETH_of_mainTheorem (h : SqrtLog.Statement.MainTheorem) :
    ¬ PositiveRateETH
```

### C2 — Final theorem (`FinalImplication.lean`)

```lean
theorem not_positiveRateETH : ¬ OAI.ParityWL.Complexity.PositiveRateETH :=
  not_positiveRateETH_of_mainTheorem OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.original_sat_main
```

Dependency chain of the final theorem:

```
not_positiveRateETH                                     (C2)
└─ not_positiveRateETH_of_mainTheorem                   (C1b.2)
   ├─ original_sat_main                                 (OpenAI)
   └─ not_positiveRateETH_of_feasible_three             (C1b.2)
      ├─ simulationHypothesis_proved                    (C1b.2 ← C1b.1 ← C1a)
      └─ not_positiveRateETH_of_feasible_three_of_simulation   (C0)
         └─ not_positiveRateETH_of_decider              (C0)
            ├─ runtimeFactor_expBound                   (A)
            ├─ converter_seq, convTime_expBound,
            │  canonicalWordProgram_time_le             (B2)
            ├─ bitCanonical_{width,satisfiable,varBound_le}   (B1)
            └─ sat_code_rate, SATTimeBound.rate_mono    (ParityLifts)
```

---

## 4. Complexity

### 4.1 OpenAI's Lean bound and the paper's bound

The Lean statement uses (`SqrtLog/StatementScale.lean:18,55`, natural logarithms):

```
runtimeScale n     = n · (log log (n + 16))² / √(log (n + 16))
runtimeBound C A d L n = C · (L + 1)^d · 2^(A · runtimeScale n)
```

so the verified machine runs in time `C (L+1)^d 2^{A n (log log n)² / √log n}` (asymptotically), with
`L` the canonical encoding's bit length. OpenAI's scope note (`lean/docs/378.md`) records that
the October 25 manuscript claims the sharper `(n+m)^{O_k(1)} 2^{O_k(n log log n / √log n)}`; that
sharper bound is a paper claim and is not what the Lean statement asserts. The bridge uses only
the Lean bound.

### 4.2 How subexponential dependence on `N` is preserved

For `F : Formula N`, the composed decider is the fixed code
`p = .seq canonicalWordProgram.code (primitiveRunner M)`.

1. **Converter.** `canonicalWordProgram_time_le` bounds the conversion by `convTime N`, and
   `convTime_expBound` shows `convTime` is polynomial (`ExpBound _ 0`). The canonical formula has at
   most `N` variables (`bitCanonical_varBound_le`) and an encoding of length at most `convTime N`
   (`encodeCNF_length_le_convTime`).
2. **Verified machine.** Its time is at most `C (convTime N + 1)^d 2^{A · runtimeScale n'}` with
   `n' ≤ N`. Component A bounds `2^{A · runtimeScale n'}` by `K (N+1)^{D'} 2^{r' N}` for any chosen
   `r' > 0`.
3. **Simulation.** `primitiveRunner_poly` costs `c (s + |w| + 1)^e` with `c, e` depending only on
   the machine.
4. **Budget.** The total `R N = convTime N + c (S N + convTime N + 1)^e + 1` satisfies
   `ExpBound R (e · r')` (`not_positiveRateETH_of_decider`, `MachineInterface.lean:81`).

### 4.3 Where the rate argument and uniformity are established

* **Rate.** In `not_positiveRateETH_of_decider`: given `δ > 0`, choose `r' = δ / (4(e+1))`, so
  `e · r' ≤ δ/4`; `sat_code_rate` (`ParityLifts/SATRates.lean:74`) with `ε = δ/2` yields rate
  `2 e r' + δ/2 ≤ δ`; `SATTimeBound.rate_mono` (`FixedBridge.lean:50`) adjusts it to `δ`.
* **Uniformity of the decider.** `p` and the resulting machine `(satCode p).decision` are fixed
  before `δ`, `N` and `F`. Constants of the converter are independent of `N` and `F`
  (`canonicalWordProgram_time_poly`); constants of the simulator depend only on `M`
  (`primitiveRunner_poly`).
* **Remark (not formalized).** Because the machine is independent of `δ`, the argument also
  appears to refute ParityLifts' stronger `UniformSubexponentialETH`; no such theorem is stated or
  checked.

---

## 5. Trust boundary

1. **Kernel acceptance.** Lean 4.34.1's kernel accepted `OAI.Bridges.ETH.not_positiveRateETH`
   in the VPS build (§6). Kernel acceptance covers the entire proof, including OpenAI's proof of
   `original_sat_main`, which is compiled as part of that build.
2. **Axioms.** `#print axioms` reports `[propext, Classical.choice, Quot.sound]`, Lean's standard
   foundational axioms. This rules out `sorryAx`, added axioms, and `native_decide`'s
   `Lean.ofReduceBool` anywhere in the proof's dependency graph. It says nothing about whether
   definitions mean what their names suggest.
3. **The imported OpenAI theorem.** `original_sat_main` is used only as a proof term. Its
   statement `MainTheorem` does not appear in the final theorem's statement, so the meaning of the
   final theorem does not depend on whether `MainTheorem` faithfully formalizes OpenAI's paper. Its
   correctness is covered by item 1. OpenAI's Comparator configuration checks a different
   declaration, `exact_count_and_sat`; `original_sat_main` is derived from it inside OpenAI's
   source and checked by the kernel, not by Comparator.
4. **The statement's definitions.** The final theorem's meaning is determined by
   `PositiveRateETH` and everything it unfolds to: `SATTimeBound`, `Machine`, `Configuration`,
   `step`, `run`, `Emits`, `Formula`, `Clause`, `Formula.Satisfiable`, `encodeFormula`,
   `encodeNat` (ParityLifts), and Mathlib's reals and real powers. These were written by OpenAI for
   the ParityLifts development and are used unchanged.
5. **Relation to conventional ETH.** The following judgments are outside Lean:
   * `PositiveRateETH` matches the standard form `s₃ > 0`: some `δ > 0` with no deterministic
     algorithm deciding 3-SAT in time `poly(L) · 2^{δN}`. Points to check: the model is a
     deterministic multitape Turing machine (refuting the hypothesis in this weak model yields
     algorithms in stronger models such as RAMs, which simulate it with small overhead); clauses
     have *at most* three literals and may repeat; `N` is the declared variable count; the
     polynomial factor is in the encoding length `L`; the constant `C` and degree `d` may depend on
     `δ`.
   * The binary encoding `encodeFormula` is a reasonable input convention.

---

## 6. Verification record

| Item | Evidence |
|---|---|
| Bridge milestones A–C1b.2 | Built in Claude's cloud checkout (Lean 4.34.1, Mathlib cache at the pinned manifest). Last full targeted build of the 16 non-final modules: 9,037 jobs, exit 0; 222 `#print axioms` lines, each a subset of `propext`, `Classical.choice`, `Quot.sound`. |
| Milestones on the VPS | Each milestone patch was re-applied with `git am` and audited on the VPS (operator-reported). |
| C2, final theorem | Not built in Claude's checkout: `SqrtLogSpace.Final` pulls 2,569 OpenAI modules. The C2 commit message therefore reads "NOT built in this environment", which was accurate when written. |
| C2 on the VPS (2026-11-01) | Operator-reported: target `OAI.Bridges.ETH.FinalImplication`, 11,600 jobs, exit 0; `not_positiveRateETH` axioms `[propext, Classical.choice, Quot.sound]`; HEAD `81ec97cd23d21675cee4ee76768fffba33a61e17`, clean tree; log `~/eth-bridge-C2-verified-11600.log`. |
| Source integrity (this checkout) | All commits since `7ef5c0c` add files only under `lean/OAI/Bridges/ETH/`; `git diff --name-only 7ef5c0c HEAD` lists nothing else. Strict scan for `sorry`, `admit`, `axiom` declarations, `native_decide`, `unsafe`, `implemented_by`, `extern` in bridge files: no matches. |
| Source facts | `not_positiveRateETH` has no explicit hypotheses and is defined from `original_sat_main`; `simulationHypothesis_proved : SimulationHypothesis` is a theorem, consumed by `not_positiveRateETH_of_feasible_three`. |

The C2 commit message is left as written; the sequence above is the record. Git history was not
rewritten.

---

## 7. Remaining interpretation questions

* Whether `PositiveRateETH` should be accepted as *the* ETH, or as one faithful formalization among
  several (e.g. randomized variants, sparse-formula variants, different encodings).
* Whether the trust placed in OpenAI's 2,569-module proof of `original_sat_main` is adequate for the
  intended audience; the kernel check covers it, but an independent re-check (e.g. with a second
  kernel such as nanoda, disabled in OpenAI's Comparator configuration) would strengthen it.
* Whether to state and check `¬ UniformSubexponentialETH`, which the argument appears to support.
