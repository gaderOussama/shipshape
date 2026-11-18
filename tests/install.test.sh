#!/usr/bin/env bash
# Tests for install.sh. Run: bash tests/install.test.sh
# Every test gets a fresh temp dir holding a tiny fake repo and a fake CLAUDE_HOME.
set -u

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
START='<!-- shipshape:start -->'
END='<!-- shipshape:end -->'
FAILS=0
TESTS=0
TMP=

assert_eq() { # name expected actual
  if [ "$2" = "$3" ]; then return 0; fi
  FAILS=$((FAILS + 1))
  printf '  FAIL %s\n    expected: %s\n    actual:   %s\n' "$1" "$(printf %s "$2" | od -c | head -5)" "$(printf %s "$3" | od -c | head -5)"
}
assert_true() { # name cmd...
  local n=$1
  shift
  if "$@"; then return 0; fi
  FAILS=$((FAILS + 1))
  echo "  FAIL $n"
}
assert_false() {
  local n=$1
  shift
  if "$@"; then
    FAILS=$((FAILS + 1))
    echo "  FAIL $n"
  fi
}
count() { grep -c -F -- "$1" "$2" || true; } # count lines containing $1 in $2

# fresh fake repo ($REPO) + fake home ($H) in a new temp dir
setup() {
  TMP=$(mktemp -d)
  REPO=$TMP/repo
  H=$TMP/home
  mkdir -p "$REPO/skills/ship" "$REPO/rules" "$H"
  printf 'ship skill\n' >"$REPO/skills/ship/SKILL.md"
  printf 'rules v1\n' >"$REPO/rules/pstack-models.md"
  printf 'SNIPPET-V1\n' >"$REPO/CLAUDE.snippet.md"
  cp "$HERE/install.sh" "$REPO/install.sh"
}
teardown() { rm -rf "$TMP"; }
inst() { CLAUDE_HOME=$H bash "$REPO/install.sh" "$@"; }
# file content plus a trailing "x", so $(...) cannot eat trailing newlines; expected values end with x too
slurp() { cat "$1"; printf x; }

run() { # test_function_name
  TESTS=$((TESTS + 1))
  echo "- $1"
  setup
  "$1"
  teardown
}

test_fresh_install_creates_skill_rules_and_one_block() {
  inst >/dev/null
  assert_eq "skill copied" "ship skill" "$(cat "$H/skills/ship/SKILL.md")"
  assert_eq "rules copied" "rules v1" "$(cat "$H/rules/pstack-models.md")"
  assert_eq "one start marker" 1 "$(count "$START" "$H/CLAUDE.md")"
  assert_eq "one end marker" 1 "$(count "$END" "$H/CLAUDE.md")"
  assert_eq "CLAUDE.md exact" "$START
SNIPPET-V1
${END}
x" "$(slurp "$H/CLAUDE.md")"
  assert_false "no backups dir on a clean install" test -e "$H/backups"
}

test_second_install_does_not_duplicate_block_or_change_file() {
  inst >/dev/null
  local first
  first=$(slurp "$H/CLAUDE.md")
  inst >/dev/null
  assert_eq "markers still 1" 1 "$(count "$START" "$H/CLAUDE.md")"
  assert_eq "file identical" "$first" "$(slurp "$H/CLAUDE.md")"
  assert_false "unchanged rerun makes no backup" test -e "$H/backups"
}

test_existing_claude_md_content_survives_byte_for_byte() {
  # no markers yet, no trailing newline, CRLF line and odd spacing
  printf '# mine\r\n  indented  \nlast-no-newline' >"$H/CLAUDE.md"
  inst >/dev/null
  # original bytes + the newline we had to add, blank separator, block
  assert_eq "appended after original" "$(printf '# mine\r\n  indented  \nlast-no-newline\n\n%s\nSNIPPET-V1\n%s\nx' "$START" "$END")" "$(slurp "$H/CLAUDE.md")"
  assert_eq "backup holds original" "$(printf '# mine\r\n  indented  \nlast-no-newline'; printf x)" "$(slurp "$(find "$H/backups" -name CLAUDE.md)")"

  # markers in the middle: only the block changes
  printf 'top\n\n%s\nOLD STUFF\n%s\nbottom\n\n  end  ' "$START" "$END" >"$H/CLAUDE.md"
  inst >/dev/null
  assert_eq "before and after untouched" "$(printf 'top\n\n%s\nSNIPPET-V1\n%s\nbottom\n\n  end  x' "$START" "$END")" "$(slurp "$H/CLAUDE.md")"
}

