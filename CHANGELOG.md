# Changelog

Versions follow [SemVer](https://semver.org/). For this repository that means:

- **Major** — a stable id is removed or its meaning changes, or an install layout
  breaks. The `IDs never get renumbered` promise makes this rare by design.
- **Minor** — new review questions, a new category or stack file, new tooling.
  Additive: a consumer written against the previous minor keeps working.
- **Patch** — wording, grep signals, fixes that change no id.

## [2.2.0]

A fourth command, and the first one that runs the project instead of only
reading it: `/appsec-test` takes a single finding and produces the test that
fails because that finding is real. The material has been asking for exactly
this for four releases without ever delivering it — `A01` rule 2 requires a
route's exemptions to be "enumerable by a test", `A01.Q3` asks whether the
exemption is listed in one, `A02` says to put a test on the anchored pattern,
`A06` step 4 says to write the test that proves the abuse case, `A06.Q9` asks
whether a test asserts the limit or the forbidden transition, and `NEST.4` and
`SPR.1` each name the obligation outright. Every one of those is an instruction
to the developer that nothing in the plugin fulfilled. This does.

The pipeline is one line with three endings: resolve the finding, find the
harness and take **the baseline**, triage whether the property is provable here
at all, write the test, run it — and only then, with the test red on screen,
ask the one question the skill asks. **A fix without a red test is a guess with
write permission**, so the fix is last and gated, never offered up front.

### Added

- **`appsec-test` skill and `/appsec-test`.** Takes the finding in whatever form
  the developer has it — a finding number from `SECURITY-REPORT.md`, a `TM-<nn>`
  from `STRIDE-REPORT.md`, a ref (`A01.Q2`, `NEST.3`, `E.Q3`), a ref pinned to a
  number (`A01.Q2#3`), a `file:line`, the claim in prose, or nothing at all —
  and resolves it to one **resolved item**: taxonomy, ref, location, claim,
  echoed back before a line is written. `#3` is a handle, never an identity:
  `api-secure-report` re-derives its numbering every run, so finding 3 today is
  a different defect tomorrow. Working with no report at all is the normal case
  rather than a fallback, because `/pr-appsec-review` writes no file to work
  from.
- **Three outcomes, and the positive control that makes them mean anything.**
  `RED` is the positive control passing and the attack assertion failing — the
  finding is real. `GREEN` is both passing — not reproducible here. `BROKEN` is
  the positive control failing — the test never reached the code. Every
  generated test carries both assertions, always: the attack, and the control
  asserting that the legitimate caller still succeeds down the same path.
  Without the control, red is indistinguishable from a route that 404s, a
  missing fixture or a 401 that never reached the handler, and `BROKEN`
  reported as `RED` is a fix applied to code nothing ran.
- **`GREEN` is the outcome nothing else in the plugin can produce.** The other
  three commands generate findings; this one is the only thing that can retire
  them, which is free calibration of the material against reality. It splits
  three ways and the run says which: the finding was wrong, the code was fixed
  since the report was written, or the test does not exercise the vulnerable
  path. Only the first two are false positives — the third is a bad test and
  gets reworked, not counted. On the first, the run offers a row in
  `SECURITY-NOTES.md` under `## Verified clean`, offered and never silent, so
  the next `/api-secure-report` reports it as known instead of re-litigating the
  same false positive every run.
- **The gate.** The fix runs from `RED` and from nowhere else. `GREEN` and
  `BROKEN` never reach it, `--fix` included, and there is no `--force` — for an
  unproven finding the existing path is already correct, which is to load
  `secure-coding` and fix it by hand. Verification is two runs: the security
  test must flip green, and the suite is compared against **the baseline** taken
  at harness discovery, before anything was written. Without that baseline, "the
  fix broke three tests" is unknowable — they may have been red all along. The
  test is never edited to make it pass; a test weakened until it is green is the
  vulnerability re-shipped with a green badge.
- **Not everything is provable, and the run says so instead of writing
  theatre.** Testability comes from whether the security property is observable
  at a boundary the project can drive, not from whether the item has a
  `file:line`: an absent rate limit is provable with no line to cite, a lockfile
  pin under `A03` never is however exact its line, and `A06.Q9` is *satisfied*
  by this skill rather than proved by it, since the existence of a test is not a
  runtime property. A test written to pass because there was nothing to assert
  is worse than no test — it is committed, and it reads as evidence.
- **The test is committed**, in deliberate contrast to the two reports, which
  are gitignored and overwritten on every run. `install.sh` adds no ignore line
  for it and CI still asserts `.gitignore` has not grown. A document is evidence
  until the next run replaces it; a test in the suite is evidence until somebody
  deletes it on purpose.
- **It consumes both bodies of material and owns neither**, the way
  `/pr-appsec-review` does. A resolved item is an OWASP finding or a STRIDE
  threat and never both: it cites `A01.Q2` or it cites `E.Q3`, and the generated
  test's header block carries only its own vocabulary. A missing root disables
  that input family loudly — both missing is a hard stop, because a test written
  from a remembered rule proves whatever it was written to prove, and then it is
  committed.
- **Harness knowledge lives in the new skill's references, not in
  `secure-coding/stacks/`.** `jest` and `supertest` over
  `Test.createTestingModule`; Pest or PHPUnit with `RefreshDatabase` and
  `actingAs` in `tests/Feature/`; JUnit 5 with `@SpringBootTest` and `MockMvc`
  in `src/test/java/`. Keeping it here is what lets the core stay
  language-agnostic and `CONTRIBUTING.md`'s rule — name the obligation, never
  the runner — stand where it was written. No runner detected is a full stop:
  the skill names what the project would have to install and writes nothing,
  because scaffolding a test framework is a supply-chain decision taken as a
  side effect of a security question.
- **Three checks in `scripts/check-ids.sh`** (17–19) holding the new skill's
  references to the same promises the others make: manifest rows resolve, no
  orphans, and every threat id it cites is real. Its OWASP ids were already
  covered by check 4, whose glob is `skills/*/references/`.

### Changed

- **This is the first skill with `Edit`, and the first that runs your project's
  code.** It is stated here rather than left to be discovered in a frontmatter:
  `/appsec-test` carries `Write` and `Edit`, and its `Bash` drives the project's
  own test suite. Two promises in `README.md` stop being true and are rewritten
  instead of left standing — *"three read-only commands"* and *"**Nothing is
  modified.** No command has `Edit`"*. The boundary is now explicit rather than
  absolute: three commands read, one writes, and it writes only after it has
  proved the thing it is fixing. *Nothing leaves your machine* stays true and
  stays in.
- **Both agents stay read-only, and neither is dispatched.** `/appsec-test` has
  no `Agent` in its frontmatter at all. `security-auditor` and `threat-modeler`
  each forbid running project code in their own definitions, and an agent
  defined never to run anything would either break that definition or quietly
  skip the suite — and a suite that silently did not run reports exactly what a
  passing one does.
- **`install.sh` installs the fifth skill.** No `.gitignore` line is added for
  it, because the file it produces is meant to be committed. CI asserts both
  halves of that: the directory lands, and the ignore file does not grow.

## [2.1.0]

A third command, and the first one that consumes both bodies of material at once:
`/pr-appsec-review` reviews a single change — a pull request, or a pair of
branches — asking the two questions a reviewer actually has. *Does this follow the
OWASP Top 10?* and *does this create risk under STRIDE?* They are answered in two
halves that run side by side and never mix: each cites only its own ids, and no
single item ever carries both vocabularies.

### Added

- **`pr-appsec-review` skill and `/pr-appsec-review`.** Takes a pull request URL,
  a `#number`, or `<branch> <base>` — `main`, `dev`, `staging`, whatever the
  project merges into. Resolves the merge-base, maps every hunk, classifies every
  changed file, and fans out over both existing read-only agents. **It writes
  nothing**: no `Write` in its frontmatter at all, and the review is printed to
  the terminal. The other two commands leave a document behind; this one leaves
  nothing in the branch it just reviewed.
- **`origin` on every item** — `introduced`, `aggravated` or `pre-existing`,
  decided by reading the same construct at the merge-base, not by guessing. It is
  what separates a review of a change from a scan of a repository: a pre-existing
  defect in touched code is still reported, in front of someone already editing
  that file, but it does not block the merge on its own.
- **A computed verdict.** *Bloqueia o merge* · *Requer atenção* · *Nada
  bloqueante*, from a rule table rather than a judgment, so two runs over the same
  change agree. It always names the item that decided it and states how much of
  the change was actually read.
- **Trust-boundary deltas.** The STRIDE half models only what the change moves,
  and reports separately when a boundary is added, moved, widened or narrowed —
  the highest-value output of that half, and the one thing a line-by-line review
  cannot produce.
- **Degraded halves are visible.** With only `secure-coding` installed the OWASP
  half runs alone; with only `app-stride-report`, the STRIDE half does. The header
  marks the missing half `✘`, **Limites** repeats it, and a half that did not run
  never reports "nothing found". Both missing is a hard stop.
- **Three checks in `scripts/check-ids.sh`** (14–16) holding the new skill's
  references to the same promises: manifest rows resolve, no orphans, and every
  threat id it cites is real. Its OWASP ids were already covered by check 4.

### Changed

- **Both agents accept `git diff` and `git merge-base`.** Still read-only, still
  no `Write` and no `Edit` — reading a change is reading. A git command that names
  a ref is fine; one that moves the working tree is not, and `gh pr checkout`,
  `git checkout`, `git switch`, `git stash` and `git merge` are named as forbidden.
- **Both agents take their return contract from the dispatch** instead of a
  hardcoded path, since the two consumers now specify different blocks. The PR
  review pastes each axis's contract inline rather than pointing an agent at its
  own `references/report-format.md` — that file names both taxonomies, and an
  agent that reads the other half's ids is an agent that will eventually cite one.
- **`install.sh` installs the third skill.** No `.gitignore` line is added for it,
  because it produces no file to ignore.

## [2.0.0]

The repository is now `claude-appsec` and so is the plugin: this is a set of code
security skills for Claude Code, of which the OWASP material is one. That rename
breaks the old install command, which is what makes this a major rather than the
minor the material alone would have been.

It also adds a second, independent body of material: STRIDE threat modelling. It
ships in the same plugin and shares nothing else — its own ids, its own files,
and a check that fails the build if the two taxonomies ever start citing each
other.

### Added

- **`app-stride-report` skill and `/app-stride-report`.** Decomposes the project into
  actors, processes, stores, flows and trust boundaries, draws the data-flow
  diagram in Mermaid, and enumerates STRIDE threats per element — each with its
  attack path, whether anything currently stops it, and what would. Writes
  `STRIDE-REPORT.md` to the project root.
- **`stride/` material** with stable ids `S.Q1`–`S.Q6`, `T.Q1`–`T.Q6`,
  `R.Q1`–`R.Q5`, `I.Q1`–`I.Q6`, `D.Q1`–`D.Q6`, `E.Q1`–`E.Q7`, under the same
  never-renumbered promise the OWASP ids carry.
- **`threat-modeler` agent.** Read-only like the auditor, with the one rule that
  had to differ: a threat whose mitigation is absent has no `file:line` to cite,
  so `evidence` is either the control that was found or an account of where the
  agent searched and found nothing. An unmitigated threat with no account of the
  search is discarded at consolidation.
- **The STRIDE-per-element matrix** decides the fan-out. An agent owning only
  stores and flows is never asked about spoofing or elevation, and its prompt
  does not carry those files.
- **Five checks in `scripts/check-ids.sh`.** The threat material is held to the
  same promises as the core — manifest rows resolve, no orphans, cited ids
  exist, numbering is contiguous — plus one it makes alone: no file under
  `skills/app-stride-report/` may cite an OWASP id, a stack id, or the rules skill.
  Independence is verified, not promised.

### Changed

- **Renamed to `claude-appsec`** — the repository, the marketplace and the
  plugin. The skills keep their names, so `skills/secure-coding/` and the
  `@.claude/skills/secure-coding/TRIGGER.md` line in your `CLAUDE.md` are
  untouched, and `install.sh --project` upgrades in place. Only the plugin route
  breaks:

  ```
  -  /plugin marketplace add joaovicdev/claude-owasp-10
  -  /plugin install secure-coding@claude-owasp-10
  +  /plugin marketplace add joaovicdev/claude-appsec
  +  /plugin install claude-appsec@claude-appsec
  ```

  Remove the old marketplace and add the new one. GitHub redirects the old
  repository URL, so `git clone` and the `curl` of `TRIGGER.md` keep working.
- **`/app-stride-report` reads what is already in the project.** `SECURITY-NOTES.md`
  supplies accepted risks; a `SECURITY-REPORT.md` from `/api-secure-report`
  marks the threats already confirmed in code — cited by that report's finding
  number, never by the taxonomy it uses. The two documents share a project, not
  a vocabulary.
- **`install.sh` installs skills and agents from two lists** instead of naming
  one agent in each of its two modes, and gitignores `STRIDE-REPORT.md` alongside
  `SECURITY-REPORT.md`.
- **Check 4 covers every consumer's `references/`**, not only the report format,
  so a new consumer citing a dead id fails the build the day it is added.

## [1.0.0]

First public release. The material itself is unchanged; everything here is about
making it installable by someone other than the author.

### Added

- **Two install routes from one source.** As a Claude Code plugin
  (`/plugin marketplace add joaovicdev/claude-owasp-10`), or vendored into a
  single repository with `./install.sh --project`, so a team gets the skill from
  a plain `git clone`.
- **`install.sh`** with `--project`, `--check` and a global mode. `--check`
  reports where the skill was found, which version, and whether the trigger is
  actually wired — the previous failure mode was silent.
- **`security-auditor` agent.** `/api-secure-report` used to ask `general-purpose`
  subagents not to edit anything. The auditor ships with no `Write` and no
  `Edit`, so read-only is enforced by the agent definition.
- **`TRIGGER.md`**, importable into a project's `CLAUDE.md` with a single `@`
  line, so the trigger tracks upstream instead of being pasted once and drifting.
- **`scripts/check-ids.sh`** — verifies that manifest rows resolve, cross
  references point at ids that exist, `report-format.md` cites only real review
  questions, review questions are contiguous, no shipped file hardcodes an
  install path, and the version agrees everywhere. Runs in CI.
- **`stacks/_TEMPLATE.md`** for contributing a stack the repository does not ship.

### Changed

- **Layout** is now `skills/secure-coding/` and `skills/api-secure-report/` as
  siblings. Previously `SKILL.md` sat at the repository root and
  `api-secure-report/` was nested *inside* the `secure-coding` skill.
- **No shipped file references an absolute install path.** `/api-secure-report`
  resolves the rules directory relative to its own location and passes that
  absolute path to its subagents. The hardcoded `~/.claude/skills/...` in the
  trigger and in three places in `api-secure-report/SKILL.md` used to resolve to
  nothing outside the author's machine — and the scan continued anyway.
- **`/api-secure-report` refuses to run without its rules** instead of producing
  a clean-looking report from a partial rule set.
- **`SECURITY-REPORT.md`** is offered to `.gitignore` rather than only warned
  about in the README. `install.sh --project` adds it up front.
- **README** is written for someone adopting the skill rather than for the author.

[2.2.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v2.2.0
[2.1.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v2.1.0
[2.0.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v2.0.0
[1.0.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v1.0.0
