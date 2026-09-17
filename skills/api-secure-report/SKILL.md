---
name: api-secure-report
description: Full security inventory of every HTTP route in a backend project — each route marked clean or carrying findings, with the exploitation path and the mitigation, written in the user's language (pt-BR by default). Use when the user runs /api-secure-report, or asks for a security report, audit or inventory of the project's APIs.
allowed-tools: Read, Glob, Grep, Bash, Write, Agent
---

# API security report

Produces one artifact: an inventory of **every** route in the project under
review, each marked clean or carrying findings, plus a findings section stating
what is wrong, how an attacker reaches it, and what fixes it.

This skill is a **consumer** of the `secure-coding` skill. It never restates
security material — it reads that skill's files and cites their stable ids
(`A01.Q2`, `NEST.3`). If a rule seems missing, the fix is to add a review
question there, not to invent one here.

Nothing in this skill modifies the project under review. It has no `Edit`. It
writes inside `appsec/` and nowhere else: the report, and the snapshot of the
previous report it moves into `appsec/history/` before writing.

## Arguments

`/api-secure-report [language] [path]` — both positional, both optional.

| Argument | Default | Meaning |
|---|---|---|
| `language` | `pt-BR` | Output language: `pt-BR`, `en`, `es`, … Anything that is not a recognized language tag is treated as `path`. |
| `path` | repository root | Restrict the scan to a subdirectory. Stated in the report header when set. |

## Step 1 — Resolve the roots, then load the rules

Everything downstream is addressed by absolute path, so establish every root
before anything else and reuse them verbatim.

1. **`RULES_ROOT`** — the `secure-coding` skill directory. It is the sibling of
   this skill: resolve `../secure-coding/` against the directory this `SKILL.md`
   was loaded from, and make it absolute. That holds in every installation —
   plugin cache, a project's `.claude/skills/`, or the user's global skills
   directory — because the two skills always ship side by side.

   If `RULES_ROOT/SKILL.md` does not exist, **stop and say so**, naming the path
   you tried. Never continue with a partial rule set: a scan missing its rules
   produces a clean-looking report, which is worse than no report.

2. **`SCAN_ROOT`** — the root of the project under review, absolute; the `path`
   argument if given, otherwise the repository root.

3. Read `RULES_ROOT/SKILL.md` and use **its** manifest and stack-detection table.
   Do not duplicate that table here.

4. Detect the stack once: `nest-cli.json` → `stacks/nestjs.md` ·
   `artisan`/`composer.json` → `stacks/laravel.md` · `pom.xml`/`build.gradle` →
   `stacks/spring-boot.md`. No match means the language-agnostic core applies
   alone — that is the design, not a degraded run.

5. If `SECURITY-NOTES.md` exists at `SCAN_ROOT`, read it. Anything listed there
   under **Accepted risks** is reported in its own section as accepted, not as a
   new finding. Anything under **Open** that is still present is reported with
   its existing id.

6. **`PROFILE`** — `SCAN_ROOT/appsec/profile.md`. If it exists, read it:
   it is this project's own architecture as the developer states it, in claims
   with an evidence anchor each. It says where the guard is, how a query is
   scoped, what is public by declaration — so the scan reports what is actually
   missing instead of what is merely not in front of the agent that looked.

   Three rules, and they are what keep a generated file from silencing real
   findings:

   - **Re-grep the anchor of every claim you are about to rely on.** A claim whose
     symbol is no longer at that line does not apply on this run; count it and say
     so under **Limites**.
   - **A claim with no `Does not apply to:` line applies to nothing**, and neither
     does one sitting under `## Stale`. Those are documentation: read them, spend
     no context re-deriving them, and still report what you find.
   - If there is no profile, say so **once** and name `/appsec-profile` — offered,
     never written silently. The scan then runs exactly as it did before the file
     existed.

