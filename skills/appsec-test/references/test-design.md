# Test design

Writing the test is where this skill stops reading and starts producing
something the repository keeps. A report is overwritten on the next run; this
file is committed, so a test that cannot fail ships as evidence forever.

This file names runners, packages and language APIs, which nothing else in the
repository does. The departure is deliberate, written down in `CONTRIBUTING.md`,
and confined here: a skill that writes a test cannot write one without knowing
the runner, and keeping that knowledge in the consumer is what leaves
`RULES_ROOT/stacks/` naming the obligation, never the runner, inside its
4–8-lines-per-item budget. Nothing in this file is added there. The core names
the obligation and the consumer names the runner; collapse the two and the rules
stop being portable to the stack nobody has written yet.

Harness discovery produces exactly this, and the rest runs on nothing else:

```
<runner> | <how the app boots> | <how data is seeded> | <where tests live>
baseline: <n> passed, <n> failed, <n> skipped — <the command that produced it>
```

## Harness discovery

The stack was detected in Step 1 — `nest-cli.json`, `artisan`, `pom.xml`. This
selects the recipe. Detection is by file and by the project's own scripts, never
by asking the developer what they use.

### NestJS

```bash
# the runner, and whether the e2e suite is separate from the unit one
rg -n '"test(:e2e)?"\s*:' package.json
# the e2e config, and the two packages a route-level test needs
rg -n 'testRegex' test/jest-e2e.json; rg -n 'supertest|@nestjs/testing' package.json
```

`jest` + `supertest`, tests in `test/*.e2e-spec.ts`, run by `npm run test:e2e`.
The app boots through `Test.createTestingModule`, and the boot is what goes
wrong:

```ts
const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
app = moduleRef.createNestApplication();
app.useGlobalPipes(new ValidationPipe({ whitelist: true }));  // mirror main.ts
await app.init();       // then drive request(app.getHttpServer())
```

Mirror what `main.ts` registers — pipes, global guards, the exception filter. A
module that omits them is a different application from the deployed one.

### Laravel

```bash
# which runner — Pest and PHPUnit share a bootstrap, so look for both
ls tests/Pest.php phpunit.xml phpunit.xml.dist
# the database trait the existing tests use, and the factories that seed principals
rg -n 'RefreshDatabase|DatabaseTransactions' tests/; rg --files database/factories
```

Pest or PHPUnit, tests in `tests/Feature/`, run by `php artisan test --filter`
or `./vendor/bin/pest`. `RefreshDatabase` plus `actingAs` is the whole harness:

```php
uses(RefreshDatabase::class);
$tenantA = User::factory()->create();
$order   = Order::factory()->for($tenantA)->create();
$this->actingAs($tenantB)->getJson("/api/orders/{$order->id}")->assertNotFound();
```

`tests/Feature/`, never `tests/Unit/`. A unit test calls the class; the
middleware, the policy and the FormRequest are what the finding is about.

### Spring Boot

```bash
# the runner arrives in one starter — its absence is the full stop below
rg -n 'spring-boot-starter-test|junit-jupiter' pom.xml build.gradle
# how the existing tests reach a route, and the principal they already mint
rg -n '@SpringBootTest|@WebMvcTest|@WithMockUser|@WithUserDetails' -g 'src/test/**'
```

JUnit 5 with `@SpringBootTest` and `MockMvc` (`WebTestClient` on WebFlux), tests
in `src/test/java/`, run by `./mvnw test -Dtest=OrderSecurityTest`:

```java
@SpringBootTest @AutoConfigureMockMvc
class OrderSecurityTest {
  @Autowired MockMvc mvc;
  // mvc.perform(get("/orders/{id}", ORDER_A)).andExpect(status().isNotFound());
}
```

`@WebMvcTest` alone stands up the controller without the `SecurityFilterChain`,
so that slice asserts against an application that has no access control — and
`SPR.1` is the reminder that the annotation may be inert anyway.

### No runner detected

**Stop.** Name the files looked for and not found, name the one thing the
project would install for its stack — `jest` and `supertest`, `pestphp/pest`,
`spring-boot-starter-test` — say the finding stands unproven, write nothing.

Installing a runner adds a dependency, a lockfile entry and a CI job the project
never chose: a supply-chain decision (`A03.Q1`) taken as a side effect of a
security question. A framework scaffolded by an agent is a build someone else
has to own on Monday.

## The baseline

Run the suite once, whole, before a line is written, and record the counts:

```bash
# the whole suite, before anything is written — keep the counts, not the log
npm test                # NestJS · plus npm run test:e2e when e2e is separate
php artisan test        # Laravel · Pest and PHPUnit both run through it
./mvnw -q test          # Spring Boot · or ./gradlew test
```

**The baseline** is that line: how many passed, how many failed, which names
failed, and the exact command. A suite already red is reported up front, because
it changes what the fix can promise — with three unrelated failures on the board
*"the suite is unchanged"* is the only claim available, and *"the suite is
green"* is not. A suite that cannot run at all — a missing service, an unseeded
database, no environment file — is the full stop above: say which command failed
and what it printed, and write nothing.

Without the baseline the two verification runs in `references/fix-protocol.md`
compare against nothing, and a failure the fix caused is indistinguishable from
one that was already there this morning.

## Rules for the test itself

- **Two assertions, always.** The attack assertion states the property the
  finding says is broken; the positive control states that the legitimate caller
  still succeeds down the same path, in the same `describe`. A test carrying
  only the attack assertion cannot tell RED from BROKEN.
- **Assert the security property, not the implementation.** *"Tenant B cannot
  read tenant A's order"*, never *"the `where` clause contains `tenantId`"*.

```ts
// wrong                                      // right
expect(sql).toContain('tenantId = ?')         expect(res.status).toBe(404)
expect(repo.findOne).toHaveBeenCalledWith(a)  expect(res.body.customer).toBeUndefined()
```

  The left column asserts today's query builder; the right asserts what the
  attacker does not get. The fix has to be free to move the scope from the
  service into the repository without the test noticing — a test that fails on
  the refactor that fixes it gets deleted, and the vulnerability returns unseen.

- **Drive the highest boundary that still runs in CI.** Access control is route,
  guard and query composed: a unit test on the service passes happily while the
  route is wide open, because the guard it never loaded is the missing piece.
- **One file per module, not per finding.** `test/orders.security.spec.ts` grows
  one `describe` per finding, named by its ref. Ninety findings must not become
  ninety files — nobody runs a directory they cannot read.
- **Match the project's own conventions.** Placement, naming, fixture style, and
  the language the existing tests are written in. The `language` argument
  governs the terminal output; the committed test follows the repository. A
  `security/` directory invented in a project that has none is a test the next
  developer deletes without reading it.

Breaking any of these still produces red, which is what makes them easy to skip:
red for the wrong reason reads exactly like red for the right one.

## The header block

The test outlives this run, and whoever next sees it fail will not have the
transcript. The block above the `describe` says they are looking at a regression
rather than a stale test, and it carries the resolved item's own taxonomy — the
OWASP ref or the STRIDE ref, never both.

```ts
/**
 * Security regression — A01.Q2
 * src/orders/orders.controller.ts:14 — order looked up by id alone.
 * Proven red 2026-09-10; fixed in the same change.
 * Do not weaken these assertions. Red again means the vulnerability is back.
 */
```

```php
/**
 * Security regression — E.Q3
 * app/Http/Controllers/OrderController.php:62 — order looked up by id alone.
 * Proven red 2026-09-10; fixed in the same change.
 * Do not weaken these assertions. Red again means the vulnerability is back.
 */
```

```java
/**
 * Security regression — A07.Q4
 * src/main/java/com/example/auth/JwtVerifier.java:41 — alg read from the token.
 * Proven red 2026-09-10; fixed in the same change.
 * Do not weaken these assertions. Red again means the vulnerability is back.
 */
```

Four lines, fixed: the ref, the location, the date the run went RED and what
happened next, and the instruction. When the gate was answered no, line three
reads `Proven red <date>; unfixed` and names where that was recorded. A security
test with no header is the one weakened at 2 a.m. to unblock a deploy.

## Test shapes by category

One skeleton per family that carries an assertion. The id in a heading is the
one the resolved item cites: a finding cites the `A` id, a threat cites its
twin, and no test carries the pair.

### Access control — `A01.Q2`, `E.Q3`

Two principals, one resource, cross-access — the strongest shape here, and
almost always available.

```ts
describe('GET /orders/:id — tenant scope', () => {
  const get = (id: string, token: string) => request(app.getHttpServer())
    .get(`/orders/${id}`).set('Authorization', `Bearer ${token}`);

  it('serves the order to its own tenant', () =>                // positive control
    get(orderOfTenantA, tokenTenantA).expect(200));

  it('refuses the same order to another tenant', async () => {  // attack assertion
    const res = await get(orderOfTenantA, tokenTenantB);
    expect(res.status).toBe(404);
    expect(res.body.customer).toBeUndefined();
  });
});
```

