# I — Information Disclosure

**ID:** `I` · **Property violated:** Confidentiality · **Applies to:** process, flow, store

## What this category is

Data reaches someone who should not see it. The disclosure rarely looks like a
breach at the moment it happens — it looks like a helpful error message, a field
nobody trimmed from a response, a log line written for debugging that stayed.

## How it shows up in a backend

- A persistence object returned straight from a handler, so every column added
  later is published the day it is added — password hashes, internal flags,
  another party's identifiers.
- A record fetched by the identifier the caller supplied and returned without the
  query ever being scoped to the caller, so the identifier is the authorization.
- An error handler that returns the exception, the stack trace, the query, or
  the driver's message, describing the schema to whoever triggers it.
- Debug endpoints, metrics, API documentation, or a health check that enumerates
  dependency versions and hostnames, reachable without authentication.
- Secrets and personal data in logs, traces, and crash reports, which are copied
  to more places and kept longer than the database ever is.
- A store holding sensitive data with no encryption at rest, on the assumption
  that reaching it requires reaching the app.
- Sequential identifiers, so enumerating the dataset needs a loop and no
  vulnerability at all.
- Differences an attacker can measure — a slower response for a real account, a
  distinct message for a wrong password — that answer questions nobody exposed.

## Which elements it applies to

| Element | Applies | Why |
|---|---|---|
| Actor | no | the actor is who receives; disclosure happens elsewhere |
| Process | yes | it decides what leaves and what an error says |
| Flow | yes | data in transit, and flows carrying more than is needed |
| Store | yes | data at rest, and who can read it |

## Threat questions

- **I.Q1** — What sensitive data does this store hold, who can read it, and is it
  protected at rest to the degree that data warrants?
- **I.Q2** — Does this flow carry more than its destination needs — whole objects
  where an id would do, whole tables where a page would do?
- **I.Q3** — Can an error, a stack trace, a debug endpoint, or a response header
  reveal internals to an untrusted actor?
- **I.Q4** — Can an actor read a record belonging to another actor by supplying
  its identifier, because the lookup was never scoped to the caller?
- **I.Q5** — Do logs, metrics, traces, or crash reports carry secrets, tokens, or
  personal data?
- **I.Q6** — Is anything sensitive inferable without reading it — enumerable
  identifiers, response timing, response size, distinguishable error messages?

## Mitigation patterns

- An explicit response shape per endpoint. Sensitive fields are opt-in, so the
  next column added to the model is invisible until someone decides otherwise.
- Scope the lookup by the caller in the query predicate itself, so a record that
  is not theirs is not found rather than found and then refused.
- One error shape for the caller — generic, stable, no internals. Detail goes to
  the log, correlated by an id the caller may quote.
- Debug surfaces, docs and metrics are off in production or behind the same
  authentication as everything else. Reachable-but-obscure is reachable.
- Encrypt at rest what would matter if the storage layer alone were obtained,
  and keep the key somewhere the storage layer's compromise does not reach.
- Opaque, unguessable identifiers on anything an outsider can request.
- Uniform responses and comparable timing where the difference itself is the
  disclosure.

## Grep signals

```bash
rg -ni 'return (user|entity|model|record)|res\.json\((user|row|entity)'
rg -ni 'select \*|findAll\(|\.all\(\)|SELECT \* FROM'
rg -ni 'stack|stacktrace|getMessage\(\)|err\.message|exception\.__str__'
rg -ni 'swagger|openapi|graphiql|/debug|/actuator|/metrics|/health'
rg -ni 'password|secret|token|api_?key|ssn|cpf|credit_?card' -g '!*.lock'
rg -ni 'encrypt|kms|at_?rest|pgcrypto|cipher'
rg -n 'autoincrement|AUTO_INCREMENT|SERIAL|@GeneratedValue'
```
