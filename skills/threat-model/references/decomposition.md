# System decomposition

A threat model is worth exactly what its decomposition is worth. A trust
boundary nobody found is a boundary nobody threat-modeled — and in the finished
document it looks identical to one that was found and cleared.

Five element types, five fixed line shapes. Produce all five lists before
enumerating a single threat.

```
ACTOR    | name | authenticated by | trust level
PROCESS  | name | file:line (entry point) | runs as | zone
STORE    | name | technology | where it lives | what it holds
FLOW     | source -> sink | protocol | crosses a boundary? | carries
BOUNDARY | name | what changes when you cross it
```

## What each element is

- **Actor** — anything outside the system that starts a flow. An anonymous
  visitor, an authenticated user, an admin, a partner service, a scheduler, a
  webhook sender. Two actors that differ in what they may reach are two actors,
  even when the same person is behind both.
- **Process** — code that runs and decides. A route handler, a queue consumer, a
  cron job, a websocket gateway, a CLI entry point, a middleware that can reject
  a request. Group by deployable unit, not by file.
- **Store** — anything holding state between requests: a database, a cache, a
  bucket, a queue, a log sink, the filesystem, a config or secret store. Record
  what it holds, because that is what an attacker is after.
- **Flow** — data moving between two elements. Record the protocol and whether
  it crosses a boundary; a flow that stays inside one zone carries far less risk
  than the same bytes crossing out of it.
- **Boundary** — the line where the trust level changes. Not the network
  diagram: two services on the same host are separated by a boundary if one
  authenticates the other.

## Where the boundaries actually are

Most decompositions find the first one and stop. Look for all of these:

| Boundary | What changes when you cross it |
|---|---|
| internet → app | input stops being trusted; the caller is unknown until proven |
| anonymous → authenticated | an identity exists and can be attributed |
| tenant → tenant | the same code serves data that must never mix |
| user → admin | the same session reaches a wider set of operations |
| app → datastore | credentials are presented; the store trusts whatever asks |
| app → third party | data leaves; an outage or a lie arrives back |
| sync → async | the request identity has to be carried, or it is lost |
| build → runtime | code and config chosen at one time run at another |

The last two are the ones that get missed. A job pushed onto a queue and picked
up by a worker crosses a boundary: whatever the worker knows about who asked for
the work, it knows because someone serialized it, not because it was proven.

## STRIDE per element

Which categories apply to which element type. A dash is not a threat somebody
forgot to write down — it is a threat that cannot exist on that element.

| Element | S | T | R | I | D | E |
|---|---|---|---|---|---|---|
| Actor | ✔ | — | ✔ | — | — | — |
| Process | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| Flow | — | ✔ | — | ✔ | ✔ | — |
| Store | — | ✔ | ✔ | ✔ | ✔ | — |

This table decides the fan-out: an agent that owns only stores and flows is
never asked about spoofing or elevation, and its prompt does not carry those
files. Processes carry all six, which is why a boundary with many processes is
worth splitting across agents.

## Finding the elements

Run the recipe for the detected stack, then the **Cross-check** at the bottom
regardless of stack. Stack detection here serves discovery only — nothing in
this skill's threat material is framework-specific.

### NestJS

```bash
# processes — every entry point, HTTP and not
rg -n '@(Get|Post|Put|Patch|Delete|Head|Options|All)\(' --type ts
rg -n '@(Controller|MessagePattern|EventPattern|SubscribeMessage|Cron|Interval)\(' --type ts
# boundary controls — what stands between an actor and a process
rg -n '@(UseGuards|Public|Roles|CheckAbilities|Throttle|SkipThrottle)\(' --type ts
# stores
rg -n 'TypeOrmModule|MongooseModule|PrismaService|createClient|new Redis|S3Client|BullModule' --type ts
# outbound flows
rg -n 'HttpService|axios|fetch\(|got\(|new URL\(' --type ts
```

### Laravel

```bash
# processes
rg -n 'Route::(get|post|put|patch|delete|any|match|resource|apiResource)' routes/
rg -n 'class \w+ implements ShouldQueue|protected \$signature|->command\(' app/ routes/
# boundary controls
rg -n '->middleware\(|Route::middleware\(|Gate::|->authorize\(' routes/ app/
# stores and outbound flows
rg -n "config\('database|Storage::|Cache::|Queue::|Redis::"
rg -n 'Http::(get|post|put|patch|delete)|new Client\('
```

### Spring Boot

```bash
# processes
rg -n '@(RequestMapping|GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping)\('
rg -n '@(Scheduled|KafkaListener|RabbitListener|JmsListener|MessageMapping)\('
# boundary controls
rg -n '@(PreAuthorize|PostAuthorize|Secured|RolesAllowed|PermitAll)\(|SecurityFilterChain'
# stores and outbound flows
rg -n 'spring\.datasource|@Entity|RedisTemplate|S3Client|MongoRepository'
rg -n 'RestTemplate|WebClient|FeignClient'
```

### Stack-agnostic fallback

No stack detected is a normal run, not a degraded one.

```bash
# 1. deployment topology names the processes and stores faster than code does
rg --files -g '{docker-compose,compose}.{yml,yaml}' -g 'Dockerfile*' -g '*.tf' -g '{k8s,deploy}/**'
# 2. what the app connects to — the store list, nearly complete
rg -n '(?i)(DATABASE_URL|REDIS|AMQP|KAFKA|MONGO|_BUCKET|S3_|QUEUE_)' -g '*.env*' -g '*.yml' -g '*.yaml'
# 3. entry points
rg -n '\b(app|router|fastify|server)\.(get|post|put|patch|delete|all)\s*\('
rg -n 'path\(|re_path\(' --glob '**/urls.py'
rg -n '\.(HandleFunc|Handle|GET|POST|PUT|PATCH|DELETE)\('
# 4. outbound flows — every one is a boundary crossing
rg -n '(?i)(https?://|fetch\(|axios|requests\.(get|post)|http\.Client)'
```

A `docker-compose.yml` is usually the best decomposition document a project has,
and nobody wrote it for that. Read it first when it exists.

## Cross-check

Whatever produced the lists, before drawing anything:

1. **Count.** Every process appears in at least one flow, and every flow names
   two elements that exist in the lists. A process with no flow was invented; a
   flow to an element that is not listed means the list is short.
2. **Trace.** Pick the two most sensitive things the system holds and follow
   each from the actor that creates it to the store that keeps it. Every
   boundary that trace crosses must already be in the boundary list.
3. **Declare.** Anything that cannot be decomposed statically — a service whose
   code is not in this repository, an upstream gateway, infrastructure
   configured outside the repo, a dynamically registered handler — is written
   down now and reproduced under **Limits**. An area nobody could see must never
   read as an area with nothing wrong in it.
