# Diff discovery

Resolving the change is the step that must be exact. A wrong base makes commits
someone else already merged look like this author's work, and a missed file is a
file the review silently claims is untouched.

Every recipe here is read-only. Nothing in this file modifies the working tree,
and the one command that writes anything at all — a fetch, which writes a ref —
is asked for before it runs.

The step produces exactly this, and the rest of the skill runs on nothing else:

```
HEAD_REF @ <sha>   BASE_REF @ <sha>   MERGE_BASE <sha>
<path> | +<added>/-<removed> | <classification> | <hunk ranges on the new side>
```

## 1. Resolve the target

Try these in order and stop at the first that resolves.

```bash
# no target given — the branch you are standing on
git rev-parse --abbrev-ref HEAD

# a target was given: is it a ref? this wins, always
git rev-parse --verify --quiet "<target>^{commit}"

# not a ref — is it a pull request? accept a URL, #123, or a bare number
gh pr view "<target>" --json number,title,url,headRefName,baseRefName,headRefOid,author,isCrossRepository
```

A ref beats a pull request on ambiguity. A branch literally named `123` is a
branch, and reviewing the wrong thing quietly is the worst outcome available
here.

If `gh` is missing or unauthenticated, say so plainly and ask for the local pair
instead — `/pr-appsec-review <branch> <base>`. Do not guess a number, and do not
fall back to reviewing the current branch: the user named a target.

## 2. Resolve the base

For a pull request, the base is `baseRefName` from the JSON above — never
guessed.

Otherwise, in order:

```bash
# the base the user passed, if any
git rev-parse --verify --quiet "<base>^{commit}"
# the remote's declared default
git symbolic-ref --quiet refs/remotes/origin/HEAD        # -> refs/remotes/origin/main
# fallbacks, first that exists
for b in main master develop dev; do git rev-parse --verify --quiet "$b"; done
```

State the base in the header. If it had to be guessed from the fallback list,
say which and put it under **Premissas** — a review against the wrong base is
wrong in a way that reads as confident.

## 3. Merge-base, and why three dots

```bash
MERGE_BASE=$(git merge-base "<base>" "<head>")
git diff --merge-base "<base>" "<head>" --numstat
```

Two dots (`git diff base head`) shows the difference between two tips, so
everything merged into the base since this branch forked appears as if this
change removed it. Three dots — which `--merge-base` makes explicit — shows what
*this branch did*. That is the only question a PR review is asking.

Put all three shas in the header. A review that cannot be reproduced six commits
later is an opinion, not a review.

Reading the base side of a file is `git show`, and it carries one shell trap
worth naming, because deciding `origin` depends on it:

```bash
git show "${MERGE_BASE}:src/orders/orders.controller.ts"   # correct
git show "$MERGE_BASE:src/orders/orders.controller.ts"     # zsh: bad substitution
```

Brace the variable, always. In zsh a `:` immediately after `$NAME` opens a
modifier, so the command dies before git ever sees it — and it dies with a shell
error, which is easy to misread as "the file is not there".

A file genuinely absent at the base fails differently, with `exists on disk, but
not in <sha>`. That is not an error, it is the answer: `origin: introduced`.

## 4. The file list and the hunk map

```bash
# the spine of the review — path, added, removed
git diff --merge-base "<base>" "<head>" --numstat

# rename and delete detection, so a moved file is not read as new
git diff --merge-base "<base>" "<head>" --name-status -M

# hunk ranges with zero context — the exact new-side lines this change owns
git diff --merge-base "<base>" "<head>" --unified=0 -- "<path>" | grep '^@@'
```

`@@ -28,6 +28,12 @@` means: on the new side, 12 lines starting at line 28. Those
ranges are what goes into a subagent prompt and what fills the *Onde no PR* line
of a finding. `-` on the new side (`+28,0`) is a pure deletion — it still matters
(a removed guard is a finding), and it is reported against the base-side line.

