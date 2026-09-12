# claude-appsec

**Code security for Claude Code.** Five skills: OWASP Top 10:2025 rules Claude
applies **while it writes your backend code**, `/api-secure-report`, which audits
every HTTP route in a project, `/app-stride-report`, which maps the system's trust
boundaries and works STRIDE across them, `/pr-appsec-review`, which asks both
questions of a single pull request, and `/appsec-test`, which turns one finding
into the failing test that proves it is real.

Markdown the agent reads, plus four commands. Three of them only read.
`/appsec-test` is the exception: it writes a test into your suite and runs it,
and it edits your code only after that test has gone red proving the finding it
is about to fix. Still not a scanner, and nothing leaves your machine.

<p align="center">
  <a href="examples/example-data-flow-diagram.png">
    <img src="examples/example-data-flow-diagram.png" width="860"
         alt="Data-flow diagram produced by /app-stride-report: trust boundaries drawn as zones — untrusted internet, the authenticated zone, the NestJS application, build/runtime, third party and the data zone — with actors, guards, controllers, services and stores as nodes, and every crossing labelled with its protocol and credential: bearer JWT and x-api-key or ?api_key= into the guards, POST /webhooks/payments carrying x-provider-signature, a WebSocket handshake authenticated by ?token=, a caller-supplied path reaching readFileSync and execSync, an outbound call with TLS verification off, request headers, body and decoded claims written to the log sink, and stack traces plus SQL returned in the HTTP response.">
  </a>
</p>
<p align="center"><sub>
  The data-flow diagram <code>/app-stride-report</code> writes into <code>STRIDE-REPORT.md</code>,
  rendered from Mermaid — one of the five skills below. From a real run;
  click to enlarge.
</sub></p>

## What you get

One plugin, five skills. The first applies itself; the other four are commands.

| Skill | What it does | How you invoke it | What it writes |
|---|---|---|---|
| `secure-coding` | OWASP Top 10:2025 rules Claude reads *before* it writes a route, guard, query, auth flow, config or dependency — then flags what it just wrote, citing the rule id | nothing to run — the trigger in your `CLAUDE.md` loads it | nothing. Inline flags, while you work |
| `api-secure-report` | Every HTTP route in the project, each marked clean or carrying findings: route → vulnerability → how an attacker reaches it → fix | `/api-secure-report [language] [path]` | `SECURITY-REPORT.md` at the project root |
| `app-stride-report` | Decomposes the system into actors, processes, stores, flows and trust boundaries, draws the data-flow diagram, works STRIDE across every element | `/app-stride-report [language] [path]` | `STRIDE-REPORT.md` at the project root |
| `pr-appsec-review` | Reviews one change in two halves: OWASP findings on the changed code, STRIDE threats on the boundaries it touches — each marked introduced, aggravated or pre-existing, with a computed verdict | `/pr-appsec-review [language] [target] [base]` | nothing. It prints, and leaves the branch untouched |
| `appsec-test` | Takes one finding and writes the test that fails because it is real — the attack assertion red, a positive control green — runs it in your own framework, and only from red offers the minimal fix | `/appsec-test [language] [finding] [--fix\|--no-fix]` | a test file in your test directory — committed, not gitignored — and, if you say so, the fix |

The two report commands take the same two optional arguments: `language`
defaults to `pt-BR`, `path` to the repository root. `/pr-appsec-review` takes a
target instead — a PR link, or a pair of branches; `/appsec-test` takes the
finding, in whatever form you have it. The first three are read-only: the two
reports overwrite their document on every run, and the PR review writes nothing
at all. `/appsec-test` is the one that writes, and what it writes first is a
test.

## Install

Pick one — both give you the same files.

### Option 1 — for you, in every project

```
/plugin marketplace add joaovicdev/claude-appsec
/plugin install claude-appsec@claude-appsec
```

The repository, the marketplace and the plugin are all called `claude-appsec`;
the skill inside it is still `secure-coding`.

Then add the trigger to your global `CLAUDE.md` (or paste
[`TRIGGER.md`](skills/secure-coding/TRIGGER.md) in by hand):

```bash
curl -sL https://raw.githubusercontent.com/joaovicdev/claude-appsec/main/skills/secure-coding/TRIGGER.md \
  >> ~/.claude/CLAUDE.md
```

### Option 2 — for one repository, shared with your team

