# Discovery probes

The bounded probe list. This file is what keeps the command cheap: a fixed set of
greps per section, the files they hit, and nothing else.

**The budget, and it is a ceiling rather than a target:** at most ~6 `rg`
invocations per section, **stop at the first probe that answers the section**, and
open at most ~15 files in the whole run. Never start a second round of questions
because the first round was interesting. A section the probes cannot answer is an
entry in `## Not claimed` — that is a finished outcome, not a failure.

Each section below carries the signals for the three detected stacks and a
stack-agnostic fallback. Run the block for the detected stack; run the fallback
when nothing was detected.

## Module map

```bash
rg -l '@Controller\(' src/                      # NestJS — take the DIRECTORIES, not the routes
rg -l 'extends Controller|Route::' app/ routes/ # Laravel
rg -l '@RestController|@RequestMapping' src/    # Spring Boot
rg -l --type-add 'h:*.{go,py,rb,ts,js,java,php,cs}' -t h 'router|route|handler|controller'
```

**Record the grouping, not the routes.** Route enumeration belongs to the audit
command and is not repeated here. What this section holds is the list of module
names and the directory each lives in — the grouping a later run partitions its
fan-out by, so two runs partition the same way.

## Trust boundaries

Derived, not grepped: build the table from `## Module map`, `## External systems`
and the entry points. One row per boundary, naming what changes when a request
crosses it and which elements sit on the inner side. These names are what a threat
model reuses verbatim, which is where run-to-run consistency actually comes from.

## Authentication

```bash
rg -n 'passport|JwtStrategy|jwt\.(sign|verify)|bcrypt|argon2|session\(' src/
rg -n 'req\.user|@CurrentUser|getAuthenticated'                        src/
rg -n 'Auth::|Sanctum|attempt\(|Hash::make'                            app/ config/
rg -n 'UserDetailsService|AuthenticationManager|PasswordEncoder'       src/
```

Open the strategy or provider, and the login handler. Record: what issues the
identity, what validates it on each request, and **where the request identity
lands** — that last one is the fact later runs spend the most context re-deriving.

## Authorization

```bash
rg -n 'APP_GUARD|CanActivate|@UseGuards|@Roles\(|casl|ability'  src/
rg -n 'Gate::|Policy|authorize\(|can:|middleware\(.auth'        app/ routes/
rg -n '@PreAuthorize|SecurityFilterChain|hasRole|permitAll'     src/
rg -n 'authoriz|permission|can_|is_admin|require_role'
```

Open the global registration **and** the class it registers. A guard that exists as
a class and is never registered is not a control — record that in `## Not claimed`,
because *declared is not applied* is the single most common false claim a run could
make here.

## Tenancy and data scoping

```bash
rg -n '\$use\(|\$extends|addGlobalScope|BaseRepository|TenantRepository' src/ app/
rg -n 'tenant_?[Ii]d|org_?[Ii]d|company_?[Ii]d|account_?[Ii]d'
```

Then the bypasses, and **this probe is the one that may not be skipped**:

```bash
rg -n '\$queryRaw|\$executeRaw|createQueryBuilder|\.query\(|DB::raw|createNativeQuery|entityManager\.' src/ app/
```

Every hit is opened. The bypass list is what becomes the `Does not apply to:`
line, and that line is the only thing standing between a suppressing claim and a
false negative. **A run that cannot complete this probe writes no suppressing
claim for this section** — it records the mechanism in `## Not claimed` and says
why.

## Public by design

```bash
rg -n '@Public\(\)|@SkipAuth|@AllowAnonymous'          src/
rg -n 'withoutMiddleware|->middleware\(\[\]\)|guest'   app/ routes/
rg -n 'permitAll\(\)|antMatchers|requestMatchers'      src/
```

A row needs the **declaration**, not the absence of a guard. An unguarded route
with nothing declaring it public goes to `## Not claimed` as a finding for the
audit to make. See rule 3 of `profile-format.md`.

## Input validation

```bash
rg -n 'ValidationPipe|whitelist|forbidNonWhitelisted|class-validator|zod|joi' src/
rg -n 'FormRequest|->validate\(|Validator::make'                              app/
rg -n '@Valid\b|@Validated|ConstraintValidator'                               src/
```

Open the bootstrap. The mechanism matters less than **the flags it was configured
with** — whether unknown fields are stripped, rejected, or silently bound is the
fact a later run needs and cannot guess.

## Errors and logging

```bash
rg -n 'ExceptionFilter|@Catch\(|APP_FILTER|useGlobalFilters'   src/
rg -n 'Handler::render|report\(|withoutDuplicates'             app/
rg -n '@ControllerAdvice|@ExceptionHandler'                    src/
rg -n 'logger\.\w+\(.*(req|request|body|headers|token)|redact|sanitize|mask'
```

Record what reaches the caller versus what reaches the log, and what is redacted.
Again: a filter that is declared and never registered is `## Not claimed`.

## Configuration and secrets

```bash
rg -n 'process\.env\.[A-Z_]+\s*(\|\||\?\?)'                 src/    # a default behind a secret
rg -n 'ConfigModule|validationSchema|joi\.object'           src/
rg -n "env\('[A-Z_]+',\s*'"                                 config/ app/
rg -n '@Value\("\$\{[^}]*:'                                 src/
```

The fact worth recording is binary and easy to get wrong later: **does a missing
secret stop the boot, or does the app start with a default?**

## External systems

```bash
rg -n 'axios|fetch\(|httpService|HttpClient|RestTemplate|WebClient|Guzzle|Http::' src/ app/
rg -n 'new S3|Storage::|stripe|sqs|kafka|redis|amqp|mongo|elastic'
```

The list is the claim; no file needs opening. This section feeds
`## Trust boundaries` and cannot suppress anything on its own.

## Test harness

```bash
rg -n '"scripts"' -A8 package.json
rg -n '<plugin>' -A3 pom.xml ; rg -n 'test' -A3 build.gradle
rg -n 'autoload-dev|"test"' -A4 composer.json
rg --files -g '*[Tt]est*' -g '*[Ss]pec*' -g '!node_modules' -g '!vendor' | head -20
rg -n "set\(.Authorization|actingAs|withToken|@WithMockUser"
```

**Record the value the project declares, quoted — never a name this file knew in
advance.** The command that runs the suite, the directory tests live in, how the
app is booted for a test, and how an authenticated request is built: four facts
that otherwise cost a discovery pass on every run of the test command. Quoting the
project's own value is also what keeps tool names out of this repository's files.

## Not claimed

Not a probe — the destination for everything above that came back empty or
ambiguous. Each entry names **the search that failed**, so the next run does not
repeat it blindly and a reader can judge whether the gap is real:

```
- <the question> — <the greps run>, no hit. <what that means for a later run>
```

## Cross-check

- **Count.** Every section above produced either a claim or an entry in
  `## Not claimed`. No section is silently absent.
- **Sample.** For three claims, re-run the anchor's grep and confirm it lands on
  the symbol recorded.
- **Declare.** State how many files were opened against the ~15 budget. A run that
  went over did not follow the list, and the next reader needs to know the profile
  cost more than it claims to.
