# E — Elevation of Privilege

**ID:** `E` · **Property violated:** Authorization · **Applies to:** process

## What this category is

An actor does something the design never meant them to do. Spoofing is being
someone else; elevation is being yourself and reaching further than yourself is
allowed. It is the category with the worst outcomes and the quietest symptoms —
nothing crashes, nothing errors, the operation simply succeeds.

## How it shows up in a backend

- Authentication mistaken for authorization: a guard proves who the caller is,
  and nothing after it decides what that caller may reach.
- A record fetched by the caller's identifier and then checked — or not checked —
  after the fetch, so ownership is an afterthought and often an omission.
- Two paths to the same resource with different rules: the REST handler checks,
  the batch endpoint does not; the read is scoped, the export is not.
- A role, scope, tenant, or permission the caller can influence — sent in the
  registration payload, editable through the profile update, inferred from a
  header.
- An internal element trusting a request because it came from inside, so
  reaching any element inside the boundary is reaching all of them.
- Admin, management, or debug surfaces protected by being unlinked rather than by
  being authorized.
- A process running with far more privilege than its work requires — database
  superuser, cloud role with wildcards, container as root — so any foothold in it
  starts from the top.
- Authorization spread across handlers, so the answer to "who may do this" is
  assembled from a dozen places and no one of them is wrong on its own.
- An outbound request whose destination the caller chooses, so the process's
  network position — internal services, cloud metadata, the loopback interface —
  is borrowed by whoever can reach the endpoint.

## Which elements it applies to

| Element | Applies | Why |
|---|---|---|
| Actor | no | the actor gains privilege; the process grants it |
| Process | yes | the process is where the decision is made or skipped |
| Flow | no | a flow carries the request; it decides nothing |
| Store | no | a store enforces its own grants, modeled as tampering |

## Threat questions

- **E.Q1** — What is the least privilege this process needs, and what does it
  actually run with — database grants, cloud role, filesystem, container user?
- **E.Q2** — Is the authorization decision made in the same place for every path
  that reaches this resource, or can one path skip it?
- **E.Q3** — Is the caller's entitlement enforced inside the lookup, or fetched
  first and checked afterwards — or not checked at all?
- **E.Q4** — Can a caller set or influence their own role, scope, tenant, or
  permission, at registration, at update, or through a header?
- **E.Q5** — Does an element inside the boundary trust a request purely because it
  arrived from inside?
- **E.Q6** — Can an actor reach an admin, management, or debug surface that is
  protected only by being undocumented?
- **E.Q7** — Can the caller choose where this process sends a request, connects,
  or loads from, so the process's network position or credentials are used on the
  caller's behalf?

## Mitigation patterns

- Deny by default at the boundary. Access is granted per route, never assumed;
  a route that forgets to declare its rule gets the strictest one, not none.
- The entitlement belongs in the query predicate, so a resource the caller may
  not have is not returned rather than returned and then refused.
- One authorization component both paths call. Two implementations of the same
  rule diverge, and the divergence is the vulnerability.
- Role, scope and tenant are assigned by the server from a source the caller
  cannot write. They are never accepted as input, at any endpoint.
- Every element authenticates and authorizes its callers, internal ones
  included. Inside is a location, not a permission.
- Grant each process only what it uses, and separate credentials per process so
  a foothold in one is not a foothold in all.
- Outbound destinations come from an allowlist. A caller may choose among hosts
  you listed; it may never supply one. Re-check the resolved address after DNS
  and refuse loopback, link-local and private ranges.
- A test per rule that asserts the forbidden case is refused. A rule with only
  happy-path tests is a rule that will be removed and nobody will know.

## Grep signals

```bash
rg -ni 'guard|policy|authorize|can\(|ability|permission|@Roles|hasRole'
rg -ni 'isAdmin|is_admin|role|scope|tenant|organization_?id|account_?id'
rg -ni 'findOne|findById|findByPk|get\(id|where.*\bid\b'
rg -ni 'GRANT|superuser|rds_superuser|"Action": "\*"|Resource": "\*"'
rg -ni 'USER root|runAsUser|privileged: true|--privileged'
rg -ni 'admin|internal|management|/debug|actuator' -g '!*.md'
rg -ni 'public|permitAll|AllowAnonymous|@Public|skipAuth'
rg -ni 'axios\.(get|post)\(|fetch\(|HttpService|RestTemplate|requests\.(get|post)\('
```
