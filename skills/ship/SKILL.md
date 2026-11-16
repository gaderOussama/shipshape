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

## 2. Test first (M, L; S only when logic changes)

- The main session lists, in the worker brief, the behaviors to test and the break each one catches. The worker writes the failing tests first and shows the failing output before any production code. It then writes the minimal code to pass them. Each test must fail for the intended reason.
- Each test names the break it catches. Assert observable behavior through the public interface.
- Derive expected values by hand, never by calling the code under test.
- Mock only slow or external boundaries (network, clock, filesystem, third parties), never the unit under test.
- No change-detector tests (`expect(MAX_RETRIES).toBe(5)`), no tests of the framework, no snapshot-everything tests. Prefer no test to a bad test. Trivial code earns none.
- Never weaken an assertion to go green. A test that exposes a real bug gets reported under BUGS_FOUND.
- Code touching auth, sessions, payments, PII, or tokens gets these cases: unauthorized access, missing, expired, or tampered credentials, and no secret in output or logs.
- Deterministic tests only: frozen clock, seeded randomness, no sleeps.
- L: tag tests with the spec's `AC-N`. Run `/test` to cover the rest.
- No test framework in the repo: leave one runnable assert-based check, and say so.

## 3. Build

- S: inline. M and L: Sonnet workers.
- Each worker brief holds:
  - the goal, restated
  - the files it owns
  - the data shape
  - the behaviors to test (phase 2)
  - the rules below
  - "report DONE, DONE_WITH_CONCERNS, or BLOCKED, with failing-then-passing test output"
- Never give two workers the same files. Run workers in parallel only when the throughput checkpoint shows independent streams. Dispatch them per `dispatching-parallel-agents`.
- Accept each worker diff only after checking it against the brief: it does what was asked, the tests were written first and pass, and no files outside its scope changed. This is acceptance, not the review. Phase 5 is the independent review of the combined diff. When a diff is wrong, brief a fresh worker with the consolidated scope. Do not resume the old one.

Rules for all code:
- Reuse, then stdlib, then native platform, then an existing dependency, then new code. A new dependency needs a stated reason, and must be real, pinned, and maintained.
- Match the codebase's patterns, naming, and error handling.
- Validate input fail-closed at trust boundaries, and parse external data into types.
- Check authorization, not only authentication, on every action, including object ownership (IDOR).
- No secrets or PII in code, logs, or error messages.
- Parameterized queries. No shell, eval, or template strings built from input. Safe path joins.
- Network calls have timeouts. Retries are bounded and idempotent. Resources get closed.
- Missing required config fails loudly at startup.
- When a new API replaces an old one, migrate every caller, delete the old one in the same change, and prove zero references remain.
- Comments only for a non-obvious why. A deliberate shortcut gets a `ponytail:` comment naming its ceiling and upgrade path.
- TypeScript: discriminated unions, `unknown` over `any`, `satisfies` over `as`, exhaustive `never` switches. For more, read `~/.claude/skills/typescript-best-practices/references/patterns.md`.
- Postgres: use the `supabase-postgres-best-practices` skill.

## 4. Verify (every tier)

- Follow `verification-before-completion`: no "done", "fixed", or "passing" claim without running the command in this turn and reading its output.
- Run typecheck, lint, and the full test suite. Report unrelated failures by name. Do not hide them.
- Prove it on the real artifact. Run the app, CLI, or endpoint the way a user would and show the output. "It compiles" is not done. If you cannot run it, report BLOCKED and say why.
- Bug fix: show failing-before and passing-after output.
- L: run `/check verify` against the spec's ACs (no evidence, no tick). For critical logic, run a mutation check: break the code on purpose, confirm a test fails, then restore it.
- Performance claims: measure before and after, and name what limits the number.

## 5. Review (M, L, or `/ship review`)

Run these on the final diff with read-only reviewers in parallel. Reviewers use a different model from the author. Sonnet-written code is reviewed on Opus, and main-session code is reviewed on Sonnet. When the author is unknown or mixed (`/ship review` on someone's branch), run the correctness and security pass on both Sonnet and Opus. The model that finds a problem first is right until shown otherwise.

S tier: no reviewer agents. The main session reads the diff once against the correctness and security list below before reporting.

1. **Correctness and security.** Severity is Blocker, Major, Minor, or Nit. Check for:
   - logic errors and edge cases (empty, null, huge, concurrent)
   - injection (SQL, command, path, template), XSS, CSRF
   - authn, authz, IDOR
   - secrets, SSRF, unsafe deserialization
   - missing rate limits
   - error messages that leak internals
   - new or changed dependencies
2. **Over-engineering** (ponytail-review rules). What can be deleted, what stdlib or native feature replaces it, and which abstractions are speculative. Report `net: -N lines`.
3. **Readability.** Look for:
   - layers between a question and its answer
   - one-caller wrappers
   - hidden mutable state
   - names that lie
   - comments that narrate (keep why-comments and `ponytail:` markers)

L, in addition:
- the built-in `/security-review` on the branch
- a blast-radius pass: what outside the diff could break, and prove the one fact the change is safe because of
- `/check review`, which writes `docs/reviews/`

Brief the correctness and security reviewer from the template `~/.claude/skills/requesting-code-review/code-reviewer.md`, adding the security list above.

Handle findings per `receiving-code-review`: verify each finding against the code before acting on it, and never agree just to agree. Fix Blockers and Majors, then rerun phase 4. Push back on wrong findings with a concrete reason. Fix Minor and Nit findings when they are one-liners; otherwise list them.

## 6. Finish

S: ponytail's format. Show the code, then at most three lines, one of them the evidence (the command and its result).

M and L: write the final report in short plain sentences, with no filler or hype:
- the goal, in one line
- what changed, by file and why
- evidence: commands and results
- risks and what was not verified
- follow-ups

Only on the user's go:
- Commit in small ordered commits with Conventional Commit titles.
- Write the PR body as Why, What changed, Scope, Tradeoffs, Blast radius, Verification.
- L: run `/document pr`, and run `/sync` when the repo has `AGENTS.md` or `docs/specs/`.

