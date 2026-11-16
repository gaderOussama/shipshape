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

