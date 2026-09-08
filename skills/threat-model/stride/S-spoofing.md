# S — Spoofing

**ID:** `S` · **Property violated:** Authentication · **Applies to:** actor, process

## What this category is

Someone or something is accepted as an identity it is not. Spoofing is answered
before authorization is: a system that cannot tell who is calling cannot decide
what the caller may do, and every access rule below it is decoration.

## How it shows up in a backend

- A token accepted without verifying the signature, the issuer, the audience, or
  the expiry — any one of those missing makes the token forgeable by whoever
  knows the shape.
- The identity read from something the caller controls: an `X-User-Id` header, a
  `userId` in the body, a query parameter a gateway was supposed to overwrite
  and does not.
- An internal call trusted because it arrived on the internal network, so
  anything that reaches that network is every service at once.
- A webhook receiver that acts on the payload without verifying the sender's
  signature, so the sender is whoever posts to the URL.
- One shared static key for every client, so revoking one revokes all and
  attributing an action to one is impossible.
- A scheduler, worker, or migration running as an identity nobody authenticated,
  because nothing in that pipeline ever asks.
- A reset token, invitation code, or session id drawn from a non-cryptographic
  source or a short alphabet, so an identity is reachable by guessing instead of
  by stealing.

## Which elements it applies to

| Element | Applies | Why |
|---|---|---|
| Actor | yes | the actor is exactly the thing being claimed |
| Process | yes | a process can impersonate another, or be impersonated |
| Flow | no | a forged flow is a spoofed element at one of its ends |
| Store | no | a store presents no identity of its own |

## Threat questions

- **S.Q1** — Does every actor reaching this process prove who it is before the
  process acts on its behalf?
- **S.Q2** — Can a caller present a credential the system did not issue and have
  it accepted — unverified signature, unchecked issuer or audience, or an
  algorithm the verifier reads from the token instead of pinning?
- **S.Q3** — Can one process impersonate another, through an unauthenticated
  internal call, a shared static secret, or a header the caller can set?
- **S.Q4** — Is any identity taken from a value the caller controls rather than
  from a verified credential?
- **S.Q5** — Can an authenticated caller act as an identity other than the one it
  authenticated as?
- **S.Q6** — Are the credentials this system issues — session tokens, reset
  links, invitations, API keys — drawn from a cryptographically secure source,
  long enough that guessing is not a path to an identity, and bounded by an
  expiry and a use count?

## Mitigation patterns

- One place decides identity, and every entry point — HTTP, queue, scheduler,
  websocket — goes through it. A second path that authenticates differently is a
  second implementation to keep correct forever.
- Verify the whole credential: signature, issuer, audience, expiry, and an
  algorithm the verifier pins rather than accepts from the token.
- Per-client credentials, revocable one at a time, so an action attributes to one
  client and revocation costs one client.
- Sign what crosses a boundary and verify it on arrival, asynchronous work
  included: the identity that queued a job travels with the job or is gone.
- Network position is not an identity. An internal caller authenticates too.
- Issue credentials from the platform's cryptographic random source, never the
  general-purpose one, with enough entropy that guessing is not a strategy — and
  give every one of them an expiry and a single use.

## Grep signals

```bash
rg -ni 'verify\(|decode\(|jwt\.|jsonwebtoken|parseToken'
rg -ni "algorithms?\s*[:=]|['\"]none['\"]|verify\s*[:=]\s*false"
rg -ni 'x-user|x-userid|x-auth|req\.headers\[|getHeader\('
rg -ni 'webhook|signature|hmac|x-hub-signature|x-signature'
rg -ni 'internal|trusted|localhost|127\.0\.0\.1'
rg -ni 'Math\.random|rand\(\)|mt_rand|uniqid|new Random\(|shuffle'
```
