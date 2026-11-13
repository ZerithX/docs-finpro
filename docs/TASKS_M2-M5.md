# CampusDesk: Audit 10 Nov dan Pembagian Tugas M2–M5 (v2)

> Disusun 10 Nov 2026 dari audit folder `campusdesk` (git log kedua repo, `docs/PROGRESS.md`, `01-business/`). Acuan scope: `docs/PRD_CampusDesk.md` §7. Target M5 selesai **Jumat 21 Nov**.
> **v2 (10 Nov):** peran ditukar karena B tidak bisa backend. **Radya = Application & Data**, **B = Platform & Delivery**, C tetap Security & Operations.
> Label: [CEK] = perlu dibuktikan saat dikerjakan.
> Detail langkah per orang: `docs/HANDOFF_Radya_Backend.md` dan `docs/HANDOFF_B_Platform.md`.

---

## 1. Hasil Audit (per 10 Nov)

**Tidak ada commit, PR, atau file baru sejak 3 Nov.** Satu minggu tidak ada progres yang tercatat. Satu-satunya file baru adalah `cloud-ai.zip`, yang hanya berisi salinan dokumen.

| Milestone | Target | Status | Bukti / catatan |
|---|---|---|---|
| M0 Proposal | 5 Nov | 🟡 **Terlambat** | `01-business/proposal.md` ada, tapi `approval.md` masih PENDING (belum dikirim ke dosen). Nama/NIM B dan C belum diisi. |
| M1 Arsitektur | 10 Nov → **13 Nov** | ⬜ **Terlambat** | Belum ada satu pun ADR atau quality scenario. |
| M2 Aplikasi MVP | 14 Nov (freeze 17 Nov) | ⬜ | Kode masih skeleton: hanya `Unit` + `GET /api/units` (publik), 1 tes. Belum ada OIDC, tiket, SLA, maupun tenant filter. |
| M3 Platform | 14 Nov | 🟡 ~60% | Deployment, Service, Ingress, probe, resources, ConfigMap/Secret sudah jalan. Belum ada: bukti rollout/scale, bukti readiness saat DB mati (A2), catatan troubleshooting, dan `namespace` masih hard-coded di base. |
| M4 Delivery | 17 Nov | 🟡 ~40% | CI → registry → GitOps → Argo CD dev sudah jalan (`6aa3092` → `c8162ce`). Fix A1 belum di-merge. staging/prod, promosi, rollback, dan tabel traceability belum ada. |
| M5 Operations & SLO | 21 Nov | ⬜ | `/q/metrics` sudah ada dari skeleton, tapi belum ada metrik bisnis, dasbor, maupun SLO. |

**Temuan**

1. **Dua branch untuk fix yang sama:** `fix/ci-publish-on-push` (`d8c8ba9`) dan `fix/ci-publish-push` (`b535a8d`). Pertahankan yang pertama, buka PR, dan hapus yang lain.
2. **Kontribusi:** commit B = 0 dan C = 0. Risiko nilai individu dan defense (Guideline §4). Setiap anggota wajib punya PR sendiri, mulai minggu ini.
3. **Dokumen di root `campusdesk/`** (proposal, PRD, PROGRESS, evidence) belum masuk version control.
4. **`CLAUDE.md` merujuk `CampusDesk_Rencana_Kerja.md`**, padahal file itu tidak ada di folder ini.
5. **[CEK] Risiko issuer OIDC (dikoreksi 10 Nov):** pod tidak bisa menjangkau `host.k3d.internal:8081` karena Keycloak hanya bind ke `127.0.0.1` (sama dengan T10). Discovery/JWKS dari pod harus lewat `keycloak:8080`, sedangkan token dari laptop memuat `iss = http://localhost:8081/...`. Karena keduanya berbeda, issuer yang diterima perlu diset terpisah (`OIDC_TOKEN_ISSUER`); kalau tidak, semua request ditolak (401). Detail di `HANDOFF_Radya_Backend.md` R2 poin 7.
6. **Role harus dibaca dari `realm_access.roles`, bukan `groups`:** setelah mapper grup aktif, token berisi `groups: ["/tenant-a"]` yang bukan role. Di middleware auth (TypeScript, sejak ADR-014), ambil role hanya dari `realm_access.roles`.

---

## 2. Prinsip Pembagian

