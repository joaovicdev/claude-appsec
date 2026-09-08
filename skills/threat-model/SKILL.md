---
name: threat-model
description: STRIDE threat model of the project under review — system decomposition, a data-flow diagram with trust boundaries, and every threat per element with its attack path, current status and mitigation, written in the user's language (pt-BR by default). Use when the user runs /threat-model, or asks for a threat model, STRIDE analysis, attack surface review, or an assessment of the project's trust boundaries.
allowed-tools: Read, Glob, Grep, Bash, Write, Agent
---

# Threat model — STRIDE

Produces one artifact: a model of the system under review — its actors,
processes, stores, flows and trust boundaries — with every threat that applies
to each element, its attack path, whether anything currently stops it, and what
would.

This skill is **self-contained**. Its threat material lives in `stride/` beside
this file and its ids (`S.Q1`, `E.Q3`) are its own. It reads no other skill and
depends on none being installed. Any other security material in the project is a
different taxonomy that happens to share a repository — never cite across.

Nothing here modifies the project under review. There is no `Edit`, and the only
file written is the model itself.

## The distinction the whole skill defends

**A threat is a hypothesis with a status. A finding is a confirmed defect.**

A threat whose mitigation is absent has no line of code to point at — that
absence *is* the threat, and it is the main product of this exercise. So this
skill does not require a `file:line` per threat. It requires something harder to
fake: an account of where the agent looked. See the evidence rule in
`references/threat-model-format.md`.

## Arguments

`/threat-model [language] [path]` — both positional, both optional.

| Argument | Default | Meaning |
|---|---|---|
| `language` | `pt-BR` | Output language: `pt-BR`, `en`, `es`, … Anything that is not a recognized language tag is treated as `path`. |
| `path` | repository root | Restrict the model to a subdirectory. Stated in the header, and in **Limits**, when set. |

## Manifest

| ID | File | Load when analysing |
|---|---|---|
| S | `stride/S-spoofing.md` | actors and processes — identity, credentials, tokens, webhook senders, internal calls, anything that answers "who is this" |
| T | `stride/T-tampering.md` | processes, flows and stores — input binding, server-authoritative values, transport, write scope, query and path construction, deserialization, audit trails of data |
| R | `stride/R-repudiation.md` | actors, processes and stores — audit records, attributed identity, log durability, correlation across hops |
| I | `stride/I-information-disclosure.md` | processes, flows and stores — response shape, caller-scoped lookups, error detail, debug surfaces, data at rest, logs, enumerable identifiers |
| D | `stride/D-denial-of-service.md` | processes, flows and stores — limits, unbounded work, shared finite resources, timeouts and retries, cost per invocation |
| E | `stride/E-elevation-of-privilege.md` | processes — where the authorization decision is made, entitlement in the lookup, caller-influenced roles, internal trust, admin surfaces, process privilege |
| — | `references/decomposition.md` | always, in Step 2 — element shapes, the boundary catalogue, the STRIDE-per-element matrix, discovery recipes |
| — | `references/threat-model-format.md` | always, in Steps 4 and 6 — the return contract, the evidence rule, risk, the output template |

Every path is relative to this skill's own directory, so the same bytes work
whether this was installed as a plugin, committed into a project's
`.claude/skills/`, or linked into the user's global skills directory.

## Step 1 — Resolve the roots

Everything downstream is addressed by absolute path. Establish both before
anything else and reuse them verbatim.

1. **`STRIDE_ROOT`** — this skill's own directory, made absolute from wherever
   this `SKILL.md` was loaded. `STRIDE_ROOT/stride/` and
   `STRIDE_ROOT/references/` are what the subagents read.

   If `STRIDE_ROOT/stride/` does not exist, **stop and say so**, naming the path
   you tried. Never continue without the material: a model built from memory
   looks exactly like one built from the files, and is worth nothing.

2. **`SCAN_ROOT`** — the root of the project under review, absolute; the `path`
   argument if given, otherwise the repository root.

3. Detect the stack — `nest-cli.json`, `artisan`/`composer.json`,
   `pom.xml`/`build.gradle`, or none. This selects a **discovery recipe** in
   `references/decomposition.md` and nothing else. No threat question in this
   skill is framework-specific, so "no stack detected" is a normal run.

4. Read these at `SCAN_ROOT` if they exist, and say which you found:
   - **`SECURITY-NOTES.md`** — anything under **Accepted risks** goes to its own
     section, not into the threat list.
   - **`SECURITY-REPORT.md`** — a code-level audit of the same project, if the
     user has run one. Threats it already confirmed get marked in Step 5.

