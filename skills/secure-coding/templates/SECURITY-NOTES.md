# Security notes — <project>

Per-project security state. The rules live in the `secure-coding` skill; this
file records only what is true **here**. Read alongside the skill.

> These entries rot. Treat them as hints and re-verify before relying on one.
> Any change that closes an `OPEN` item updates its line in the same commit.

**Stack:** <framework, ORM, auth> · **Last reviewed:** <YYYY-MM-DD>

## Open

| ID | Ref | Finding | Impact if it matters |
|---|---|---|---|
| O-1 | `A02.Q1` | <what is wrong, in one line> | <what an attacker gets> |

## Accepted risks

Each entry states the precondition that would force a revisit. An accepted risk
without a revisit condition is an ignored risk.

| ID | Ref | Risk | Why accepted | Revisit when |
|---|---|---|---|---|
| R-1 | `A08.Q1` | <risk> | <reason> | <the condition that invalidates the reason> |

## Verified clean

Worth recording so a reviewer does not re-derive it — with the date, because it
expires.

| Ref | Checked | Date |
|---|---|---|
| `A05.Q1` | <what was checked> | <YYYY-MM-DD> |

## Project-specific rules

**Prescriptive** rules only — an in-house pattern to copy, a file nobody should
touch without understanding why, a boundary that is load-bearing and why.

Descriptive architecture — where the guard is, how a query gets scoped, what is
public on purpose — belongs in `appsec/profile.md`, which `/appsec-profile`
generates and every command reads. The two files answer different questions: this
one records what is **wrong** and changes on every run; the profile records what
**exists** and changes when the architecture does.
