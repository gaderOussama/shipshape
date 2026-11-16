# One Command to Ship Better Code: Combining Four Claude Code Skill Packs into `/ship`

I had four Claude Code skill packs installed. Each one was good at something. Together they fought each other. This post covers how I audited them, merged the best parts into one command called `/ship`, and made it the default for every project.

## The problem

Claude Code skills are folders of instructions (`SKILL.md` files) that tell the agent how to work. I had collected four packs:

| Pack | What it is good at |
|---|---|
| **ponytail** | Writing the least code that works. Fighting over-engineering. |
| **pstack** (poteto-mode) | Engineering principles, design before code, proving changes on the real app. |
| **superpowers** | Test-first discipline, root-cause debugging, verification before claiming "done". |
| **lifecycle pack** (`/architect`, `/test`, `/check`, `/audit`) | Written specs, test writing, cross-model review, security checks spread across phases. |

The trouble: they overlapped and contradicted each other.

- Four different code reviewers. Three debugging loops. Two planning systems.
- ponytail says "do less". pstack says "build 2-3 prototypes and compare".
- superpowers' brainstorming says "you MUST use this before any change" and stops for approval. pstack says "never block on the human".
- Some skills pointed at files that were never installed.
- pstack was written for Cursor, so its default model names did not exist in Claude Code.

Running all of them on every task would be slow and expensive. Picking skills by hand each time would mean I would stop doing it.

```mermaid
flowchart LR
    T[Coding task] --> A[ponytail]
    T --> B[pstack]
    T --> C[superpowers]
    T --> D[lifecycle pack]
    A -. "do less" .-x B
    B -. "never block" .-x C
    C -. "tests first" .-x D
    D -. "tests after" .-x C
    style T fill:#f4f4f4,stroke:#333
```

*Before: four packs pulling in different directions on the same task.*

## Step 1: Security check before installing anything

Skills are instructions an AI agent follows, and some ship scripts it can run. A malicious skill could tell the agent to leak secrets or run harmful commands. So every new pack got checked before it was installed.

```mermaid
flowchart TD
    A[Clone repo into an isolated scratch folder] --> B[List every file by type]
    B --> C{Code files}
    B --> D{Markdown instructions}
    C --> C1[Network calls?]
    C --> C2[Process spawning / eval?]
    C --> C3[Secret or credential access?]
    C --> C4[Encoded or obfuscated payloads?]
    D --> D1[Prompt injection: 'ignore previous', 'skip permissions'?]
    D --> D2[Unknown URLs or data exfiltration?]
    D --> D3[Hidden Unicode characters?]
    C1 & C2 & C3 & C4 & D1 & D2 & D3 --> E[Read every hit in context]
    E --> F{Malicious?}
    F -- No --> G[Install]
    F -- Yes --> H[Stop and report]
```

What the checks found:

- **pstack (569 files):** clean. Its scripts only call `gh`, `git`, a pinned npm package with a checksum, and a checksummed TLA+ jar from the official GitHub release. One behavior was overridden: its "external actions proceed without asking" rule. The agent still asks before sending, posting, pushing, or deploying.
- **superpowers (68 files installed):** clean. Its one network component, a brainstorming preview server, binds to `127.0.0.1` only and requires a random token plus an origin check. It opens a browser only when you opt in.

