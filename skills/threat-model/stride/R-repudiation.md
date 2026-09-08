# R — Repudiation

**ID:** `R` · **Property violated:** Non-repudiation · **Applies to:** actor, process, store

## What this category is

Something happened and nobody can prove who did it. Repudiation is the only
STRIDE category whose damage lands after the incident: it does not let an
attacker in, it makes the response impossible. A breach you cannot reconstruct
is a breach you cannot scope, cannot notify accurately, and cannot close.

## How it shows up in a backend

- A state-changing operation that writes no record of who asked for it — the row
  changed, and the only evidence is that it is different from yesterday.
- The identity in the log taken from the payload rather than from the verified
  credential, so the log records what the caller claimed.
- Logs written to the container filesystem or to stdout with nothing collecting
  them, so the evidence dies with the process that produced it.
- An actor able to delete or edit the records of their own actions, because the
  audit table is a table like any other and the app credential can write to it.
- Timestamps with no timezone, or taken from the client, so ordering events
  across two services is guesswork.
- No correlation id, so a request that touched four services is four unrelated
  log lines.
- Logs so noisy that the one line that mattered is unfindable — and logs so
  detailed they contain the credentials an attacker would want next.

## Which elements it applies to

| Element | Applies | Why |
|---|---|---|
| Actor | yes | the actor is who denies having done it |
| Process | yes | the process is what fails to record the act |
| Flow | no | a flow is recorded at the elements it connects |
| Store | yes | the store holds the evidence, or loses it |

## Threat questions

- **R.Q1** — Does every operation that changes state or grants access record who
  did it, when, to what, and from where?
- **R.Q2** — Is the identity written to the record the verified one, or one the
  caller supplied?
- **R.Q3** — Can the actor who performed an action delete, edit, or overwrite the
  record of it?
- **R.Q4** — Does the record survive the process that wrote it, and for as long
  as an investigation would need it?
- **R.Q5** — Can a sequence of related events be reconstructed across processes —
  correlation id, unambiguous timestamps, source?

## Mitigation patterns

- Audit the decision, not the traffic: who, what, which resource, the outcome,
  the source. One line per state change beats a transcript nobody can search.
- The recorded actor comes from the verified identity. If the process cannot
  name a verified actor, that is itself the finding.
- Append-only, and written with a credential that cannot delete. Separate the
  audit path from the application path so one compromise does not erase both.
- Ship logs off the host as they are written; a retention period stated
  somewhere, tied to how long an investigation would plausibly need.
- One correlation id created at the boundary and carried across every hop,
  asynchronous work included.
- Log by allowlist. A record that carries tokens, request bodies, or credentials
  turns the evidence trail into a second target.

## Grep signals

```bash
rg -ni 'logger|log\.(info|warn|error)|console\.(log|error)|Log::|slf4j'
rg -ni 'audit|trail|activity_?log|event_?log|history'
rg -ni 'correlation|request_?id|trace_?id|x-request-id'
rg -ni 'new Date\(|Date\.now|time\.Now|LocalDateTime\.now|now\(\)'
rg -ni 'delete|truncate|drop table|hard_?delete' -g '*audit*' -g '*log*'
rg -ni 'JSON\.stringify\(req|print_r\(|var_dump\(|%s.*body'
```
