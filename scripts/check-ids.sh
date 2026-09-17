#!/usr/bin/env bash
#
# Integrity check for the secure-coding material. The repository promises three
# things — stable ids, resolvable cross-references, and install-location
# independence. This verifies all three instead of trusting them.
#
#   ./scripts/check-ids.sh

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE="$REPO/skills/secure-coding"
fails=0

red=$'\033[31m'; grn=$'\033[32m'; bold=$'\033[1m'; off=$'\033[0m'
fail() { printf '%s✘%s %s\n' "$red" "$off" "$*"; fails=$((fails + 1)); }
pass() { printf '%s✔%s %s\n' "$grn" "$off" "$*"; }

# 1 — every manifest row points at a file that exists ------------------------
printf '%s\n' "${bold}manifest rows resolve${off}"
missing=0
while read -r f; do
  [ -f "$CORE/$f" ] || { fail "manifest cites $f, which does not exist"; missing=1; }
done < <(grep -oE '`(owasp|stacks)/[A-Za-z0-9._-]+\.md`' "$CORE/SKILL.md" | tr -d '`' | sort -u)
[ "$missing" = 0 ] && pass "every file named in the manifest exists"

# 2 — every core category is in the manifest ---------------------------------
printf '%s\n' "${bold}no orphan category files${off}"
orphans=0
for f in "$CORE"/owasp/*.md "$CORE"/stacks/*.md; do
  rel="${f#"$CORE"/}"
  case "$rel" in stacks/_*) continue ;; esac   # templates are not categories
  grep -qF "\`$rel\`" "$CORE/SKILL.md" || { fail "$rel exists but no manifest row loads it"; orphans=1; }
done
[ "$orphans" = 0 ] && pass "every category file has a manifest row"

# 3 — cross-references resolve both ways -------------------------------------
printf '%s\n' "${bold}cross-references resolve${off}"
badref=0
while read -r ref; do
  file="${ref%% *}"; ids="${ref#* }"
  [ -f "$CORE/$file" ] || { fail "cross-reference to missing file: $file"; badref=1; continue; }
  for id in $(printf '%s' "$ids" | tr -d '()' | tr ',' ' '); do
    grep -qE "^#+ $id[[:space:]]|^- \*\*$id\*\*|\*\*$id\*\*" "$CORE/$file" \
      || { fail "$file is pointed at as $id, which is not defined there"; badref=1; }
  done
done < <(grep -hoE 'stacks/[a-z-]+\.md \([A-Z]+\.[0-9]+(, ?[A-Z]+\.[0-9]+)*\)' "$CORE"/owasp/*.md | sort -u)
[ "$badref" = 0 ] && pass "every → stacks/x.md (ID) points at an id that exists"

# 4 — every ref a consumer enumerates is a real review question --------------
# Both a SKILL.md and a references/ file may cite an id, and an unguarded
# SKILL.md was how an invented A99.Q9 once shipped green.
printf '%s\n' "${bold}consumer refs exist as review questions${off}"
badq=0
while read -r q; do
  cat="${q%%.*}"
  f=$(ls "$CORE"/owasp/"$cat"-*.md 2>/dev/null | head -1)
  [ -n "$f" ] || { fail "a consumer cites $q but there is no $cat file"; badq=1; continue; }
  grep -qF "**$q**" "$f" || { fail "a consumer cites $q, which is not a review question in $(basename "$f")"; badq=1; }
done < <(grep -rhoE '\bA[0-9]{2}\.Q[0-9]+\b' "$REPO"/skills/*/SKILL.md "$REPO"/skills/*/references/ | sort -u)
[ "$badq" = 0 ] && pass "every id enumerated by a consumer is a real review question"

# 5 — review questions are numbered without gaps -----------------------------
printf '%s\n' "${bold}review questions are contiguous${off}"
gaps=0
for f in "$CORE"/owasp/*.md; do
  base=$(basename "$f" .md); cat="${base%%-*}"
  n=0
  while read -r i; do
    n=$((n + 1))
    [ "$i" = "$n" ] || { fail "$base jumps from Q$((n - 1)) to Q$i — ids must never be renumbered, but they must not skip either"; gaps=1; n=$i; }
  done < <(grep -oE "\*\*$cat\.Q[0-9]+\*\*" "$f" | sed -E 's/.*\.Q([0-9]+)\*\*/\1/')
  [ "$n" = 0 ] && { fail "$base has no review questions"; gaps=1; }
