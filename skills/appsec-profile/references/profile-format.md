# Profile format

The output contract. Everything here is what a consumer relies on, so none of it
is a matter of taste: a run lifts a section by its heading and tests a claim by
its label.

## 1. The fixed headings

The section list **is** the slicing contract. Order is fixed, headings are English
in every language, and a section with nothing in it says so rather than being
omitted.

| Heading | Holds | Can suppress |
|---|---|---|
| `## Module map` | module or component names and their directories | no |
| `## Trust boundaries` | the boundary table a threat model names its boundaries from | no |
| `## Authentication` | what issues identity, what validates it, where the request identity lands | yes |
| `## Authorization` | the guard, filter or middleware that decides, and where policies live | yes |
| `## Tenancy and data scoping` | the mechanism that scopes a query, and its bypasses | yes |
| `## Public by design` | routes exposed on purpose, each with the declaration in code | yes |
| `## Input validation` | the global validator and the defaults it was configured with | yes |
| `## Errors and logging` | the global error handler, the logger, what is redacted | yes |
| `## Configuration and secrets` | where config comes from, whether a missing secret fails at boot | yes |
| `## External systems` | every outbound dependency the project talks to | no |
| `## Test harness` | where tests live, how one runs, how an authenticated request is built | no |
| `## Not claimed` | every question a probe could not answer, and the search that failed | no |
| `## Stale` | claims whose evidence anchor no longer resolves | no |
| `## Notes` | whatever the developer wrote that no probe can express | no |

`## Not claimed` is not a footnote — on many projects it is most of the file, and
it is the part with **no false-negative risk at all**. A negative claim cannot
silence anything; it sharpens what follows. *There is no global guard* turns every
unguarded handler into a real finding instead of an argument.

`## Stale` is a **position, not a badge**. A claim relocated there keeps its text
and its id; it simply stops being under a heading that can suppress. That is how
staleness works without reintroducing a per-claim status.

## 2. The claim

Five lines. Nothing else is a claim.

```markdown
### P<n> — <the claim, one line, in the run's language>

- **Mechanism:** <how it works, in the project's own vocabulary>
- **Evidence:** <file:line> — <the symbol or pattern a later run re-greps>
- **Applies to:** <the scope, stated positively and countably>
- **Does not apply to:** <the bypasses — never the word "none">
```

| Field | Required | Note |
|---|---|---|
| heading | always | `### P<n> — …`. The id is how a claim is identified; nothing else is. |
| `Mechanism:` | always | The project's words. If the codebase says "use-case", do not say "application service". |
| `Evidence:` | always | No anchor, no claim. The symbol in the anchor is what makes staleness detectable in one grep. |
| `Applies to:` | always | Countable where it can be: *11 of 14 models*, *every route in `src/`*. |
| `Does not apply to:` | **to suppress** | The bypasses. Absent → the claim documents, it does not exempt. |

**A claim carries no severity and no grade.** It never says a mechanism is
sufficient, adequate or weak. Whether the mechanism is any good is the audit's
question; this file only says the mechanism is there.

## 3. The two rules the generator obeys

**Never write `none` or `n/a` into `Does not apply to:`.** Where discovery found no
bypass, write the bypass *shapes* for that mechanism anyway — the raw query API,
the query builder, the manager or session used directly, a second registration
path. A run cannot prove a negative over code it did not read.
*"nothing — every read goes through it"* is a sentence only a human may type, and
a human typing it is the review working.

**Record declarations, never intentions.** `## Public by design` takes a row only
when the code *declares* the exposure: a public-route decorator, a permit-all
matcher, an exclusion in the guard registration. A route that is merely unguarded
is a finding and belongs in `## Not claimed`. Without this rule a run would
manufacture exactly the exemptions it was asked to discover, which is the one
failure that would make this file worse than nothing.

## 4. The merge

Ids behave like every other id in this repository: **never renumbered, never
reused.** The high-water mark and the retired set live in a ledger comment on the
file's last line.

```markdown
<!-- appsec-profile · schema 1 · ids issued: P1-P12 · retired: P4 · from 1d67aba on 2026-09-12 -->
```

If that comment is gone, fall back to `max(id present)` and **say so in the
summary** — from that point on a number can be reused, and a stale reference in an
old report would resolve to the wrong claim.

| Situation | What happens |
|---|---|
| No profile yet | Every claim is new. |
| Claim found again, same mechanism | **Only the `Evidence:` line number is refreshed.** Every other line is copied byte for byte. |
| Claim found again, mechanism changed | Keep the id, write the new mechanism, report it as *changed*. Never blend the two sentences. |
| Anchor no longer resolves | Relocate to `## Stale`, text intact. Never delete. |
| Id below the high-water mark, absent from the file | The developer deleted it. **Do not re-add it.** Say so once, by id, and leave the file alone. |
| A fact with no matching claim | A new claim at the next id. |
| `## Notes`, and prose no probe can express | Copied through verbatim. |

Matching is **by id, then by `(mechanism, file)`** — never by prose similarity. A
developer who rewrote a claim's sentence still owns that claim.

**A deletion is an instruction.** It is the only way the file has of saying *stop
claiming this*, and a run that helpfully restores it would make the file
impossible to correct.

## 5. Language

The claim prose and the terminal summary are written in the run's language; the
default is `pt-BR`.

**The section headings and the claim field labels are fixed English and are never
translated.** This is a deliberate deviation from how the reports are rendered, and
the reason is mechanical: a consumer lifts `## Authorization` by its heading to
paste into a subagent prompt, and tests a claim for the literal string
`Does not apply to:` before it is allowed to suppress anything. Translate those and
the contract breaks silently in one language and holds in another.

Also never translated: claim ids, file paths, route paths, HTTP methods, symbols,
and code.

## 6. Budget

Five lines per claim, one line per table row. A typical project lands 12–16 claims
and 10–25 rows — about 150 lines, with 200 the ceiling worth defending.

The number that actually matters is the **slice**: the largest block any single
subagent receives — `## Authorization` + `## Tenancy and data scoping` +
`## Input validation` + `## Public by design` + `## Not claimed` — stays under
~60 lines. Past that, a claim is describing the code instead of naming the
mechanism, and the file has started costing the tokens it exists to save.

## Cross-check

- **Count.** Every suppressing section's claims have all five lines; the count of
  `Does not apply to:` equals the count of `### P` headings under those headings.
- **Sample.** Re-grep three anchors at random. Each resolves to the symbol named.
- **Declare.** State the claim count, the `## Not claimed` count, and the ledger's
  high-water mark in the terminal summary — a profile that hides how much it could
  not answer is worse than no profile.
