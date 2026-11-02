import OAI.Bridges.AnthropicETH.Reduction

/-!
# RPI-378.3a audit

Building this module prints the axioms of the reduction and fails if the reduction could have
borrowed either upstream ETH result:

1. **Module check.** No module whose name starts with `OAI.Algorithms`, `OAI.Bridges.ETH`,
   `Solution`, `Challenge`, `WidthThree`, `PaddedDescent`, `Groundwork` or `ToTuring` is loaded,
   and `MainResults` is the only Anthropic module present.
2. **Constant check.** Every constant reachable from the statement and proof of
   `ethIsFalse_of_not_positiveRateETH` lives in Lean core, Mathlib, `MainResults`,
   `OAI.ParityWL`, `OAI.Combinatorics.ParityLifts`, or `OAI.Bridges.AnthropicETH`.
-/

open Lean Meta Elab Command

namespace OAI.Bridges.AnthropicETH.Audit

/-- Module-name prefixes that must be absent from the environment. -/
def forbiddenModulePrefixes : List Name :=
  [`OAI.Algorithms, `OAI.Bridges.ETH, `Solution, `Challenge, `WidthThree, `PaddedDescent,
    `Groundwork, `ToTuring, `Bridge]

/-- Constant-name prefixes that must be absent from the dependency closure. -/
def forbiddenConstPrefixes : List Name :=
  [`OAI.Algorithms, `OAI.Bridges.ETH, `MainResults.ethIsFalse, `MainResults.mainTheorem,
    `Sat3, `WidthThree, `Groundwork, `Bridge]

/-- All constants reachable from `c` through types and values. -/
partial def closure (env : Environment) (c : Name) : NameSet := Id.run do
  let mut seen : NameSet := {}
  let mut todo : Array Name := #[c]
  while h : todo.size > 0 do
    let n := todo.back
    todo := todo.pop
    if seen.contains n then continue
    seen := seen.insert n
    if let some ci := env.find? n then
      for m in ci.type.getUsedConstants do todo := todo.push m
      if let some v := ci.value? (allowOpaque := true) then
        for m in v.getUsedConstants do todo := todo.push m
  return seen

end OAI.Bridges.AnthropicETH.Audit

open OAI.Bridges.AnthropicETH.Audit in
run_cmd do
  let env ← getEnv
  let mods := env.header.moduleNames
  let bad := mods.filter fun m => forbiddenModulePrefixes.any (·.isPrefixOf m)
  unless bad.isEmpty do throwError "forbidden modules loaded: {bad}"
  logInfo m!"module check passed: {mods.size} modules loaded, none forbidden"
  let target := `OAI.Bridges.AnthropicETH.ethIsFalse_of_not_positiveRateETH
  let cl := closure env target
  let badC := cl.toList.filter fun n => forbiddenConstPrefixes.any (·.isPrefixOf n)
  unless badC.isEmpty do throwError "forbidden constants in closure: {badC}"
  -- every reachable constant from an OAI-side module is in the two permitted namespaces
  let oai := cl.toList.filter fun n =>
    (`OAI).isPrefixOf n && !((`OAI.ParityWL).isPrefixOf n ||
      (`OAI.Combinatorics.ParityLifts).isPrefixOf n || (`OAI.Bridges.AnthropicETH).isPrefixOf n)
  logInfo m!"constant check passed: {cl.size} constants reachable; OAI constants outside \
    ParityWL/ParityLifts/AnthropicETH: {oai}"

#print axioms OAI.Bridges.AnthropicETH.ethIsFalse_of_not_positiveRateETH
#print axioms OAI.Bridges.AnthropicETH.inTime_of_not_positiveRateETH
#print axioms OAI.Bridges.AnthropicETH.ethIsFalse_of_forall_inTime
#print axioms OAI.Bridges.AnthropicETH.length_le_of_isKCNF
#print axioms OAI.Bridges.AnthropicETH.encClauses_length_le
#print axioms OAI.Bridges.AnthropicETH.encodeFormula_toFormula_length_le
#print axioms OAI.Bridges.AnthropicETH.satisfiable_toFormula_iff
#print axioms OAI.Bridges.AnthropicETH.PolyBound.absorb
