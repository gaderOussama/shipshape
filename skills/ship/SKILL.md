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

