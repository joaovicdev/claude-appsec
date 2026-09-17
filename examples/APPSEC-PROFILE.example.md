<!--
  A real /appsec-profile run against examples/vulnerable-app/, reproduced here as
  the worked example the README links. To regenerate:

      /appsec-profile pt-BR examples/vulnerable-app

  Note what this fixture produces: almost every claim is NEGATIVE, and
  '## Public by design' is empty. That is the design working, not a thin run — an
  unguarded route is a finding, never an exemption, so nothing gets claimed here
  that would silence one. The whole value of this file for this project is that it
  makes later findings sharper.

  MOVED FOR 3.0.0 — this file now lands at appsec/profile.md instead of
  .claude/appsec-profile.md. Its claim ids and format are unchanged.
  Regenerate with the recipe above before tagging 3.0.0.
-->

# vulnerable-app — appsec architecture profile

**Stack:** NestJS 10 (TypeORM `DataSource`, @nestjs/jwt) · **Scope:** examples/vulnerable-app
**Generated:** 2026-09-12 by `/appsec-profile` · **Commit:** `1d67aba`
**Claims:** 7 · **Not claimed:** 6 · **Stale:** 0

> Cada claim abaixo remove uma pergunta de toda execução seguinte. Uma claim errada
> não gera um achado errado — ela não gera achado nenhum. Leia, corrija, apague o
> que você não reconhece: apagar uma claim devolve a pergunta. Uma claim sem a linha
> **Does not apply to:** não remove nada.
>
> Os títulos de seção e os rótulos dos campos ficam em inglês de propósito — é por
> eles que uma execução recorta este arquivo.

## Module map

| Module | Directory |
|---|---|
| auth | `src/auth/` |
| users | `src/users/` |
| orders | `src/orders/` |
| common | `src/common/` |

## Trust boundaries

| Boundary | What changes when it is crossed | Inner side |
|---|---|---|
| internet → app | a entrada deixa de ser confiável; o chamador é desconhecido até `JwtGuard`, que não cobre todas as rotas | AuthController, UsersController, OrdersController, `GET /docs` |
| app → banco | a aplicação apresenta a própria credencial; o banco confia em quem pergunta | `DataSource` (TypeORM) |
| app → terceiro | a URL de saída é escolhida pelo chamador | `axios` em `src/orders/orders.controller.ts:31` |

## Authentication

### P1 — A identidade é provada por um JWT verificado dentro do guard

- **Mechanism:** `JwtGuard` verifica o token do header e anexa o payload em `request.user`; não há strategy nem módulo de auth separado.
- **Evidence:** `src/auth/jwt.guard.ts:5` — `class JwtGuard implements CanActivate`
- **Applies to:** apenas as rotas cujo controller declara `@UseGuards(JwtGuard)` — hoje `users` e `orders`.
- **Does not apply to:** `AuthController` inteiro (`src/auth/auth.controller.ts:6`) e `GET /docs` (`src/main.ts:11`), que não passam pelo guard. O guard prova um token, não uma permissão: não há checagem por objeto em nenhum lugar.

## Authorization

### P2 — Não existe guard global; a autorização é declarada por controller

- **Mechanism:** `AppModule` não registra `APP_GUARD`. A proteção é opt-in, controller por controller, via `@UseGuards(JwtGuard)`.
- **Evidence:** `src/app.module.ts:7` — `@Module({` sem `providers: [{ provide: APP_GUARD`; os dois opt-ins em `src/orders/orders.controller.ts:8` e `src/users/users.controller.ts:6`
- **Applies to:** nada globalmente. Esta claim não isenta rota alguma.
- **Does not apply to:** toda rota de um controller que não declare o guard, e toda rota acrescentada a um controller novo. Um controller sem `@UseGuards` é um achado real aqui, não um falso positivo.

## Tenancy and data scoping

### P3 — Não existe mecanismo global de escopo por tenant

- **Mechanism:** nenhum. Cada handler monta o próprio `where`. Não há repositório-base, não há middleware de ORM, não há contexto por requisição.
- **Evidence:** `src/orders/orders.controller.ts:19` — `tenantId: user.tenantId`, a **única** ocorrência de escopo por tenant no repositório
- **Applies to:** nada. Esta claim não isenta nenhuma consulta.
- **Does not apply to:** toda consulta do projeto — `getRepository(...).findOne` (`src/orders/orders.controller.ts:14`, `src/users/users.controller.ts:12`), `getRepository(...)` solto (`src/users/users.controller.ts:17`), `DataSource.query(...)` (`src/auth/auth.controller.ts:13` e `:23`, `src/orders/orders.controller.ts:24`), e qualquer método acrescentado depois desta data. Um lookup sem `tenantId` no predicado é um achado real.

## Public by design

Rota que não está nesta tabela não é pública: é uma rota sem guard, e isso é um
achado. Só entra aqui o que o código **declara** — um `@Public()`, um
`permitAll()`, uma exclusão no registro do guard.

