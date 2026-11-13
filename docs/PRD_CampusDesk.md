# PRD: CampusDesk (Multi-Tenant IT Service Desk)

| Field | Value |
|---|---|
| Course | Modern Cloud Computing, Final Capstone (Information Systems, Sem. V, 2026/2027) |
| Track | IT Service: Multi-Tenant Service Desk (tenant = campus faculty/unit) |
| Team | Radya (Application & Data), B (Platform & Delivery), C (Security & Operations). Roles swapped on 10 Nov; see `docs/TASKS_M2-M5.md` v2. |
| Version | v1.0, 3 Nov 2026 |
| Target defense | ~2 Dec 2026 |
| Source of truth | `Final_Capstone_Project_Guideline` (milestones M0 to FINAL, rubric, quality gates). If this PRD conflicts with the Guideline, the Guideline wins. |

> **How to use this PRD (humans and AI agents):** Work on **one milestone at a time**. Before coding, read the milestone's requirements, acceptance criteria, and *Out of scope*. A milestone is done only when every acceptance box is checked **and** its evidence exists in the matching numbered folder (`01-business/` … `11-demo-defense/`) using the evidence standard (section 5). Do not invent command output, scan results, or metrics.

---

## 1. Outcome

By the defense, a lecturer can watch the team log in as a faculty user, create an IT ticket, and see an operator resolve it within an SLA. They also see a different faculty denied access to that ticket. All of this runs on k3d via CI, an immutable image, and Argo CD. The team then shows metrics/SLO, a controlled failure with recovery, a validated database restore, and a cost/capacity rationale.

## 2. Why (Problem)

Campus units (faculties, study programs, support units) request IT help through WhatsApp, email, or verbally. Requests get lost, nobody measures response time, data from different units is not separated, and IT management has no service summary to evaluate.

CampusDesk is **one shared platform serving many units (multi-tenant)**. Load is uneven (spikes at semester start, registration, and exams). The SLA is a measurable business objective, and ticket history is a service record that must be recoverable. These are the cloud characteristics this project must prove.

This is an **IT service management** domain (ticket → assignment → resolution → SLA summary). It is **not** a campus academic or facility-reservation system.

## 3. Users and Roles

| Persona | Keycloak role / group | Can do | Cannot do |
|---|---|---|---|
| Unit staff/lecturer/student | `user` + group `tenant-x` | Create tickets, view and comment on **own unit's** tickets, view own unit's SLA summary | See other units' tickets; assign or close tickets |
| IT technician | `operator` (no tenant group) | View tickets of **all** units, assign, change status, comment. Every cross-tenant action is audit-logged. | Manage units or SLA policies |
| Head of IT | `admin` | Manage units and SLA policies, view reports for all units | n/a |

Lab accounts: `usera` (tenant-a), `userb` (tenant-b), `operator`, `appadmin`.

## 4. Scope

**In scope**
- Entities: `Unit` (tenant), `SlaPolicy`, `Ticket`, `TicketComment`, `AuditLog`. The SLA report is computed from queries, not stored.
- Workflow `OPEN → ASSIGNED → IN_PROGRESS → RESOLVED → CLOSED`. Invalid transitions are rejected.
- SLA by **priority** (KRITIS/TINGGI/SEDANG/RENDAH), 24x7. Due times are computed and stored when a ticket is created.
- Per-unit SLA summary: ticket count, average and p95 first-response time, % within SLA.
- Tenancy Option A: tenant comes from the token's `groups` claim, tenant-aware queries, and automated negative isolation tests.
- REST API + Swagger UI (API-only, justified in the proposal).
- Three environments in one cluster: dev (auto), staging (promotion PR), prod (promotion PR + manual Argo CD sync).

**Out of scope (do not build)**
- Frontend UI, email/SMS notifications, campus SSO/LDAP, mobile app, business-hours calendar/holidays, message broker, microservices, file attachments, HA claims.

## 5. Global Constraints (apply to every milestone)

