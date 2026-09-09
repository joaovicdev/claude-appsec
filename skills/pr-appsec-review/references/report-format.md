# Report format

Four contracts: what each subagent returns, how the two halves are rated, how the
verdict is computed, and the shape of what gets printed.

The two halves keep separate contracts on purpose. An agent on one axis is never
shown the other axis's block, its scale, or its ids.

## 1. Subagent return contracts

A subagent returns zero or more blocks and nothing else — no preamble, no
summary, no reassurance that it looked carefully.

### OWASP axis — `security-auditor`

```
--- FINDING
scope: file | global
file: src/orders/orders.controller.ts     # file scope only
component: bootstrap (main.ts)            # global scope only — what the finding is about
location: src/orders/orders.controller.ts:31
hunk: @@ -28,6 +28,12 @@                  # required unless origin is pre-existing
origin: introduced | aggravated | pre-existing
ref: A01.Q2                               # an id that exists in the secure-coding files
severity: critical | high | medium | low
what: <one or two sentences — the defect, stated plainly>
exploit: <concrete steps an attacker takes, with the request that does it>
fix: <what to change, in this project's idiom, pointing at the correct pattern>
--- END
```

### STRIDE axis — `threat-modeler`

```
--- THREAT
element: actor | process | flow | store
name: OrdersController
boundary: internet -> app
boundary_change: none | added | moved | widened | narrowed
origin: introduced | aggravated | pre-existing | mitigated-by-change
ref: E.Q2                                 # an id that exists in the stride/ files
status: unmitigated | partial | mitigated | n/a
evidence: src/orders/orders.controller.ts:31
impact: high | medium | low
likelihood: high | medium | low
threat: <what an attacker does, one or two sentences>
attack: <the concrete path — the request, the sequence, the precondition>
mitigation: <what closes it, in this project's own idiom>
--- END
```

### The origin rule — both axes

`origin` is the field that makes this a review of a change rather than a scan of
a repository, so it is not a guess:

> **Decide `origin` by looking at the base side.** Read the same construct at
> `MERGE_BASE` — from the `-` side of the hunk, or with
> `git show "${MERGE_BASE}:<path>"`, braces included (see `diff-discovery.md`).
> Present and identical there → `pre-existing`.
> Absent there → `introduced`. Present but narrower, unreachable, or less likely
> there → `aggravated`, and say in `what`/`threat` what the change widened.

An item with no `origin` is discarded at consolidation. `pre-existing` is a real
and useful answer — it is a defect in code someone is already editing — and it is
never inflated to `introduced` to make it land harder.

### The evidence rule — STRIDE axis only

A threat is a hypothesis with a status; a finding is a confirmed defect. That
difference is why `evidence` is not a file reference and nothing else:

> **`evidence` is either the `file:line` of the control that was found, or the
> paths searched and the signals run that found nothing.** "This change adds an
> endpoint with no rate limit" is a claim about a search, and the search has to
> be visible. A `status: unmitigated` with no account of where the agent looked
> is discarded — not because the threat is wrong, but because nobody can check it.

The OWASP axis has the stricter rule instead: **no `location`, no finding.**

### Everything else both contracts enforce

- **`ref` must exist.** OWASP axis: `A01.Q1`–`A01.Q11`, `A02.Q1`–`A02.Q8`,
  `A03.Q1`–`A03.Q7`, `A04.Q1`–`A04.Q8`, `A05.Q1`–`A05.Q9`, `A06.Q1`–`A06.Q9`,
  `A07.Q1`–`A07.Q9`, `A08.Q1`–`A08.Q7`, `A09.Q1`–`A09.Q7`, `A10.Q1`–`A10.Q8`,
  plus `NEST.1`–`NEST.17`, `LAR.1`–`LAR.12`, `SPR.1`–`SPR.12`. STRIDE axis:
  `S.Q1`–`S.Q6`, `T.Q1`–`T.Q6`, `R.Q1`–`R.Q5`, `I.Q1`–`I.Q6`, `D.Q1`–`D.Q6`,
  `E.Q1`–`E.Q7`. If nothing fits, the gap belongs in the source material as a new
  question — never invented in a review.
