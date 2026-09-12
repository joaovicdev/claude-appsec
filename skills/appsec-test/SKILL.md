---
name: appsec-test
description: Turns one security finding into the test that proves it — a failing test in the project's own framework, written where the project keeps its tests, then optionally the minimal fix that turns it green. Written in the user's language (pt-BR by default). Use when the user runs /appsec-test, or asks to prove, reproduce, regression-test or fix a specific security finding or threat.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
---

# Security regression test

Produces one artifact: one test, committed to the project's own suite, carrying
the attack assertion and the positive control — red when the finding is real —
and, only from there, the minimal fix that turns it green.

This skill is a **consumer** of both bodies of material. It restates neither — it
reads their files and cites their stable ids (`A01.Q2`, `NEST.3`, `E.Q3`). If a
rule seems missing, the fix is to add a question there, not to invent one here.

**This skill writes, and it runs the project's code.** `Edit` is new to this
repository — the other three commands have none — and `Bash` here executes the
project's test suite rather than only reading files. Both are the point: a
finding nobody ran is a claim. Nothing leaves the machine.

**There is no `Agent`.** `security-auditor` and `threat-modeler` both forbid
running project code in their own definitions, so neither is dispatched. An agent
defined never to run anything would either break that definition or quietly skip
the suite — and a suite that silently did not run looks exactly like one that
passed.

## The gate this skill exists to defend

**A fix without a red test is a guess with write permission.**

The material has been asking for this for four releases. `A01.Q3` wants the
exemption "listed in a test that enumerates all public routes"; `A06.Q9` asks
whether a test asserts the limit or the forbidden transition; `NEST.4` and
`SPR.1` name the obligation outright. Every one of them is an instruction to the
developer that nothing in the plugin fulfilled.

So the order is fixed and the fix is last. RED is the evidence; the fix is what
the evidence licenses. Reversed, this is a linter with a commit bit.

## Arguments

`/appsec-test [language] [finding] [--fix|--no-fix]` — both positional, both
optional, the two flags mutually exclusive.

| Argument | Default | Meaning |
|---|---|---|
| `language` | `pt-BR` | Output language: `pt-BR`, `en`, `es`, … Only the first token is tested; anything that is not a recognized language tag is treated as `finding`. |
| `finding` | the reports at `SCAN_ROOT` | The item to prove: a finding number (`3`, `#3`), a threat id (`TM-07`), a ref (`A01.Q2`, `NEST.3`, `E.Q3`), a ref pinned to a number (`A01.Q2#3`), a `file:line`, or the claim in prose. With none of those, the reports are triaged and the provable items offered for a pick. |
| `--fix` | the question at the gate | Answers the gate's question yes in advance. Skips the question, never the gate. |
| `--no-fix` | the question at the gate | Answers it no. The test is still written, run and kept. |

Examples, each a form `references/finding-resolution.md` resolves:

```
/appsec-test                               # triage the reports, then pick
/appsec-test en 3                          # finding 3, in English
/appsec-test TM-07 --no-fix                # prove the threat, stop there
/appsec-test 'GET /orders/:id returns another tenant order'
```

## Manifest

| ID | File | Load when |
|---|---|---|
| — | `references/finding-resolution.md` | always, in Steps 2 and 4 — the input forms, the resolved item, the two report grammars, taxonomy separation, the testability triage |
| — | `references/test-design.md` | always, in Steps 3 and 5 — harness discovery per stack, the baseline, the two assertions, placement and naming, the header block |
| — | `references/fix-protocol.md` | always, in Steps 6 and 7 — the three outcomes and their rendering, the gate, the shape of the fix, the two verification runs, the calibration loop |
| A01:2025 … A10:2025 | `owasp/*.md`, under `RULES_ROOT` | an OWASP resolved item — the one category its ref belongs to, and no other |
| NEST · LAR · SPR | `stacks/*.md`, under `RULES_ROOT` | a stack was detected — Step 7's fix takes the shape that file prescribes |
| S · T · R · I · D · E | `stride/*.md`, under `STRIDE_ROOT` | a STRIDE resolved item — the one category its ref belongs to, and no other |