done
[ "$gaps" = 0 ] && pass "every category numbers its review questions 1..n"

# 6 — nothing in the shipped material hardcodes an install location ----------
printf '%s\n' "${bold}install-location independence${off}"
hits=$(grep -rn '~/\.claude' "$REPO/skills" "$REPO/agents" 2>/dev/null || true)
if [ -n "$hits" ]; then
  while read -r l; do fail "hardcoded install path: $l"; done <<< "$hits"
else
  pass "no shipped file references an absolute install path"
fi

# 7 — stack files declare their grounding ------------------------------------
printf '%s\n' "${bold}stack files declare grounding${off}"
ungrounded=0
for f in "$CORE"/stacks/*.md; do
  case "$(basename "$f")" in _*) continue ;; esac
  grep -qE '\*\*Status:?( )?(\*\*)?' "$f" \
    || { fail "$(basename "$f") has no **Status:** header — grounded or unverified must be visible"; ungrounded=1; }
done
[ "$ungrounded" = 0 ] && pass "every stack file states whether it is grounded"

# 8 — the version agrees everywhere it is written ---------------------------
printf '%s\n' "${bold}version agreement${off}"
v_plugin=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$REPO/.claude-plugin/plugin.json" | head -1)
v_market=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$REPO/.claude-plugin/marketplace.json" | head -1)
v_trig=$(sed -n 's/.*secure-coding trigger v\([0-9][^ ]*\).*/\1/p' "$CORE/TRIGGER.md" | head -1)
if [ "$v_plugin" = "$v_market" ] && [ "$v_plugin" = "$v_trig" ]; then
  pass "plugin.json, marketplace.json and TRIGGER.md all say $v_plugin"
else
  fail "version disagreement — plugin.json=$v_plugin marketplace.json=$v_market TRIGGER.md=$v_trig"
fi
grep -q "^## \[$v_plugin\]" "$REPO/CHANGELOG.md" 2>/dev/null \
  && pass "CHANGELOG.md has an entry for $v_plugin" \
  || fail "CHANGELOG.md has no ## [$v_plugin] entry"


# The app-stride-report skill carries its own material and its own ids. Checks 9-13
# hold it to the same promises the core makes, plus the one it makes alone: the
# two bodies of material never cite each other, so either is usable without the
# other installed.

TM="$REPO/skills/app-stride-report"

# 9 — every app-stride-report manifest row points at a file that exists -----------
printf '%s\n' "${bold}app-stride-report manifest rows resolve${off}"
tmissing=0
while read -r f; do
  [ -f "$TM/$f" ] || { fail "app-stride-report manifest cites $f, which does not exist"; tmissing=1; }
done < <(grep -oE '`(stride|references)/[A-Za-z0-9._-]+\.md`' "$TM/SKILL.md" | tr -d '`' | sort -u)
[ "$tmissing" = 0 ] && pass "every file named in the app-stride-report manifest exists"