1. **Stack:** Node.js 24 + TypeScript, Hono, Drizzle ORM, Vitest (switched from Java 21/Quarkus on 10 Nov, see ADR-014), PostgreSQL 17, Keycloak 26.8.1, k3d/k3s, Gitea Actions, Argo CD 3.5.6, Prometheus/Grafana, Trivy 0.76.0. Do not add a dependency without stating why in the PR.
2. **Architecture:** modular monolith; one shared DB and shared schema with `tenant_id`. The tenant **must never** come from request input.
3. **Delivery:** separate app and GitOps repos. CI = verify → build image (tag = short SHA) → Trivy → push → update `overlays/dev`. **CI never runs `kubectl apply`**; Argo CD reconciles.
4. **Schema changes only through new migration files** in `drizzle/` (generated with `npm run db:generate`). Never edit an already-applied migration.
5. **Secrets:** no real passwords or tokens in Git. Kubernetes Secrets are created with `kubectl`; only `*.example.yaml` files are committed.
6. **Git:** `main` is protected and changes go through a PR with **one review by a different member**. Branches use `feat/`, `fix/`, `docs/`, `ops/`; commits use Conventional Commits; releases use `vX.Y.Z` tags.
7. **Do not modify** the lecturer package (`Final_Project/infrastructure`, `scripts`, `templates`) unless an ADR records the reason.
8. **Evidence standard:** every evidence file records *scope, owner, source/version, timestamp, method, observation, interpretation, limitation, decision supported*. A screenshot alone is not evidence.

---

## 6. Current Status (Audit, 3 Nov 2026)

| Area | Status | Proof found |
|---|---|---|
| Lab (Gitea, runner, registry, k3d, Argo CD) | ✅ Running on Radya's laptop | CI run #2 green (5m0s); GitOps commit `c8162ce` by Capstone CI |
| Walking skeleton (health, metrics, OpenAPI, Flyway V1 `units`, 1 test) | ✅ | `capstone-app@6aa3092`; `curl http://capstone.localhost:8088/api/units` returns 2 units |
| CI test DB (`campusdesk_test` via `TEST_DB_PW` secret) | ✅ | `.gitea/workflows/ci.yml` |
| GitHub + Gitea dual remotes, PR flow | ✅ Partly | GitHub PR #1 merged; Gitea PR #1 (configmap fix). **All commits are by Radya so far.** |
| DB_URL changed from `host.k3d.internal` to `postgres:5432` | ✅ Works | Needs an ADR, since it deviates from the template |
| M0 proposal, M1 architecture/ADRs | ❌ Not in folder | n/a |
| Keycloak `groups` mapper, OIDC in app | ❌ | `quarkus-oidc` not in `pom.xml`; `/api/units` is public |
| staging/prod overlays | ❌ | Only `overlays/dev` |
| Evidence standard | ⚠️ | `evidence/` has 2 screenshots + 1 curl output with no timestamp, interpretation, or limitation |

**Hygiene issues found**
- H1. Every file in `capstone-app` (and the GitOps overlay) shows as modified, but the change is **line endings only (CRLF)**. `git diff --ignore-cr-at-eol` is empty. If this gets committed, `mvnw` may break on the Linux runner. Fix: add `.gitattributes` (`* text=auto eol=lf`, `*.cmd text eol=crlf`) and run `git restore .` or `git add --renormalize .`.
- H2. `capstone-app/README.md` is still the template README.
- H3. `campusdesk/.github/modernize/...` is leftover from a VS Code Java upgrade extension. It's not part of the project and can be deleted.
- H4. `campusdesk/` root and `evidence/` are not under version control. Decide where the evidence portfolio lives (suggestion: a third repo `cloud-capstone-<team>` on GitHub, structured per Guideline §9.1 during the semester and mapped to §15 at submission; see task B1).
- H5. `pom.xml` has both `quarkus-hibernate-orm` and `quarkus-hibernate-orm-panache`. Panache already includes ORM, so this is harmless but redundant. *(Obsolete since 10 Nov: `pom.xml` removed in the TypeScript migration.)*

---

## 7. Milestones

Status legend: ✅ done · 🟡 partial · ⬜ not started. The dates are the team's internal targets.

### M0: Case Proposal 🟡 (target: Wed 5 Nov) · Owner: C, all review

**Goal:** the lecturer approves a feasible, cloud-relevant case.

Requirements
- M0-1 A proposal covering problem, stakeholders, workflow, persistent data, authN/authZ decisions, cloud rationale, measurable success criteria, team roles, and initial risks (Guideline §5.1, deliverable A).
- M0-2 An explicit section on how this differs from the Campus Services track.
- M0-3 A justification for API-only + Swagger UI.
- M0-4 Questions sent to the lecturer (section 10).

Acceptance
- [ ] `01-business/proposal.md` exists and answers all 7 questions in Guideline §5.1.
- [ ] Success criteria are numeric (see section 8).
- [ ] Proposal submitted; lecturer response recorded in `01-business/approval.md`.

### M1: Architecture ⬜ (target: Mon 10 Nov) · Owner: Radya + C

**Goal:** the team can explain boundaries and trade-offs.