Every path is relative to this skill's own directory, so the same bytes work
whether this was installed as a plugin, committed into a project's
`.claude/skills/`, or linked into the user's global skills directory.

## Step 1 — Resolve the roots

Everything downstream is addressed by absolute path. Establish all three before
anything else and reuse them verbatim.

1. **`RULES_ROOT`** — the `secure-coding` skill directory, the sibling of this
   one: resolve `../secure-coding/` against the directory this `SKILL.md` was
   loaded from, and make it absolute. Drives the OWASP input family.
2. **`STRIDE_ROOT`** — the `app-stride-report` skill directory, resolved the
   same way from `../app-stride-report/`. Drives the STRIDE input family.
3. **`SCAN_ROOT`** — the root of the project under test, absolute. The test is
   written there, the suite is run there, and any fix lands there.

**A missing root disables its input family — loudly, never silently.**

| Missing | What happens |
|---|---|
| `RULES_ROOT/SKILL.md` | No OWASP item resolves, and no OWASP fix has a shape to take. Say so now, name the path you tried, and repeat it under **Limites** — the outcome header carries the outcome, the ref and the location, and has no slot for a marker. |
| `STRIDE_ROOT/stride/` | No STRIDE item resolves. Same treatment. |
| both | **Stop.** Name both paths. A test written from a remembered rule looks exactly like one written from the material — and unlike a report, it is committed. |

Then, still in Step 1:

4. Read `RULES_ROOT/SKILL.md` and use **its** manifest and stack-detection
   table. Do not duplicate that table here. Detect the stack once:
   `nest-cli.json` → `stacks/nestjs.md` · `artisan`/`composer.json` →
   `stacks/laravel.md` · `pom.xml`/`build.gradle` → `stacks/spring-boot.md`. The
   same detection selects the harness recipe in Step 3. No match means the
   language-agnostic core applies alone — that is the design, not a degraded run.
5. Read these at `SCAN_ROOT` if they exist, and say which you found:
   - **`SECURITY-REPORT.md`** — a route audit, supplying findings by number.
     Those numbers are re-derived every run, so Step 2 resolves them at once.
   - **`STRIDE-REPORT.md`** — a threat model, supplying threats by `TM-<nn>`.
   - **`SECURITY-NOTES.md`** — an item recorded there as an accepted risk is not
     proved; say so and stop. `## Verified clean` is the table Step 6 offers to
     append a row to — offered, never written silently.

## Step 2 — Resolve the finding

Follow `references/finding-resolution.md`. It takes the finding in whatever form
the developer has it — a number, a `TM-<nn>`, a ref, a `file:line`, prose, or
nothing at all — and produces exactly this, which the rest of the skill runs on:

```
<taxonomy> | <ref> | <file:line, or — for an absence> | <the claim, one sentence>
```

Echo that **resolved item** back before anything is written, and stop rather than
guess: an input matching more than one item is offered for a pick, and an
`A01.Q2#3` whose finding 3 cites something else means the report is stale. A
resolved item nobody confirmed is a test written against the wrong defect, and it
will go red convincingly.

## Step 3 — Find the harness and take a baseline

Follow `references/test-design.md` for the stack detected in Step 1 — runner, how
the app is booted in a test, how data is seeded, where tests live. **No runner
detected is a full stop**: name what the project would have to install and why,
and write nothing. Scaffolding a test framework into someone's project as a side
effect of a security question is a larger change than the finding.

Then run the suite once, before a line is written, and record **the baseline**.
A suite already red is reported up front, because it changes what Step 7 can
promise. Without the baseline, "the fix broke three tests" is unknowable — they
may have been red all along.

## Step 4 — Triage: is this provable here?

The triage table is in `references/finding-resolution.md`. The rule it encodes:
**testability comes from whether the security property is observable at a
boundary the project can drive, not from whether the item has a `file:line`.**
An absent rate limit (`A07.Q1` as a finding, `D.Q1` as a threat) is provable with
no line to cite; a lockfile pin (`A03.Q2`) never is, however exact its line.

