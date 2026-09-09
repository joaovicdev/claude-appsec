---
name: pr-appsec-review
description: Security review of a pull request in two independent halves — OWASP Top 10:2025 findings on the changed code, and STRIDE threats on the trust boundaries the change touches — each item marked as introduced by this change or pre-existing, written in the user's language (pt-BR by default). Use when the user runs /pr-appsec-review, or asks to review a PR, a diff, or a branch for security risk.
allowed-tools: Read, Glob, Grep, Bash, Agent
---

# PR security review

Produces one artifact: a review of a single change — the diff, read in the
context of the code it lands in — answering the two questions a reviewer
actually has, in two separate halves:

- **Does this follow the OWASP Top 10?** Findings on the changed code, citing
  the ids of the `secure-coding` skill (`A01.Q2`, `NEST.3`).
- **Does this create risk under STRIDE?** Threats against the elements and trust
  boundaries the change touches, citing the ids of the `app-stride-report` skill
  (`S.Q1`, `E.Q3`).

This skill is a **consumer** of both. It restates neither — it reads their files
and cites their stable ids. If a rule seems missing, the fix is to add a question
there, not to invent one here.

**Nothing is written. Not even the review.** The other two commands write a
document; this one has no `Write` at all, and prints to the terminal. A review
that leaves a file behind in someone's branch is a review that shows up in their
next `git status`.

## The two halves

This is the only skill in the repository where both taxonomies run, and they run
**beside each other, never inside each other**:

- Each half loads only its own material and cites only its own ids.
- Each half produces its own section, its own scale, its own numbering.
- **No single item ever carries both vocabularies.** A finding cites `A01.Q2`; a
  threat cites `E.Q3`; nothing cites the two together.

Either half runs without the other installed. A missing half is reported as
missing — never as a half that found nothing.

## What a PR review adds that a scan does not

Every item carries an **origin**: `introduced`, `aggravated`, or `pre-existing`.
A reviewer needs to know what *this change* is answerable for. A pre-existing
defect in touched code is still worth reporting — it is in front of someone who
is already editing that file — but it does not, by itself, block the merge.

That field is what makes the verdict computable rather than a matter of mood.
See `references/report-format.md`.

## Arguments

`/pr-appsec-review [language] [target] [base]` — all positional, all optional.

| Argument | Default | Meaning |
|---|---|---|
| `language` | `pt-BR` | Output language: `pt-BR`, `en`, `es`, … Only the first token is tested; anything that is not a recognized language tag is treated as `target`. |
| `target` | the current branch | What to review: a local ref (`feature/orders`, a sha, `HEAD`), or a pull request (`https://github.com/org/repo/pull/123`, `#123`). Resolved as a ref first — a branch literally named `123` wins over PR 123. |
| `base` | the repository's default branch | What to compare against: `main`, `dev`, `staging`, … Ignored when `target` is a pull request, which carries its own base. |

Examples, each a form `references/diff-discovery.md` resolves:

```
/pr-appsec-review                                   # current branch vs the default base
/pr-appsec-review en                                # same, in English
/pr-appsec-review feature/orders staging            # explicit pair
/pr-appsec-review pt-BR https://github.com/org/repo/pull/123
```

## Manifest

| ID | File | Load when |
|---|---|---|
| — | `references/diff-discovery.md` | always, in Step 2 — target resolution, merge-base, the hunk map, file classification |
| — | `references/report-format.md` | always, in Steps 4, 5 and 6 — the two return contracts, the two scales, the verdict rule, the output template |

Every path is relative to this skill's own directory, so the same bytes work
whether this was installed as a plugin, committed into a project's
`.claude/skills/`, or linked into the user's global skills directory.

## Step 1 — Resolve the roots

Everything downstream is addressed by absolute path. Establish all three before
anything else and reuse them verbatim.

1. **`RULES_ROOT`** — the `secure-coding` skill directory, the sibling of this
   one: resolve `../secure-coding/` against the directory this `SKILL.md` was
   loaded from, and make it absolute. Drives the OWASP half.
2. **`STRIDE_ROOT`** — the `app-stride-report` skill directory, resolved the same
   way from `../app-stride-report/`. Drives the STRIDE half.
3. **`SCAN_ROOT`** — the root of the working tree under review, absolute.

**A missing root disables its half — loudly, never silently.**

| Missing | What happens |
|---|---|
| `RULES_ROOT/SKILL.md` | The OWASP half does not run. Say so now, name the path you tried, mark `OWASP ✘` in the header, and repeat it under **Limites**. |
| `STRIDE_ROOT/stride/` | The STRIDE half does not run. Same treatment. |
| both | **Stop.** Name both paths. A review with no material looks exactly like a review that found nothing. |