- **Peran ditukar (v2):** Radya memegang backend, termasuk fondasi auth (OIDC + TenantContext) karena langsung tersambung ke fitur tiket. B memegang platform. Platform sebagian besar berupa YAML, Kustomize, `kubectl`, Argo CD, dan Git, yang sudah dikuasai B, dan langkahnya sudah tertulis di handoff.
- **Jalur kritis M2:** mapper grup Keycloak (C1) → auth di app (R2) → fitur tiket (R3–R6). C1 harus selesai **11 Nov** dan R2 **12 Nov**.
- **Lab resmi ada di laptop Radya.** B mengubah manifest lewat PR ke repo GitOps. Langkah yang dijalankan langsung di cluster resmi (DB, Secret, Argo Application) dikerjakan **berpasangan** di laptop Radya, atau B berlatih dulu di lab sendiri lalu Radya mengulanginya dari catatan B.
- Setiap PR direview oleh **anggota lain**. B mereview PR backend Radya, sebagai bekal menjelaskan aplikasi saat defense.
- Tes di CI **tidak butuh Keycloak**: tes menandatangani JWT sendiri dengan kunci tes (`jose`), lalu app memverifikasinya lewat JWKS lokal (lihat `HANDOFF_Radya_Backend.md` R2).
- **Stack aplikasi sejak 10 Nov: Node.js 24 + TypeScript (Hono, Drizzle, Vitest)**, ADR-014. Kontrak platform (port, `/q/health`, `/q/metrics`, env DB) tidak berubah.
- Satu tugas = satu branch = satu PR kecil. Setiap PR yang selesai dicatat di `docs/PROGRESS.md`.

---

## 3. Tugas per Orang

### Radya: Application & Data (M2) + fondasi auth

| ID | Tugas | Milestone | Selesai jika | Target |
|---|---|---|---|---|
| R1 | Merge fix A1 (satu branch, hapus duplikat; review oleh B/C). Buktikan run PR berhenti setelah verify dan run `main` tetap publish. | M4 | 2 run tercatat di `05-ci-cd-gitops/` | Sel 11 Nov |
| R2 | **Fondasi auth:** middleware JWT (`jose`, JWKS Keycloak), auth wajib di `/api/**` (kecuali health/metrics/OpenAPI), `TenantContext`, role dari `realm_access.roles`, `GET /api/units` sesuai role (DTO), helper tes JWT bertanda tangan kunci tes, uji issuer di cluster | M2 | Tanpa token → 401; `usera` → hanya tenant-a; `appadmin` → semua; tes hijau di CI | **Rab 12 Nov** |
| R3 | Migrasi Drizzle: `sla_policy` + seed, `tickets`, `ticket_comments`, `audit_log` (skema di `src/db/schema.ts`, `npm run db:generate`). | M2 | `npm run typecheck` + `npm test` hijau | Rab 12 Nov |
| R4 | Buat tiket + list/get yang difilter tenant **di satu tempat**. Hitung `response_due_at`/`resolve_due_at` saat dibuat. Respons memakai DTO. | M2 | Tes: usera membuat → 201 tenant-a; usera GET tiket tenant-b → 404 | Jum 14 Nov |
| R5 | State machine + `assign` + `status` + komentar. Transisi tidak valid → 409. `first_response_at` diisi saat ASSIGNED. Aksi operator/admin ditulis ke `audit_log`. | M2 | Tes per transisi valid dan tidak valid | Sab 15 Nov |
| R6 | Breach berbasis query + `GET /api/reports/sla` (jumlah, rata-rata, p95, % sesuai SLA). Seed data demo sekitar 20 tiket (khusus dev). Tes negatif dari matriks C2. | M2 | Tes breach dengan jam tetap; laporan cocok dengan perhitungan manual; baris matriks C2 punya tes | Sen 17 Nov (**freeze**) |
| R7 | Metrik bisnis berlabel `tenant`: `campusdesk_tickets_created_total`, histogram `campusdesk_first_response_seconds`, gauge `campusdesk_sla_breached_tickets` | M5 | Muncul di `/q/metrics` | Rab 19 Nov |
| R8 | ADR: 001 modular monolith, 005 tenggat SLA disimpan saat create, 009 SLA 24x7, 012 issuer OIDC | M1 | ADR di `10-decisions-adr/` | Kam 13 Nov |

### B: Platform & Delivery (M3, M4)

| ID | Tugas | Milestone | Selesai jika | Target |
|---|---|---|---|---|
| B1 | Repo portofolio `cloud-capstone-<tim>` (root `campusdesk/` + `.gitignore`) dengan struktur Guideline §9.1 (`01-business/` … `11-demo-defense/`, `source/`); pindahkan `evidence/` lama ke folder bernomor; README root yang menautkan repo app dan GitOps; undang tim. Perbaiki `CLAUDE.md`/`AGENTS.md` (temuan 4). | M0/M1 | Radya dan C sudah clone | Sel 11 Nov |
| B2 | Tiga environment: hapus `namespace` dari base; overlay `dev/staging/prod` (namespace, DB, host, issuer); DB `campusdesk_dev/_staging/_prod`; Secret per namespace (tidak di-commit); 3 Argo CD Application (prod sync manual) | M4 | 3 env Running, `curl` tiap host berhasil | Sab 15 Nov |
| B3 | Bukti M3: `rollout status/history`, scale 1→2, readiness turun saat DB mati (A2), satu catatan troubleshooting. `.gitattributes` di kedua repo, pin digest base image. | M3 | `04-platform-kubernetes/` berisi bukti yang sudah diinterpretasi | Sab 15 Nov |
| B4 | Rilis: latihan `v0.1.0` sekarang, lalu `v0.2.0` setelah freeze. Promosi dev→staging→prod lewat PR GitOps, latihan rollback (`git revert`), tabel traceability, ukur waktu merge→Running (QS6). | M4 | Bukti di `05-ci-cd-gitops/` | Sen 17 – Sel 18 Nov |
| B5 | ADR: 006 config/secret, 007 GitOps promote, 008 DB di luar cluster, 010 DB_URL via `postgres`, 011 tiga env satu cluster, 013 perubahan paket dosen (T8–T10) | M1 | ADR di `10-decisions-adr/` | Kam 13 Nov |
| B6 | Koleksi request API (`.http` atau Bruno/Postman): ambil token tiap user + semua endpoint + kasus ditolak. Dipakai untuk uji manual, bukti M2, dan demo. Nanti juga menyusun demo script FINAL. | M2/FINAL | Koleksi di repo; berjalan terhadap dev | Sel 18 Nov |