test_different_rules_file_is_backed_up_not_lost() {
  mkdir -p "$H/rules"
  printf 'my custom models\n' >"$H/rules/pstack-models.md"
  inst >/dev/null
  assert_eq "rules replaced" "rules v1" "$(cat "$H/rules/pstack-models.md")"
  local b
  b=$(find "$H/backups" -name pstack-models.md)
  assert_true "backup file exists" test -n "$b"
  assert_eq "backup has user content" "my custom models" "$(cat "$b")"
}

test_changed_snippet_replaces_block_content_on_reinstall() {
  printf 'mine\n' >"$H/CLAUDE.md"
  inst >/dev/null
  printf 'SNIPPET-V2 line a\nline b\n' >"$REPO/CLAUDE.snippet.md"
  inst >/dev/null
  assert_eq "block now v2, one block" "$(printf 'mine\n\n%s\nSNIPPET-V2 line a\nline b\n%s\nx' "$START" "$END")" "$(slurp "$H/CLAUDE.md")"
  assert_eq "no v1 left" 0 "$(count SNIPPET-V1 "$H/CLAUDE.md")"
}

test_check_reports_missing_on_empty_home_then_ok_with_fake_packs() {
  local out
  out=$(inst --check)
  assert_eq "check exits 0 on empty home" 0 "$(inst --check >/dev/null; echo $?)"
  assert_true "ship missing" grep -Eq '^missing +core/ship skill$' <<<"$out"
  assert_true "rules missing" grep -Eq '^missing +core/rules file$' <<<"$out"
  assert_true "block missing" grep -Eq '^missing +core/CLAUDE.md block$' <<<"$out"
  assert_true "ponytail missing" grep -Eq '^missing +ponytail/ponytail$' <<<"$out"
  assert_true "poteto missing" grep -Eq '^missing +pstack/poteto-mode$' <<<"$out"
  assert_true "superpowers missing" grep -Eq '^missing +superpowers/test-driven-development$' <<<"$out"
  assert_true "lifecycle missing flagged optional" grep -Eq '^missing +lifecycle/audit \(optional\)$' <<<"$out"
  assert_false "no warn on empty home" grep -q '^warn' <<<"$out"

  # packs: some as plain skill folders, some only inside a plugin cache
  mkdir -p "$H/skills/ponytail" "$H/skills/ponytail-review" "$H/skills/poteto-mode"
  mkdir -p "$H/plugins/cache/mk/pstack/1.0.0/skills/pstack-architect"
  mkdir -p "$H/skills/test-driven-development" "$H/skills/systematic-debugging"
  mkdir -p "$H/plugins/cache/mk/superpowers/5.0/skills/verification-before-completion"
  mkdir -p "$H/plugins/cache/mk/superpowers/5.0/skills/receiving-code-review"
  mkdir -p "$H/skills/architect" "$H/skills/develop" "$H/skills/test" "$H/skills/check" "$H/skills/audit"
  inst >/dev/null
  out=$(inst --check)
  assert_true "ship ok" grep -Eq '^ok +core/ship skill$' <<<"$out"
  assert_true "rules ok" grep -Eq '^ok +core/rules file$' <<<"$out"
  assert_true "block ok" grep -Eq '^ok +core/CLAUDE.md block$' <<<"$out"
  assert_true "ponytail ok" grep -Eq '^ok +ponytail/ponytail$' <<<"$out"
  assert_true "ponytail-review ok" grep -Eq '^ok +ponytail/ponytail-review$' <<<"$out"
  assert_true "poteto ok" grep -Eq '^ok +pstack/poteto-mode$' <<<"$out"
  assert_true "pstack-architect found in plugin cache" grep -Eq '^ok +pstack/pstack-architect$' <<<"$out"
  assert_true "superpowers via skills dir" grep -Eq '^ok +superpowers/systematic-debugging$' <<<"$out"
  assert_true "superpowers via plugin cache" grep -Eq '^ok +superpowers/receiving-code-review$' <<<"$out"
  assert_true "lifecycle ok" grep -Eq '^ok +lifecycle/audit$' <<<"$out"
  assert_false "nothing missing now" grep -q '^missing' <<<"$out"
  assert_false "no warn while architect is the lifecycle one" grep -q '^warn' <<<"$out"

  # pstack's architect under the plain name triggers the rename warning
  printf -- '---\ndescription: Sketch types, signatures and so on\n---\n' >"$H/skills/architect/SKILL.md"
  out=$(inst --check)
  assert_true "rename warning" grep -q '^warn' <<<"$out"
}

