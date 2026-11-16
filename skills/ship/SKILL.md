---
name: ship
argument-hint: "[S|M|L|review|setup] <task>"
description: Default dev workflow for any coding task (feature, bug fix, refactor, change, review). One tiered loop that combines ponytail (minimal code), pstack (principles, proof on the real artifact), superpowers (test first, root-cause debugging) and the lifecycle pack (/architect specs, /test, /check, /audit). Phases are frame, design, test first, build, verify, review (security, over-engineering, readability), finish. Use for /ship, "ship this", or any request to write, fix, change, or review code. Ceremony scales with risk (S, M, L). Proof never scales down.
---

# Ship

One loop for every coding task. Scale ceremony to risk. Never skip proof.

Usage:
- `/ship <task>` picks the tier itself.
- `/ship S|M|L <task>` forces a tier.
- `/ship review` runs phase 5 on the current diff.
- `/ship setup` prepares the current repo (see Setup).

## Always on

- **ponytail**, at the user's current level (default full), governs every line. Read `~/.claude/skills/ponytail/SKILL.md` once per session. The ladder: need it at all, reuse, stdlib, native, existing dependency, one line, minimum code. ponytail never trades away validation at trust boundaries, data-loss handling, security, or accessibility.
- **Where ship and ponytail differ**:
  - Tests: ship's rules (phase 2) win for M and L. ponytail's "one runnable check" applies to S, and to repos with no test framework.
  - Report length: ponytail's format (code, then at most three lines) applies to S. M and L get the phase 6 report.
- **Orchestration rule** (global CLAUDE.md). Sonnet workers build (`Agent`, `model: "sonnet"`). The main session frames, briefs, accepts or rejects each worker diff, and verifies. Only trivial one-line edits stay inline. Any other S task goes to one Sonnet worker.
- **Outward actions need a yes.** Commit, push, PR, deploy, messages. Never force-push. Never skip hooks.
- **Evidence or label.** Every claim in the final report is measured (command plus output) or marked inferred or guess.

## 0. Frame (every tier)

1. Restate the goal, the problem, and the smallest change that meets it, in two or three lines. Do not wait for confirmation.
2. Ask ponytail's rung 0: does this need to exist? If the evidence rules out the requested change, show it and stop.
3. Read before writing. Trace the code you will touch and grep all its callers. If code looks odd, check `git log -L` or blame before changing it. It may be deliberate.
4. Pick the tier and say it in one line.
   - **S**: one or two files with no behavior change for users, and nothing on a security, data, or money path. Typos, config, renames, copy, dependency bumps with green tests.
   - **M** (default): a feature, bug fix, or refactor inside one subsystem. Any bug fix is at least M, because it needs a repro test.
   - **L**: crosses modules or a public API, adds a data model or migration, touches auth, sessions, payments, PII or secrets, involves concurrency, is a one-way door, or spans roughly eight or more files.
   - Bump one tier when the change can lose data, leak data, or move money. An L task that bumps stays L, and the built-in `/security-review` becomes mandatory.
5. Ask the user only real preference calls (product or UX choices no experiment can settle). Anything observable (behavior, timing, output, perf) gets tried and measured, and the result decides. The one planned interview is `/architect` in L. Even there, when the user said "run until done" or is away, take each question's recommended option and list the defaults you took in the report.

## 1. Design (M, L)

M:
- Name the data shape first. Write the caller's usage first, then derive types and signatures from it.
- Model the domain (state machine, table, or typed model) instead of scattered conditionals.
- Make illegal states unrepresentable.
- Validate and parse at system boundaries, and trust internal types.
- Subtract before you add: delete dead code first.
- No abstraction with one caller. One way to do each thing.

L, in addition:
- Run `/architect` (the lifecycle spec skill). It writes `docs/specs/NNNN-*.md` with AC-1 style acceptance criteria, a data model, a security model, and a build plan. Every value an action produces needs a named source, or it is an open decision.
- For a real fork between two or more structurally different designs on a one-way door, read `~/.claude/skills/pstack-architect/SKILL.md`. Sketch at least two shapes and pick by interface depth. Do not run arena routinely.
- Write the throughput checkpoint: blocking first steps, independent workstreams, shared mutable state, and the smallest safe decomposition. It sets the worker split in phase 3.

Plans name files, data shapes, and tests. Plans never contain full code.

## Debug loop (bug fixes and any failing check)

1. Reproduce on the surface where the bug was reported and capture the failing output.
2. Localize. Bisect the code or the history. In multi-component flows, instrument each boundary.
3. Form one falsifiable hypothesis at a time, test it, and change one thing.
4. Fix the root cause at the first place the system went wrong. Grep for siblings with the same shape. No extra guards that "might help".
5. After three failed fixes that share a premise, stop. Write the premise down and test it directly. If the design is wrong, go back to phase 1 and tell the user.

Techniques in `~/.claude/skills/systematic-debugging/`:
- `root-cause-tracing.md` for tracing a bad value back up the call stack.
- `defense-in-depth.md` for deciding which layers get validation after the fix.
- `condition-based-waiting.md` for flaky or timing tests (replace sleeps with conditions).
- `find-polluter.sh` for finding the test that pollutes shared state.

The repro test lands before the fix.