Requirements
- M1-1 A provider-neutral architecture view, plus a lab implementation mapping and a CloudStack target mapping labelled *design*. Adapt the ManagedDesk ArchiMate model by renaming Client→Unit and ServicePlan→SlaPolicy.
- M1-2 Trust boundaries B1–B7 and failure boundaries.
- M1-3 Quality scenarios QS1–QS7 (section 8).
- M1-4 ADRs in `10-decisions-adr/`: 001 modular monolith, 002 shared schema + `tenant_id`, 003 OIDC with tenant from the groups claim, 004 operator cross-tenant + audit, 005 SLA due time stored at creation, 006 ConfigMap/Secret handling, 007 GitOps with build once/promote, 008 PostgreSQL outside the cluster, 009 24x7 SLA, **010 DB_URL via `postgres` service on `capstone-net`** (already implemented), 011 dev/staging/prod in one cluster.

Acceptance
- [ ] Every ADR has context, decision, alternatives, consequences, and status.
- [ ] Each member can explain any ADR in 1 minute (checked in a team session).

### M2: Application MVP ⬜ (target: Fri 14 Nov; **feature freeze Mon 17 Nov**) · Owner: Radya, reviewed by B

**Goal:** the business process works before infrastructure complexity grows.

Requirements
- M2-1 Keycloak: add a *Group Membership* mapper (claim `groups`) to client `capstone-app`. The realm change is exported and committed (without secrets) so it is reproducible.
- M2-2 The app validates JWTs (issuer, signature, roles). Every `/api/**` endpoint requires authentication except health, metrics, and OpenAPI.
- M2-3 Tenant context is resolved once per request from the token (`/tenant-a` → `units.code = tenant-a`). All ticket queries filter by it in **one central place**. `operator` and `admin` have no tenant filter, and their reads/writes on tickets are written to `AuditLog`.
- M2-4 Migrations: `sla_policy` (seeded with KRITIS 30m/4h, TINGGI 1h/8h, SEDANG 4h/24h, RENDAH 8h/72h), `tickets`, `ticket_comments`, `audit_log`.
- M2-5 Ticket lifecycle with the allowed transitions only:
  `OPEN→ASSIGNED` (operator), `ASSIGNED→IN_PROGRESS` (operator), `IN_PROGRESS→RESOLVED` (operator), `RESOLVED→CLOSED` (reporter or operator), `RESOLVED→IN_PROGRESS` (reopen by reporter). Anything else returns 409.
- M2-6 At creation, store `response_due_at` and `resolve_due_at` from the priority's policy. `first_response_at` is set on the first transition to `ASSIGNED`. A ticket is in breach when `now > due_at` and the matching timestamp is still empty. Breach is **computed by query**, not by a scheduler (this stays safe with more than one replica).
- M2-7 SLA summary per unit and period: count, avg and p95 first-response time, % within SLA. Users see their own unit; admin sees all.
- M2-8 API responses use DTOs, not entities.
- M2-9 Seed demo data: 2 units and around 20 tickets with mixed priorities and states, via a dev/test-only migration or script.

Proposed API contract (agents may refine it but must document changes)

| Method | Path | Roles |
|---|---|---|
| GET | `/api/units` | admin (all), user (own) |
| POST | `/api/tickets` | user |
| GET | `/api/tickets`, `/api/tickets/{id}` | user (own unit), operator, admin |
| POST | `/api/tickets/{id}/assign` | operator |
| POST | `/api/tickets/{id}/status` | operator; reporter for CLOSE/reopen |
| POST/GET | `/api/tickets/{id}/comments` | user (own unit), operator |
| GET/PUT | `/api/sla-policies` | admin (PUT), all (GET) |
| GET | `/api/reports/sla?from=&to=` | user (own unit), admin (all) |

Acceptance (automated tests in CI unless noted)
- [ ] `usera` creates a ticket → 201 with `tenant-a` and due times matching the policy.
- [ ] **Negative:** `usera` GET a `tenant-b` ticket → 404 (or 403, whichever ADR 003 chooses); the list for `usera` contains zero `tenant-b` tickets.
- [ ] **Negative:** a `user` calling assign → 403; a request without a token → 401.
- [ ] An invalid transition (e.g. `OPEN→RESOLVED`) → 409.
- [ ] A breach test with a fixed clock: a ticket past `response_due_at` without assignment is reported as breached.
- [ ] Data survives a pod restart (manual check, recorded in evidence).
- [ ] Test coverage of the tenant filter and state machine. `./mvnw verify` is green in CI.

### M3: Cloud-Native Platform 🟡 (target: Fri 14 Nov) · Owner: B (pairing on Radya's lab)

**Goal:** the workload deploys repeatably and can be inspected.