- **A block never carries an id from the other axis.** A finding citing `E.Q3`,
  or a threat citing `A01.Q2`, is discarded whole rather than corrected.
- **`ref` must be one the element can carry** (STRIDE axis). The matrix in the
  threat skill's `decomposition.md` is binding: a store cannot carry an `S.*`, a
  flow cannot carry an `E.*`.
- **The hunk is a lead, not the finding.** Judge the changed line in the context
  of the whole file and its wiring. A handler with no guard is not a finding when
  a global guard covers the module.
- **`exploit` and `attack` are concrete.** "An attacker could gain unauthorized
  access" is not one. "Authenticate as any user, call `GET /orders/9001` with an
  id belonging to another tenant, receive the full order including the customer's
  address" is.
- **`fix` and `mitigation` name the construct this stack uses** — `where: { id,
  tenantId }`, a policy plus a global scope, a `Specification` carrying the
  tenant predicate — not "add proper authorization".
- Write in **English**. Translation happens once, at consolidation, so the
  vocabulary stays consistent across agents.

## 2. The two scales

They sit side by side and are never merged. A finding has a severity; a threat
has a risk; there is no combined number, because there is no question a combined
number answers.

### Severity — OWASP half

| Severity | Definition |
|---|---|
| **critical** | Reachable unauthenticated, or grants privilege escalation / arbitrary code / mass data access. No preconditions worth mentioning. |
| **high** | Any authenticated caller reaches data or actions belonging to another user or tenant, or a secret is exposed. Preconditions are trivially met. |
| **medium** | Real impact behind a precondition — a specific role, a race, a particular configuration — or an information leak that enables another attack. |
| **low** | Defense in depth, hardening, or a defect whose impact is bounded and non-sensitive. |

When two severities are arguable, take the higher one and say why in `what`.

### Risk — STRIDE half

Impact and likelihood are judged separately, then combined. Judging them together
is how everything becomes "medium".

| Level | Impact — what it costs if it happens | Likelihood — what it takes to do it |
|---|---|---|
| **high** | mass data access, privilege escalation, arbitrary code, money moved, the system down for everyone | no precondition worth stating: anyone who can reach the endpoint |
| **medium** | one actor's data, one tenant's data, a leak that enables the next step, degraded service | a real precondition — a role, a race, a specific configuration |
| **low** | bounded and non-sensitive; defense in depth | a chain of preconditions, or an attacker position that implies worse access already |

| | Impact high | Impact medium | Impact low |
|---|---|---|---|
| **Likelihood high** | Alto | Alto | Médio |
| **Likelihood medium** | Alto | Médio | Baixo |
| **Likelihood low** | Médio | Baixo | Baixo |

## 3. The verdict

Computed, not judged, so two runs over the same change agree. Take the first row
that matches:

| Verdict | When |
|---|---|
| **Bloqueia o merge** | any finding of severity `critical` or `high` with `origin: introduced` or `aggravated` — or any threat of risk **Alto** with the same origin |
| **Requer atenção** | any finding of severity `medium` introduced or aggravated; any `critical`/`high` finding marked `pre-existing` in touched code; any threat whose `boundary_change` is `added`, `moved` or `widened`; or a diff-only run that could not read context |
| **Nada bloqueante** | everything else |

The verdict line always names the item that decided it, by number, and always
states what was actually read. **Nada bloqueante** on a run that read three of
eleven changed files is a statement about the run, not about the change, and has
to say so on the same line.

A half that did not run never produces **Nada bloqueante** for its own section.
It produces `✘ não executada`, and the verdict says the review is partial.

## 4. Output template

Below is the `pt-BR` rendering, which is the default. For another language,
translate labels and prose and keep the structure, the ids, the paths, the refs
and the code exactly as they are.

````markdown
# Revisão de segurança — <título do PR, ou `<head>` → `<base>`>

**Head:** `feature/orders` @ `a1b2c3d` · **Base:** `main` @ `e4f5a6b` · **Merge-base:** `9c8d7e6`
**Arquivos alterados:** 7 (+184 / -12) · **Stack:** NestJS
**Metades:** OWASP ✔ · STRIDE ✔
**Data:** <YYYY-MM-DD>

## Veredito