Then, still in Step 1:

4. Read `RULES_ROOT/SKILL.md` and use **its** manifest and stack-detection table.
   Do not duplicate that table here. Detect the stack once: `nest-cli.json` →
   `stacks/nestjs.md` · `artisan`/`composer.json` → `stacks/laravel.md` ·
   `pom.xml`/`build.gradle` → `stacks/spring-boot.md`. No match means the
   language-agnostic core applies alone — that is the design, not a degraded run.
5. Read these at `SCAN_ROOT` if they exist, and say which you found:
   - **`SECURITY-NOTES.md`** — an accepted risk goes to its own section, not into
     the findings. An open item that this change touches keeps its existing id.
   - **`SECURITY-REPORT.md`** — a previous route audit. A finding it already
     records in touched code is `origin: pre-existing`, cited **by its finding
     number**.
   - **`STRIDE-REPORT.md`** — a previous threat model. Seeds the decomposition in
     Step 3 instead of rebuilding it, and tells you which elements are new since.

## Step 2 — Resolve the change and get the diff

Follow `references/diff-discovery.md`. It resolves the target, finds the
merge-base, and produces the three things the rest of the skill runs on:

```
HEAD_REF @ <sha>   BASE_REF @ <sha>   MERGE_BASE <sha>
<path> | +<added>/-<removed> | <classification> | <hunk ranges on the new side>
```

The file list is the spine of the review — the *Arquivos alterados* table is
built from it, not from whatever the analysis happened to notice. A touched file
with no finding appears there marked `OK`; that is the point of enumerating.

Two hard rules, both from that file:

- **The working tree is never modified.** No `checkout`, no `stash`, no `merge`.
  Fetching a pull request head writes a ref, so it is *asked for* first.
- Anything that cannot be read — a head that is not local, a binary blob, a file
  deleted by the change — is recorded now and reproduced under **Limites**.

## Step 3 — Decompose the delta

*Skip this step entirely if the STRIDE half is disabled.*

Do not model the whole system; model what moved. Using the element shapes, the
boundary catalogue and the element matrix in
`STRIDE_ROOT/references/decomposition.md`, list only:

- elements the change **adds** (a new handler, a new store, a new outbound call,
  a new queue consumer, a new env var read at boot);
- elements the change **alters** (a guard whose condition moved, a response shape
  that grew a field, a query whose predicate changed);
- the **boundaries those elements sit on or cross**, and whether the change
  *adds*, *moves*, *widens* or *narrows* one.

If `STRIDE-REPORT.md` exists at `SCAN_ROOT`, seed the list from it and mark what
is new since it was written — re-deriving a decomposition that already exists
wastes the run and invites a second, contradictory one.

Print the delta and the touched boundaries to the user **before** fanning out,
and continue without waiting. Every judgment call made here is written down now
and reproduced under **Premissas**.

A boundary that the change adds, moves or widens is the single most important
output of this half. It leads the STRIDE section even when no individual threat
against it is High.

## Step 4 — Fan out

Two axes, dispatched together, capped at **8 concurrent agents in total** across
both halves, with the remainder in further batches. Both agents ship alongside
these skills; each name carries the plugin's namespace as a prefix under a plugin
install (`claude-appsec:security-auditor`) and resolves bare otherwise. Neither
has `Write` or `Edit`, so read-only is enforced by the definitions rather than
requested in a prompt.

If a name does not resolve, that agent was not installed. Fall back to
`general-purpose`, **tell the user** which half is running without the
enforced-read-only agent, and paste the full set of rules from that agent's
definition into every prompt by hand.

**OWASP axis — `security-auditor`.** One agent per module of changed files, split
so none exceeds ~12 files:

| Category | File to read, under `RULES_ROOT` |
|---|---|
| A01:2025 | `owasp/A01-broken-access-control.md` |
| A05:2025 | `owasp/A05-injection.md` |
| A09:2025 | `owasp/A09-security-logging-and-alerting-failures.md` |
| A10:2025 | `owasp/A10-mishandling-of-exceptional-conditions.md` |
| stack | the detected `stacks/*.md`, if any |

Plus one agent per cross-cutting area **the diff actually touches** — a
three-line change to one controller does not pay for four global agents:

| Agent | Dispatch when the change touches | Reads, under `RULES_ROOT` |
|---|---|---|
| config | bootstrap, CORS, headers, TLS, debug flags, docs or admin surfaces | `owasp/A02-security-misconfiguration.md` |
| deps | a dependency manifest, a lockfile, a Dockerfile, a CI workflow, an install script | `owasp/A03-software-supply-chain-failures.md` |
| auth | login, registration, reset, MFA, sessions, tokens, API keys, password or key handling | `owasp/A04-cryptographic-failures.md`, `owasp/A07-authentication-failures.md` |
| design | workflows, limits, quotas, money, invitations, webhook receivers, deserialization, signed payloads | `owasp/A06-insecure-design.md`, `owasp/A08-software-or-data-integrity-failures.md` |

