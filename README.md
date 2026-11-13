# CampusDesk — Cloud Capstone Evidence Portfolio

**CampusDesk** adalah *Multi-Tenant IT Service Desk* untuk kampus: setiap unit/fakultas adalah tenant. Alur intinya tiket → penugasan → penyelesaian → ringkasan SLA, dengan workflow `OPEN → ASSIGNED → IN_PROGRESS → RESOLVED → CLOSED` dan SLA berdasarkan prioritas.

Proyek final mata kuliah Modern Cloud Computing (Sistem Informasi, Semester V, 2026/2027). Repo ini adalah **portofolio evidence** dengan struktur Guideline §9.1. Kode aplikasi dan manifest deployment ada di repo terpisah (lihat [`source/`](source/README.md)).

## Tim

| Anggota | Peran |
|---|---|
| Radya | Application & Data (termasuk auth/OIDC) |
| B | Platform & Delivery |
| C | Security & Operations |

## Stack

Node.js 24 + TypeScript · Hono · Drizzle ORM · PostgreSQL 17 · Keycloak (OIDC) · REST API + Swagger UI · Docker · k3d/k3s · Gitea Actions · Argo CD · Prometheus/Grafana · Trivy. Arsitektur: modular monolith.

## Repo

| Repo | Isi |
|---|---|
| **ini** | Portofolio evidence, ADR, dokumen kerja tim |
| [helpdesk-campus](https://github.com/ZerithX/helpdesk-campus) | Source aplikasi, tes, Dockerfile, CI |
| [helpdesk-gitops](https://github.com/ZerithX/helpdesk-gitops) | Manifest Kustomize + Argo CD (desired state) |

Lab yang dipakai: paket infrastruktur bersama dari dosen (Gitea, registry, Keycloak, PostgreSQL, k3d, Argo CD, Prometheus, Grafana), dijalankan di laptop.

## Peta portofolio

| Folder | Milestone | Owner |
|---|---|---|
| [01-business](01-business/) | M0 Proposal | C |
| [02-architecture](02-architecture/) | M1 Architecture | C, Radya |
| [03-application-data](03-application-data/) | M2 Application MVP | Radya |
| [04-platform-kubernetes](04-platform-kubernetes/) | M3 Platform | B |
| [05-ci-cd-gitops](05-ci-cd-gitops/) | M4 Delivery | B |
| [06-security](06-security/) | M6 Security | C |
| [07-observability-slo](07-observability-slo/) | M5 Operations & SLO | C |
| [08-reliability-recovery](08-reliability-recovery/) | M7 Reliability | C, Radya |
| [09-capacity-finops](09-capacity-finops/) | M8 Capacity & FinOps | C, semua |
| [10-decisions-adr](10-decisions-adr/) | ADR (sepanjang proyek) | semua |
| [11-demo-defense](11-demo-defense/) | FINAL | semua |
| [source](source/) | Tautan ke kode dan versi yang dinilai | — |

Status setiap milestone: [`docs/PROGRESS.md`](docs/PROGRESS.md).

**`docs/`** berisi dokumen kerja tim (PRD, pembagian tugas, handoff, log progres). Isinya **bukan** evidence.

## Evidence standard

Output alat (screenshot, log, hasil perintah) baru dihitung sebagai bukti setelah diberi interpretasi. Setiap file bukti mencatat:

| Field | Arti |
|---|---|
| Scope | Komponen/tes apa yang dibuktikan |
| Owner | Siapa yang membuat/mereview |
| Source / version | Commit, image, manifest, atau versi software |
| Timestamp | Kapan diambil (WIB) |
| Method | Perintah, skenario, atau metode tes |
| Observation | Apa yang terjadi |
| Interpretation | Kenapa hasil itu penting |
| Limitation | Apa yang **tidak** dibuktikan |
| Decision supported | Keputusan apa yang didukung atau berubah |

Password dan token selalu diredaksi sebelum disimpan.