7. **`REPORT`** — `SCAN_ROOT/appsec/security-report.md`, and **`LEDGER`** — the
   `appsec-ledger` comment on its last lines. If the report exists, read the
   ledger now and keep it: it carries every id this project has ever issued, what
   each one was, whether it was open or fixed, and which ones a regression test
   already pins down. Step 4 reconciles against it and Step 5 rewrites it.

   No report yet means no ledger: every finding this run is `[new]`, ids start at
   `SEC-1`, and the report says there was nothing to compare against. A report
   whose ledger comment is missing or unparseable is **not** a fresh start — fall
   back to `max(id present in the document)`, carry on from there, and say so in
   the terminal summary. Silently restarting at `SEC-1` would hand an old id to a
   new defect, and a committed test citing that id would then point at the wrong
   thing.

## Step 2 — Enumerate the routes

Follow `references/route-discovery.md` for the detected stack, or its
stack-agnostic fallback. Every recipe produces the same line shape:

```
METHOD | PATH | file:line | guard/middleware observed
```

This list is the spine of the report — the inventory section is built from it,
not from whatever the analysis happened to find. Group the lines by
module/controller; that grouping is also how the fan-out is partitioned.

If enumeration cannot cover something — routes registered dynamically, an
upstream gateway, a generated router — record it now and reproduce it verbatim
under **Limits** in the report. Never let an uncovered area read as a clean one.

## Step 3 — Fan out

Dispatch both axes together as **`security-auditor`** subagents — the agent
shipped alongside these skills, named `claude-appsec:security-auditor` under a
plugin install and `security-auditor` otherwise. It has no `Write` and no `Edit`,
so read-only is enforced by its definition rather than by asking politely in a
prompt.

If neither name resolves, the agent was not installed. Fall back to
`general-purpose`, **tell the user** that the scan is running without the
enforced-read-only agent, and put the full set of rules from the agent's
definition into every prompt by hand.

**Per-module (route-local).** One subagent per group of routes; split groups so
none exceeds ~15 routes, and cap this axis at 8 concurrent agents, running the
remainder in further batches. Each agent gets its slice of the route list and
evaluates the categories that live inside a handler:

| Category | File to read |
|---|---|
| A01:2025 | `owasp/A01-broken-access-control.md` |
| A05:2025 | `owasp/A05-injection.md` |
| A09:2025 | `owasp/A09-security-logging-and-alerting-failures.md` |
| A10:2025 | `owasp/A10-mishandling-of-exceptional-conditions.md` |
| stack | the detected `stacks/*.md`, if any |

**Global (cross-cutting).** One subagent per area that is a property of the
project rather than of a route:

| Agent | Reads | Looks at |
|---|---|---|
| config | `owasp/A02-security-misconfiguration.md` | bootstrap, CORS, security headers, TLS options, debug flags, API docs exposure, admin/actuator endpoints |
| deps | `owasp/A03-software-supply-chain-failures.md` | dependency manifests and lockfiles, Dockerfile, CI workflows, install scripts |
| auth | `owasp/A04-cryptographic-failures.md`, `owasp/A07-authentication-failures.md` | login, registration, reset, MFA, sessions, tokens, API keys, password storage, key management |
| design | `owasp/A06-insecure-design.md`, `owasp/A08-software-or-data-integrity-failures.md` | workflows, limits, quotas, money, invitations, webhook receivers, deserialization, signed payloads |

Every subagent prompt must state, explicitly:

- **`RULES_ROOT`** and **`SCAN_ROOT`**, both as the absolute paths resolved in
  Step 1. The rule files listed in the tables above are relative to `RULES_ROOT`
  — interpolate the absolute path rather than pasting the relative one.
- The slice this agent owns, and that everything outside it belongs to another
  agent.