Done: image, Deployment, Service, Ingress, probes, initial resources, ConfigMap + Secret, running on k3d.

Requirements
- M3-1 Add `quarkus-oidc` config (`OIDC_ISSUER`) via the ConfigMap; no hard-coded URLs.
- M3-2 Readiness includes a DB check, so the pod goes NotReady when the DB is down.
- M3-3 Evidence of rollout (`kubectl rollout status/history`), `describe`, and logs, plus one troubleshooting note.
- M3-4 Remove the hard-coded `namespace:` from base manifests so overlays control it (prep for M4).

Acceptance
- [ ] `04-platform-kubernetes/` evidence: nodes, objects, probes, resources, and the registry path, each interpreted.
- [ ] Scaling 1→2 replicas works and both pods become Ready (recorded).

### M4: Delivery Automation 🟡 (target: Mon 17 Nov) · Owner: B (Radya merges CI fix A1)

**Goal:** a change moves from source to runtime with traceability.

Done: CI verify/build/scan/push/update dev; Argo CD sync of dev.

Requirements
- M4-1 Overlays `staging` and `prod`, each with its own namespace (`campusdesk-dev/-staging/-prod`), its own DB (`campusdesk_dev/_staging/_prod`), and its own host (`dev.` / `staging.` / bare `capstone.localhost`).
- M4-2 Three Argo CD Applications: dev and staging auto-sync + selfHeal; **prod with manual sync**.
- M4-3 Promotion = a PR in the GitOps repo that copies the dev image tag into staging/prod (same image, no rebuild).
- M4-4 Release tag `v0.1.0` on the app repo, mapped to the image SHA.
- M4-5 Rollback drill: `git revert` of the promotion commit → Argo CD returns to the previous image.
- M4-6 Add `.gitattributes` (H1) so the runner never receives CRLF scripts.

Acceptance
- [ ] Traceability table: commit SHA → CI run → image tag/digest → GitOps commit → Argo revision → running pod image.
- [ ] Time from merge to Running in dev is measured (target ≤ 15 min, QS6).
- [ ] Rollback drill recorded with timestamps.

### M5: Operations & SLO ⬜ (target: Fri 21 Nov) · Owner: C

**Goal:** the team can explain service health for a defined audience.

Requirements
- M5-1 Custom metrics labelled by `tenant`: `campusdesk_tickets_created_total`, `campusdesk_first_response_seconds` (histogram), `campusdesk_sla_breached_tickets` (gauge from query). Document the cardinality risk.
- M5-2 Prometheus target UP. Verify the known issue: the scrape target `host.docker.internal:8088` vs Ingress host `capstone.localhost`. Fix it and record an ADR.
- M5-3 A Grafana dashboard for the *service owner* (Head of IT): SLA %, breaches per unit, request rate, 5xx rate, p95 latency, pod restarts.
- M5-4 SLI/SLO definitions: business SLO ≥ 95% of tickets meet first response per unit/period; technical p95 ≤ 500 ms; non-5xx ≥ 99% in the test window.
- M5-5 A short runbook: what to check when the 5xx rate rises, or when the SLA % drops.

Acceptance
- [ ] Dashboard exported as JSON into the repo, plus an interpreted screenshot.
- [ ] One induced 5xx spike visible within 1 min (QS7).

### M6: Security ⬜ (target: Mon 24 Nov) · Owner: C

**Goal:** trust boundaries are enforced and findings are prioritized.

Requirements
- M6-1 Authorization test matrix (role × endpoint × tenant): allowed and denied cases, automated.
- M6-2 A non-superuser DB role per environment for the app (least privilege, boundary B5). `POSTGRES_USER` is a superuser.
- M6-3 Trivy results for the current image: list of HIGH/CRITICAL, top 3 prioritized with a reasoned decision (fix, accept, or defer).
- M6-4 Repository secret review (grep/gitleaks-style check) across both repos and the full Git history.
- M6-5 A threat/control note for B1–B7, including residual risks (runner Docker socket, HTTP without TLS, public GitOps repo).

Acceptance
- [ ] At least one fix applied from the scan (e.g. base image update) with before/after counts.
- [ ] Zero real secrets in history; any found are rotated and documented.

### M7: Reliability & Recovery ⬜ (target: Mon 24 Nov) · Owner: C + Radya

**Goal:** the team can recover rather than merely claim recoverability.