### C: Security & Operations (M0 tutup, keamanan M2, M5)

| ID | Tugas | Milestone | Selesai jika | Target |
|---|---|---|---|---|
| C0 | **Finalisasi dan kirim proposal M0** (peran sudah diperbarui ke v2; isi nama/NIM), catat jawaban di `approval.md` | M0 | Terkirim; tanggal tercatat | **Sel 11 Nov** |
| C1 | **Keycloak:** mapper *Group Membership* (claim `groups`) di client `capstone-app`, dipasang di Keycloak **laptop Radya** (lab resmi), export realm tanpa secret, decode token `usera`/`userb`/`operator` | M2 | Token `usera` berisi `groups: ["/tenant-a"]`; bukti di `06-security/` | **Sel 11 Nov** |
| C2 | Matriks uji authz (role × endpoint × tenant) dalam bentuk tabel kasus. Radya menulis tesnya (R6), C memeriksa semua baris tercakup. | M2/M6 | Semua baris punya tes yang lulus di CI | Sen 17 Nov |
| C3 | ADR 002 shared schema + `tenant_id`, 003 OIDC + tenant dari klaim grup (404 vs 403), 004 operator lintas tenant + audit. Trust boundary B1–B7, quality scenario QS1–QS7. | M1 | Di `02-architecture/` dan `10-decisions-adr/` | Kam 13 Nov |
| C4 | Prometheus: `up-observability`, cek target (masalah `host.docker.internal:8088` vs host Ingress per env), perbaiki, catat keputusan | M5 | Target UP; bukti + ADR | Rab 19 Nov |
| C5 | Dasbor Grafana untuk Kepala TI: % SLA, breach per unit, request rate, rate 5xx, p95, restart pod. Export JSON. | M5 | JSON + screenshot yang sudah diinterpretasi | Kam 20 Nov |
| C6 | SLI/SLO (bisnis ≥ 95%; p95 ≤ 500 ms; non-5xx ≥ 99%), runbook singkat, uji lonjakan 5xx terlihat ≤ 1 menit (QS7) | M5 | `07-observability-slo/` lengkap | Jum 21 Nov |

---

## 4. Kalender Singkat

| Hari | Radya (backend) | B (platform) | C (security & ops) |
|---|---|---|---|
| Sel 11 | R1 merge, R2 mulai, R3 | B1, setup/latihan lab sendiri | C0 kirim, **C1 di laptop Radya** |
| Rab 12 | **R2 selesai**, R3 selesai | B2 mulai (overlay + PR GitOps) | C3 mulai |
| Kam 13 | R4, R8 | B5, B2 | C3 selesai |
| Jum 14 | R4 selesai | B2 (sesi pairing di lab resmi: DB, Secret, Argo) | C2 tabel kasus |
| Sab 15 | R5 | B2 selesai, B3 | C2 |
| Sen 17 | **R6 → FEATURE FREEZE** | B4 latihan `v0.1.0` | C2 selesai |
| Sel 18 | Bug fix, review | B4 `v0.2.0` + rollback, B6 | C4 mulai |
| Rab 19 – Jum 21 | R7, bantu C4/C5 | Bantu C4 (target per env), rapikan M3/M4 | C4 → C5 → C6 |

**Rapat sinkron singkat (15 menit):** Rabu 12 Nov (cek jalur kritis auth), Senin 17 Nov (freeze: fitur yang belum selesai dipotong, bukan ditunda), Jumat 21 Nov (review M2–M5 dan lanjut ke M6/M7).

## 5. Kalau Terlambat Lagi

Beban Radya paling berat (auth + seluruh M2 dalam sekitar 6 hari). Urutan yang dipotong lebih dulu: p95 di laporan (cukup rata-rata dan %), komentar tiket, lalu overlay prod (cukup dev + staging). **Jangan dipotong:** OIDC + tenant filter + uji negatif (QS1), CI/GitOps, dan bukti restore di M7. Ketiganya adalah quality gate di Guideline.
