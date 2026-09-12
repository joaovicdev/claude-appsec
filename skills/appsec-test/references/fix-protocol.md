# Fix protocol

Five contracts and one refusal: the outcome the run reports, the gate the fix
passes, the shape the fix takes, the two runs that verify it, and the loop that
feeds a false positive back into the material instead of losing it. The refusal
is that the test is never edited to make it pass. The outcome is read off the
two assertions; the fix is read off the outcome.

## 1. The three outcomes

One of three, decided by the attack assertion and the positive control and by
nothing else:

```
RED      the positive control passes, the attack assertion fails
GREEN    both pass
BROKEN   the positive control fails
```

`RED`, `GREEN` and `BROKEN` are ids — uppercase, untranslated, never softened
into prose. "The test sort of failed" is not one of the three.

Below is the `pt-BR` rendering, which is the default. For another language,
translate labels and prose and keep the structure, the ids, the paths, the refs
and the code exactly as they are.

```
RED · A01.Q2 · src/orders/orders.controller.ts:14
  test/orders.security.spec.ts
  ✔ controle positivo — o dono lê o próprio pedido          200
  ✘ ataque — o tenant B lê o pedido do tenant A             200, esperado 403
  O achado é real: a requisição chegou ao handler, e o handler respondeu
  errado. Baseline: 128 testes, 0 falhas.
  Corrigir agora? [s/N]
```

```
GREEN · A01.Q2 · src/orders/orders.controller.ts:14
  ✔ controle positivo — o dono lê o próprio pedido          200
  ✔ ataque — o tenant B lê o pedido do tenant A             403
  Não reproduzível aqui. Causa: achado errado — o escopo já está no
  predicado, em src/orders/orders.repository.ts:22. Nada é corrigido; o
  teste fica no repositório como regressão.
  Registrar em SECURITY-NOTES.md, sob ## Verified clean? [s/N]
```

```
BROKEN · A01.Q2 · src/orders/orders.controller.ts:14
  ✘ controle positivo — o dono lê o próprio pedido          404
  ✘ ataque — o tenant B lê o pedido do tenant A             404
  O teste nunca alcançou o código: com o controle positivo vermelho, o 404
  do ataque não é evidência de nada. Prováveis causas: rota não montada no
  módulo de teste, fixture ausente, 401 antes do handler.
  Corrigir o harness, nunca o código. Nada é corrigido.
```

The header line is `<OUTCOME> · <ref> · <file:line>` in all three, with `—` in
place of the location when the finding is an absence — a login route with no
limit (`A07.Q1`, or `D.Q1` when the resolved item is a threat). BROKEN printed
as RED is a fix applied to code the suite never reached.

BROKEN ends the run where GREEN does. Fix the harness — the bootstrap, the
fixture, the credential the positive control carries — re-run, and take whatever
the two assertions then say. Nothing about the handler has been established on
the way through, so nothing about the handler changes: a run that never reached
the code is not a verdict on the code.

## 2. GREEN splits three ways, and the run says which

A GREEN that does not name its cause is not a result. Only the first two are
false positives; the third is a bad test.

- **The finding was wrong.** The property holds, and held when the report was
  written. This is the false positive worth keeping — section 7 records it.
- **The code was already fixed since the report was written.** A false positive
  against the report, not against the code. Read the cited line, find the commit
  that changed it, name that commit — and record nothing, because a revert
  brings the defect back and the report was right when it was written.
- **The test does not exercise the vulnerable path.** Not a false positive at
  all. Compare the request the test sends against the `exploit` bullet of the
  resolved item: a different route, a different principal, or an attack
  parameter that is never actually sent puts the test where the defect is not.
  Rework the test and run it again.

**A rework changes what the test drives, never what it asserts.** The route, the
principal, the fixture and the parameter are all in play; the assertion is not.
That is the line between finding the defect and manufacturing it — and without
it, "rework until it goes red" is the gate with an extra step in front of it. A
second GREEN after a rework is a GREEN, and it is recorded as one.

Counting the third cause as calibration is how a real finding gets closed with a
green badge on top of it.

## 3. The gate

**The fix runs from RED and from nowhere else.** GREEN and BROKEN never reach
it, `--fix` included: `--fix` answers the gate's question in advance, it does
not open the gate. From RED, ask once, in the requested language, and edit only
on a yes — the default is no, and silence is no. `--no-fix` suppresses the
question and keeps the test.

**There is no `--force`.** For an unproven finding the existing path is already
correct, and saying so is the whole answer: load `secure-coding` at
`RULES_ROOT`, read the rule the ref names — `owasp/A01-broken-access-control.md`
for `A01.Q2`, the detected `stacks/*.md` for its stack item — and fix it by
hand. Name that file at the point of refusal, so the developer is pointed
somewhere rather than merely stopped.

A gate with an override is a suggestion, and a suggestion is what the other
three commands already offer.

## 4. The shape of the fix