# 10 — every stride category and reference is in the manifest ----------------
printf '%s\n' "${bold}no orphan app-stride-report files${off}"
torphans=0
for f in "$TM"/stride/*.md "$TM"/references/*.md; do
  rel="${f#"$TM"/}"
  grep -qF "\`$rel\`" "$TM/SKILL.md" || { fail "$rel exists but no manifest row loads it"; torphans=1; }
done
[ "$torphans" = 0 ] && pass "every stride and reference file has a manifest row"

# 11 — every ref the app-stride-report enumerates is a real threat question -------
# Checks 11, 16 and 19 all extract threat ids with [A-Z], never [STRIDE]. The
# narrow class matches only the six valid letters, so an invented category — a
# Z.Q9 — is never extracted and the check passes while checking nothing. With
# [A-Z] the id is extracted, no Z-*.md is found, and the build goes red. Do not
# narrow these back.
printf '%s\n' "${bold}app-stride-report refs exist as threat questions${off}"
badt=0
while read -r q; do
  cat="${q%%.*}"
  f=$(ls "$TM"/stride/"$cat"-*.md 2>/dev/null | head -1)
  [ -n "$f" ] || { fail "app-stride-report cites $q but there is no $cat file"; badt=1; continue; }
  grep -qF "**$q**" "$f" || { fail "app-stride-report cites $q, which is not a threat question in $(basename "$f")"; badt=1; }
done < <(grep -rhoE '\b[A-Z]\.Q[0-9]+\b' "$TM/SKILL.md" "$TM"/references/ | sort -u)
[ "$badt" = 0 ] && pass "every id enumerated in the app-stride-report references is a real threat question"

# 12 — threat questions are numbered without gaps ----------------------------
printf '%s\n' "${bold}threat questions are contiguous${off}"
tgaps=0
for f in "$TM"/stride/*.md; do
  base=$(basename "$f" .md); cat="${base%%-*}"
  n=0
  while read -r i; do
    n=$((n + 1))
    [ "$i" = "$n" ] || { fail "$base jumps from Q$((n - 1)) to Q$i — ids must never be renumbered, but they must not skip either"; tgaps=1; n=$i; }
  done < <(grep -oE "\*\*$cat\.Q[0-9]+\*\*" "$f" | sed -E 's/.*\.Q([0-9]+)\*\*/\1/')
  [ "$n" = 0 ] && { fail "$base has no threat questions"; tgaps=1; }
done
[ "$tgaps" = 0 ] && pass "every stride category numbers its threat questions 1..n"

# 13 — the two bodies of material stay independent ---------------------------
printf '%s\n' "${bold}taxonomies stay separate${off}"
leak=$(grep -rnE 'A[0-9]{2}\.Q[0-9]+|A[0-9]{2}:2025|\b(NEST|LAR|SPR)\.[0-9]+|secure-coding|RULES_ROOT' \
  "$TM" "$REPO/agents/threat-modeler.md" 2>/dev/null || true)
if [ -n "$leak" ]; then
  while read -r l; do fail "app-stride-report material is coupled to the rules skill: $l"; done <<< "$leak"
else
  pass "no app-stride-report file cites an OWASP id, a stack id, or the rules skill"
fi
# The pr-appsec-review skill consumes both bodies of material and owns neither. It is
# the one place the two taxonomies sit in the same directory, and they sit there
# as two sections — never inside one item. Checks 14-16 hold its own references to
# the same promises the others make. Its OWASP ids are already covered by check 4,
# whose glob is skills/*/references/.

PR="$REPO/skills/pr-appsec-review"

# 14 — every pr-appsec-review manifest row points at a file that exists ------
printf '%s\n' "${bold}pr-appsec-review manifest rows resolve${off}"
pmissing=0
while read -r f; do
  [ -f "$PR/$f" ] || { fail "pr-appsec-review manifest cites $f, which does not exist"; pmissing=1; }
done < <(grep -oE '`references/[A-Za-z0-9._-]+\.md`' "$PR/SKILL.md" | tr -d '`' | sort -u)
[ "$pmissing" = 0 ] && pass "every file named in the pr-appsec-review manifest exists"

