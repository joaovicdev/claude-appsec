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
printf '%s\n' "${bold}consumer refs exist as review questions${off}"
badq=0
while read -r q; do
  cat="${q%%.*}"
  f=$(ls "$CORE"/owasp/"$cat"-*.md 2>/dev/null | head -1)
  [ -n "$f" ] || { fail "a consumer cites $q but there is no $cat file"; badq=1; continue; }
  grep -qF "**$q**" "$f" || { fail "a consumer cites $q, which is not a review question in $(basename "$f")"; badq=1; }
done < <(grep -rhoE '\bA[0-9]{2}\.Q[0-9]+\b' "$REPO"/skills/*/references/ | sort -u)
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
printf '%s\n' "${bold}app-stride-report refs exist as threat questions${off}"
badt=0
while read -r q; do
  cat="${q%%.*}"
  f=$(ls "$TM"/stride/"$cat"-*.md 2>/dev/null | head -1)
  [ -n "$f" ] || { fail "app-stride-report cites $q but there is no $cat file"; badt=1; continue; }
  grep -qF "**$q**" "$f" || { fail "app-stride-report cites $q, which is not a threat question in $(basename "$f")"; badt=1; }
done < <(grep -rhoE '\b[STRIDE]\.Q[0-9]+\b' "$TM/SKILL.md" "$TM"/references/ | sort -u)
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
done < <(grep -rhoE '\b[STRIDE]\.Q[0-9]+\b' "$PR/SKILL.md" "$PR"/references/ | sort -u)
[ "$badp" = 0 ] && pass "every threat id enumerated by pr-appsec-review is a real threat question"

printf '\n'
if [ "$fails" -gt 0 ]; then
  printf '%s%d check(s) failed%s\n' "$red" "$fails" "$off"
  exit 1
fi
printf '%sall checks passed%s\n' "$grn" "$off"
