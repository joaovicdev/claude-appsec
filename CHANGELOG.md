# Changelog

Versions follow [SemVer](https://semver.org/). For this repository that means:

- **Major** — a stable id is removed or its meaning changes, or an install layout
  breaks. The `IDs never get renumbered` promise makes this rare by design.
- **Minor** — new review questions, a new category or stack file, new tooling.
  Additive: a consumer written against the previous minor keeps working.
- **Patch** — wording, grep signals, fixes that change no id.

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

- **`threat-model` skill and `/threat-model`.** Decomposes the project into
  actors, processes, stores, flows and trust boundaries, draws the data-flow
  diagram in Mermaid, and enumerates STRIDE threats per element — each with its
  attack path, whether anything currently stops it, and what would. Writes
  `THREAT-MODEL.md` to the project root.
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
  `skills/threat-model/` may cite an OWASP id, a stack id, or the rules skill.
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
- **`/threat-model` reads what is already in the project.** `SECURITY-NOTES.md`
  supplies accepted risks; a `SECURITY-REPORT.md` from `/api-secure-report`
  marks the threats already confirmed in code — cited by that report's finding
  number, never by the taxonomy it uses. The two documents share a project, not
  a vocabulary.
- **`install.sh` installs skills and agents from two lists** instead of naming
  one agent in each of its two modes, and gitignores `THREAT-MODEL.md` alongside
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

[2.0.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v2.0.0
[1.0.0]: https://github.com/joaovicdev/claude-appsec/releases/tag/v1.0.0
