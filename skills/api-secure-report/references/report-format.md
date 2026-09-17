# Report format

Three contracts: what a subagent returns, how severity is decided, and the shape
of the final document.

## 1. Subagent return contract

A subagent returns zero or more blocks and nothing else — no preamble, no
summary, no reassurance that it looked carefully. One block per finding:

```
--- FINDING
scope: route | global
method: GET                      # route scope only
route: /orders/:id               # route scope only
component: bootstrap (main.ts)   # global scope only — what the finding is about
location: src/orders/orders.controller.ts:31
ref: A01.Q2                      # an id that exists in the secure-coding files
severity: critical | high | medium | low
profile: P7 | —                  # a profile claim that explains this, if any
what: <one or two sentences — the defect, stated plainly>
exploit: <concrete steps an attacker takes, with the request that does it>
fix: <what to change, in this project's idiom, pointing at the correct pattern>
--- END
```

Rules the consolidation step enforces, so state them in the subagent prompt:

- **No `location`, no finding.** A defect the agent did not open a file to
  confirm does not go in the report.
- **`ref` must exist.** `A01.Q1`–`A01.Q11`, `A02.Q1`–`A02.Q8`, `A03.Q1`–`A03.Q7`,
  `A04.Q1`–`A04.Q8`, `A05.Q1`–`A05.Q9`, `A06.Q1`–`A06.Q9`, `A07.Q1`–`A07.Q9`,
  `A08.Q1`–`A08.Q7`, `A09.Q1`–`A09.Q7`, `A10.Q1`–`A10.Q8`, plus `NEST.1`–`NEST.17`,
  `LAR.1`–`LAR.12`, `SPR.1`–`SPR.12`. If nothing fits, the gap belongs in the
  `secure-coding` skill as a new review question — not invented here.
- **`exploit` is concrete.** "An attacker could gain unauthorized access" is not
  an exploit. "Authenticate as any user, call `GET /orders/9001` with an id
  belonging to another tenant, receive the full order including the customer's
  address" is.
- **`fix` is actionable and idiomatic.** Name the construct this stack uses —
  `where: { id, tenantId }`, a policy plus a global scope, a `Specification`
  carrying the tenant predicate — not "add proper authorization".
- **`profile` tags, it does not silence.** An agent given profile claims never
  stays silent about the absence a claim explains: it emits the block and sets
  `profile:` to that claim's id. Consolidation removes the item and counts it — the
  count is what **Limites** owes the reader, and an agent that suppressed on its
  own would make that count impossible. A claim with no `Does not apply to:` line,
  one under `## Stale`, or one whose anchor no longer re-greps is not a claim for
  this purpose: leave `profile:` empty and report the finding.
- Write in **English**. Translation happens once, at consolidation.

## 2. Severity

One line each, so that agents working on different modules land in the same
place:

| Severity | Definition |
|---|---|
| **critical** | Reachable unauthenticated, or grants privilege escalation / arbitrary code / mass data access. No preconditions worth mentioning. |
| **high** | Any authenticated caller reaches data or actions belonging to another user or tenant, or a secret is exposed. Preconditions are trivially met. |
| **medium** | Real impact behind a precondition — a specific role, a race, a particular configuration — or an information leak that enables another attack. |
| **low** | Defense in depth, hardening, or a defect whose impact is bounded and non-sensitive. |

When two severities are arguable, take the higher one and say why in `what`.
## 3. Identity, status and the ledger

A report is regenerated whole on every run: **the prose is replaced, the identity
is not.** This is the one thing here most easily got wrong — `appsec-profile`
merges because a human edits it, and a report does not merge because nothing in
it is hand-written. What crosses runs is the id, the date the item was first
seen, its status history, and its regression test.

### The id

`SEC-<n>`, issued once and **never renumbered, never reused** — the same promise
every other id in this repository makes. No zero padding: `SEC-7`, `SEC-142`,
like `P7` in the profile. Padding only ever made sense while the number carried
the ordering, and it no longer does.

The **natural key** an id is matched by:

| Finding | Key |
|---|---|
| route-scoped | `(METHOD + route path, ref)` |
| global | `(file path of `location`, ref)` — the path only, never the line |

### Reconciling a run against the ledger

In this order, and never by prose similarity — the profile's rule, for the
profile's reason:

1. Match by key.
2. Exactly one unmatched item on each side sharing a key → the same finding; the
   id carries over.
3. Several sharing a key — two `A02.Q5` findings both in `src/main.ts` is the
   normal case — → pair them by `location`, nearest line wins. Leftovers are new.
4. A ledger row nothing matched this run → `fixed`, dated today.
5. A match whose ledger status was `fixed` → `reopened`, **the same id**.
6. Anything still unmatched → a new id at the next number.

A route that was renamed reads as one `fixed` and one `new`. That is correct and
honest: nothing in the document can tell a renamed route from a deleted one plus
an added one, and guessing would put the wrong history on a finding.

### Status tokens

Four tokens, **fixed English, never translated**, appended to the finding
heading. They are deliberately literal strings for the same mechanical reason the
profile's headings are English: a consumer greps them.

```
[new]                    first run this finding appeared in
[open since <date>]      carried over unchanged
[reopened <date>]        matched again after having been fixed
[fixed <date>]           matched nothing this run
```

A `[fixed …]` finding appears **only** in `## Desde a execução anterior`, for
exactly one run, and then leaves the document. Its ledger row stays, so a reopen
gets its id back.

### The ledger

An HTML comment on the last lines of the report — self-contained, exactly like
the profile's ledger, so there is no second file to fall out of sync. Every
column is an id, a ref, a path or a date, so the block is identical whatever
language the prose was written in.

