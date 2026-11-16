# pstack model configuration for Claude Code. One line per role. Delete a line to fall back to the skill default.
# Mapped to the user's orchestration rule: Sonnet workers build, the parent (Opus) judges. Values are Claude Code Agent model aliases.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit the subagent `model`).
# defaults: 2
# budget: large (xhigh)
feature, refactoring: sonnet
bug-fix: sonnet
perf-issue: sonnet
hillclimb: sonnet
judgment and prose: inherit-parent
hardest tasks: opus
reflect tooling: sonnet
reflect judgment, divergent, synthesizer: inherit-parent
arena runners: sonnet, opus, fable
arena cross-judge pool: fable, sonnet
swarm workers: sonnet
architect runners: sonnet, opus, fable
interrogate reviewers: sonnet, opus, fable