```bash
git clone https://github.com/joaovicdev/claude-appsec
./claude-appsec/install.sh --project /path/to/your/repo
```

This copies the five skills into `.claude/skills/`, both read-only agents into
`.claude/agents/`, imports the trigger in the repo's `CLAUDE.md`, and gitignores
`SECURITY-REPORT.md` and `STRIDE-REPORT.md` — never the tests `/appsec-test`
writes, which exist to be committed. Commit the result — teammates get it on
their next pull.

> **The trigger is not optional.** *"Add an endpoint"* does not read as a
> security request, so nothing would make Claude open the skill on its own.
> `TRIGGER.md` inlines the eight baseline rules and tells Claude when to load the
> rest. Without it the material sits on disk unused — and you cannot tell.

### Verify

`./install.sh --check /path/to/your/repo` (from a clone) reports what is
installed and whether the trigger is wired. Or ask Claude, inside the project:

1. *"What security rules apply to adding a route that takes an id?"* — must say
   the lookup is scoped by the caller **in the query**; generic "validate your
   input" advice means the trigger never fired.
2. *"Load the secure-coding skill — which manifest row covers CORS?"* — must
   answer `A02`; anything else means Claude cannot find the files.

They fail separately: 1 tests the trigger, 2 the skill.

## `secure-coding` — the rules Claude writes with

No command. The trigger in your `CLAUDE.md` makes Claude open these files before
it touches a route, guard, query, auth flow, config or dependency — so the
unscoped lookup is flagged while the handler is still being written, when the fix
costs nothing, even if you never mentioned security:

```
you    add a GET /orders/:id endpoint

claude … writes the handler, then:

       A01.Q2 — orders.controller.ts:31 — the lookup is by id alone. An
       authenticated user can read any order by guessing the id. The guard
       proved who the caller is, not what they may reach.

       Scoped it in the query predicate instead of checking after the fetch:
         where: { id, tenantId: caller.tenantId }
```

