# Contributing

Two bodies of material live here — the OWASP rules under
`skills/secure-coding/` and the STRIDE material under `skills/app-stride-report/`.
The first half of this file is the recipe for a stack file; the conventions from
`## Cross-reference discipline` onwards apply to both.

## Adding a stack file — ground it, or mark it

**Ground it, or mark it.** A stack file written from documentation is worth less
than one written from code that was actually wrong, and the difference must be
visible in the header:

```
**Status:** grounded in <n> production codebases (<orm>, <auth>, <authz>).
**Status: unverified against a real codebase.** Written from framework documentation.
```

Never quietly promote a file from unverified to grounded. Promote it when you
have read real projects and rewritten the items around what they got wrong.

## Recipe for a stack file

1. **Survey before writing.** Read every project on this machine using the stack.
   For each, answer: how is input validated, where does authorization live, what
   is returned from handlers, which query APIs are used raw, what does the
   bootstrap configure (CORS, headers, docs, rate limiting), where do secrets come
   from, what does the error handler return, what does the logger record.
2. **Rank by observed frequency.** `NEST.1` is first because it was wrong in half
   the projects. Do not order by severity or by OWASP number — order by what the
   next diff is most likely to get wrong.
3. **Write each item in 4–8 lines**: the rule, the wrong form, the right form,
   and a `→ Ann` pointer to the core categories it serves. Budget roughly 10
   lines per item — `nestjs.md` runs ~185 for 17 items, and that ratio is the
   ceiling worth defending. Past it, an item belongs in the core, not here.
   (Core files run 95–155 lines. The spread is real: `A01` is the longest because
   it absorbed both SSRF and CSRF from the 2021 edition, and `A04` the shortest
   because its scope is narrow. Treat the shape as the guide, not the number —
   never trim substance to hit a rounder figure.)
4. **Use the project's own vocabulary.** If the codebase says "use-case", do not
   say "application service". The guidance has to sound like the code.
5. **Cite the pattern, never the evidence.** No `file:line`, no project names, no
   client identifiers — this repo is publishable. Concrete findings belong in that
   project's `SECURITY-NOTES.md`.
6. **Add `## Grep signals`** at the end, tuned to the language.
7. **Wire it up**: add a row to the manifest in `skills/secure-coding/SKILL.md`,
   add the detection file to the stack list in `skills/secure-coding/TRIGGER.md`
   and to Step 1 of `skills/api-secure-report/SKILL.md`, and add a row to the
   `## Idiom by stack` table of each core file the items serve.
8. **Run `./scripts/check-ids.sh`.** It fails on a manifest row pointing at a
   missing file, a `→ stacks/x.md (ID)` naming an id that does not exist, a gap
   in review-question numbering, a stack file with no `**Status:**` header, and a
   shipped file that hardcodes an install path. Green is the bar for a PR.

`skills/secure-coding/stacks/_TEMPLATE.md` is the blank, with this recipe's
wiring steps repeated in comments so they are in front of you while you write.

## Cross-reference discipline

Core files point at stack items as `→ stacks/<file>.md (NEST.3)`; stack items
point back as `→ A01`. Both directions are plain text, greppable, and survive
renaming. If an item has no core category, the core is missing something — add it
there first.

`A06` is the deliberate exception with no outgoing pointer, and says so in the
file: design flaws do not reduce to framework idiom. Do not add one to make the
grep tidy.

Core files carry seven sections. `## Applies when` is an optional eighth, used by
`A04` and `A06` — the two categories most often loaded when they do not actually
apply. Add it where the manifest row alone over-triggers, and nowhere else.

## Changing the core

The ten core files are agnostic. Anything that names a framework, a package, or a
language API belongs in `stacks/`. The test: if a sentence would confuse someone
reading it in a Go or Python project, it is in the wrong file.

## The threat material is a separate body

`skills/app-stride-report/stride/` is the second body of material in this repository
and it is deliberately independent: its own ids (`S.Q1`…`E.Q6`), its own files,
its own consumer. It answers a different question — *what could go wrong here by
design* — over a different unit of analysis: the trust boundary, not the route.

**Neither body cites the other.** Not as a "see also", not in a comment. Check 13
of `scripts/check-ids.sh` fails the build on an OWASP id, a stack id, or a
reference to the rules skill appearing anywhere under `skills/app-stride-report/` or
in `agents/threat-modeler.md`. The reason is portability: either half has to be
usable, and correct, with the other uninstalled. A single convenience
cross-reference is how that stops being true.

**`skills/pr-appsec-review/` is the one exception, and it is a narrow one.** A
reviewer looking at a pull request wants both questions answered, so that skill
consumes both bodies. It is a consumer of each and an owner of neither: the two
halves run side by side, produce separate sections with separate scales and
separate numbering, and **no single item ever carries both vocabularies** — a
finding cites `A01.Q2`, a threat cites `E.Q3`, nothing cites the pair. Its
subagent prompts paste each axis's contract inline rather than pointing an agent
at that skill's own `references/report-format.md`, precisely because that file
names both. Either half runs with the other uninstalled and says so in the
header when it does. That last rule is the one check 13 cannot express, which is
why it is written here.

