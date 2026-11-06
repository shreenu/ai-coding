---
name: "ai-coding-challenge"
description: "Build full-stack AI coding challenges fast and accurately: SOLID folders, readable code, shadcn UI, Docker/AWS-ready backend, tests, OTel zero-code observability, security, LLM evals. Use for any coding challenge or full app build."
---

# AI-Assisted Coding Challenge

Goal: ship a **working, testable, readable** app **fast**, without cutting corners on security, observability, or evals.

Speed comes from: checking the machine first, installing only what is needed, a short plan, few interruptions, a working vertical slice early, and tests written alongside code. Accuracy comes from: running the code before saying it's done.

---

## 0. Check the machine first (1 minute, before any install)

Docker may or may not exist on the local/dev machine. Never assume it. Run quick checks and pick the run mode:

```
node -v            pnpm -v  /  npm -v
python3 --version  uv --version
docker --version   docker info   # docker info confirms the daemon is actually running
psql --version
aws --version      # only if AWS is needed
```

- **Docker mode:** Docker is installed AND the daemon is running -> use docker compose for Postgres + OTel collector + Jaeger.
- **Native mode:** no Docker (or daemon not running) -> run app processes directly, use the fast local alternatives below. Do not install Docker and do not stop to ask about it.

Log the detected tools and chosen mode in `docs/DECISIONS.md`.

### Install only what is needed

Every install costs time. Before adding a package, ask: is it used by code I am writing now?

- Use tools already on the machine: pnpm if present, else npm; `uv` if present, else pip in a venv. Don't install a new package manager just to save seconds.
- Python: prefer `uv` (much faster than pip) when available.
- Add **only the shadcn components actually used** (`npx shadcn@latest add button card ...`), not the whole set.
- Call the Bedrock/LLM SDK directly for simple calls. Add LangGraph/LangChain only for real multi-step agent flows.
- Playwright: skip unless UI flow tests are required (browser download is slow).
- OTel Python: do **not** run `opentelemetry-bootstrap -a install` blindly; install only the instrumentations for libraries actually used (e.g. fastapi, httpx, sqlalchemy, botocore).
- No global installs. No packages "for later".

---

## 1. Human-in-the-loop: when to stop and ask

Ask the user ONLY at these gates. Decide everything else yourself and log it in `docs/DECISIONS.md` (one line: decision + why).

**Stop and ask when:**
1. **Plan checkpoint (once, at start)** - show the 1-page plan (Section 2) and wait for OK.
2. **Requirements conflict or are unclear** in a way that changes the design (not small details).
3. **Auth or data storage choice** is not given in the challenge (e.g., Cognito vs JWT, Postgres vs DynamoDB).
4. **Anything irreversible or costly** - deleting data/files, paid cloud resources, real credentials.
5. **Scope change** - a feature turns out much bigger than expected.

**Do NOT ask about:** run mode (Docker vs native), naming, folder layout, library versions, UI details, test structure, minor patterns. Pick the sensible default and move on.

When asking, give 2-3 options with a recommended one, so the user can answer in one word.

---

## 2. Plan first (keep it to ~1 page)

Write `docs/PLAN.md` with short bullets:

1. Problem & goal (what "done" means)
2. FR - functional requirements
3. NFR - performance, scale, security, availability
4. User flow
5. Data flow
6. System design (architecture diagram in Mermaid)
7. Data model & API contracts (endpoints, request/response shapes)
8. Tech stack + run mode (Docker or native)
9. Coding patterns used
10. Security summary
11. Test, eval & observability plan

Then **stop for the plan checkpoint**.

---

## 3. Same code for local and prod

The exact same code runs locally and on AWS. Only **environment variables** change (12-factor).

- No `if (env === 'local')` branches in business logic.
- Differences are chosen by config at one wiring point (DI module / factory), e.g.:
  - `DATABASE_URL` -> local DB or RDS
  - `LLM_PROVIDER=bedrock|mock` -> real or mock LLM (mock only when no AWS creds, and in tests)
  - `OTEL_TRACES_EXPORTER=otlp|console` -> collector or console
  - `AUTH_MODE` / issuer URL -> local JWT secret or Cognito
- `.env.example` documents every variable; `.env.local.example` and `.env.prod.example` show the two value sets.
- Same start command everywhere (e.g. `node dist/main.js` / `uvicorn app.main:app`). Docker just wraps that command.
- Frontend: same build; API URL comes from `VITE_API_URL`.

---

## 4. Default tech stack

Use what the challenge asks for. If not specified:

