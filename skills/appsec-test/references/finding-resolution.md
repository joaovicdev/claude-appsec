# Finding resolution

Resolving the item is the step that must be exact. Everything after it is
mechanical — the harness, the two assertions, the fix — and all of it is aimed
at whatever this step decided. A test written against the wrong defect still
goes red, and it goes red convincingly.

The step produces exactly this, and the rest of the skill runs on nothing else:

```
<taxonomy> | <ref> | <file:line, or — for an absence> | <the claim, one sentence>
```

That line is **the resolved item**. It is echoed back before anything is
written, and it is what the generated test's header block carries. Stop rather
than guess: an input matching more than one item is offered for a pick, never
settled by taking the first.

## 1. The input forms

Every form the developer already has the finding in is accepted. None is
privileged, and none requires a report to exist.

| Input | Resolution |
|---|---|
| *(nothing)* | Read `SECURITY-REPORT.md` and `STRIDE-REPORT.md` at `SCAN_ROOT`, run the triage in section 6 over both, and print only the provable items, ranked by severity or risk, for a pick. |
| `3` / `#3` | Finding 3 of `SECURITY-REPORT.md`, resolved the moment it arrives — section 2. |
| `TM-07` | Threat `TM-07` of `STRIDE-REPORT.md`. |
| `A01.Q2` / `NEST.3` / `E.Q3` | Every item in either report citing that ref. One match resolves; more than one is offered for a pick. |
| `A01.Q2#3` | Finding 3, **validated** against the ref. A disagreement stops the run — section 2. |
| `src/orders/orders.controller.ts:14` | Locate by position: open the file, read the handler, state the claim. No report needed. |
| free text | The claim in prose — *"GET /orders/:id returns another tenant's order"*. Ref and taxonomy are derived in section 5. No report needed. |

A form that resolves to nothing is said out loud, with the form quoted back. A
silent fall back to "the first finding in the report" is how the wrong defect
ends up with a committed test carrying someone else's line number.

## 2. `#N` is a handle, never an identity

`api-secure-report` re-derives its numbering on every run — *"Order findings by
severity, then by module. Number them so the report can be discussed by
number."* — so finding 3 today and finding 3 tomorrow are different defects. The
number is how a developer points at a line in a document open in front of them.
It is not the item.

Resolve it the moment it arrives. Read the finding, take its ref, its
`file:line` and its claim, echo the resolved item back, and do not use the
number again — not in the test header, not in the fix, not in the terminal
output past that echo.

On `A01.Q2#3`, check the halves against each other. If finding 3 does not cite
`A01.Q2`, **stop.** The report was regenerated after the developer read it, and
finding 3 is now some other defect. Name the ref finding 3 actually carries and
ask which item was meant. The ref half of that form exists for no other reason
than to catch this, and catching it is worth more than the run it costs.

A resolved item nobody confirmed is a test committed against a defect nobody
reported.

## 3. Working without a report is the normal case, not a fallback

Two of the three producers of findings in this repository write no file this
skill could read. `/pr-appsec-review` prints its review to the terminal and
writes nothing at all, by design. `secure-coding` produces findings inline while
the developer is writing the code — a flag shaped
`A01.Q2 — orders.controller.ts:14 — order looked up by id alone`, pasted
straight out of the conversation it appeared in.

Both must work. Requiring `SECURITY-REPORT.md` would couple this skill to one of
its three producers, and to the one whose output is gitignored and overwritten
on every run.

So a report is an input, never a precondition. A `file:line` form and a prose
form skip section 4 entirely and join at section 5: read the code at the
location, state the claim in one sentence, pick the taxonomy and the ref,
triage. A skill that can only prove what a document already recorded proves
nothing about the code being written today.

## 4. Parsing the two reports

Three heading grammars. The ids and the paths in them are invariant whatever
language the document was written in:

```
### <n>. <METHOD> <ROUTE> — <Severity> — `<ref>` [(also `<ref>`, …)]
### <n>. <Component> — <Severity> — `<ref>`
### TM-<nn> — <Element> — <Risk> — `<ref>`
```

The first two are `SECURITY-REPORT.md`, a route finding and a global finding.
The third is `STRIDE-REPORT.md`. `pr-appsec-review` emits all three, in the
terminal rather than to a file.

Beneath each heading the bullets carry **translated labels in a fixed order**.
Match on position, never on the label: *A vulnerabilidade* is *The
vulnerability* in an English run and something else again in a Spanish one,
while the bullet in that position is the defect in all of them. The `file:line`
sits in backticks inside the first bullet, beside the route, the component or
the element.

The exploit bullet — *Como um atacante pode explorar* in a finding, *Caminho de
ataque* in a threat — is required by both report formats to be a concrete
request, not a category: *"authenticate as any user, call `GET /orders/9001`
with an id belonging to another tenant, receive the full order"*. **That bullet
is the raw material for the test.** The attack assertion is that request, driven
at the boundary and asserted to fail. Where the bullet is vague and the format
required it to be concrete, the report is at fault and the run says so — no test
can be written from "an attacker could gain unauthorized access".

## 5. Taxonomy separation

A resolved item is an OWASP finding **or** a STRIDE threat. It carries one
vocabulary and cites one ref — `A01.Q2`, or `E.Q3`, never the pair. The rule is
`CONTRIBUTING.md`'s, and `pr-appsec-review`'s before it: the two bodies of
material are independent, either is usable with the other uninstalled, and one
convenience cross-reference is how that stops being true.

This skill is a **consumer** of each body and an owner of neither. It resolves
into one of them, reads that one's files, cites that one's ids, and writes a
test header in that one's vocabulary. It never restates an item in the other's
terms, and it never records that the two happen to describe the same defect.

The taxonomy is decided first. Only its section below is then read.

### OWASP — the resolved item is a finding

The taxonomy is OWASP when the input is a finding number, a ref shaped
`A<nn>.Q<n>`, a stack ref (`NEST.3`, `LAR.2`, `SPR.5`), or a heading out of
`SECURITY-REPORT.md`.

The ref is read off the item, never re-derived. For a `file:line` or a prose
input carrying none, open the one category file under `RULES_ROOT/owasp/` whose
subject matches the claim and take the review question that states the property
— that question text is the claim, already phrased as the thing the test
asserts. A stack ref is OWASP-side material and stands on its own: `NEST.4` and
`SPR.1` each name the test obligation outright, and an item citing one resolves
against `RULES_ROOT/stacks/`.

Never mint a question id. A ref that does not exist in those files is a gap in
`secure-coding`, and the fix is a new review question there — an id invented
here is a header line that nothing downstream can resolve.

### STRIDE — the resolved item is a threat

The taxonomy is STRIDE when the input is a `TM-<nn>`, a ref shaped
`<letter>.Q<n>`, or a heading out of `STRIDE-REPORT.md`.

A threat carries no `file:line` requirement. That is `app-stride-report`'s
evidence rule and not an oversight, so the location half of the resolved item is
then `—`. What the threat does carry is the element, the boundary and the attack
path, and those three are what the test drives.

A threat whose *Estado atual* is only an account of where the agent searched has
no claim to assert yet. Resolve its element and boundary, then triage it like
any other item — many stop at section 6, which is the honest answer rather than
a failure.

The twins are the trap. `E.Q3` asks of a threat what `A01.Q2` asks of a finding,
and `I.Q4`, `E.Q4`, `T.Q3`, `S.Q2`, `T.Q5`, `I.Q5`, `I.Q3` and `D.Q1` each have
a counterpart across the line. Cite the one belonging to the taxonomy the item
resolved into. A test header carrying `A01.Q2` and `E.Q3` together describes an
item that belongs to neither body.

## 6. Testability triage

Not every real defect has an assertion. The triage runs before a line of test
code is written and answers one question: is the security property observable at
a boundary this project can drive?