The conventions are otherwise the same — stable ids, contiguous numbering,
questions answerable yes/no, grep signals as a pre-filter, nothing hardcoding an
install path — and checks 9–13 enforce them the same way. Two things differ, and
both are load-bearing:

- **`## Which elements it applies to`** replaces `## Idiom by stack`. Stack idiom
  lives in the rules skill, which this one does not read; the element matrix in
  `references/decomposition.md` is what drives the fan-out instead, and a
  category file must agree with it.
- **Evidence is an account of the search, not a `file:line`.** A threat whose
  mitigation is absent has no line to cite. The auditor's rule would delete the
  main product of a threat model, which is why `threat-modeler` is a separate
  agent rather than a prompt on the existing one. Do not "fix" this by adding a
  location requirement.

## The one skill that writes and runs

`skills/appsec-test/` is the second consumer of both bodies, and it is held to
the same rule as the first. A *resolved item* — the triple of ref + location +
claim it produces before anything is written — cites `A01.Q2` or it cites
`E.Q3`, never the pair, and the header of the test it generates carries only
that item's own vocabulary. Two taxonomies, never inside one item. It owns
neither body: if a rule seems missing, add a question to the body it belongs
to, not a paragraph to the skill.

**It is the only thing here that writes into the project under review, and the
only one that runs that project's code.** The other three commands write their
own report and nothing else — none of them has `Edit` — and both agents have
neither `Write` nor `Edit`, which is why neither is dispatched from this skill:
`security-auditor` and `threat-modeler` forbid running project code in their own
definitions, and an agent defined never to run anything would either break that
definition or quietly skip the suite. All of it is enforced in frontmatter,
where a drifting prompt cannot reach it. A new skill starts read-only and stays
read-only unless it has the reason this one has — a failing test on screen,
proving the thing it is about to change. Anything less is a guess with write
permission.

**The generated test is committed.** The two reports are gitignored and
overwritten on the next run; the test is the one output meant to outlive the
document, which is why `install.sh`'s gitignore block gains no line for it and
CI asserts `.gitignore` has not grown. An ignore rule there would delete the
only reason the skill exists.

**Test-harness knowledge lives in `skills/appsec-test/references/test-design.md`
and nowhere else.** Runner names — `jest`, `supertest`, Pest, PHPUnit, JUnit,
`MockMvc` — appear in that one file and in no other file under `skills/`.
Moving any of them into `skills/secure-coding/stacks/` breaks two rules already
written above: the 4–8-lines-per-item budget, which has no room for a harness
recipe, and the test in `## Changing the core` — *if a sentence would confuse
someone reading it in a Go or Python project, it is in the wrong file*. The
split is deliberate. The core names the obligation — `A06.Q9`, *is there a test
that asserts the limit or the forbidden transition* — and the consumer names the
runner that satisfies it. Collapse the two and the rules stop being portable to
the stack nobody has written yet.

Checks 17–19 hold the skill to the promises the other consumers make: every
manifest row resolves to a file that exists, every file under its `references/`
has a manifest row loading it, and every threat id it cites is a real threat
question. Its OWASP ids come free — check 4's glob is `skills/*/references/`,
and has covered them since the first consumer.

**A green run of `./scripts/check-ids.sh` is not proof that anything was
checked.** The script holds skill paths in constants — `TM=`, `PR=`, and now
`AT=` — and pointed at a directory that does not exist, several checks print `✔`
having examined nothing: a `while read` loop fed by a `grep` that matched no
file gets empty input and never runs its body, and the `|| true` that keeps
`set -uo pipefail` from aborting swallows the error that would have said so.
Rename a skill directory, move a reference, edit a constant, and the checks
guarding it go quietly green. So after any rename or path change, prove they
still bite: break a file on purpose and watch the build go red before trusting
the tick it prints afterwards. Three breaks that are verified to bite, all in
`skills/appsec-test/references/` — `A99.Q9` fails check 4, and `E.Q99` and
`Z.Q9` both fail check 19, whose glob is `[A-Z]\.Q[0-9]+` rather than the six
letters, so an invented category is caught as loudly as an invented number.
The rename is the trap in miniature: point `AT=` at a directory that is not
there and checks 17 and 19 both print `✔` having read nothing at all. A check
nobody has watched fail is a check nobody should believe.

## Conventions worth preserving

- **IDs are stable and never renumbered.** A future edition goes in
  `owasp/2029/` alongside, so a finding citing `A05.Q2` stays resolvable.
- **`## Review questions`** are the contract a review skill iterates over. Adding
  one extends every consumer.
- **`## Grep signals`** are a pre-filter, not proof.
- **Nothing restates the material.** Consumers read these files and cite ids.
- **Nothing shipped hardcodes an install path** — that is what lets one set of
  bytes work as a plugin, in a project, or in your home directory.
- **The two bodies of material never cite each other**, so either is usable
  alone.

`./scripts/check-ids.sh` enforces all of these that can be enforced mechanically.