# 15 — every pr-appsec-review reference is in the manifest -------------------
printf '%s\n' "${bold}no orphan pr-appsec-review files${off}"
porphans=0
for f in "$PR"/references/*.md; do
  rel="${f#"$PR"/}"
  grep -qF "\`$rel\`" "$PR/SKILL.md" || { fail "$rel exists but no manifest row loads it"; porphans=1; }
done
[ "$porphans" = 0 ] && pass "every pr-appsec-review reference file has a manifest row"

# 16 — the threat ids it cites are real threat questions ---------------------
# check 4 already did this for the OWASP half; this is the other half.
printf '%s\n' "${bold}pr-appsec-review threat refs exist as threat questions${off}"
badp=0
while read -r q; do
  cat="${q%%.*}"
  f=$(ls "$TM"/stride/"$cat"-*.md 2>/dev/null | head -1)
  [ -n "$f" ] || { fail "pr-appsec-review cites $q but there is no $cat file"; badp=1; continue; }
  grep -qF "**$q**" "$f" || { fail "pr-appsec-review cites $q, which is not a threat question in $(basename "$f")"; badp=1; }
done < <(grep -rhoE '\b[A-Z]\.Q[0-9]+\b' "$PR/SKILL.md" "$PR"/references/ | sort -u)
[ "$badp" = 0 ] && pass "every threat id enumerated by pr-appsec-review is a real threat question"

# The appsec-test skill consumes both bodies of material and owns neither. It is
# the one skill that writes and runs: it puts a test file in the project and
# drives the project's own suite. Checks 17-19 hold its references to the same
# promises the others make. Its OWASP ids are covered by check 4 and its stack
# ids by check 20, both of which read every consumer's SKILL.md as well as its
# references/ — this skill cites ids in both places.

AT="$REPO/skills/appsec-test"

# 17 — every appsec-test manifest row points at a file that exists -----------
printf '%s\n' "${bold}appsec-test manifest rows resolve${off}"
amissing=0
while read -r f; do
  [ -f "$AT/$f" ] || { fail "appsec-test manifest cites $f, which does not exist"; amissing=1; }
done < <(grep -oE '`references/[A-Za-z0-9._-]+\.md`' "$AT/SKILL.md" | tr -d '`' | sort -u)
[ "$amissing" = 0 ] && pass "every file named in the appsec-test manifest exists"

# 18 — every appsec-test reference is in the manifest ------------------------
printf '%s\n' "${bold}no orphan appsec-test files${off}"
aorphans=0
for f in "$AT"/references/*.md; do
  rel="${f#"$AT"/}"
  grep -qF "\`$rel\`" "$AT/SKILL.md" || { fail "$rel exists but no manifest row loads it"; aorphans=1; }
done
[ "$aorphans" = 0 ] && pass "every appsec-test reference file has a manifest row"

# 19 — the threat ids it cites are real threat questions ---------------------
# check 4 already did this for the OWASP half; this is the other half.
printf '%s\n' "${bold}appsec-test threat refs exist as threat questions${off}"
bada=0
while read -r q; do
  cat="${q%%.*}"
  f=$(ls "$TM"/stride/"$cat"-*.md 2>/dev/null | head -1)
  [ -n "$f" ] || { fail "appsec-test cites $q but there is no $cat file"; bada=1; continue; }
  grep -qF "**$q**" "$f" || { fail "appsec-test cites $q, which is not a threat question in $(basename "$f")"; bada=1; }
done < <(grep -rhoE '\b[A-Z]\.Q[0-9]+\b' "$AT/SKILL.md" "$AT"/references/ | sort -u)
[ "$bada" = 0 ] && pass "every threat id enumerated by appsec-test is a real threat question"

# 20 — every stack id a consumer cites is a real stack rule ------------------
# Check 3 validates the → stacks/x.md (ID) pointers written inside the core
# files. Nothing validated the same ids when a consumer cites them, so a
# NEST.99 in a skill shipped green. This is that half.
printf '%s\n' "${bold}consumer stack refs exist as stack rules${off}"
bads=0
while read -r id; do
  case "${id%%.*}" in
    NEST) sf='nestjs.md' ;;
    LAR)  sf='laravel.md' ;;
    SPR)  sf='spring-boot.md' ;;
    *)    fail "a consumer cites $id, whose prefix maps to no stack file"; bads=1; continue ;;
  esac
  [ -f "$CORE/stacks/$sf" ] || { fail "a consumer cites $id but $sf does not exist"; bads=1; continue; }
  grep -qE "^#+ $id[[:space:]]|^- \*\*$id\*\*|\*\*$id\*\*" "$CORE/stacks/$sf" \
    || { fail "a consumer cites $id, which is not a rule in $sf"; bads=1; }
done < <(grep -rhoE '\b(NEST|LAR|SPR)\.[0-9]+\b' "$REPO"/skills/*/SKILL.md "$REPO"/skills/*/references/ | sort -u)
[ "$bads" = 0 ] && pass "every stack id enumerated by a consumer is a real stack rule"

# The appsec-profile skill owns no taxonomy at all. It is the only skill here that
# cites no id from either body of material, which is exactly what lets both bodies
# read the file it generates. Checks 21-22 hold it to the same promises the other
# consumers make; check 23 is the one check nothing else needed, and the reason is
# counter-intuitive: checks 4 and 20 *validate* an id and would happily pass a real
# A01.Q2 sitting in this skill, and checks 11/16/19 never glob this directory at
# all. There is deliberately no "every id it cites is real" check, because it cites
# none — do not add one, wire the profile to a taxonomy and both halves stop being
# able to read it.

PF="$REPO/skills/appsec-profile"

# The guard CONTRIBUTING.md documents but nothing enforced ---------------------
# A constant pointing nowhere makes the checks below print a tick having read
# nothing: a `while read` fed by a grep that matched no file never runs its body.
# One line per constant closes that, so the trap is now a failure instead of a
# paragraph of prose warning you about it.
printf '%s\n' "${bold}skill path constants resolve${off}"
badconst=0
for c in TM PR AT PF; do
  eval "d=\$$c"
  [ -d "$d" ] || { fail "\$$c points at $d, which is not a directory — the checks using it would pass having read nothing"; badconst=1; }
done
[ "$badconst" = 0 ] && pass "every skill path constant points at a real directory"

# 21 — every appsec-profile manifest row points at a file that exists ----------
printf '%s\n' "${bold}appsec-profile manifest rows resolve${off}"
pmissing=0
while read -r f; do
  [ -f "$PF/$f" ] || { fail "appsec-profile manifest cites $f, which does not exist"; pmissing=1; }
done < <(grep -oE '`(references|templates)/[A-Za-z0-9._-]+\.md`' "$PF/SKILL.md" | tr -d '`' | sort -u)
[ "$pmissing" = 0 ] && pass "every file named in the appsec-profile manifest exists"

# 22 — every appsec-profile reference and template is in the manifest ---------
# Unlike checks 15/18 this also covers templates/. That is deliberate: a template
# is exactly where an example claim carrying a forbidden id would rot unnoticed.
printf '%s\n' "${bold}no orphan appsec-profile files${off}"
porphans=0
for f in "$PF"/references/*.md "$PF"/templates/*.md; do
  [ -e "$f" ] || continue
  rel="${f#"$PF"/}"
  grep -qF "\`$rel\`" "$PF/SKILL.md" || { fail "$rel exists but no manifest row loads it"; porphans=1; }
done
[ "$porphans" = 0 ] && pass "every appsec-profile reference and template has a manifest row"

# 23 — the profile skill cites no id from either body -------------------------
# The mirror of check 13. `[A-Z]\.Q[0-9]+` rather than the six STRIDE letters, for
# the same reason check 19 uses it: an invented category has to be caught as
# loudly as an invented number.
printf '%s\n' "${bold}appsec-profile carries no taxonomy${off}"
badpf=0
while read -r hit; do
  fail "appsec-profile must cite no id from either body, but carries: $hit"
  badpf=1
done < <(grep -rhoE 'A[0-9]{2}\.Q[0-9]+|A[0-9]{2}:2025|\b(NEST|LAR|SPR)\.[0-9]+|\b[A-Z]\.Q[0-9]+|secure-coding|RULES_ROOT' "$PF" | sort -u)
[ "$badpf" = 0 ] && pass "appsec-profile cites no id from either body of material"

# 24 — test-harness tool names stay in the one file that owns them ------------
# CONTRIBUTING.md confines these to skills/appsec-test/references/test-design.md
# and nowhere else under skills/. Nothing enforced it until the profile gained a
# test-harness section, which is the first thing that makes it easy to break.
printf '%s\n' "${bold}harness tool names stay in one file${off}"
badharn=0
while read -r f; do
  [ "$f" = "$REPO/skills/appsec-test/references/test-design.md" ] && continue
  fail "${f#"$REPO"/} names a test runner — those belong only in skills/appsec-test/references/test-design.md"
  badharn=1
done < <(grep -rliE 'jest|supertest|\bpest\b|phpunit|junit|mockmvc' "$REPO"/skills/ | sort -u)
[ "$badharn" = 0 ] && pass "test runner names appear only in the one file that owns them"

# --- the appsec/ layout and the durable-id contract --------------------------
# Every check below states its corpus size first. This repository's documented
# failure mode is a check that passes by producing NO INPUT — a constant pointing
# nowhere, a grep whose character class matched nothing — so a `while read` loop
# that never runs its body prints a tick having verified nothing. Asserting the
# corpus is non-empty is what turns that into a failure.

RF_OWASP="$REPO/skills/api-secure-report/references/report-format.md"
RF_STRIDE="$REPO/skills/app-stride-report/references/report-format.md"
FR="$REPO/skills/appsec-test/references/finding-resolution.md"

# 25 — no artifact path from before the appsec/ layout survives ---------------
printf '%s\n' "${bold}no pre-appsec artifact paths${off}"
legacy_corpus=$(find "$REPO/skills" "$REPO/agents" -name '*.md' | wc -l | tr -d ' ')
if [ "$legacy_corpus" -lt 20 ]; then
  fail "only $legacy_corpus markdown files found under skills/ and agents/ — this check would pass having read almost nothing"
else
  badlegacy=0
  while read -r hit; do
    fail "${hit} names a path from before the appsec/ layout"
    badlegacy=1
  done < <(grep -rn -e 'SECURITY-REPORT\.md' -e 'STRIDE-REPORT\.md' -e '\.claude/appsec-profile\.md' \
             "$REPO"/skills/ "$REPO"/agents/ "$REPO"/install.sh "$REPO"/README.md "$REPO"/CONTRIBUTING.md \
             2>/dev/null | sed "s|$REPO/||")
  [ "$badlegacy" = 0 ] && pass "no legacy artifact path survives outside CHANGELOG.md ($legacy_corpus files searched)"
fi

# 26 — every consumer names the canonical appsec/ path -----------------------
printf '%s\n' "${bold}consumers name the canonical appsec/ paths${off}"
badpath=0
for pair in \
  "skills/secure-coding/SKILL.md:appsec/profile.md" \
  "skills/secure-coding/TRIGGER.md:appsec/profile.md" \
  "skills/pr-appsec-review/SKILL.md:appsec/security-report.md" \
  "skills/pr-appsec-review/SKILL.md:appsec/stride-report.md" \
  "skills/appsec-test/SKILL.md:appsec/security-report.md" \
  "skills/appsec-test/SKILL.md:appsec/stride-report.md" \
  "skills/app-stride-report/SKILL.md:appsec/security-report.md" \
  "skills/api-secure-report/SKILL.md:appsec/profile.md" \
  "skills/appsec-profile/SKILL.md:appsec/profile.md"; do
  f="${pair%%:*}"; want="${pair#*:}"
  [ -f "$REPO/$f" ] || { fail "$f does not exist — check 26 would verify nothing"; badpath=1; continue; }
  grep -qF "$want" "$REPO/$f" || { fail "$f never names $want"; badpath=1; }
done
[ "$badpath" = 0 ] && pass "every consumer names the appsec/ artifact it reads"

# 27 — the heading grammar agrees between producer and parser ----------------
printf '%s\n' "${bold}finding/threat heading grammar agrees${off}"
badgram=0
for f in "$RF_OWASP" "$FR"; do
  [ -f "$f" ] || { fail "${f#"$REPO"/} missing — check 27 would verify nothing"; badgram=1; continue; }
  grep -q 'SEC-' "$f" || { fail "${f#"$REPO"/} never mentions the SEC- id form"; badgram=1; }
done
for f in "$RF_STRIDE" "$FR"; do
  [ -f "$f" ] || { fail "${f#"$REPO"/} missing — check 27 would verify nothing"; badgram=1; continue; }
  grep -qE 'TM-[0-9<]' "$f" || { fail "${f#"$REPO"/} never mentions the TM- id form"; badgram=1; }
done
# the old positional grammar must be gone from the parser
grep -qE '^### <n>\.' "$FR" && { fail "finding-resolution.md still documents the positional '### <n>.' grammar"; badgram=1; }
[ "$badgram" = 0 ] && pass "producer and parser document the same SEC-/TM- heading grammar"

# 28 — the status tokens are byte-identical in both report formats -----------
# They are fixed English on purpose: a consumer greps them literally, so a
# translated or reworded token silently stops matching.
printf '%s\n' "${bold}status tokens agree across report formats${off}"
badtok=0
for f in "$RF_OWASP" "$RF_STRIDE"; do
  [ -f "$f" ] || { fail "${f#"$REPO"/} missing — check 28 would verify nothing"; badtok=1; continue; }
  for tok in '[new]' '[open since ' '[reopened ' '[fixed ' '[tested '; do
    grep -qF "$tok" "$f" || { fail "${f#"$REPO"/} does not specify the status token '$tok'"; badtok=1; }
  done
done
[ "$badtok" = 0 ] && pass "all five status tokens are specified identically in both report formats"

# 29 — the ledger schema and its columns agree -------------------------------
printf '%s\n' "${bold}ledger schema agrees across report formats${off}"
badled=0
for f in "$RF_OWASP" "$RF_STRIDE"; do
  [ -f "$f" ] || { fail "${f#"$REPO"/} missing — check 29 would verify nothing"; badled=1; continue; }
  grep -qF 'appsec-ledger · schema 1' "$f" || { fail "${f#"$REPO"/} does not specify the appsec-ledger schema line"; badled=1; }
  grep -qF 'id | ref | key | status | first seen | last seen | test' "$f" \
    || { fail "${f#"$REPO"/} does not specify the 7 ledger columns"; badled=1; }
done
[ "$badled" = 0 ] && pass "both report formats specify the same ledger schema and columns"

# 30 — the single-writer rule on the ledger is stated where it binds ---------
# Two writers in one id space is the failure the ledger exists to prevent, and
# the rule only works if the skill that writes the column also carries it.
printf '%s\n' "${bold}ledger single-writer rule is stated${off}"
badwr=0
AT_SKILL="$REPO/skills/appsec-test/SKILL.md"
[ -f "$AT_SKILL" ] || { fail "appsec-test/SKILL.md missing — check 30 would verify nothing"; badwr=1; }
if [ "$badwr" = 0 ]; then
  grep -qF 'Never an id, never the item' "$AT_SKILL" \
    || { fail "appsec-test/SKILL.md no longer states that it writes no id and no status"; badwr=1; }
  for f in "$RF_OWASP" "$RF_STRIDE"; do
    grep -qF 'has one writer, and it is not this skill' "$f" \
      || { fail "${f#"$REPO"/} no longer states who owns the ledger test column"; badwr=1; }
  done
fi
[ "$badwr" = 0 ] && pass "the ledger's single-writer rule is stated in all three files that depend on it"

printf '\n'

if [ "$fails" -gt 0 ]; then
  printf '%s%d check(s) failed%s\n' "$red" "$fails" "$off"
  exit 1
fi
printf '%sall checks passed%s\n' "$grn" "$off"
