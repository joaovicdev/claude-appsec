<!--
  The blank for .claude/appsec-profile.md. Copied to SCAN_ROOT/.claude/ by
  /appsec-profile, then filled from the probe results.

  Wiring, repeated here so it is in front of you while you fill it in:
   1. Section headings and field labels stay ENGLISH. Prose follows the run's
      language. A consumer lifts a section by its heading.
   2. Every claim is five lines. A claim missing `Does not apply to:` suppresses
      nothing — that is the only safety property this file has.
   3. Never write `none` into `Does not apply to:`. Write the bypass SHAPES for
      the mechanism. "nothing — every read goes through it" is a human's sentence.
   4. `## Public by design` takes a row only where the code DECLARES the exposure.
      An unguarded route is a finding, and belongs in `## Not claimed`.
   5. No severities, no grades. This file says what exists, never whether it is
      enough.
   6. The ledger comment on the last line carries the id high-water mark. Ids are
      never renumbered and never reused.
-->

# <project> — appsec architecture profile

**Stack:** <framework, ORM, auth> · **Scope:** <repository root, or the subdirectory>
**Generated:** <YYYY-MM-DD> by `/appsec-profile` · **Commit:** `<sha>`
**Claims:** <n> · **Not claimed:** <n> · **Stale:** <n>

> Every claim below removes a question from every later run. A wrong claim does not
> produce a wrong finding — it produces no finding at all. Read it, correct it,
> delete what you do not recognise: deleting a claim restores the question. A claim
> with no **Does not apply to:** line removes nothing.
>
> Section headings and field labels are English on purpose — that is how a run
> lifts a section out of this file.

## Module map

| Module | Directory |
|---|---|
| <name> | `<path>` |

## Trust boundaries

| Boundary | What changes when it is crossed | Inner side |
|---|---|---|
| <internet → app> | <the caller stops being known / trusted> | <elements> |

## Authentication

### P1 — <what issues identity, what validates it>

- **Mechanism:** <…>
- **Evidence:** `<file>:<line>` — `<symbol>`
- **Applies to:** <…>
- **Does not apply to:** <the bypasses — never "none">

## Authorization

### P2 — <the guard, filter or middleware that decides>

- **Mechanism:** <…>
- **Evidence:** `<file>:<line>` — `<symbol>`
- **Applies to:** <…>
- **Does not apply to:** <the opt-outs, and what the mechanism does not decide>

## Tenancy and data scoping

### P3 — <the mechanism that scopes a query>

- **Mechanism:** <…>
- **Evidence:** `<file>:<line>` — `<symbol>`
- **Applies to:** <…>
- **Does not apply to:** <the raw query API, the query builder, every path around it>

## Public by design

A route not in this table is not public on purpose: it is a route without a guard,
and that is a finding. Only what the code **declares** goes here.

| Route | Declaration | Why | Evidence |
|---|---|---|---|
| <METHOD /path> | `<the decorator or matcher>` | <?> | `<file>:<line>` |

## Input validation

### P4 — <the global validator and the flags it carries>

- **Mechanism:** <…>
- **Evidence:** `<file>:<line>` — `<symbol>`
- **Applies to:** <…>
- **Does not apply to:** <…>

## Errors and logging

### P5 — <the global handler, and what is redacted>

- **Mechanism:** <…>
- **Evidence:** `<file>:<line>` — `<symbol>`
- **Applies to:** <…>
- **Does not apply to:** <…>

## Configuration and secrets

### P6 — <where config comes from, and whether a missing secret stops the boot>

- **Mechanism:** <…>
- **Evidence:** `<file>:<line>` — `<symbol>`
- **Applies to:** <…>
- **Does not apply to:** <…>

## External systems

| System | Reached by | Evidence |
|---|---|---|
| <name> | `<client>` | `<file>:<line>` |

## Test harness

| Fact | Value, quoted from the project |
|---|---|
| Command that runs the suite | `<as declared by the project>` |
| Where tests live | `<path>` |
| How the app is booted for a test | `<file>:<line>` |
| How an authenticated request is built | `<file>:<line>` |

## Not claimed

Every question the probes could not answer, with the search that failed. This
section suppresses nothing — it sharpens what follows.

- <the question> — <the greps run>, no hit. <what that means for a later run>

## Stale

Claims whose evidence anchor no longer resolves. Text intact, id kept; they
suppress nothing while they sit here. Re-anchor or delete.

## Notes

Anything true here that no probe can express. Copied through verbatim on every
regeneration.

<!-- appsec-profile · schema 1 · ids issued: none · retired: none · from <sha> on <YYYY-MM-DD> -->
