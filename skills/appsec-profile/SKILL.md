---
name: appsec-profile
description: Architecture profile of the project under review — the module map, the trust-boundary names, where the guard is, how tenancy is applied, what is public by declaration, and where validation, error handling, configuration and the test harness live — written to .claude/appsec-profile.md as claims every later run reads instead of re-deriving. Use when the user runs /appsec-profile, or asks to record or refresh the project's security architecture so the other commands stop reporting controls that already exist.
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Appsec architecture profile

Produces one artifact: a description of what this project already does about
authentication, authorization, tenancy, validation, errors, configuration and its
own test harness — written as numbered claims with an evidence anchor each, at
`.claude/appsec-profile.md`, for the other commands to read before they audit
anything.

This skill reads **neither body of material** shipped alongside it. It loads no
rule file, no threat file, and cites no id from either. That is the whole reason
both halves can read its output: a profile that cited a rule would belong to one
taxonomy and be unusable by the other. It states what the project *does*, never
which rule that satisfies and never whether it is enough.

**One file is written, and it is not code.** `Write` is here because the profile
is this skill's one artifact. There is no `Edit`: a regeneration is
read-old → merge → write-whole, so the file is never half-updated and nothing the
project already had is ever modified. `Bash` is read-only search — the same
restriction the two agents carry in their own definitions.

**There is no `Agent`.** Discovery is a bounded probe list, not an investigation:
a fixed set of greps per section, read the files they hit, stop. Fan-out would
cost the two things this file exists to provide — a cheap run, and the same answer
twice. Eight agents inferring one architecture produce eight vocabularies for it,
and consolidating those is a second inference pass over the first one's guesses.

**Nothing is asked.** The run discovers, merges, writes, and prints what it wrote.
There is no question to answer and no prompt to hang on, which is what makes this
the one command here that runs unattended in CI.

## What this file is allowed to silence

> **The profile is not evidence. It is what you told the run to stop checking.**

Every line in it removes a question from every run that follows. That is the
file's entire value and its entire danger: a claim that is wrong does not produce
a wrong finding — it produces no finding at all, quietly, for as long as it
stands. So nothing here is a status to be ticked. The file **is** the review: what
survives in it has authority, what you delete from it restores the question, and
it arrives in your repository as a diff, which is the thing your team already
knows how to read.

Two rules replace the status field. Both are rules about the shape of the file, so
both enforce themselves.

**A claim with no `Does not apply to:` line suppresses nothing.** The consumers
test for the literal label, not for good intentions. The mechanism is never the
whole story — a base repository with one caller that bypasses it, a global guard
with an exclusion list — and the line that names the exceptions is the line that
keeps the claim from silencing them. It is pre-printed in the blank so it cannot
be forgotten, and **you never write `none` or `n/a` into it**: where discovery
found no bypass, write the bypass *shapes* for that mechanism anyway — the raw
query API, the query builder, a second registration path. *"nothing — every read
goes through it"* is a sentence only a human may type.

**Record declarations, never intentions.** A route is public *by design* when the
code says so — a public-route decorator, a permit-all matcher, an exclusion in the
guard registration. A route that is merely unguarded is not a declaration, it is a
finding, and it goes to `## Not claimed`. This is the rule that stops a run from
manufacturing the exemption it was asked to discover.

## Arguments

`/appsec-profile [language] [path] [--check]` — both positional arguments
optional, the flag optional.

| Argument | Default | Meaning |
|---|---|---|
| `language` | `pt-BR` | Language of the claim **prose** and of the terminal summary. Section headings and claim field labels are fixed English and never translated — a consumer lifts a section by its heading and tests a claim by its label. Anything that is not a recognized language tag is treated as `path`. |
| `path` | repository root | Restrict discovery to a subdirectory. Stated in the profile header; everything outside it goes to `## Not claimed`. |
| `--check` | off | **Writes nothing.** Re-greps every anchor in the existing profile, lists the claims whose evidence moved or vanished, and **exits non-zero on drift**. This is the CI gate; the plain run is the CI refresher. Requires an existing profile. |

**There is no overwrite mode, and no flag that blesses every claim at once.** The
plain run always merges (Step 5); a flag that replaced the file would destroy the
only thing in it worth anything, which is what you changed by hand. And a flag
that confirmed everything would defeat the one property this file has.

```
/appsec-profile                          # pt-BR, repository root
/appsec-profile en                        # English prose, repository root
/appsec-profile en services/api           # one subdirectory
/appsec-profile --check                   # CI: fail if the profile no longer describes the code
```

## Manifest

| ID | File | Load when |
|---|---|---|
| — | `references/discovery-probes.md` | always, in Step 3 — the probe list per section and per stack, the file budget, the cross-check |
| — | `references/profile-format.md` | always, in Steps 4, 5, 6 and 7 — the fixed headings, the claim labels, the well-formedness rules, the merge algorithm, the ledger, the line budget |
| — | `templates/appsec-profile.md` | Step 7, on a project that has no profile yet — the blank, with the claim stencil |

Every path in this file is relative to this skill's own directory, so the same
bytes work whether the skill was installed as a plugin, committed into a project's
`.claude/skills/`, or linked into the user's global skills directory. The one
exception is `.claude/appsec-profile.md`, which is relative to `SCAN_ROOT` — the
project under review — and never to this skill.

## Step 1 — Resolve the roots

1. **`SCAN_ROOT`** — the root of the project under review, absolute; the `path`
   argument if given, otherwise the repository root.