- The output contract from `references/report-format.md`, in **English**.
- **The profile sections this agent's slice needs — never the whole file.** The
  headings are fixed English precisely so this is a mechanical lift:

  | Agent | Sections pasted |
  |---|---|
  | per-module | `## Authorization`, `## Tenancy and data scoping`, `## Input validation`, `## Public by design`, `## Not claimed` |
  | config | `## Configuration and secrets`, `## Module map` |
  | deps | none — the profile says nothing about lockfiles |
  | auth | `## Authentication`, `## Public by design` |
  | design | `## External systems`, `## Trust boundaries` |

  Say in the prompt that a claim is the developer's word and is not to be
  re-derived — that is where the token saving comes from. And state the tagging
  rule: **an agent never stays silent.** It emits the block it would have emitted
  with one extra field, `profile: P<n>`, naming the claim it relied on, and
  consolidation decides. An agent that suppressed on its own would make the count
  this report owes **Limites** impossible to produce.

The agent's own definition already carries the rest — grep-signals-first, answer
the review questions, no finding without a `file:line` it read. Restating those
in the prompt is harmless, but they are enforced whether you do or not.

## Step 4 — Consolidate

- **Deduplicate** by `(route, ref)`. A cross-cutting finding — a bare
  `ValidationPipe`, a permissive CORS — appears once in the global section, never
  repeated on every route it happens to affect.
- **Drop** any finding without a verifiable `file:line`, and any `ref` that does
  not exist in the `secure-coding` files. A fabricated id breaks the contract
  that makes findings resolvable.
- **Order** the inventory by module, then by path. Order findings by severity,
  then by module.
- **Reconcile against `LEDGER`** and assign ids, following section 3 of
  `references/report-format.md`: match by `(METHOD + route, ref)` for a route
  finding and by `(file path, ref)` for a global one; carry the id of every
  match; a ledger row nothing matched is `fixed`; a match that was `fixed` is
  `reopened` and keeps its id; anything left is a new id at the next number.
  **Ids are never renumbered and never reused** — the finding's position in this
  document says nothing about its identity, which is the whole point.
- **Cross-check** against `SECURITY-NOTES.md`: an accepted risk moves to its own
  section, an already-open finding keeps its existing id.
- **Remove, and count.** A finding tagged `profile: P<n>` against a well-formed
  claim does not enter the report — not as a finding, not as a note on the route,
  not in the severity tables. It is counted, and that count plus the claim ids is
  the line this run owes **Limites**. A tag against a claim with no
  `Does not apply to:` line, a claim under `## Stale`, or a claim whose anchor did
  not re-grep is **not** a removal: the finding stands, and `what` says why.

## Step 5 — Emit

Everything this skill writes lives under `SCAN_ROOT/appsec/` — never in this
skill's own repository. Create the directory if it is absent.

1. **Archive the previous run, do not overwrite it.** If `REPORT` exists, read
   its `**Data:**` and `**Commit:**` header and move it to
   `appsec/history/security-<that date>-<that sha>.md`. Same date and same sha as
   a file already there → append `-2`, `-3`. A report with no `**Commit:**`
   header predates this layout: name it `security-<that date>-nogit.md`.
2. **Write the new report** to `appsec/security-report.md`, ledger comment last.
3. **Print it to the terminal** as well.

The invariant is worth stating because it is what makes the directory readable:
`appsec/security-report.md` is the current run and `appsec/history/` is every run
before it. A run never copies itself into the history — it moves its predecessor
there, so no two files ever hold the same content.

Capture the sha for this run's header with
`git -C "$SCAN_ROOT" rev-parse --short HEAD`; a dirty worktree gets `<sha>-dirty`
and a directory that is not a git repository gets `nogit`. Without that field the
next run has nothing to name the snapshot with.

**This report quotes internal paths and spells out how to exploit them, and it
is committed.** That is deliberate: a history nobody shares is a history nobody
compares, and the diff between two runs is the thing this document exists to
produce. Say so once, plainly, on a first run — a repository that is public, or
one whose read access is wider than the team, should decide that knowingly rather
than discover it later. Never add an ignore rule on the user's behalf.

Use the template in `references/report-format.md`. Translate the prose and the
labels into the requested language. Never translate: ids (`A01.Q2`, `NEST.3`),
file paths, route paths, HTTP methods, identifiers, or code.

Close with the fixed **Limits** section: what was not scanned, how many routes
were actually read, and that no finding is not proof of no vulnerability.