- **Frontend:** React + Vite + TypeScript, **shadcn/ui**, **lucide-react** icons, Tailwind, TanStack Query for API calls
- **Backend:** NestJS (TypeScript) or FastAPI (Python) - pick based on the challenge (Python if heavy AI/ML)
- **AI/LLM:** AWS Bedrock SDK; LangGraph only for multi-step agents
- **DB:** Postgres dialect everywhere (RDS on AWS). Locally:
  - Docker mode -> Postgres container
  - Native + Postgres installed -> local Postgres
  - Native, no Postgres, Node -> **PGlite** (Postgres in-process, npm install, no server) with **Drizzle ORM** (supports both node-postgres and PGlite; only the driver line in `db/client.ts` differs, picked by `DATABASE_URL`)
  - Native, no Postgres, Python -> **SQLite** via SQLAlchemy; keep SQL portable (no Postgres-only features) so only `DATABASE_URL` changes
- **Tests:** Vitest (TS) or pytest (Python); Playwright only if required
- **Validation:** zod / class-validator / pydantic

---

## 5. Code structure (SOLID, many small files)

Never put logic in flat files. Split by **feature**, then by **responsibility**. One class/main function per file. Avoid empty abstractions - every file must earn its place.

**Backend (NestJS example):**
```
backend/
  src/
    main.ts
    app.module.ts
    config/              # env loading + validation (one place)
    db/
      client.ts          # picks driver from DATABASE_URL (only place that knows)
      schema/
      migrations/
    common/
      filters/           # global error handler
      guards/            # auth guards
      interceptors/
      pii/               # PII redaction helpers
    modules/
      <feature>/
        <feature>.controller.ts   # HTTP only, no business logic
        <feature>.service.ts      # business logic
        <feature>.repository.ts   # DB access only
        dto/                      # request/response shapes + validation
        interfaces/               # contracts for DI (dependency inversion)
        __tests__/
    llm/
      llm.provider.interface.ts   # interface - swap Bedrock/mock
      llm.provider.factory.ts     # picks provider from LLM_PROVIDER
      bedrock.provider.ts
      mock.provider.ts
      prompts/                    # prompts as separate files, versioned
  evals/
  test/
  Dockerfile
```
For FastAPI use the same idea: `app/api/routes`, `app/services`, `app/repositories`, `app/schemas`, `app/db`, `app/llm`, `app/core` (config, security).

**Frontend:**
```
frontend/src/
  components/ui/          # shadcn components (only the ones used)
  components/layout/
  features/<feature>/
    components/
    hooks/
    api/                  # API calls for this feature
    types.ts
  lib/                    # utils, api client
  pages/
```

**SOLID in practice:**
- S: controller = HTTP, service = logic, repository = data
- O: add new providers/strategies by adding a file, not editing a switch
- L: mock and real providers are fully swappable
- I: small interfaces (`LlmProvider`, `UserRepository`), not one giant one
- D: services depend on interfaces, injected via DI

---

## 6. Readable code

The reviewer must understand the code quickly.

- No clever one-liners, nested ternaries, or long chained calls. Use clear steps with named variables.
- Functions short (~30 lines max), one job each.
- **Every function gets a doc comment** (JSDoc / docstring): what it does, params, return, and *why* if not obvious.
- Named constants instead of magic numbers/strings.
- Clear names: `calculateRiskScore`, not `calc`.
- Consistent formatting: Prettier + ESLint (TS) or Ruff (Python).

---

## 7. UI (shadcn + interactive)

- Use shadcn components (Button, Card, Dialog, Form, Table, Sonner, Skeleton, Tabs) - add only what's used.
- Use lucide-react icons on buttons and status.
- Make it interactive: loading skeletons, toasts for success/error, disabled buttons while submitting, empty states, form validation messages, hover/focus states.
- Responsive layout. Light/dark mode if cheap.
- Never show raw errors or stack traces to users.

---

## 8. Backend: scalable, maintainable, runs locally, AWS-ready

- **Stateless** API (no in-memory sessions) so it can scale horizontally on ECS/Fargate.
- All config from env vars; validate at startup and fail fast with a clear message.
- Health endpoint `/health` (used by Docker and AWS load balancer).
- Pagination on list endpoints; DB indexes on query fields.
- Global error handler with consistent error shape: `{ code, message, requestId }`.

**Fallbacks: only where needed, keep simple.**
- Only for external calls that can fail (LLM, third-party APIs).
- Pattern: timeout + one retry with backoff, then one fallback (e.g., backup model or a clear error). No chains of fallbacks.
- Do not add fallbacks for internal code - fix the bug instead.

**Deployment files (no CI/CD pipeline):**
- Always write `backend/Dockerfile`, `frontend/Dockerfile` (multi-stage, small base, non-root user, healthcheck) and root `docker-compose.yml` (app + postgres + otel-collector + jaeger) - these are for AWS and for machines that have Docker.
- Native mode: still write them, but don't block on them. If Docker isn't available, say clearly in the final report that Dockerfiles were reviewed but not built.
- `docs/DEPLOY_AWS.md`: ECR -> ECS Fargate, RDS, Secrets Manager, ALB, CloudWatch. Text only.

