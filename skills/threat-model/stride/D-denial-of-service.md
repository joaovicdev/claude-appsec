# D — Denial of Service

**ID:** `D` · **Property violated:** Availability · **Applies to:** process, flow, store

## What this category is

The system stops serving the people it is for. Threat-model it as resource
exhaustion rather than as flood volume: the interesting failures are the ones
where one ordinary-looking request consumes far more than one request's worth of
something finite, and the attacker needs no bandwidth at all.

## How it shows up in a backend

- An endpoint with no limit per actor and per unit of time, so cost scales with
  whoever is willing to call it most.
- One request causing unbounded work — a query with no pagination, an upload with
  no size cap, a filter that fans out to every row, a regex whose runtime is
  quadratic in an input the caller chooses, recursion the payload controls.
- A shared finite resource one actor can hold: the connection pool, disk, the
  queue, a lock, the memory of a single process.
- A dependency with no timeout, so its slowness becomes the process's slowness,
  and then its outage becomes the process's outage.
- Retries with no ceiling and no backoff, so recovery is the thing that keeps the
  system down.
- The expensive path reachable before authentication, so there is no cost to
  the attacker and no identity to rate-limit against.
- An action that costs money per call — SMS, email, a paid API, generated
  documents, compute — with nothing capping it. The system stays up; the budget
  does not.
- A limit configured but never enforced: commented out, applied to a route that
  was renamed, or set so high it can never fire.

## Which elements it applies to

| Element | Applies | Why |
|---|---|---|
| Actor | no | the actor is the source, not the thing exhausted |
| Process | yes | it is the thing that stops responding |
| Flow | yes | a flow can be saturated, or made to carry unbounded volume |
| Store | yes | connections, disk, and locks are finite and shared |

## Threat questions

- **D.Q1** — Does this entry point enforce a limit per actor and per unit of
  time, and is that limit actually reachable in the code path serving it?
- **D.Q2** — Can one request cause unbounded work — no pagination, no size cap,
  caller-controlled fan-out, recursion, or a regex over caller input?
- **D.Q3** — Is there a shared finite resource one actor can exhaust for
  everyone: connections, disk, queue depth, memory, a lock?
- **D.Q4** — Does a dependency that hangs or fails take this process with it, or
  are there timeouts, bounded retries, and a way to shed load?
- **D.Q5** — Can an unauthenticated actor reach the expensive path?
- **D.Q6** — Does anything here cost money per invocation, and what caps the
  spend rather than the request rate?

## Mitigation patterns

- A default limit at the boundary that every entry point inherits, and
  exceptions granted per route rather than protection added per route.
- Every collection response is paginated with a maximum the caller cannot
  raise. Every upload and every body has a size ceiling enforced before parsing.
- Timeouts on every outbound call, bounded retries with backoff and jitter, and
  a breaker that stops calling a dependency that is already failing.
- Bound the pools and queues explicitly, and decide what happens when they are
  full — rejecting quickly is a design, filling until death is not.
- Move expensive work behind authentication so there is an identity to attribute
  and throttle.
- Cap spend, not just rate, on anything that costs money, and alert on the cap
  rather than discovering it in an invoice.
- Test the limit. A quota with no test asserting it fires is a quota that will
  be removed by a refactor nobody notices.

## Grep signals

```bash
rg -ni 'throttle|rate_?limit|ratelimit|bucket|quota|limiter'
rg -ni 'take|limit|offset|paginate|per_?page|pageSize|maxResults'
rg -ni 'timeout|deadline|AbortController|context\.WithTimeout|setTimeout'
rg -ni 'retry|retries|backoff|circuit|breaker|resilience'
rg -ni 'pool|maxConnections|max_?size|maxPoolSize|concurrency'
rg -ni 'multer|upload|maxFileSize|client_max_body_size|MAX_CONTENT_LENGTH'
rg -ni 'sendMail|sendSms|invoice|charge|openai|anthropic|generate'
rg -n '^\s*(//|#)\s*.*(throttle|rate_?limit|quota)'
```