### Provable here

| Family | What the test drives | Ids that carry an assertion |
|---|---|---|
| **A01 / E** — access control | Two principals. B asks for A's resource by id and is refused, while B's own request still succeeds. The strongest case in the inventory. | `A01.Q2`, `A01.Q5`, `A01.Q7` · `E.Q3`, `E.Q4`, `T.Q3`, `I.Q4` |
| **A05 / T** — injection | A payload that changes query or command semantics, asserted by effect — a row that must not appear, a record that must still exist. Never by string-matching the query. | `A05.Q1`, `A05.Q2` · `T.Q5` |
| **A07 / S** — authentication | A credential forged, expired, absent, belonging to someone else, or signed with an algorithm the verifier should have pinned. | `A07.Q1`, `A07.Q4`, `A07.Q6` · `S.Q1`, `S.Q2`, `S.Q4` |
| **A09 / R** — logging | A captured log sink, a request carrying a secret, and the assertion that the sink never received it. | `A09.Q1` · `I.Q5`, `R.Q1` |
| **A10 / I** — error handling | A forced failure: the response carries no stack frame, no SQL fragment, no internal path, and the security check denies rather than falling open. | `A10.Q1`, `A10.Q3` · `I.Q3` |
| **A02** — misconfiguration | Response headers, a preflight with a hostile `Origin`, an unauthenticated GET on a docs or management path. Not when the setting lives only in a deployment manifest. | `A02.Q3`, `A02.Q5`, `A02.Q6` |
| **D** — denial of service | N+1 requests at the entry point, one of which must be refused. | `D.Q1` |

The pairing in the first column names two families, not one item. An
access-control test cites `A01.Q2` or it cites `E.Q3`, per section 5.

### Not provable here

| Family | Why there is no assertion |
|---|---|
| **A03** — supply chain, all of it | A lockfile, registry and pipeline property. `A03.Q2` has an exact line and no runtime behaviour behind it; `A03.Q7` is an audit tool's output plus a documentation state. |
| **A06** — insecure design, mostly | `A06.Q2` and `A06.Q4` are business-rule tests and do belong above. `A06.Q1` is the threat-model question itself; `A06.Q8`, a check-then-act race, is provable only by a concurrent test that is flaky in every runner `references/test-design.md` names. |
| Deployment and infrastructure | `A02.Q7` needs a live peer with a bad certificate; `A01.Q10` needs a controllable redirecting host and DNS; `E.Q1`, `T.Q1`, `T.Q4`, `R.Q4` and `I.Q1` are process privilege, transport, credential scoping, retention and data at rest. |
| Timing and capacity | `A07.Q2`'s timing half, `A04.Q4`, `I.Q6`'s timing and size halves, `D.Q3`, `D.Q6`. A wall-clock or load assertion is not a regression test, and a flaky test is worse than no test. |
| Judgement and structure | `A01.Q8` (intent), `A05.Q4` (necessity), `A05.Q8` (foresight), `A09.Q6` (third-party configuration), `A09.Q7`, and `A10.Q4` — whose consequence *is* testable, as `A10.Q3`; cite that instead. |

`A06.Q9` is the sharpest case and is never the ref of a generated test. It asks
whether a test exists, and the existence of a test is not a runtime property:
`/appsec-test` satisfies that question rather than proving it.

### The rule that generalises all of it

**Testability comes from whether the security property is observable at a
boundary the project can drive, not from whether the item has a `file:line`.**

That is why an absent rate limit is provable with nothing to cite — absence is
observable, so drive the requests and watch for the refusal that never arrives —
and why a lockfile pin never is, however exact its line. The `file:line` is
where the fix goes; the boundary is where the proof comes from, and they are two
different questions.

When an item lands here, name the id, say which of the two it failed, and stop.
The existing path is already the right one: load `secure-coding` and fix it by
hand. A test written because something had to be written is a test that passes,
gets committed, and reads as evidence for a claim nobody proved.