When the item is not provable here, name the id, say why, and stop — the existing
path is already right: load `secure-coding` and fix it by hand. A test written to
pass because there was nothing to assert is worse than no test, because it is
committed and it reads as evidence.

## Step 5 — Write the test

Follow `references/test-design.md` for placement, naming, the header block and
the project conventions the committed test has to match. Two of its rules govern
everything else:

- **Two assertions, always.** The attack assertion states the property the
  finding says is broken; the positive control states that the legitimate caller
  still succeeds down the same path. A test carrying only the attack assertion
  cannot tell RED from BROKEN, which makes its red worth nothing.
- **Assert the security property, not the implementation.** *"Tenant B cannot
  read tenant A's order"*, never *"the `where` clause contains `tenantId`"*. The
  test has to survive the refactor that fixes it — that is what makes it a
  regression test rather than a snapshot of today's code.

The `language` argument governs the terminal output; the committed test follows
the repository. A `security/` directory invented in a project that has none is a
test the next developer deletes.

## Step 6 — Run, and name the outcome

Run the new test alone, then report exactly one of three outcomes. They are ids:
uppercase, untranslated, never softened into prose.

```
RED      the positive control passes, the attack assertion fails
GREEN    both pass
BROKEN   the positive control fails
```

RED is the finding proved at one boundary, GREEN is not reproducible here, and
BROKEN is a test that never reached the code.

**The positive control is what separates RED from BROKEN.** A test that goes red
because the route 404s, the fixture is missing, or the request gets a 401 before
it ever reaches the handler proves nothing. A positive control that fails means
the harness is wrong and the handler was never touched — fix the harness, never
the code.

GREEN splits three ways and the run says which; `references/fix-protocol.md`
carries the split, the rendering of all three, and the calibration loop that
offers a GREEN caused by a wrong finding to `SECURITY-NOTES.md` under
`## Verified clean`. GREEN and BROKEN both end here — neither reaches the gate,
and BROKEN reported as RED is a fix applied to code that was never reached.

## Step 7 — The gate, and the fix

**The gate: the fix runs from RED and from nowhere else.** GREEN and BROKEN never
reach it, `--fix` included. There is no `--force`, because an escape hatch here
defeats the one thing this skill does. From RED, ask once — in the requested
language — whether to fix now, and edit only on a yes.

The shape of the fix and the two verification runs against **the baseline** live
in `references/fix-protocol.md`. Two of its rules are absolute: the fix is
minimal and takes the form the cited rule prescribes — scope in the query
predicate, never a check after the fetch — and **the test is never edited to
make it pass**. A test weakened until it is green is the vulnerability
re-shipped with a green badge.

Use the template in `references/fix-protocol.md`. Translate the prose and the
labels into the requested language. Never translate: ids (`A01.Q2`, `NEST.3`,
`E.Q3`, `TM-04`), the outcome names `RED`, `GREEN` and `BROKEN`, source and test
file paths, git refs and shas, runner and framework names, assertion names, HTTP
methods, identifiers, or code.

Close with the run's **Limites**, mandatory and never empty: what the outcome
proves and what it does not, whether the baseline was already red, and which
input family did not run. A run that hides what it did not assert is worse than
no run — the test is committed, and the next reader trusts it.

## Honest limits

Whole families carry no assertion, and this skill says so rather than writing
something that passes. `A03` is a lockfile and pipeline property, not a runtime
behaviour; most of `A06` is a design question with no boundary to drive; a
misconfiguration living only in a deployment manifest is invisible to the app's
own suite. `A06.Q9` is the sharpest case — it asks whether a test exists, so this
skill satisfies it and can never prove it. RED is evidence for one claim at one
boundary and nothing more: it does not say the module is otherwise sound, and it
does not carry to the sibling route nobody drove. GREEN has three causes and only
two are false positives; counting the third — a test that missed — as calibration
is how a real finding gets closed. A suite already red at the baseline limits
what Step 7 can promise. `references/test-design.md` carries the per-stack
harness recipes — treat them as a starting point and tighten them the first time
you work in a project they do not fit.