Requirements
- M7-1 Failure tests: delete the pod (QS3 ≤ 60 s), a manual drift such as `kubectl scale` or editing an image (Argo CD self-heal), and stopping PostgreSQL (readiness fails, controlled errors, then recovery).
- M7-2 Backup with `backup-postgres` → restore into `*_restore_validation` → compare row counts and 3 business records → measure RTO (target ≤ 30 min). RPO = age of the last backup. **Test the PowerShell restore script early**, since it may fail (`param` placement, needs PowerShell 7).
- M7-3 Recovery objectives justified, with limitations stated (single node, single DB, no HA).

Acceptance
- [ ] Each test recorded with time started, time recovered, and interpretation.
- [ ] Restore proof includes validation queries and output, not just a `.dump` file.

### M8: Capacity & FinOps + Roadmap ⬜ (target: Fri 28 Nov) · Owner: C, all

**Goal:** optimize without weakening reliability or security.

Requirements
- M8-1 A load test (e.g. k6) with 20 concurrent users on core endpoints: p95, error rate, CPU/memory per pod (QS4).
- M8-2 Rightsizing of requests/limits based on observed usage, with before/after values.
- M8-3 A simple cost model: an equivalent VM or cloud cost assumption → cost per month and **cost per unit (tenant) and per ticket**, with stated assumptions.
- M8-4 A roadmap: two residual risks, prioritized next steps, the CloudStack migration (design), and one evaluated advanced capability (e.g. PostgreSQL RLS, HPA, or NetworkPolicy).

Acceptance
- [ ] `09-capacity-finops/` worksheet with raw numbers and interpretation.

### FINAL: Demo & Defense ⬜ (docs Mon 1 Dec; defense ~2 Dec) · Owner: all

Requirements
- F-1 Final technical report (Guideline §15.1, 12 sections).
- F-2 Demo script that follows the 13 steps in Guideline §13, with exact commands and fallback screenshots/recordings.
- F-3 Individual reflections (3).
- F-4 At least 2 full rehearsals with random-member questions from Guideline §13.1.

Acceptance
- [ ] Every item in Guideline §16 (Final Acceptance Checklist) is ticked with a link to evidence.
- [ ] Each member has at least 1 merged PR and an individual contribution log.

---

## 8. Success Metrics / Quality Scenarios

| ID | Attribute | Measure | Milestone |
|---|---|---|---|
| QS1 | Tenant isolation | Cross-tenant read → 403/404, 0 records leaked, automated in CI | M2/M6 |
| QS2 | SLA correctness | Overdue unassigned ticket flagged as breached | M2 |
| QS3 | Pod recovery | Pod deleted → Ready again ≤ 60 s | M7 |
| QS4 | Performance | 20 concurrent users, p95 ≤ 500 ms | M8 |
| QS5 | Recoverability | RTO ≤ 30 min, measured; RPO = backup age | M7 |
| QS6 | Deployability | Merge → Running in dev ≤ 15 min | M4 |
| QS7 | Operability | 5xx spike visible on the dashboard ≤ 1 min | M5 |
| Business | SLA | ≥ 95% first-response within policy per unit/period | M5 |

## 9. Risks

| Risk | Mitigation |
|---|---|
| Only one member has committed so far, which is a contribution and defense risk | B owns M2 PRs and C owns M0/M5/M6 PRs starting this week; reviews must be cross-member |
| Groups claim missing from JWT | M2-1 first, verified by decoding a token |
| A query forgets the tenant filter | Central filter + negative tests in CI |
| CRLF breaks the CI scripts | `.gitattributes` (M4-6) |
| Restore script fails on Windows | Test in week 2, not week 4 |
| Over-scope | Feature freeze on 17 Nov; anything in *Out of scope* is rejected in review |

## 10. Open Questions (each with a working assumption)

| # | Question (for the lecturer or team) | Assumption until answered |
|---|---|---|
| 1 | Is the kampus-context IT Service Desk distinct enough from Campus Services? | Yes |
| 2 | Is API-only + Swagger UI acceptable? | Yes |
| 3 | Is GitHub PR history acceptable as contribution evidence, with CI in Gitea? | Yes, and both are shown |
| 4 | Are dev/staging/prod as namespaces + DBs in one cluster enough? | Yes, with the limitation stated |
| 5 | Is a 24x7 SLA OK for the MVP? | Yes |
| 6 | Is CloudStack as design + roadmap only acceptable? | Yes |
| 7 (team) | Does cross-tenant GET return 403 or 404? | 404 (does not reveal that the ticket exists) |
| 8 (team) | What counts as first response: assignment, or first operator comment? | Assignment (`OPEN→ASSIGNED`) |
| 9 (team) | Where does the evidence portfolio live? | A new `cloud-capstone-<team>` repo (Guideline §9.1 structure; task B1) |
