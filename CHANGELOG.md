# Changelog

Versions follow [SemVer](https://semver.org/). For this repository that means:

- **Major** — a stable id is removed or its meaning changes, or an install layout
  breaks. The `IDs never get renumbered` promise makes this rare by design.
- **Minor** — new review questions, a new category or stack file, new tooling.
  Additive: a consumer written against the previous minor keeps working.
- **Patch** — wording, grep signals, fixes that change no id.

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

[2.1.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v2.1.0
[2.0.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v2.0.0
[1.0.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v1.0.0
