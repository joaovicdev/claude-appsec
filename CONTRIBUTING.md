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

**A third file now sits between the two bodies and belongs to neither.**
`appsec/profile.md`, generated into the project under review by
`/appsec-profile`, states project facts and cites no id from either taxonomy. Both
halves read it precisely because it carries neither vocabulary, and check 23 is
what keeps that true as the skill is edited. Note why a new check was needed at
all: checks 4 and 20 *validate* an id, they do not forbid one — a real `A01.Q2`
sitting in that skill would pass both and quietly tie the profile to one half.

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

**It is the only thing here that changes code the project already had, and the
only one that runs that project's code.** That boundary is narrower than this
paragraph used to claim, and the narrowing is honest rather than a concession:
four commands now write a file into the project under review — the two reports,
the architecture profile, and the test — and exactly one of them has `Edit`.
*Writes a file* was never the line; *can change a line somebody else wrote, and
can execute the project* is. The other four write their own artifact and nothing
else — none of them has `Edit` — and both agents have
neither `Write` nor `Edit`, which is why neither is dispatched from this skill:
`security-auditor` and `threat-modeler` forbid running project code in their own
definitions, and an agent defined never to run anything would either break that
definition or quietly skip the suite. All of it is enforced in frontmatter,
where a drifting prompt cannot reach it. A new skill starts read-only and stays
read-only unless it has the reason this one has — a failing test on screen,
proving the thing it is about to change. Anything less is a guess with write
permission. `skills/appsec-profile/` is that rule working rather than an
exception to it: it writes one file it alone owns, has no `Edit`, and its `Bash`
searches and nothing else.

**Every generated artifact is committed, and the installer writes no ignore
rule.** The test is meant to outlive the document. The profile is worthless to
the next reader if it is not in the repository — and being committed is also the
only review it gets, since a claim then arrives as a diff. The two reports are
committed for a third reason: their value is the diff between two runs, and a
file nobody shares is a file nobody diffs. CI asserts the installer leaves the
target's `.gitignore` untouched, which is the inverse of the assertion it used to
make.

That is a real trade — both reports spell out how to attack the project under
review. The decision belongs to whoever owns that repository, not to this
installer, so nothing here writes `/appsec/` into a `.gitignore` on their behalf
and the two report skills say plainly, once, what the document contains.

**The reports carry durable ids, and that is what makes them worth keeping.**
`SEC-<n>` and `TM-<n>` come out of an `appsec-ledger` comment on the document's
last lines — the same never-renumbered, never-reused promise every other id in
this repository makes, and the same shape `appsec-profile`'s `P<n>` ledger
already uses. Both report formats specify that ledger identically; checks 28, 29
and 30 fail the build when they drift apart. The prose of a report is regenerated
whole on every run, the identity is not, and `/appsec-test` may write exactly one
column of that ledger and nothing else.

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

## The profile is a suppression mechanism

`skills/appsec-profile/` is the third kind of material here: **project facts, no
taxonomy.** It states what a project does; it never says which rule that answers
or whether it is enough. Eight rules, and the first three are the ones that make
the rest safe.

1. **It cites no id from either body, and check 23 enforces it** over the whole
   skill directory including `templates/` — which no other check globs, and which
   is exactly where an example claim would rot unnoticed. There is deliberately no
   *"every id it cites is real"* check, because it cites none. Do not add one.
2. **`Does not apply to:` is mandatory, and it is the only safety property.**
   There is no status field, so a claim's authority is not gated on ceremony — it
   is gated on shape. A claim missing that line suppresses nothing; a consumer
   reads it, saves the context, and still reports what it finds. **A run never
   writes `none` into it**: where discovery found no bypass it records the bypass
   *shapes* for that mechanism anyway, because a run cannot prove a negative over
   code it did not read. *"nothing — every read goes through it"* is a sentence
   only a human may type, and a human typing it is the review working.
3. **The generator records declarations, never intentions.** A route is public by
   design when the code says so. A route that is merely unguarded is a finding and
   goes to `## Not claimed`. Without this rule a run would manufacture exactly the
   exemptions it was asked to discover, which is the one failure that would make
   the file worse than nothing.
4. **`P<n>` ids are the profile's own** — never renumbered, never reused, retired
   numbers stay retired. The high-water mark lives in a ledger comment on the
   file's last line, so an id in an old report stays resolvable.
5. **A deletion is an instruction.** A claim the developer removed is not re-added
   on the next run. It is the only way the file has of saying *stop claiming this*,
   and a run that helpfully restored it would make the file impossible to correct.
6. **Removal is total in the report body, and accounted for in one line.** A
   suppressed item appears nowhere in the document; the `## Limites` line names the
   count and the claim ids responsible. That is a deliberate trade rather than an
   oversight: it is the only accounting that exists, and deleting it makes
   suppression completely silent.
7. **Only `/appsec-profile` ever writes the file.** One writer, no second write
   path to reason about. Other skills may tell the developer to paste something
   into a claim by hand; none of them does it.
8. **A claim carries no severity and no grade.** Whether a mechanism is any good is
   the audit's question. The profile only says the mechanism is there.

The harness section is the one place where an existing rule needed mechanising
rather than restating. Runner names still belong only in
`skills/appsec-test/references/test-design.md`; the profile's `## Test harness`
section records **the value the project itself declares, quoted**, so the template
can define the section without naming a runner. Check 24 now enforces that rule
across `skills/`, which nothing did before — it was defended by hand for two
versions, and the profile is the first thing that made it easy to break by
accident.

Checks 21-22 hold the skill to the same manifest promises the other consumers
make. And the constant guard added alongside them closes the trap described above
rather than only warning about it: `TM`, `PR`, `AT` and `PF` are now asserted to be
real directories, so a rename fails loudly instead of printing a tick over an empty
read.

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
- **The profile cites neither**, so either body can read it.

`./scripts/check-ids.sh` enforces all of these that can be enforced mechanically.