- **Minimal.** One defect, one change, in the code under test. The diff reads as
  the answer to the assertion that is red and to nothing else.
- **The shape the cited rule prescribes.** Read the rule before editing, and the
  stack item when a stack was detected: `A01.Q2` with `NEST.3`, `LAR.3` or
  `SPR.3`; `A05.Q1` with the stack's binding rule; `A09.Q1` with its log
  allowlist. The test says what must stop being true; the rule says what the
  correct form looks like here.

```ts
// wrong                                   // right
findOne({ where: { id } })                 findOne({ where: { id, tenantId: caller.tenantId } })
if (o.tenantId !== caller.tenantId)        // no row to check — the predicate refused
```

Scope in the query predicate, never in a check after the fetch. Both turn the
attack assertion green, and only one of them is still there after the next
refactor moves the lookup.

- **Cite the ref in the change.** The test header already carries it; the commit
  message names the ref and the stack item, so the fix is resolvable against the
  material six months later.
- **No drive-by.** No refactoring, no rename, no formatting pass, no second
  finding fixed because it was two lines away. A second finding is a second run
  of `/appsec-test`, with its own test and its own RED.

A fix that touches more than the finding cannot be reverted cleanly when the
suite goes red — and section 6 exists precisely to revert it.

## 5. Never edit the test to make it pass

**The test is never edited to make it pass.** Once RED is on screen the
assertions are frozen: not the expected status, not the principal, not the
route, not the payload, not a widened matcher, and never a skip. Only the code
under test changes.

One edit to the test file is permitted after a fix, and it touches no assertion:
completing the header block's line recording the date the finding was proven red
and that it was fixed in the same change.

A test weakened until it is green is the vulnerability re-shipped with a green
badge — and unlike the finding, the badge is committed.

## 6. Verification is two runs

1. **The security test, alone.** The attack assertion flips to green and the
   positive control stays green. A control that went red during the fix means
   the fix broke the legitimate path — not a pass, a denial of service with a
   correct-looking diff.
2. **The whole suite, against the baseline** taken at harness discovery. Compare
   failure for failure. Anything failing now that passed then is a new failure,
   and is reported **by name**, never as a count.

```
Verificação
  ✔ controle positivo — o dono lê o próprio pedido          200
  ✔ ataque — o tenant B lê o pedido do tenant A             403
  Suite: 128 testes, 2 falhas — baseline: 128 testes, 0 falhas.
  Novas falhas:
    - orders.service.spec.ts > findOne retorna o pedido por id
    - orders.e2e-spec.ts > GET /orders/:id como admin
  Reverter a correção? [s/N]   O teste permanece, e volta a ficar vermelho.
```

The revert offer is not optional and is not a formality: on a yes, undo the edit
and leave the tree as it was found, with the test still committed and still red.
A test that is red on purpose is a finding somebody can act on; a suite that is
red by accident is a finding nobody goes looking for.

## 7. The calibration loop

On a GREEN whose cause is **the finding was wrong** — cause 1 of section 2,
never cause 3 — offer to record it in `SECURITY-NOTES.md` at `SCAN_ROOT`, under
`## Verified clean`, whose columns are already `| Ref | Checked | Date |`.

That file is hand-maintained today and no skill in this repository writes to it,
so the offer takes the shape `api-secure-report` Step 5 uses for its
`.gitignore` prompt — *"say so plainly and offer to add it — one line, at the
user's call. Do not add it silently, and do not skip the question"*. Show the
row first:

```markdown
| `A01.Q2` | GET /orders/:id — leitura cruzada entre tenants recusada; teste em test/orders.security.spec.ts | 2026-09-12 |
```

The `Checked` cell names what was checked and where the test that checks it
lives, because that file's own warning is that these entries rot — the row
expires, the committed test does not. If `SECURITY-NOTES.md` is absent, say so
and point at `templates/SECURITY-NOTES.md` under `RULES_ROOT`; do not create the
file as a side effect of a test run.

This closes the loop: the next `/api-secure-report` reads that file and reports
the entry as known rather than as a new finding. Without the row the same false
positive is re-litigated every run, and the third time it appears somebody stops
reading the report.

## 8. What every run closes with

All three outcomes end with the same section, inside the emitted output:

```markdown
## Limites desta prova

- <o que a asserção não cobre — a rota irmã, outro principal, outro método>
- <qual família de entrada não rodou, e por quê — nunca omitir>
- Asserções efetivamente executadas: <n> de <n>. Baseline: <n> falhas.
- RED prova uma afirmação em um limite. Ausência de RED não é prova de ausência
  de vulnerabilidade. Um item citando `A01.Q2` é resolvível contra
  `owasp/A01-broken-access-control.md`; um citando `E.Q3`, contra
  `stride/E-elevation-of-privilege.md`.
```

The **Limites** section is not optional and is never empty — at minimum it
states which assertions ran, the baseline numbers and the last line. A run that
hides what it did not assert is worse than no run: the test is committed, and
the next reader takes it for coverage.