2. **`PROFILE`** — `SCAN_ROOT/.claude/appsec-profile.md`.
3. Capture what the header carries: today's date, and
   `git -C "$SCAN_ROOT" rev-parse --short HEAD`. If the project is not a git
   repository, the header says `Commit: —` and `--check` says it cannot detect new
   entry points.

**There is no rules root and no threat root, on purpose.** This is the only
command here that needs neither body installed, and it stays useful when only one
of them is.

## Step 2 — Read what is already there

Read `PROFILE` if it exists and parse it into claims by id, plus the ledger
comment on its last line. Under `--check`, a missing profile is a stop that names
`/appsec-profile`.

**A claim is identified by its `### P<n>` heading and by nothing else.** Prose
that has been rewritten by hand is still that claim, and Step 5 depends on it.

## Step 3 — Probe: bounded, grep-first, one pass

Detect the stack once: `nest-cli.json` → NestJS · `artisan`/`composer.json` →
Laravel · `pom.xml`/`build.gradle` → Spring Boot. No match means the
stack-agnostic fallback applies alone — that is the design, not a degraded run.

Follow `references/discovery-probes.md`, one section at a time, in the order the
headings appear there. Grep first; open a file only on a hit, and only the file
the hit names. Each probe produces the same line, which is the spine of everything
downstream:

```
<section> | <mechanism, one clause> | <file:line> | <symbol to re-grep> | <bypass shapes>
```

**Stop at the first probe that answers a section.** A section with no answer is an
entry in `## Not claimed`, not a reason for a second round. The file budget in
that reference is a ceiling, not a target.

## Step 4 — Anchor every claim

The mirror of the auditor's rule: **no anchor, no claim.** Every claim carries a
`file:line` and a symbol a later run can re-grep in one command. A fact that
cannot be anchored goes to `## Not claimed` together with the search that failed.

Then re-grep each **existing** claim's anchor. An anchor whose symbol is gone
means the claim is relocated to `## Stale` — text intact, never deleted.
Relocation is a position, not a badge: only the content headings suppress, and
`## Stale` is not one of them.

Under `--check`, stop here, print, and exit non-zero if anything moved.

## Step 5 — Merge, never clobber

A plain overwrite that eats what the developer wrote is the worst bug this skill
could ship, and it would be invisible — the file would still look right.

1. No existing profile → every claim is new; skip to 6.
2. **Ids are never renumbered and never reused.** The high-water mark and the
   retired set live in the ledger comment on the last line. If that comment is
   gone, fall back to `max(id present)` and **say so**, because from then on a
   number can be reused.
3. Match discovered facts to existing claims **by id, then by (mechanism, file)**
   — never by prose similarity.
4. Existing claim, discovered again, same mechanism → **refresh only the line
   number in `Evidence:`**. Every other line is copied through byte for byte. The
   developer's sentence is the point of the file.
5. Existing claim, mechanism changed → keep the id, write the new mechanism, and
   list it in the summary under *changed since last run*. Never merge the two
   sentences into one.
6. Existing claim, anchor gone → `## Stale` (Step 4).
7. Claim id absent from the file but below the high-water mark → the developer
   deleted it. **It is not re-added.** If discovery found the same fact again, the
   summary says so once, by id, and the file is left alone. **A deletion is an
   instruction.**
8. New fact → a new claim at the next id.
9. `## Notes`, and any prose the probes cannot express → copied through verbatim.
10. Write the whole file, then the ledger.

## Step 6 — Check the file is well formed

Before writing, assert: every claim in a suppressing section has `Mechanism:`,
`Evidence:`, `Applies to:` and **`Does not apply to:`**; no claim carries a
severity, a grade, or any id belonging to either body of material; no row in
`## Public by design` lacks a declaration in code; the file is within budget.

A claim that fails any of these is **not written** — it is reported in the summary
as a probe that produced something unusable. This is the step that keeps the
file's promises checkable by a later grep.

## Step 7 — Emit

Write the whole file to `PROFILE`, creating `.claude/` if absent — the only
directory this skill ever creates. Use `templates/appsec-profile.md` as the blank
when there was no profile.

Print, in `language`: the claim count per section, and what was added, refreshed,
changed, relocated to `## Stale`, or not re-added. Close with one line — *read
`.claude/appsec-profile.md` before the next run: every claim in it removes a
question.*

**This file is committed, unlike the two reports.** It describes architecture, not
exploitation, and it is worthless to the next reader if it is not in the
repository. Do not offer to gitignore it.

## Honest limits

**The design's safety rests on someone reading the file, and nothing here can make
that happen.** There is no status field and so no moment where a human is asked;
the review is the diff. The `Does not apply to:` line is what makes that diff
reviewable, and it is the only safety property in the design — which is why a run
never writes `none` into it.

**An anchor proves a symbol is still there, not that it still runs.** A guard
registered behind a config flag, a base repository one caller bypasses, a
middleware declared and never applied — all re-grep green. Staleness detection
catches deletion and rename, not a mechanism that quietly stopped working, which
is the failure mode that matters most.

**Discovery is grep-bounded on purpose, so it misses what the probes do not
name** — a guard registered through a dynamic module, tenancy in a row-level
security policy outside the repository, an authorization decision taken in a
gateway. The profile is also per-repository: a system whose authorization lives in
a sibling service is described by a profile that cannot see it.

**The `Does not apply to:` lines are the most useful paragraph here for someone
attacking this project,** and unlike the two reports this file is committed. It
names mechanisms rather than exploits, and a file nobody can see is worth nothing
— but a team with a public repository should weigh that.

**It cannot tell you whether a control is any good.** A claim says the project
applies tenancy in the predicate. Whether that predicate is correct is the audit's
question, and this file is careful never to answer it: no severities, no grades.