**Run commands (cross-platform):**
- Root `package.json` scripts (work on Windows/Mac/Linux): `dev`, `test`, `lint`, `eval`, `start`. Use `concurrently` only if running frontend + backend together.
- Python-only project: document `uv run ...` commands in README instead of a Makefile.

---

## 9. Observability: zero-instrumentation + baggage

Use **OpenTelemetry auto-instrumentation** - no tracing code in business logic. Same code in both modes; only env vars change.

- **Node:** `@opentelemetry/auto-instrumentations-node`; start with
  `NODE_OPTIONS="--require @opentelemetry/auto-instrumentations-node/register"`.
- **Python:** `opentelemetry-distro` + only the needed instrumentation packages; start with `opentelemetry-instrument uvicorn ...`.
- Env vars:
  - `OTEL_SERVICE_NAME`, `OTEL_PROPAGATORS=tracecontext,baggage`
  - `OTEL_RESOURCE_ATTRIBUTES=deployment.environment=<local|prod>`
  - Docker mode / prod: `OTEL_TRACES_EXPORTER=otlp`, `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318`
  - Native mode: `OTEL_TRACES_EXPORTER=console` (no collector needed; spans print to terminal)
- **Baggage:** carry context across services, e.g. `request.id`, `tenant.id`, `session.id`, hashed `user.id` (never raw PII).
  - Frontend/API gateway sets the `baggage` header; it propagates automatically.
  - Add a Baggage Span Processor (`@opentelemetry/baggage-span-processor` / `opentelemetry-processor-baggage`) so baggage shows up as span attributes.
- Logs: structured JSON with `traceId` + `requestId` so logs link to traces.
- LLM calls: record model, tokens, latency, cost as span attributes (GenAI semantic conventions).
- `observability/otel-collector.yaml` in repo, exporting to Jaeger locally (Docker mode) and CloudWatch/X-Ray on AWS.

---

## 10. Security

Write `docs/THREAT_MODEL.md` (short STRIDE table: threat -> risk -> mitigation) and implement:

- **Auth:** JWT with guards/middleware; locally signed with a dev secret, on AWS verified against Cognito - same guard code, issuer/keys from env. Role checks on protected routes. Short-lived tokens.
- **Secrets:** never in code or git. `.env` locally (gitignored), AWS Secrets Manager in prod (injected as env vars by ECS, so code doesn't change). Commit only example env files.
- **PII:** identify PII fields; redact in logs and traces; do not send PII to the LLM unless required (mask first); encrypt sensitive columns if needed.
- **Input:** validate every request (DTO/schema); parameterized queries via ORM.
- **API hardening:** Helmet/security headers, strict CORS, rate limiting, request size limits.
- **LLM-specific:** prompt-injection guard (separate system vs user content, validate/parse LLM output with a schema, never execute LLM output directly), limit tool permissions.
- Dependency check: `npm audit` / `pip-audit`.

---

## 11. Testing (code must work)

- Write tests alongside each feature, not at the end.
- Unit tests for services (mock repositories and LLM provider).
- Integration test for main API flow using a real DB: Postgres if available, else PGlite (Node) / in-memory SQLite (Python). No Docker needed for tests.
- LLM calls use the **mock provider** in tests so they are fast and deterministic.
- **Before saying "done":** install, build, run tests, start the app in the detected mode, hit `/health` and the main flow. Fix failures. Report what was run, in which mode, and the result.

---

## 12. Evals (AI/LLM parts)

- `evals/dataset.json`: 10-30 golden cases (input, expected output or criteria), including edge cases and a prompt-injection case.
- `evals/run_eval.(ts|py)`: runs the dataset through the real pipeline, scores each case.
- Metrics (pick what fits): exact/structured match, faithfulness/groundedness (for RAG), LLM-as-judge with a rubric, latency, token cost.
- Output a summary table + `evals/results.json`; set a pass threshold (e.g. >= 80%).
- No AWS creds locally -> run evals against the mock provider for wiring only, and say clearly that real scores need `LLM_PROVIDER=bedrock`.
- Version prompts in `prompts/` so eval results tie to a prompt version.

---

## 13. Fast workflow order

1. Check machine + pick run mode (Section 0)
2. Read challenge -> write `docs/PLAN.md` -> **checkpoint**
3. Scaffold repo: folders, env example files, package scripts, lint config, Dockerfiles + compose
4. Build one **vertical slice** end to end (UI -> API -> DB/LLM) and get it running in the detected mode
5. Add remaining features, each with tests
6. Add security pieces + threat model
7. Wire observability env vars; check spans (console or Jaeger)
8. Add evals and run them
9. Final verify (Section 11), then write `README.md`

## 14. README (final deliverable)

- What it does (2-3 lines)
- Architecture diagram (Mermaid)
- How to run - both ways:
  - With Docker: `cp .env.example .env && docker compose up`
  - Without Docker: `cp .env.local.example .env && npm install && npm run dev`
- How to test / eval / view traces
- Key decisions & trade-offs (link `docs/DECISIONS.md`)
- What I'd do with more time