Expect the status the project already returns for a missing object: a `403`
where a stranger gets `404` confirms the id exists, which is `A01.Q7` and a
second finding, not a fix. The mass-assignment variant (`A01.Q5`, `E.Q4`) is the
same skeleton with `role` in the body, asserting on the persisted value.

### Injection — `A05.Q1`, `T.Q5`

Assert by effect. The payload changes query semantics or it does not, and the
rows are what say so.

```php
it('returns only the orders the caller owns', function () {        // positive control
    $this->actingAs($tenantA)->getJson('/api/orders?q=widget')
        ->assertOk()->assertJsonCount(1, 'data');
});

it('treats an injection payload as a literal term', function () {  // attack assertion
    $this->actingAs($tenantA)->getJson('/api/orders?q=' . urlencode("' OR '1'='1"))
        ->assertOk()->assertJsonCount(0, 'data');
    expect(Order::count())->toBe(3);              // by effect: nothing was dropped
});
```

Never string-match the generated SQL: a driver that escapes differently turns
the test red with the bug fixed, and an ORM that moves to prepared statements
turns it green with the concatenation still there. The sort variant (`A05.Q2`)
sends an out-of-allowlist column and asserts a rejection, not a `500`; command
injection (`A05.Q6`) asserts a marker file that must not exist, never anything
destructive.

### Authentication — `A07.Q4`, `S.Q2`

One `describe`, the genuine token as the positive control, one case per forgery:
`alg: none`, wrong key, wrong issuer, wrong audience, expired, another user's.
Each asserts `401`. Session invalidation (`A07.Q6`) captures a token, changes
the password, replays it. Rate limiting (`A07.Q1`) takes the `D.Q1` shape below.
Never assert on timing: the response half of such a finding is provable, the
timing half is not.

### Logging — `A09.Q1`, `I.Q5`

Capture the sink, not stdout: an in-memory transport, a test appender, a spy on
the logger the project injects. Drive a request carrying a password, search the
captured records for that literal value, assert none holds it. The positive
control is that the request was logged at all — which separates a scrubbing
logger from a logger never wired up in tests. The newline variant (`A09.Q5`)
sends a field containing `\n` and asserts no extra record appeared.

### Error handling — `A10.Q3`, `I.Q3`

Force an error the handler does not expect — a malformed id, a duplicate key —
and assert the body carries no stack frame, no SQL fragment, no driver string
and no filesystem path. The positive control is the same route answering
normally for a valid request. The fail-closed variant (`A10.Q1`) stubs the
authorization dependency to throw and asserts the request is denied, not served.

### Misconfiguration — `A02.Q6`, `A02.Q3`

Assert on a real response: framing, nosniff and referrer headers on any route; a
preflight carrying `Origin: https://evil.test` answered without reflecting that
origin and without credentials beside a wildcard. Docs and management endpoints
(`A02.Q5`) are an unauthenticated `GET` asserting a refusal. When the header
comes from a proxy rather than from the app, the suite is measuring the wrong
boundary: report BROKEN and name the hop that sets it.

### Denial of service — `D.Q1`

Drive N+1 requests and assert the last is refused with the limiter's own status;
the first succeeding is the positive control. Reset the limiter store between
tests, or the next test inherits a spent quota and the suite becomes
order-dependent. The bounded-work variant (`D.Q2`) asks for an oversized page
and asserts the cap held. Never assert on elapsed time — a flaky security test
is deleted within a month, and the regression leaves with it.

A family with no skeleton here has no assertion at a boundary this project can
drive. `references/finding-resolution.md` names them, and `A03.Q2` is the
clearest case: a lockfile pin with an exact line and nothing at runtime to see.

## Cross-check

Before the test is run:

1. **Count.** Every `describe` this run added carries both the attack assertion
   and the positive control. One without the other is a claim with a test's file
   extension.
2. **Sample.** Open the nearest existing test and compare imports, fixtures,
   naming and language. A test that reads as foreign is deleted at the next
   review, and the regression it guarded goes with it.
3. **Declare.** Whatever the harness could not drive — a stub the project does
   not have, a second principal the factories do not produce — is named now and
   reaches the run's **Limites** verbatim. A boundary that was never driven must
   never read as one that held.