test_check_is_read_only() {
  inst --check >/dev/null
  assert_eq "home still empty" "" "$(ls -A "$H")"
}

test_uninstall_removes_block_and_skill_but_keeps_user_content() {
  printf 'mine\n' >"$H/CLAUDE.md"
  inst >/dev/null
  printf 'tail\n' >>"$H/CLAUDE.md"
  printf 'user data\n' >"$H/skills/other.txt"
  printf 'user rules\n' >"$H/rules/pstack-models.md" # user edited it after install
  inst --uninstall >/dev/null
  assert_eq "block gone, user lines kept" "$(printf 'mine\n\ntail\nx')" "$(slurp "$H/CLAUDE.md")"
  assert_false "ship skill removed" test -e "$H/skills/ship"
  assert_eq "modified rules kept" "user rules" "$(cat "$H/rules/pstack-models.md")"
  assert_eq "unrelated file kept" "user data" "$(cat "$H/skills/other.txt")"
  assert_true "CLAUDE.md was backed up" test -n "$(find "$H/backups" -name CLAUDE.md)"
}

test_uninstall_restores_original_and_removes_identical_rules() {
  printf 'mine\n' >"$H/CLAUDE.md"
  inst >/dev/null
  inst --uninstall >/dev/null
  assert_eq "original CLAUDE.md restored" "$(printf 'mine\nx')" "$(slurp "$H/CLAUDE.md")"
  assert_false "identical rules removed" test -e "$H/rules/pstack-models.md"
}

test_uninstall_on_empty_home_is_harmless() {
  assert_eq "exit 0" 0 "$(inst --uninstall >/dev/null; echo $?)"
  assert_eq "home still empty" "" "$(ls -A "$H")"
}

test_unknown_flag_exits_2() {
  inst --bogus >/dev/null 2>&1
  assert_eq "unknown flag" 2 "$?"
  inst --check extra >/dev/null 2>&1
  assert_eq "extra argument" 2 "$?"
  assert_false "nothing installed on bad flag" test -e "$H/skills"
}

test_real_repo_installs_its_own_files() {
  CLAUDE_HOME=$H bash "$HERE/install.sh" >/dev/null
  assert_true "real skill copied" cmp -s "$HERE/skills/ship/SKILL.md" "$H/skills/ship/SKILL.md"
  assert_true "real rules copied" cmp -s "$HERE/rules/pstack-models.md" "$H/rules/pstack-models.md"
  assert_eq "one start marker" 1 "$(count "$START" "$H/CLAUDE.md")"
  assert_true "snippet text present" grep -q 'ship: default dev workflow' "$H/CLAUDE.md"
}

# Catches: someone who pasted the snippet by hand (old README told them to) gets a second copy appended.
test_unmarked_hand_pasted_snippet_is_not_duplicated() {
  printf '# mine\nSNIPPET-V1\n' >"$H/CLAUDE.md"
  inst >/dev/null 2>&1
  assert_eq "install refuses" 1 "$?"
  assert_eq "CLAUDE.md untouched" "$(printf '# mine\nSNIPPET-V1\nx')" "$(slurp "$H/CLAUDE.md")"
  assert_true "check reports unmarked copy" sh -c "CLAUDE_HOME='$H' bash '$REPO/install.sh' --check | grep -q '^unmarked'"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do run "$t"; done

echo
if [ "$FAILS" -eq 0 ]; then echo "PASS: $TESTS tests"; else echo "FAILED: $FAILS assertion(s) in $TESTS tests"; exit 1; fi