| Route | Declaration | Why | Evidence |
|---|---|---|---|
| — | — | — | nenhuma declaração de exposição pública no repositório |

## Input validation

### P4 — Não existe validação global de entrada

- **Mechanism:** nenhum. `main.ts` não chama `useGlobalPipes`, não há `ValidationPipe`, e `class-validator` não está entre as dependências.
- **Evidence:** `src/main.ts:6` — `NestFactory.create(AppModule, ...)` sem `useGlobalPipes`
- **Applies to:** nada.
- **Does not apply to:** todo handler que lê `@Body()`, `@Query()` ou `@Param()`. O corpo chega ao handler exatamente como veio da rede; campos desconhecidos não são removidos nem rejeitados.

## Errors and logging

### P5 — O filtro de exceções existe como classe e nunca é registrado

- **Mechanism:** `AllExceptionsFilter` está implementado, mas `main.ts` não chama `useGlobalFilters` e `AppModule` não o registra como `APP_FILTER`. **Declarado não é aplicado.**
- **Evidence:** `src/common/all-exceptions.filter.ts:4` — `class AllExceptionsFilter`; ausente em `src/main.ts`
- **Applies to:** nada em tempo de execução. O handler de erro padrão do framework é o que responde.
- **Does not apply to:** toda rota. O mesmo vale para `RequestLogger`: está em `providers` (`src/app.module.ts:9`) mas `AppModule` não implementa `configure()`, então o middleware nunca entra na cadeia.

## Configuration and secrets

### P6 — Um segredo ausente não impede o boot: há default no código

- **Mechanism:** a configuração vem de `process.env` direto, sem `ConfigModule` e sem schema de validação. O segredo do JWT cai num literal quando a variável não existe.
- **Evidence:** `src/auth/jwt.guard.ts:13` — `process.env.JWT_SECRET || 'dev-secret-change-me'`
- **Applies to:** todo consumo de configuração no projeto.
- **Does not apply to:** nada — não há caminho que falhe no boot. Também em `src/main.ts:13` (`process.env.PORT || 3000`), que é benigno e está aqui só para mostrar que o padrão é o mesmo.

### P7 — CORS é permissivo e a documentação da API é servida sem guard

- **Mechanism:** `enableCors({ origin: true, credentials: true })` reflete qualquer origem com credenciais; o Swagger é montado em `/docs` no bootstrap.
- **Evidence:** `src/main.ts:8` — `enableCors`; `src/main.ts:11` — `SwaggerModule.setup('docs'`
- **Applies to:** toda requisição de navegador, e a rota `GET /docs`.
- **Does not apply to:** rotas chamadas fora do navegador, onde CORS não é a barreira. `/docs` não aparece em `## Public by design` porque nada no código declara que essa exposição é intencional.

## External systems

| System | Reached by | Evidence |
|---|---|---|
| qualquer host escolhido pelo chamador | `axios.get(body.url)` | `src/orders/orders.controller.ts:31` |
| banco relacional | `DataSource` (TypeORM) | `src/orders/orders.controller.ts:14` |

## Test harness

| Fact | Value, quoted from the project |
|---|---|
| Command that runs the suite | nenhum — `package.json` declara só `"start": "nest start"` |
| Where tests live | não há diretório de testes |
| How the app is booted for a test | — |
| How an authenticated request is built | — |

Sem runner, o comando de teste para em *"no runner detected"* sem gastar uma passada
de descoberta. Registrar a ausência é o que economiza essa passada.

## Not claimed

Every question the probes could not answer, with the search that failed. This
section suppresses nothing — it sharpens what follows.

- **Rotas sem guard e sem declaração de intenção:** `POST /auth/login` e `POST /auth/reset` (`src/auth/auth.controller.ts:6`), `GET /docs` (`src/main.ts:11`) — `rg '@Public\(\)|@SkipAuth|@AllowAnonymous' src/`, nenhum hit. Nada no código diz que a exposição é intencional, então são achados, não isenções.
- **Autorização por objeto:** `rg 'ability|casl|policy|@Roles\(' src/`, nenhum hit. Não há checagem de dono em nenhum handler que recebe um id.
- **Rate limiting:** `rg 'Throttler|@Throttle|rate.?limit' src/`, nenhum hit.
- **Configuração da `DataSource`** (credenciais, TLS, host) está fora deste repositório: nada em `src/` a constrói.
- **Como a aplicação é implantada** — processo, rede, quem opera — não é observável daqui.
- **`scripts/setup.js`,** referenciado por `"postinstall"` em `package.json:6`, não existe no repositório. Um hook de instalação que não se pode ler não é um hook que se pode descrever.

## Stale

Nenhuma. Todas as âncoras acima resolvem no commit indicado no cabeçalho.

## Notes

Este projeto é uma fixture deliberadamente vulnerável, usada pelos exemplos deste
repositório. Não a corrija: os exemplos dependem dos defeitos.

<!-- appsec-profile · schema 1 · ids issued: P1-P7 · retired: none · from 1d67aba on 2026-09-12 -->