## Step 2 — Decompose the system

Follow `references/decomposition.md`. Produce all five lists — actors,
processes, stores, flows, boundaries — before enumerating a single threat.

This decomposition is the spine of the document: the element inventory and the
STRIDE matrix are built from it, not from whatever the analysis happened to
notice. Run the **Cross-check** at the end of that file before continuing.

Every judgment call made here — what counts as one process, where a boundary
sits, what a store holds — is written down now and reproduced under
**Premissas** in the output. A wrong assumption invalidates every threat resting
on it, so it has to be visible enough to be corrected.

## Step 3 — Draw it, and show it

Emit the Mermaid data-flow diagram from the template in
`references/threat-model-format.md`: one `subgraph` per trust boundary, every
element inside the boundary it belongs to, every flow labelled with what it
carries.

Print the diagram and the element counts to the user **before** fanning out, and
continue without waiting. A wrong decomposition is cheap to correct now and
expensive to correct after eight agents have reasoned on top of it — but the
**Premissas** section catches it either way, so this does not block.

## Step 4 — Fan out

Dispatch **`threat-modeler`** subagents — the agent shipped alongside this
skill. Under a plugin install its name carries the plugin's namespace as a
prefix; the bare name resolves otherwise. It has no `Write` and no `Edit`, so
read-only is enforced by its definition rather than requested in a prompt.

If neither form resolves, the agent was not installed. Fall back to
`general-purpose`, **tell the user** the model is running without the
enforced-read-only agent, and paste the full set of rules from the agent's
definition into every prompt by hand.

**Partition by trust boundary.** One subagent per boundary, owning the elements
on its inner side. Split a boundary whose inner side exceeds ~12 elements, and
give stores and flows that belong to no single boundary — a shared database, a
log sink, an outbound integration — their own agent. Cap at 8 concurrent, run
the remainder in further batches.

**Assign categories from the matrix, not by hand.** An agent owning only stores
and flows is never asked about `S` or `E`, and its prompt does not name those
files. An agent owning processes carries all six.

Every subagent prompt states, explicitly:

- **`STRIDE_ROOT`** and **`SCAN_ROOT`**, both absolute. The `stride/` and
  `references/` paths are relative to `STRIDE_ROOT` — interpolate the absolute
  path rather than pasting the relative one.
- **The whole decomposition**, including the boundaries and elements this agent
  does *not* own. A threat that crosses a boundary is only visible to an agent
  that knows the other side is there.
- **The slice it owns**, and that everything outside it belongs to another agent.
- **Which `stride/` files to read**, from the matrix.
- The return contract from `references/threat-model-format.md`, in **English**.

## Step 5 — Consolidate

- **Deduplicate** by `(element, ref)`. A threat that is a property of the system
  rather than of one element — no rate limiting anywhere, no audit trail at all —
  is filed once against the element that would own the fix, never repeated on
  every element it touches.
- **Drop** any `ref` that does not exist in `stride/`, any `ref` the matrix says
  that element type cannot carry, and any `status: unmitigated` with no account
  of where the agent searched. A threat nobody can check is a threat nobody will
  act on.
- **Rate** each surviving threat with the impact × likelihood matrix. Order by
  risk, then by boundary.
- **Number** them `TM-01`, `TM-02`, … so the model can be discussed by number.
  Never `T-01` — `T` is Tampering.
- **Cross-check the two project files.** An accepted risk from
  `SECURITY-NOTES.md` moves to its own section. A threat that `SECURITY-REPORT.md`
  already confirmed on the same element or route gets a
  **Confirmado em código** line citing that report's **finding number** — never
  the taxonomy it uses. The two documents share a project, not a vocabulary.

## Step 6 — Emit

Print the model to the terminal **and** write it to `THREAT-MODEL.md` at
`SCAN_ROOT` — not in this skill's own repository. If that file already exists,
say so and that it is being overwritten.

**This document maps the attack surface, including the parts nobody has tried
yet.** Before finishing, check whether `THREAT-MODEL.md` is covered by the
project's `.gitignore`. If it is not, say so plainly and offer to add it — one
line, at the user's call. Do not add it silently, and do not skip the question.

Use the template in `references/threat-model-format.md`. Translate the prose and
the labels into the requested language. Never translate: ids (`S.Q1`, `TM-04`),
file paths, route paths, HTTP methods, identifiers, or code.

Close with **Premissas** and **Limites**: what was assumed, what was not
decomposed, how many elements were actually read, and that no threat is not
proof of no risk.
