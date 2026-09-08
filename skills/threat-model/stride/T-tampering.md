# T — Tampering

**ID:** `T` · **Property violated:** Integrity · **Applies to:** process, flow, store

## What this category is

Data is changed by someone who should not be able to change it — in transit, at
rest, or on its way through a process that accepts more from the caller than it
should. Spoofing asks who; tampering asks what they got to rewrite once they
were let in.

## How it shows up in a backend

- A field the outcome depends on — price, quantity, role, status, owner id,
  `isAdmin` — read from the request body instead of recomputed or looked up.
- The whole request body bound into a model, so a field nobody exposed is
  writable because nobody removed it.
- A flow crossing a boundary in plaintext, or over TLS with verification turned
  off in a config nobody revisits.
- A store one process should only read from and can write to, because both
  processes share one credential with one set of permissions.
- A file path, a query fragment, a command argument, or a template built by
  concatenating something the caller sent.
- Input deserialized into whatever type the payload names, so the payload
  chooses what code runs.
- A record updated in place with no trace of the previous value or of who
  changed it, so tampering and legitimate editing look the same afterwards.

## Which elements it applies to

| Element | Applies | Why |
|---|---|---|
| Actor | no | an actor has no state inside the system to tamper with |
| Process | yes | it accepts input and decides what to persist |
| Flow | yes | in transit is where interception happens |
| Store | yes | at rest is where the change lasts |

## Threat questions

- **T.Q1** — Can this flow be read or modified in transit — plaintext, TLS
  verification disabled, or trust in the network path instead of the transport?
- **T.Q2** — Does the process accept a value the outcome depends on from the
  caller rather than recomputing it or looking it up?
- **T.Q3** — Is any request payload bound wholesale into a persisted object, so
  the writable field set is whatever the model happens to declare?
- **T.Q4** — Can an element write to a store it should only read from, or reach
  data outside its own scope, because one credential serves every access?
- **T.Q5** — Is a query, path, command, or template built by concatenating
  something that crossed a boundary?
- **T.Q6** — Can a persisted record be changed without leaving a trace of who
  changed it, when, and from what?

## Mitigation patterns

- The server is the authority on price, quantity, entitlement, state and
  ownership. Anything the client sends about those is a proposal to validate,
  never a value to store.
- Accept an explicit field allowlist and reject unknown fields, so adding a
  column never silently widens the write surface.
- Bind values, never concatenate them; allowlist identifiers that cannot be
  bound. The same rule covers paths, commands and templates.
- One credential per process, scoped to what that process actually does —
  read-only where it only reads.
- Transport authenticated and verified at both ends; verification off is a
  finding, not a configuration.
- Deserialize into a type the code names, never into a type the payload names.
- Append-only history for records whose past matters, with the actor recorded
  from the verified identity rather than from the payload.

## Grep signals

```bash
rg -ni 'req\.body|request\.body|@Body\(\)|\$request->all\(|params\.permit'
rg -ni 'save\(|update\(|create\(|assign\(|Object\.assign|spread'
rg -ni 'rejectUnauthorized|verify_?ssl|InsecureSkipVerify|CURLOPT_SSL_VERIFYPEER'
rg -n 'http://' -g '!*.md' -g '!*.lock'
rg -ni 'exec\(|spawn\(|system\(|eval\(|Runtime\.getRuntime|shell_exec'
rg -ni 'deserialize|unserialize|pickle\.loads|readObject|yaml\.load\('
rg -ni 'updated_?by|updated_?at|audit|revision|history|version'
```