**Bloqueia o merge** — o achado 1 introduz leitura de pedido de outro tenant em
`GET /orders/:id`. 7 de 7 arquivos alterados lidos com contexto.

## Resumo

| Severidade | Introduzidos | Pré-existentes |
|---|---|---|
| Crítica | 0 | 0 |
| Alta | 1 | 1 |
| Média | 2 | 0 |
| Baixa | 1 | 0 |

| Risco STRIDE | Introduzidas | Pré-existentes |
|---|---|---|
| Alto | 1 | 0 |
| Médio | 2 | 1 |
| Baixo | 0 | 0 |

## Arquivos alterados

Todo arquivo do diff, com achado ou sem.

| Arquivo | +/- | O que mudou | Estado |
|---|---|---|---|
| src/orders/orders.controller.ts | +40/-2 | novo handler `GET /orders/:id` | ⚠ 1, 3, TM-01 |
| src/orders/orders.service.ts | +22/-4 | busca por id | ⚠ 2 |
| src/app.module.ts | +3/-0 | registra `OrdersModule` | OK |
| test/orders.e2e-spec.ts | +61/-0 | teste do novo handler | OK — teste, não analisado |

## Achados OWASP

### 1. `src/orders/orders.controller.ts:31` — Alta — `A01.Q2` — introduzido

- **Onde no PR:** `@@ -28,6 +28,12 @@` — linha adicionada
- **A vulnerabilidade:** <o defeito, em uma ou duas frases>
- **Como um atacante pode explorar:** <passos concretos, com a requisição>
- **Mitigação:** <o que mudar, no idioma da stack>

### 2. …

## Achados OWASP globais

Não pertencem a um arquivo do diff — mesma estrutura, com **Componente** no lugar
do arquivo.

### 5. Bootstrap da aplicação — Média — `NEST.1` — pré-existente

- **Componente:** `src/main.ts:14`
- **Onde no PR:** não alterado por este PR — já presente em `9c8d7e6`
- **A vulnerabilidade / Como um atacante pode explorar / Mitigação:** …

## Ameaças STRIDE

### TM-01 — OrdersController — Risco alto — `E.Q3` — introduzida

- **Elemento:** processo `OrdersController` (`src/orders/orders.controller.ts:31`)
- **Fronteira:** internet → app
- **Ameaça:** <o que um atacante faz, uma ou duas frases>
- **Caminho de ataque:** <passos concretos, com a requisição>
- **Estado atual:** aberto — <o que foi encontrado, ou onde se procurou e não achou>
- **Mitigação:** <o que fecha, no idioma deste projeto>
- **Efeito do PR:** introduz — o elemento não existia em `9c8d7e6`

### TM-02 — …

## Mudanças em fronteiras de confiança

Só aparece quando o PR adiciona, move, alarga ou estreita alguma. É o resultado
mais importante desta metade.

| Fronteira | Mudança | O que passa a cruzar | Ameaças |
|---|---|---|---|
| internet → app | alargada | `GET /orders/:id` aceita id de qualquer tenant | TM-01 |

## Riscos já aceitos

De `SECURITY-NOTES.md` — não são achados novos.

| ID | Ref | Risco | Revisar quando |
|---|---|---|---|
| R-1 | `A08.Q1` | … | … |

## Premissas

Toda suposição feita para revisar esta mudança. Uma premissa errada invalida os
itens que dependem dela — por isso ficam visíveis, e não implícitas.

- <base inferida, ambiente de deploy, o que existe fora do repositório>

## Limites desta revisão

- <o que não foi lido, e por quê — binário, arquivo gerado, head não baixado>
- Arquivos alterados efetivamente lidos: <n> de <n>.
- <qual metade não rodou, e por quê — nunca omitir>
- Ausência de achado não é prova de ausência de vulnerabilidade. As regras OWASP
  são as do skill `secure-coding` e as ameaças são as do `app-stride-report`; um
  achado citando `A01.Q2` e uma ameaça citando `E.Q3` são resolvíveis contra os
  arquivos de origem.
````

**Premissas** and **Limites** are not optional and are never empty. At minimum
they state the base that was used, the coverage numbers, which halves ran, and
the last line. A review that hides what it did not look at is worse than no
review — a reviewer trusts it and stops looking.
