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