`--numstat` prints `-` for both counts on a binary file. Binaries are not read:
list them, and say so under **Limites**.

## 5. The remote-head problem

The diff can be read without the head commit. **The context cannot** — and this
skill judges changed lines in the context of the file they land in.

```bash
git cat-file -e "<headRefOid>^{commit}"     # is the head already local?
```

If it is not:

1. **Ask before fetching.** `git fetch origin pull/<n>/head` is network access
   and writes a ref into the repository. It is the only mutating command this
   skill will ever run, and it runs only on a yes.
2. If the user declines, fall back to **diff-only** review: `gh pr diff <target>`
   gives the patch, and every agent is told it is judging hunks without
   surrounding context. Say in the header that the run is diff-only, and put it
   at the top of **Limites** — confidence is materially lower, especially for
   access control, where the answer usually lives outside the hunk.

**Never `gh pr checkout`, `git checkout`, `git switch`, `git stash`, or
`git merge`.** They move the user's working tree. A review is not worth a
surprise in someone's uncommitted work.

## 6. Classify each file

The classification routes the fan-out. One file can carry more than one label.

| Label | Matches | Sends work to |
|---|---|---|
| `route` | controllers, handlers, routers, resolvers, gateways, consumers | OWASP per-module, STRIDE process elements |
| `authz` | guards, policies, filters, middleware, decorators, interceptors | OWASP per-module + `auth` global, STRIDE `E` and `S` |
| `data` | repositories, queries, ORM entities, migrations, schemas | OWASP per-module, STRIDE store elements |
| `config` | bootstrap/entry file, env handling, CORS, headers, TLS, feature flags | OWASP `config` global |
| `deps` | `package.json`, lockfiles, `composer.json`, `pom.xml`, `build.gradle`, `Dockerfile`, CI workflows | OWASP `deps` global |
| `auth` | login, registration, reset, MFA, session, token, key, password paths | OWASP `auth` global, STRIDE `S` |
| `integration` | outbound HTTP clients, webhook receivers, queue producers, storage clients | OWASP `design` global, STRIDE flow elements |
| `test` · `doc` | tests, fixtures, markdown, changelogs | neither — listed in the table, never fanned out |

```bash
# a fast first pass over the changed paths alone
git diff --merge-base "<base>" "<head>" --name-only | rg -i \
  'controller|handler|router|resolver|gateway|guard|polic|middleware|filter|interceptor|repositor|entit|migration|schema|main\.|bootstrap|config|env|package(-lock)?\.json|composer|pom\.xml|build\.gradle|Dockerfile|\.github/workflows|auth|login|token|session|password|webhook|client'
```

The path is a lead, not the answer. A file named `utils.ts` that builds a SQL
string is `data`; confirm by reading, the same way a grep signal is confirmed.

Files labelled `test` or `doc` still appear in the *Arquivos alterados* table —
enumerating them is how the reader knows they were seen and skipped, rather than
missed.

## 7. Describe what changed

Each row of the table needs one short phrase — *"novo handler `GET /orders/:id`"*,
*"guard removido"*, *"campo `email` adicionado à resposta"*. Derive it from the
hunks, not from the commit message: a commit message is a claim about the change,
and this review is about the change.

For a `route` file, name the routes the change adds or alters, using the
enumeration recipes in the sibling skill's `route-discovery.md` if the stack has
one. A new route is the highest-value line in the whole table.

## Cross-check

Whatever produced the list, before fanning out:

1. **Count.** The number of rows must equal
   `git diff --merge-base <base> <head> --name-only | wc -l`. A gap means a
   rename, a deletion or a submodule fell out of the list.
2. **Sample.** Open two or three changed files and confirm every hunk in them is
   in the map, with the right line numbers on the new side.
3. **Declare.** Anything that could not be read — a head that was never fetched,
   a binary, a generated file, a submodule bump, a file the change deletes — is
   written down now and reproduced under **Limites**. An unread file must never
   read as a clean one.