Ten language-agnostic categories in `owasp/`, plus stack idiom for NestJS,
Laravel and Spring Boot. Every rule carries a stable id — `A01.Q2`, `NEST.3` —
that is never renumbered, so a finding written today still resolves in two
years. Category names and numbering follow the OWASP Top 10:2025 — see
[Attribution](#attribution).

## `/api-secure-report` — every route, audited

It enumerates rather than samples: **every** route in the project appears in the
inventory, marked clean or carrying findings, and each finding reads
*route → vulnerability → how an attacker exploits it → fix*, citing the rule id
it came from. The work fans out over read-only `security-auditor` subagents.

<p align="center">
  <img src="examples/example-security-report.png" width="700"
       alt="Header and summary of a /api-secure-report run: stack, scope and date, 27 routes scanned — 22 with findings, 5 clean — then 90 findings counted by severity (21 critical, 37 high, 23 medium, 9 low) and by OWASP category, A01 through A10 plus the NestJS stack idiom rows.">
</p>
<p align="center"><sub>
  Header and summary from a real run: 27 routes scanned, 90 findings counted by
  severity and by OWASP category.
  Full report: <a href="examples/SECURITY-REPORT.example.md">examples/SECURITY-REPORT.example.md</a>,
  run against <a href="examples/vulnerable-app/">examples/vulnerable-app/</a>.
</sub></p>

## `/app-stride-report` — the system, modelled

A different question and a different taxonomy: not *"is this line wrong"* but
*"what could go wrong here by design"*. It decomposes the project into actors,
processes, stores, flows and trust boundaries, draws the data-flow diagram at the
top of this page, and works STRIDE across every element — reporting what stops
each threat today, or where it looked and found nothing. STRIDE is Microsoft's
classification — see [Attribution](#attribution).

```
## STRIDE matrix
✔ no open threat · ⚠ partial or latent · ✘ open · — does not apply

| Element               | S | T | R | I | D | E |
|-----------------------|---|---|---|---|---|---|
| OrdersController      | ✔ | ⚠ | ✘ | ✘ | ✘ | ✘ |
| orders (PostgreSQL)   | — | ✔ | ✘ | ⚠ | ✔ | — |

### TM-01 — OrdersController — High risk — `E.Q3`

  Current state: open — looked in src/orders/, src/common/guards/ and
  app.module.ts; no query is scoped by the caller.
```

<p align="center">
  <img src="examples/example-stride-report.png" width="700"
       alt="Header and summary of an /app-stride-report run: stack, scope and date, then the element counts — 7 actors, 20 processes, 6 stores, 26 flows, 8 trust boundaries — and 138 numbered threats, 119 open and 13 partial, broken down by risk and by STRIDE category.">
</p>
<p align="center"><sub>
  The same run as the diagram at the top of this page: 138 numbered threats over
  59 elements — 119 open, 13 partial — counted by risk and by STRIDE category.
  Full example: <a href="examples/STRIDE-REPORT.example.md">examples/STRIDE-REPORT.example.md</a> —
  24 threats over 23 elements and 4 trust boundaries, run against
  <a href="examples/vulnerable-app/">examples/vulnerable-app/</a>, with every threat
  the route audit also confirmed linked to it by finding number.
</sub></p>

The threat material shares a plugin with the OWASP material and shares nothing
else: its own files, its own ids, no cross-citation in either direction. That
independence is a check in CI, not a promise — a `stride/` file that cites an
OWASP id fails the build.

## `/pr-appsec-review` — one change, both questions

The two report commands scan a repository; this one reviews a change. Give it a
pull request link, or a pair of branches — `main`, `dev`, `staging`, whatever
yours merges into — and it resolves the merge-base, maps every hunk, and asks
both questions in two halves that run side by side and never mix. A finding cites
`A01.Q2`; a threat cites `E.Q3`; **no item ever cites both.**

Every item carries an **origin**, decided by reading the same construct at the
merge-base rather than by guessing — which is what makes the verdict computable
instead of a matter of mood:

```
## Veredito
Bloqueia o merge — o achado 1 introduz leitura de pedido de outro tenant
em GET /orders/:id. 7 de 7 arquivos alterados lidos com contexto.

### 1. src/orders/orders.controller.ts:31 — Alta — `A01.Q2` — introduzido
  Onde no PR: @@ -28,6 +28,12 @@ — linha adicionada

### 5. src/main.ts:14 — Média — `NEST.1` — pré-existente
  Onde no PR: não alterado por este PR — já presente em 9c8d7e6
```

`pre-existing` is a real answer, not a softer one: a defect in code someone is
already editing is worth putting in front of them, and it still does not block
the merge on its own. The STRIDE half adds the thing a line-by-line review cannot
produce — whether the change **adds, moves, widens or narrows a trust boundary**.

It writes nothing. Not a report, not a comment, not a file in the branch. The
review is printed, and `git status` afterwards is exactly what it was before.
Either half runs alone if you installed only one body of material, and says so in
the header rather than reporting an empty section.

## `/appsec-test` — the finding, proved

The other three commands produce findings and no evidence that any of them is
real — a report lists them and cannot tell you which would actually reproduce.
This one takes a single item — a finding number from `SECURITY-REPORT.md`, a
`TM-<nn>` from the threat model, a ref like `A01.Q2`, a `file:line`, or the claim
in prose — finds your test runner, and writes the test that **fails** because the
finding is real. Only then, with the test red on screen, does it offer to fix it.
**A fix without a red test is a guess with write permission.**

Every generated test carries two assertions, and the second is what makes the
first mean anything: the attack assertion, and a positive control proving the
legitimate caller still succeeds down the same path. A test that goes red because
the route 404s, the fixture is missing, or the request gets a 401 before it ever
reaches the handler proves nothing. So there are three outcomes, not two:

```
RED      control passes, attack fails   the finding is real
GREEN    both pass                      not reproducible here
BROKEN   control fails                  the test never reached the code
```

RED is the one that opens the gate to a fix, and nothing else does — `--fix`
answers the question in advance, it does not open the gate, and there is no
`--force`:

```
you    /appsec-test 3

claude … resolves finding 3 to a ref, a location and a claim, finds jest and
       supertest, runs the suite once for a baseline, writes
       test/orders.security.spec.ts, runs it:

       RED · A01.Q2 · src/orders/orders.controller.ts:14
         ✔ controle positivo — o dono lê o próprio pedido      200
         ✘ ataque — o tenant B lê o pedido do tenant A         200, esperado 403
         O achado é real: a requisição chegou ao handler, e o handler
         respondeu errado. Baseline: 128 testes, 0 falhas.
         Corrigir agora? [s/N]
```

GREEN is the outcome nothing else in this plugin can produce: a finding that does
not reproduce, said out loud, with the test kept anyway as the regression that
says so. Every GREEN names which of its three causes applies — the finding was
wrong, the code was already fixed since the report was written, or the test never
exercised the vulnerable path — because only the first two are false positives
and the third is a bad test:

```
you    /appsec-test A01.Q2#7

claude … same harness, same two assertions, different answer:

       GREEN · A01.Q2 · src/orders/orders.controller.ts:14
         ✔ controle positivo — o dono lê o próprio pedido      200
         ✔ ataque — o tenant B lê o pedido do tenant A         403
         Não reproduzível aqui. Causa: achado errado — o escopo já está no
         predicado, em src/orders/orders.repository.ts:22. Nada é corrigido;
         o teste fica no repositório como regressão.
         Registrar em SECURITY-NOTES.md, sob ## Verified clean? [s/N]
```

The third outcome is what keeps the other two honest. When the positive control
itself fails, the request never reached the handler at all, and the attack's red
means nothing — so the run says so, and the harness gets fixed, never the code:

```
       BROKEN · A01.Q2 · src/orders/orders.controller.ts:14
         ✘ controle positivo — o dono lê o próprio pedido      404
         ✘ ataque — o tenant B lê o pedido do tenant A         404
         O teste nunca alcançou o código. Prováveis causas: rota não montada
         no módulo de teste, fixture ausente, 401 antes do handler.
         Corrigir o harness, nunca o código. Nada é corrigido.
```

The three transcripts above are illustrative, not recorded runs — and unlike the
two reports on this page, there is no example output to link to, because
`examples/vulnerable-app/` is wrong on purpose and deliberately not runnable: it
has no suite to go red. Point the command at a project of yours that has one.

The test lands where your project already keeps its tests, in the framework and
the style it already uses, one file per module rather than one per finding. And
unlike the two reports, which are gitignored and overwritten on every run, it is
committed. A report is the claim; the test is what still catches the defect after
the report has been overwritten.

## Running the commands

```bash
/api-secure-report                            # pt-BR, whole repository
/api-secure-report en                         # another language; ids, paths and code stay as-is
/api-secure-report pt-BR src/modules/orders   # scoped to a subdirectory

/app-stride-report                            # same two arguments, same defaults
/app-stride-report en
/app-stride-report pt-BR src/modules/payments

/pr-appsec-review                             # current branch vs the default base
/pr-appsec-review feature/orders staging      # any pair of branches
/pr-appsec-review pt-BR https://github.com/org/repo/pull/123

/appsec-test                                  # triage the reports, then pick one
/appsec-test 3                                # finding 3 of SECURITY-REPORT.md
/appsec-test TM-07 --no-fix                   # prove the threat, write no fix
/appsec-test 'GET /orders/:id returns another tenant order'
```

The two reports print to the terminal and write their document to the project
root, overwriting the previous one. Run them in either order — if
`SECURITY-REPORT.md` already exists, `/app-stride-report` reads it and marks the
threats that report already confirmed in code, citing it by finding number.
`/pr-appsec-review` only prints, and reads both documents if they are there: an
item either one already records is marked pre-existing, cited by its number.
`/appsec-test` reads them too, and resolves `3` or `TM-07` against them — but it
needs neither: a ref, a `file:line` or the claim in prose is enough, which is
what lets it prove an item `/pr-appsec-review` just printed and never wrote down.

## A threat is not a finding

`/api-secure-report` reports defects it opened a file to confirm, so every
finding carries a `file:line`. `/app-stride-report` reports what could go wrong,
including the mitigations that are simply absent — and an absent mitigation has
no line to point at. So instead of a location it owes you an account of where it
searched. A threat with neither is discarded at consolidation, not published.

That missing line is not what decides whether the thing can be proved, and
`/appsec-test` is where the two stop contradicting each other: testability comes
from whether the security property is observable at a boundary the project can
drive, not from whether the item carries a `file:line`. A login route with no
rate limit — `D.Q1` as a threat, `A07.Q1` as a finding — is proved by driving N
requests and asserting that none is refused, with nothing to point at but the
absence itself. An unpinned lockfile (`A03.Q2`) has an exact line and can never
be proved this way, because nothing about it is observable at runtime. A location
is what makes an item reportable; a boundary you can drive is what makes it
provable.

## Good to know

- **No network.** Plain Markdown, read locally — nothing uploaded, no telemetry.
- **One command modifies, and only from red.** Three of the four have no `Edit`:
  the only documents they write are the two reports, `/pr-appsec-review` has no
  `Write` at all, and the most either can do to your repository is a `git fetch`
  of a pull request head, which asks first. Both subagents are still read-only —
  neither `security-auditor` nor `threat-modeler` has `Write` or `Edit`, enforced
  by the agent definitions rather than requested in a prompt. `/appsec-test` is
  the exception and says so in its own first paragraph: it has `Write` and `Edit`
  — the first `Edit` in this repository — it runs your test suite, and it changes
  code under test only after the test it wrote has gone red, and only when you
  answer yes. It dispatches no subagent, because both of them are defined never
  to run project code.
- **Both documents are sensitive.** They quote internal paths and spell out how
  to attack them; the threat model maps the surface nobody has tried yet. Keep
  them out of git (`install.sh --project` does; otherwise the skills offer to).
- **A clean document is not proof.** Every run ends with a `Limits` section
  saying what was not covered — read it. The threat model adds `Premissas`,
  because a wrong assumption invalidates every threat resting on it.
- **Stacks.** `nestjs.md` is grounded in production code; `laravel.md` and
  `spring-boot.md` come from the docs and say `Status: unverified`. Any other
  stack gets the language-agnostic core alone — by design, not a degraded mode.
- **Per-project findings.** Copy
  [`templates/SECURITY-NOTES.md`](skills/secure-coding/templates/SECURITY-NOTES.md)
  to a project root; the skill reads it, and the report lists what is there as
  accepted risks instead of new findings.

## Layout

```
.claude-plugin/       plugin.json, marketplace.json — this repo is its own marketplace
skills/
  secure-coding/      SKILL.md (loader + manifest), TRIGGER.md,
                      owasp/    A01..A10, the language-agnostic core
                      stacks/   nestjs, laravel, spring-boot, _TEMPLATE
                      templates/SECURITY-NOTES.md
  api-secure-report/  SKILL.md + references/ — the reference consumer of secure-coding
  app-stride-report/  SKILL.md + references/, and stride/ (S, T, R, I, D, E)
                      its own ids, its own material — cites nothing above it
  pr-appsec-review/   SKILL.md + references/ — consumes both bodies, owns neither.
                      Two halves, two vocabularies, never in the same item
  appsec-test/        SKILL.md + references/ — the one that writes and runs code.
                      Proves a finding red before any fix is offered; the only
                      skill with Edit, and its test is committed, not gitignored
agents/               security-auditor, threat-modeler — the read-only workers the two
                      commands fan out to. tools: Read, Glob, Grep, Bash. No Write, no Edit
examples/             vulnerable-app/ (a NestJS app that is wrong on purpose), the two
                      documents a run produces against it, and this README's screenshots
install.sh            the non-plugin route: --project, --check
scripts/check-ids.sh  material integrity, run in CI
```

## Contributing

[`CONTRIBUTING.md`](CONTRIBUTING.md) has the recipe for adding a stack file
(`stacks/_TEMPLATE.md` is the blank) and the conventions the material follows.
`./scripts/check-ids.sh` enforces the ones that can be enforced mechanically.

## Attribution

**OWASP.** The category names, numbering, ordering and scope in
`skills/secure-coding/owasp/` follow the
[**OWASP Top 10:2025**](https://owasp.org/Top10/2025/) and were checked against
the official pages, which are the authority — where this repo and OWASP
disagree, OWASP is right and the disagreement is a bug worth filing. This
project is no longer named after OWASP, and that changes nothing about where the
taxonomy comes from. The prose, review questions, pseudocode and grep signals
are original work written for this repository; they are not an OWASP publication.

**STRIDE.** STRIDE is Microsoft's threat classification, published and
unencumbered. The material in `skills/app-stride-report/stride/` — the questions, the
element matrix, the mitigation patterns and the grep signals — is original work
written for this repository and is not a Microsoft publication.

**This project is not affiliated with, endorsed by, or maintained by the OWASP
Foundation or by Microsoft.** "OWASP" is the OWASP Foundation's trademark and
appears here only to identify the material the `secure-coding` skill is built from.

## License

MIT — see [`LICENSE`](LICENSE). MIT does not carry the attribution above into
forks; keeping it is a courtesy to the people who did the underlying work, not a
legal obligation.