**STRIDE axis — `threat-modeler`.** One agent per touched trust boundary, owning
the delta elements on its inner side; split a boundary whose inner side exceeds
~12 elements. Assign categories **from the matrix, not by hand**: an agent owning
only stores and flows is never asked about `S` or `E`, and its prompt does not
name those files.

Every prompt on either axis states, explicitly:

- The roots it needs, **absolute** — `RULES_ROOT` and `SCAN_ROOT` for the OWASP
  axis, `STRIDE_ROOT` and `SCAN_ROOT` for the STRIDE axis. The file paths in the
  tables above are relative to a root: interpolate the absolute path rather than
  pasting the relative one. **Never give an agent the other half's root**, and
  never name the other half's ids in its prompt.
- `MERGE_BASE` and `HEAD_REF`, so the agent can run
  `git diff --merge-base <base> <head> -- <its files>` itself.
- **Its slice**: the files it owns with their hunk ranges, or the boundary and
  elements it owns. Everything outside belongs to another agent.
- **Judge the change in context, not the hunk in isolation.** Read the whole
  file, and the module wiring around it. A handler with no guard on it is not a
  finding if a global guard covers the module; a query that looks unscoped is not
  a finding if the repository applies the tenant predicate. This is the rule that
  decides whether the review is worth reading — an added line is a *lead*, and
  the surrounding code decides.
- **Set `origin` on every item**, and how: compare against the base side of the
  diff, or `git show <MERGE_BASE>:<path>`. If the defect is present at
  `MERGE_BASE` unchanged, it is `pre-existing`; if the change makes an existing
  defect reachable, broader or more likely, it is `aggravated`.
- **The return contract for its axis, pasted inline, in English.** Do not point
  a subagent at this skill's `references/report-format.md`: that file carries
  both taxonomies, and an agent that reads the other half's ids is an agent
  that will eventually cite one. Copy the block its axis owns, and only that.
- For the STRIDE axis only: **the whole delta decomposition**, including
  boundaries this agent does not own. A threat that crosses out of a slice is
  only visible to an agent that knows the other side is there.

## Step 5 — Consolidate

Consolidate the two halves **separately**. They never merge, deduplicate against
each other, or share a number.

- **Deduplicate** within a half — by `(file, ref)` for findings, by
  `(element, ref)` for threats. A cross-cutting item is filed once, against the
  file or element that would own the fix, never repeated on every file it affects.
- **Drop**, in the OWASP half: any finding without a `file:line` that was read,
  and any `ref` that does not exist in the `secure-coding` files.
- **Drop**, in the STRIDE half: any `ref` that does not exist in `stride/`, any
  `ref` the element matrix says that element type cannot carry, and any
  `status: unmitigated` with no account of where the agent searched.
- **Drop, in both halves: any item with no `origin`.** An item nobody placed
  relative to the change does not belong in a review of that change.
- **Rate.** Findings on the four-level severity scale; threats on impact ×
  likelihood. Both tables live in `references/report-format.md`, side by side and
  never merged into one scale.
- **Number.** Findings `1`, `2`, … ordered by origin (`introduced` first), then
  severity, then file. Threats `TM-01`, `TM-02`, … ordered by risk, then
  boundary. Never `T-01` — `T` is Tampering.
- **Cross-check the project files.** An accepted risk from `SECURITY-NOTES.md`
  moves to its own section. An item that `SECURITY-REPORT.md` or
  `STRIDE-REPORT.md` already records is marked `pre-existing` and cited **by that
  document's item number**, never by the taxonomy it uses.
- **Compute the verdict** from the rule in `references/report-format.md`. It is a
  rule, not a judgment, so two runs over the same change agree.

## Step 6 — Emit

Print the review to the terminal. **Write nothing.** If the user wants it in a
file, they can redirect it or ask — this skill does not decide that for them, and
does not touch the branch it just reviewed.

Use the template in `references/report-format.md`. Translate the prose and the
labels into the requested language. Never translate: ids (`A01.Q2`, `NEST.3`,
`S.Q1`, `TM-04`), file paths, git refs and shas, HTTP methods, identifiers, or
code.

Close with **Premissas** and **Limites**, both mandatory and never empty: what
was assumed about the change, what was not read and why, how many changed files
were actually opened, which half ran, and that no finding is not proof of no
vulnerability.
