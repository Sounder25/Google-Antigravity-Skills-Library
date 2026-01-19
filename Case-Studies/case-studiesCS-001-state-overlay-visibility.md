CS-001: When a CALL Lies — State Overlay Visibility, CREATE2, and Trust Failures in Agent Debugging

Summary



This case study documents a real execution failure discovered while running EELS tests against a custom Ethereum execution engine.



The failure was not caused by incorrect opcode pricing, missing refunds, or bad math.

It was caused by state visibility drift between execution contexts — a problem that looks like a gas discrepancy but is actually a trust failure.



More importantly, this is exactly the kind of bug that AI coding agents are bad at fixing unless they are constrained by deterministic checks and adversarial review.



The Symptom



While running the test:



Tstore\_CreateContexts\_Create2\_AcrossConstructorAndDeployedCode\_ShouldMatchState





the test failed with a balance mismatch:



Expected: 999999999999998056640

Actual:   999999999999998499140

Difference: +442,500 wei





At first glance, this looked like:



incorrect gas accounting



missing intrinsic gas



or a refund miscalculation



That assumption was wrong.



The Smoking Gun



Tracing execution with:



$env:ELR\_TRACE\_SSTORE='1'

$env:ELR\_TRACE\_EXPENSIVE='1'

dotnet test ELR.EELS.Tests --filter "FullyQualifiedName~Tstore\_CreateContexts"





revealed this line:



\[GAS] pc=46 opcode=CALL cost=2600





This CALL targeted a contract that was just created via CREATE2 earlier in the same transaction.



That should not happen.



A CALL into deployed code must consume:



base CALL cost



plus child execution gas



Instead, only the base cost (2600) was charged.



No child gas was accounted for.



That explains the excess balance:

the engine under-charged gas because it believed the target contract had no code.



Why This Is Dangerous



This failure is subtle.



From the outside:



Gas math looks reasonable



Opcode pricing tables are correct



SSTORE, TSTORE, TLOAD all behave as expected



An AI agent (or a human skimming traces) will almost always:



chase gas constants



tweak opcode costs



add special cases



All of that is wasted effort.



The real failure is state visibility across execution overlays.



Root Cause



The engine uses state overlays to isolate execution contexts.



Flow simplified:



Parent transaction executes



CREATE2 deploys a contract



Code is written to execOverlay



A subsequent CALL is made



CALL creates a new overlay



That overlay does not see the deployed code



So the CALL executes against what looks like:



an address with no code



resulting in zero child execution



and only base CALL gas charged



In other words:



The contract existed — but only in the parent overlay.



This is not a gas bug.

It’s a state propagation bug.



Why Agents Fail Here



This is a perfect example of why “vibe coding” fails:



The symptom is numeric



The cause is architectural



The fix requires understanding execution context boundaries



An unconstrained agent will:



adjust gas math



add compensating charges



mask the bug



And it will claim success.



That is a trust failure, not a logic failure.



The Correct Fix (Conceptually)



The fix is not “charge more gas.”



The fix is to guarantee that:



State mutations performed during CREATE are visible to all subsequent CALL contexts within the same transaction.



That means:



overlays must chain correctly



or state commits must occur at the right boundary



or CALL context creation must reference the correct parent state



Once that invariant is restored, gas accounting fixes itself.



Why This Became a Skill



This bug directly motivated a new agent constraint:



SKILL-022: State Consistency Gate (Execution Context Integrity)



Purpose:



Detect state mismatches across overlays



Block fixes that modify gas math without validating state visibility



Require proof that deployed code is visible before CALL execution



This is not automation.

It’s damage prevention.



Takeaway



This failure wasn’t hard to fix.



It was hard to see.



And that’s the real problem with AI coding agents today:

they optimize for “making the test pass,” not for preserving system invariants.



Trust doesn’t come from better models.

It comes from structural guardrails that prevent the wrong class of fixes.



That’s what this skills library is for.



Artifacts



Test: Tstore\_CreateContexts\_Create2\_AcrossConstructorAndDeployedCode\_ShouldMatchState



Trace evidence: CALL charged base gas only



Root cause: overlay state visibility



Outcome: new skill derived from real failure



Closing



This case study exists for one reason:



If an agent can’t be trusted to tell you why something broke,

it can’t be trusted to fix it.



Everything else is noise.

