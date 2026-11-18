#!/usr/bin/env bash
# shipshape installer. Usage: ./install.sh [--check | --uninstall]
# Target: ${CLAUDE_HOME:-$HOME/.claude}. Needs only bash, cp, cmp, diff, find, date.
set -euo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
T=${CLAUDE_HOME:-$HOME/.claude}
S='<!-- shipshape:start -->'
E='<!-- shipshape:end -->'
BK=
NL=$'\n'

usage() { echo "usage: $0 [--check | --uninstall]" >&2; exit 2; }
die() { echo "error: $*" >&2; exit 1; }
say() { printf '%-10s %s\n' "$1" "$2"; }

# Copy $T/<rel> into the (lazily created) backup dir.
backup() {
  [ -n "$BK" ] || BK=$T/backups/shipshape-$(date +%Y%m%d-%H%M%S)
  mkdir -p "$(dirname "$BK/$1")"
  rm -rf "${BK:?}/$1"
  cp -R "$T/$1" "$BK/$1"
}

# slurp VAR FILE: whole file into VAR, byte-exact (trailing newlines kept).
slurp() {
  local s
  s=$(cat "$2"; printf x)
  printf -v "$1" '%s' "${s%x}"
}

# True when $1 (CLAUDE.md text) holds the snippet's first heading outside a marker block: a hand-pasted copy.
unmarked() {
  local key
  key=$(grep -m1 . "$SRC/CLAUDE.snippet.md") || return 1
  [[ $1 != *"$S"* && $1 == *"$key"* ]]
}

check_skill() { # label dir [optional]
  if [ -d "$T/skills/$2" ] ||
    [ -n "$(find "$T/plugins/cache" -type d -name "$2" 2>/dev/null | head -n 1)" ]; then
    say ok "$1/$2"
  else
    say missing "$1/$2${3:+ (optional)}"
  fi
}

check() {
  local c= rules=missing s
  [ -f "$T/skills/ship/SKILL.md" ] && say ok "core/ship skill" || say missing "core/ship skill"
  if [ -f "$T/rules/pstack-models.md" ]; then
    if cmp -s "$SRC/rules/pstack-models.md" "$T/rules/pstack-models.md"; then rules=ok; else rules=differs; fi
  fi
  say "$rules" "core/rules file"
  [ -f "$T/CLAUDE.md" ] && slurp c "$T/CLAUDE.md"
  if [[ $c == *"$S"* && ${c#*"$S"} == *"$E"* ]]; then say ok "core/CLAUDE.md block"
  elif unmarked "$c"; then say unmarked "core/CLAUDE.md block (hand-pasted copy found: delete it, then run install.sh)"
  else say missing "core/CLAUDE.md block"; fi
  for s in ponytail ponytail-review; do check_skill ponytail "$s"; done
  for s in poteto-mode pstack-architect; do check_skill pstack "$s"; done
  for s in test-driven-development systematic-debugging verification-before-completion receiving-code-review; do
    check_skill superpowers "$s"
  done
  for s in architect develop test check audit; do check_skill lifecycle "$s" optional; done
  if grep -qs "Sketch types, signatures" "$T/skills/architect/SKILL.md"; then
    say warn "pstack's architect sits under the plain name 'architect': rename it to pstack-architect"
  fi
}

install() {
  [ -f "$SRC/skills/ship/SKILL.md" ] && [ -f "$SRC/rules/pstack-models.md" ] && [ -f "$SRC/CLAUDE.snippet.md" ] ||
    die "run from a complete shipshape checkout"
  mkdir -p "$T/skills" "$T/rules"

  # 1. skill
  if [ -d "$T/skills/ship" ] && diff -rq "$SRC/skills/ship" "$T/skills/ship" >/dev/null 2>&1; then
    say unchanged "skills/ship"
  else
    if [ -d "$T/skills/ship" ]; then backup skills/ship; rm -rf "$T/skills/ship"; fi
    cp -R "$SRC/skills/ship" "$T/skills/ship"
    say installed "skills/ship"
  fi

  # 2. rules file
  if [ -f "$T/rules/pstack-models.md" ] && cmp -s "$SRC/rules/pstack-models.md" "$T/rules/pstack-models.md"; then
    say unchanged "rules/pstack-models.md"
  else
    if [ -f "$T/rules/pstack-models.md" ]; then backup rules/pstack-models.md; fi
    cp "$SRC/rules/pstack-models.md" "$T/rules/pstack-models.md"
    say installed "rules/pstack-models.md"
  fi

  # 3. CLAUDE.md block
  local snip c= old new
  slurp snip "$SRC/CLAUDE.snippet.md"
  [[ $snip == *"$NL" ]] || snip+=$NL
  local block=$S$NL$snip$E
  if [ -f "$T/CLAUDE.md" ]; then slurp c "$T/CLAUDE.md"; fi
  unmarked "$c" && die "$T/CLAUDE.md already has a hand-pasted shipshape snippet without markers; delete it, then re-run"
  old=$c
  if [[ $c == *"$S"* ]]; then
    local rest=${c#*"$S"}
    [[ $rest == *"$E"* ]] || die "$T/CLAUDE.md has '$S' but no '$E'; fix it by hand"
    new=${c%%"$S"*}$block${rest#*"$E"}
  elif [ -z "$c" ]; then
    new=$block$NL
  else
    [[ $c == *"$NL" ]] || c+=$NL
    new=$c$NL$block$NL
  fi
  if [ -f "$T/CLAUDE.md" ] && [ "$new" = "$old" ]; then
    say unchanged "CLAUDE.md"
  else
    if [ -f "$T/CLAUDE.md" ]; then backup CLAUDE.md; fi
    printf '%s' "$new" >"$T/CLAUDE.md"
    say installed "CLAUDE.md block"
  fi

  if [ -n "$BK" ]; then say backup "$BK"; fi
  echo
  check
}

uninstall() {
  local c= before after
  if [ -d "$T/skills/ship" ]; then backup skills/ship; rm -rf "$T/skills/ship"; say removed "skills/ship"; fi
  if [ -f "$T/rules/pstack-models.md" ] && cmp -s "$SRC/rules/pstack-models.md" "$T/rules/pstack-models.md"; then
    rm "$T/rules/pstack-models.md"
    say removed "rules/pstack-models.md"
  fi
  if [ -f "$T/CLAUDE.md" ]; then slurp c "$T/CLAUDE.md"; fi
  if [[ $c == *"$S"* && ${c#*"$S"} == *"$E"* ]]; then
    backup CLAUDE.md
    before=${c%%"$S"*}
    after=${c#*"$S"}
    after=${after#*"$E"}
    after=${after#"$NL"} # the end of the marker line
    # block was last: also drop the blank-line separator install added
    if [ -z "$after" ] && [[ $before == *"$NL$NL" ]]; then before=${before%"$NL"}; fi
    c=$before$after
    if [ -z "$c" ]; then rm "$T/CLAUDE.md"; else printf '%s' "$c" >"$T/CLAUDE.md"; fi
    say removed "CLAUDE.md block"
  fi
  if [ -n "$BK" ]; then say backup "$BK"; fi
  return 0
}

[ $# -le 1 ] || usage
case "${1:-}" in
  "") install ;;
  --check) check ;;
  --uninstall) uninstall ;;
  *) usage ;;
esac