```
<!-- appsec-ledger · schema 1 · security · ids issued: SEC-1..SEC-47 · from 324304f on 2026-09-13
SEC-1  | A05.Q1 | POST /auth/login | open  | 2026-08-15 | 2026-09-13 | test/auth.security.spec.ts · 2026-09-12 · red→green
SEC-7  | A01.Q2 | GET /orders/:id  | open  | 2026-08-15 | 2026-09-13 | —
SEC-12 | A04.Q1 | src/auth/hash.ts | fixed | 2026-08-15 | 2026-09-10 | —
-->
```

`id | ref | key | status | first seen | last seen | test`

If the comment is gone, fall back to `max(id present)` and **say so in the
terminal summary** — from that point a number can be reused, and a test or a
threat pointing at `SEC-12` would resolve to the wrong defect.

### The `test` column has one writer, and it is not this skill

`/appsec-test` fills it, and fills nothing else: never an id, never `status`,
never the order. A green test is evidence, not proof the finding is gone —
whether it is still open is decided here, by re-reading the code.

## 4. Report template

Below is the `pt-BR` rendering, which is the default. For another language,
translate labels and prose and keep the structure, the ids, the paths, the
status tokens and the code exactly as they are.

```markdown
# Relatório de segurança da API — <projeto>

**Stack:** <detectada, ou "nenhuma detectada — core agnóstico">
**Escopo:** <raiz do repositório, ou o caminho passado>
**Data:** <YYYY-MM-DD> · **Commit:** `<sha>`
**Rotas varridas:** <n> · **Com achado:** <n> · **Limpas:** <n>
**Com teste de regressão:** <n> de <n> achados

## Resumo

| Severidade | Qtd |
|---|---|
| Crítica | 0 |
| Alta | 3 |
| Média | 4 |
| Baixa | 2 |

| Categoria OWASP | Achados |
|---|---|
| A01:2025 — Broken Access Control | 4 |
| A05:2025 — Injection | 2 |

## Desde a execução anterior

Anterior: <YYYY-MM-DD>, commit `<sha>` — `appsec/history/security-<YYYY-MM-DD>-<sha>.md`.

| | Qtd | Ids |
|---|---|---|
| Novos | 3 | SEC-45, SEC-46, SEC-47 |
| Reabertos | 1 | SEC-12 |
| Corrigidos | 5 | SEC-3, SEC-8, SEC-19, SEC-22, SEC-30 |
| Inalterados | 12 | — |

## Inventário de rotas

Toda rota do projeto, com achado ou sem.

| Método | Rota | Arquivo | Guard | Status |
|---|---|---|---|---|
| GET | /orders/:id | src/orders/orders.controller.ts:31 | JwtGuard | ⚠ A01.Q2, A04.Q1 |
| POST | /orders | src/orders/orders.controller.ts:45 | JwtGuard | OK |
| GET | /health | src/health/health.controller.ts:12 | @Public() | OK |

## Achados

### SEC-7 — GET /orders/:id — Alta — `A01.Q2` [open since 2026-08-15] [tested 2026-09-12]

- **Rota vulnerável:** `GET /orders/:id` (`src/orders/orders.controller.ts:31`)
- **A vulnerabilidade:** <o defeito, em uma ou duas frases>
- **Como um atacante pode explorar:** <passos concretos, com a requisição>
- **Mitigação:** <o que mudar, no idioma da stack>
- **Teste de regressão:** `test/orders.security.spec.ts` — provado vermelho em
  2026-09-12, corrigido na mesma mudança

### SEC-45 — POST /orders — Crítica — `A05.Q1` [new]

- **Rota vulnerável:** …

## Achados globais

Não pertencem a uma rota específica — mesma estrutura, com **Componente** no
lugar de **Rota vulnerável**.

### SEC-12 — Bootstrap da aplicação — Alta — `NEST.1` [open since 2026-08-15]

- **Componente:** `src/main.ts:14`
- **A vulnerabilidade:** …
- **Como um atacante pode explorar:** …
- **Mitigação:** …

## Riscos já aceitos

De `SECURITY-NOTES.md` — não são achados novos.

| ID | Ref | Risco | Revisar quando |
|---|---|---|---|
| R-1 | `A08.Q1` | … | … |

## Limites desta varredura

- <o que não foi enumerado ou lido, e por quê>
- <rotas dinâmicas, gateway externo, código gerado, diretórios fora do escopo>
- Rotas efetivamente lidas: <n> de <n>.
- Perfil de arquitetura: `appsec/profile.md`, gerado em <YYYY-MM-DD> no
  commit `<sha>` — <n> achados removidos por claims do perfil (<P7, P9>), <n>
  claims ignoradas por âncora ausente. Sem perfil: "nenhum perfil — nada foi
  removido".
- Ausência de achado não é prova de ausência de vulnerabilidade. As regras são as
  do skill `secure-coding`; um achado citando `A01.Q2` é resolvível contra
  `owasp/A01-broken-access-control.md`.

<!-- appsec-ledger · schema 1 · security · ids issued: SEC-1..SEC-47 · from <sha> on <YYYY-MM-DD>
SEC-7  | A01.Q2 | GET /orders/:id  | open | 2026-08-15 | 2026-09-13 | test/orders.security.spec.ts · 2026-09-12 · red→green
SEC-45 | A05.Q1 | POST /orders     | open | 2026-09-13 | 2026-09-13 | —
-->
```

The **Limits** section is not optional and is never empty — at minimum it states
the coverage numbers and the last line. A report that hides what it did not look
at is worse than no report.

The profile line carries the **ids**, never the items. A finding removed by a claim
appears nowhere else in this document, so this line is the only accounting that
exists: `7 achados removidos` tells the reader nothing they can act on, while
`7 removidos por P7, P9` tells them exactly which two lines to re-read. If this
line is deleted, the suppression becomes completely silent.
