# CampusDesk — Log Progres per Task dan Milestone

**Tujuan:** satu tempat untuk melihat apa yang sudah dikerjakan, oleh siapa, dengan bukti apa, dan apa yang masih terbuka.
**Sumber milestone:** `docs/PRD_CampusDesk.md` §7. Kalau file ini dan PRD berbeda soal scope, PRD (dan Guideline) yang menang; status di sini yang paling baru.
**Aturan isi:** setiap entri mencatat tanggal (WIB), owner, apa yang berubah, bukti (commit/file/output), dan yang **belum diverifikasi**. Jangan menulis hasil yang tidak benar-benar dijalankan.

Legenda: ✅ selesai · 🟡 sebagian · ⬜ belum mulai · ⏳ menunggu pihak lain

---

## Status milestone

| Milestone | Target | Owner | Status | Catatan singkat |
|---|---|---|---|---|
| Lab & walking skeleton (minggu 1) | 3 Nov | Radya | ✅ | Skeleton terdeploy via CI + Argo CD (`6aa3092` → GitOps `c8162ce`) |
| M0 Case Proposal | 5 Nov | C | 🟡 | Draf `01-business/proposal.md` v0.1 ada; belum direview tim dan belum dikirim ke dosen |
| M1 Architecture | 13 Nov (mundur dari 10 Nov) | Semua | 🟡 | File ADR 001–015 ada (4 draf Radya + 014; B/C menunggu owner); QS1–QS7 dan trust boundary B1–B7 belum |
| M2 Application MVP | 14 Nov (freeze 17 Nov) | Radya | ⬜ | OIDC, tenant filter, tiket, SLA |
| M3 Cloud-Native Platform | 14 Nov | B | 🟡 | Image, Deployment, Service, Ingress, probe, resources sudah jalan |
| M4 Delivery Automation | 17 Nov | B (A1: Radya) | 🟡 | CI → Argo CD dev jalan; perbaikan A1 di branch; staging/prod belum |
| M5 Operations & SLO | 21 Nov | C | ⬜ | |
| M6 Security | 24 Nov | C | ⬜ | |
| M7 Reliability & Recovery | 24 Nov | C + Radya | ⬜ | |
| M8 Capacity & FinOps | 28 Nov | C, semua | ⬜ | |
| FINAL Demo & Defense | 1–2 Des | Semua | ⬜ | |

---

## Log task (terbaru di atas)

### 2026-11-13 — File ADR 001–013 dan 015 dibuat · M1 · 🟡

- **Owner:** Radya (file ditulis Claude, direview Radya). Pembagian owner mengikuti `docs/TASKS_M2-M5.md` (R8, B5, C3, C4).
- **Perubahan:** `10-decisions-adr/`: 14 file ADR baru + indeks `README.md` (link, status, alur PR).
  - ADR milik Radya (001, 005, 009, 012): draf lengkap, status *Diusulkan*.
  - ADR milik B (006, 007, 008, 010, 011, 013) dan C (002, 003, 004, 015): bagian *Konteks* berisi fakta dari PRD/PROGRESS/Rencana Kerja/proposal + pertanyaan pemandu; *Keputusan/Alternatif/Konsekuensi* sengaja dikosongkan untuk ditulis owner lewat PR (kontribusi tercatat, siap defense).
- **Keputusan kecil:** ADR-013 juga mencatat perubahan `prometheus.yml` (T2), bukan hanya T8–T10.
- **Belum diverifikasi:** ADR-012 belum diuji di cluster (butuh R2); ADR-009 dan ADR-014 menunggu jawaban dosen. Folder `campusdesk/` belum di Git (item terbuka #3).

### 2026-11-10 — R3 (sebagian): tabel `sla_policy` + endpoint baca · M2 · 🟡 (belum di-commit)

- **Owner:** Radya (file ditulis Claude Code, direview dan di-commit Radya). Branch `feat/sla-policy` dari `d35da36`.
- **Perubahan:**
  - enum `ticket_priority` (KRITIS/TINGGI/SEDANG/RENDAH, dipakai juga tabel tiket nanti);
  - tabel `sla_policy` dengan CHECK `response_minutes > 0` dan `resolve_minutes >= response_minutes`;
  - migrasi `drizzle/0001_sla_policy.sql` + seed 30/240, 60/480, 240/1440, 480/4320 (rencana §1.1, masih [USUL]);
  - `GET /api/sla-policies` dan `GET /api/sla-policies/{priority}`;
  - format error bersama `src/common/errors.ts` (400 `VALIDATION_ERROR`, 404 `NOT_FOUND`).
- **Bukti (lokal, 10 Nov):** `npm run typecheck` lolos; `npm test` 12/12 lulus (5 tes baru, termasuk 400 untuk `SUPER` dan `kritis`); server lokal: list 4 prioritas, `TINGGI` → 200, `SUPER` → 400.
- **Keputusan kecil:** prioritas tidak dikenal → **400** (validasi input; Swagger menampilkan pilihan valid), bukan 404. 404 hanya untuk prioritas valid yang belum punya baris.
- **Belum diverifikasi:** migrasi 0001 di DB cluster `capstone` (berjalan otomatis saat deploy); CI dan Argo CD. Endpoint masih tanpa auth (data referensi lintas tenant); setelah R2 wajib login, `PUT` khusus admin.

### 2026-11-10 — Infra observability M5: Prometheus target + dasbor Grafana · M5 · 🟡 (menunggu PR GitOps)

- **Owner:** Radya (dibantu Claude Code), atas nama C4. Owner M5 tetap C; brief di `docs/BRIEF_C_M5_Observability.md`.
- **Masalah:** T2 terbukti. Target `host.docker.internal:8088` DOWN, 404. Header `Host` di Prometheus ditolak promtool.
- **Perubahan:**
  - repo GitOps (belum di-commit): `base/service-metrics.yaml` (NodePort 30081) + `kustomization.yaml`;
  - lab: `prometheus.yml` target `k3d-capstone-server-0:30081`, provisioning dasbor `grafana/provisioning/dashboards/` (salinan di `07-observability-slo/grafana/`).
- **Bukti:** `Final_Project/evidence-raw/12-up-observability.txt` (sebelum), `13-prometheus-target-up.txt` (UP dengan Service sementara, sudah dihapus); query panel: up = 1, 0,42 req/s, non-5xx 100%, p95 4,8 ms.
- **Temuan baru T11:** ingress k3d ter-publish di `0.0.0.0:8088` (bisa diakses dari jaringan lain). Diusulkan untuk M6 (C).
- **Belum diverifikasi:** target UP permanen setelah PR GitOps di-merge dan Argo sync; screenshot dasbor.

### 2026-11-10 — Migrasi aplikasi ke TypeScript (Hono + Drizzle) · M2 · 🟡 (belum di-commit)

- **Owner:** Radya (file ditulis Claude Code, direview dan di-commit Radya). Keputusan: ADR-014 (draf).
- **Perubahan (branch `feat/migrate-typescript`, repo `capstone-app`):** Java/Maven dihapus; diganti `src/` TypeScript (Hono, `@hono/zod-openapi`, Drizzle + `pg`, prom-client), migrasi `drizzle/0000_create_units.sql` (idempoten), tes Vitest, Dockerfile `node:24-alpine` multi-stage (user `node`), step Verify CI → `npm ci`/`typecheck`/`test`. Kontrak platform tetap: port 8080, `/q/health/*`, `/q/metrics`, env `DB_URL` (JDBC)/`DB_USER`/`DB_PASSWORD`, sehingga GitOps dan Prometheus tidak diubah.
- **Bukti (dijalankan 10 Nov):** `npm run typecheck` lolos; `npm test` 7/7 lulus (2 file, ~2,5 detik) terhadap `campusdesk_test`; `node dist/index.js` → `/api/units` 2 unit, `/q/health/ready` UP, Swagger 200, `/q/metrics` berisi metrik proses; `docker build` sukses (294 MB); container di `capstone-net` terhadap DB `capstone` lama (tabel dari Flyway) → 2 unit, tidak ada duplikasi seed, Drizzle menambah `drizzle.__drizzle_migrations`; proses berjalan sebagai user `node`.
- **Versi:** runner CI Node v24.22.1 / npm 11.12.1 (Alpine 3.24.2); lokal Node v22.19.0; hono 4.13, drizzle-orm 0.45, zod 4.6, vitest 5.1, typescript 7.0 (lihat `package-lock.json`).
- **Belum diverifikasi:** run CI di Gitea dengan step Verify Node; deploy lewat Argo CD; Trivy image Node; perilaku advisory lock saat replica 2 (B3). Proposal M0 perlu menyebut substitusi ini (sudah ditandai di `proposal.md` untuk C).

### 2026-11-10 — Struktur folder portofolio dibuat (B1 bagian file) · M0/M1 · 🟡 (belum di Git)

- **Owner:** Radya (dibantu Claude Code); B1 tetap milik B untuk bagian Git
- **Perubahan:** folder `02-architecture/` … `11-demo-defense/` dan `source/`, masing-masing dengan `README.md` (isi, milestone, owner); `10-decisions-adr/TEMPLATE.md` + daftar ADR 001–013; `README.md` root (tim, repo, peta portofolio, evidence standard); `source/README.md` (tautan `helpdesk-campus`/`helpdesk-gitops` + versi `6aa3092`/`c8162ce`); `.gitignore`. Isi `evidence/` dipindah ke `03-application-data/` dan `05-ci-cd-gitops/`, lalu folder `evidence/` dihapus. Rujukan `CampusDesk_Rencana_Kerja.md` di `CLAUDE.md`/`AGENTS.md` diarahkan ke `docs/` dan `../Final_Project`.
- **Belum dilakukan:** `git init`, commit, repo GitHub, undang tim (menunggu nama tim).

### 2026-11-10 — B1 diperbarui: repo portofolio sesuai Guideline §9.1 · M0/M1 · usulan

- **Owner:** Radya (dibantu Claude Code); pelaksana B1: B
- **Dasar:** Guideline §9.1 (*Recommended Evidence Portfolio Structure*) dan §15 (*Final Submission Structure*). Keduanya mengatur portofolio dan submission, bukan pembagian repo kerja.
- **Perubahan dokumen:** B1 di `HANDOFF_B_Platform.md` dan `TASKS_M2-M5.md` diganti: repo `campusdesk-docs` menjadi `cloud-capstone-<tim>` dengan folder `01-business/` … `11-demo-defense/` + `source/`, pemindahan `evidence/` lama ke folder bernomor, dan pemetaan ke §15 saat submission. Repo `capstone-app` dan `capstone-gitops` tetap terpisah (CI menulis tag ke repo GitOps; Argo CD membacanya). Repo `campusdesk-lab` dicatat sebagai opsi.
- **Terbuka:** nama tim; keputusan apakah `campusdesk-lab` dibuat.

### 2026-11-10 — Koreksi catatan issuer OIDC di dokumen · M2 · 🟡 (masih [CEK])

- **Owner:** Radya (dibantu Claude Code)
- **Masalah:** `HANDOFF_Radya_Backend.md` R2 poin 7 dan `TASKS_M2-M5.md` temuan 5 mengusulkan pod memakai `host.k3d.internal:8081` untuk discovery/JWKS. Ini bertentangan dengan uji 28 Okt (T10): dari pod, `host.k3d.internal` ditolak karena layanan lab hanya bind ke `127.0.0.1`, sedangkan `keycloak:8080` open.
- **Perubahan dokumen:** R2 poin 7 dan temuan 5 diganti dengan usulan `OIDC_ISSUER=http://keycloak:8080/realms/capstone` + `OIDC_TOKEN_ISSUER=http://localhost:8081/realms/capstone`; nilai usulan ditambahkan di `HANDOFF_B_Platform.md` B2; baris "Dari cluster" di `AGENTS.md` diperbarui. `HANDOFF_Radya_Platform_v1_OLD.md` sengaja tidak diubah (usang).
- **Belum diverifikasi:** konfigurasi ini belum dijalankan. Bukti yang dibutuhkan di R2: `curl` dengan token `usera` ke cluster mengembalikan 200 (bukan 401), lalu dicatat di ADR 012.

### 2026-11-10 — Perubahan peran (v2) · semua milestone

- **Keputusan:** B tidak bisa backend, jadi peran ditukar: **Radya = Application & Data** (termasuk fondasi auth/OIDC), **B = Platform & Delivery**, C tetap Security & Operations.
- **Perubahan dokumen:** `docs/TASKS_M2-M5.md` v2 (+ PDF), `docs/HANDOFF_Radya_Backend.md`, `docs/HANDOFF_B_Platform.md` (handoff lama diganti nama jadi `HANDOFF_Radya_Platform_v1_OLD.md`), peran di `01-business/proposal.md`, owner milestone di PRD, dan `AGENTS.md`.
- **Konsekuensi:** lab resmi tetap di laptop Radya; langkah B di cluster resmi dikerjakan berpasangan. B mereview PR backend sebagai bekal defense. Catat alasan perubahan ini di refleksi individual masing-masing.

### 2026-11-10 — Audit progres M2–M5 dan pembagian tugas · M0–M5 · ⚠️

- **Owner:** Radya (dibantu Claude)
- **Observasi:** tidak ada commit/PR/file kerja baru sejak 3 Nov. M0 belum dikirim (terlambat), M1 belum mulai (jatuh tempo 10 Nov), M2 masih skeleton, M3 ~60%, M4 ~40%, M5 belum mulai. Fix A1 ada di dua branch identik (`fix/ci-publish-on-push`, `fix/ci-publish-push`), belum di-merge. Commit B dan C = 0.
- **Keputusan:** pembagian tugas dan kalender M2–M5 di `docs/TASKS_M2-M5.md`. Jalur kritis: C1 (mapper Keycloak) → R3 (OIDC + TenantContext) → B2–B4. Feature freeze tetap 17 Nov.
- **Belum diverifikasi:** risiko issuer OIDC (`localhost:8081` vs `host.k3d.internal:8081`) belum diuji.

### 2026-11-03 — A1: CI tidak lagi publish pada pull request · M4 · 🟡 (menunggu PR)

- **Owner:** Radya (dibantu Claude Code)
- **Masalah:** `.gitea/workflows/ci.yml` dipicu `push` ke `main` **dan** `pull_request`, tapi step *Build, scan, publish, and update GitOps* tidak punya kondisi. PR yang belum di-merge tetap mem-push image dan menulis tag ke `overlays/dev`, sehingga kode yang belum direview bisa ter-deploy ke dev.
- **Perubahan:** step tersebut diberi `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`. PR sekarang hanya menjalankan verify.
- **Bukti:** commit `d8c8ba9` di branch `fix/ci-publish-on-push` (repo `capstone-app`). YAML diparse ulang dan kondisi terbaca di step yang benar.
- **Belum diverifikasi:** belum di-push. Perlu dibuktikan di Gitea: (1) run untuk PR berhenti setelah verify, (2) run setelah merge tetap build, push, dan update GitOps.
- **Langkah berikut:** push branch ke GitHub, buka PR, review oleh B atau C, merge, lalu `git push gitea main` dan catat kedua run CI di sini.

### 2026-11-03 — M0: draf proposal kasus · M0 · 🟡

- **Owner:** C (owner dokumen); draf disiapkan Radya dengan Claude Code
- **Perubahan:** `01-business/proposal.md` v0.1 (7 pertanyaan Guideline §5.1, perbedaan dengan Campus Services, justifikasi API-only, kriteria sukses numerik QS1–QS7 + SLO, scope, peran, risiko, pertanyaan untuk dosen) dan `01-business/approval.md` (template, status PENDING).
- **Keputusan:** dokumen evidence sementara di root `campusdesk/01-business/` (opsi A), dipindah ke repo `campusdesk-docs` saat repo itu dibuat.
- **Belum diverifikasi / terbuka:** nilai SLA dan pilihan 404 untuk akses lintas tenant masih [USUL]; bagian Masalah masih [ASUMSI]; nama/NIM B dan C belum diisi; folder root belum di bawah version control.
- **Langkah berikut:** C review dan edit → review Radya + B → kirim ke dosen (target 5 Nov) → isi `approval.md` dengan jawaban asli.

### 2026-11-03 — Audit kode dan proyek terhadap PRD · semua milestone

- **Owner:** Radya (dibantu Claude Code)
- **Metode:** membaca source `capstone-app`, manifest `capstone-gitops`, git log/status kedua repo, lalu menjalankan `./mvnw -B verify` (Docker Desktop aktif, Dev Services `postgres:17-alpine`).
- **Observasi:**
  - `./mvnw verify` → `BUILD SUCCESS`, 1 tes, 0 gagal, 1 menit 15 detik (selesai 14:48 WIB).
  - Working tree kedua repo bersih; masalah CRLF (H1 di PRD) tidak muncul karena `core.autocrlf=true`. `.gitattributes` tetap disarankan (M4-6).
  - `mvnw` tersimpan dengan mode executable `100755`.
  - Temuan baru: **A1** CI publish pada PR (diperbaiki, lihat entri di atas); **A2** readiness kemungkinan sudah mengecek DB lewat health check datasource bawaan Quarkus (perlu dibuktikan di M3/M7); **A3** semua commit masih oleh Radya; **A4** base image `eclipse-temurin:21-jre` belum di-pin.
  - Temuan PRD yang masih berlaku: H2 (README template), H3 (`.github/modernize/`), H5 (dependensi ORM ganda), belum ada OIDC, `namespace` masih hard-coded di base GitOps, `DB_URL` masih ke DB `capstone`, `OIDC_ISSUER` masih `host.k3d.internal`, file di `evidence/` belum memenuhi evidence standard.
- **Interpretasi:** fondasi platform kuat; kekurangan terbesar ada di dokumen (M0/M1) dan kontribusi anggota lain.
- **Limitasi:** tes hanya mencakup `GET /api/units`; belum ada uji auth, tenant, atau state machine.

### 2026-11-01 — Walking skeleton terdeploy lewat CI dan Argo CD · Minggu 1 / M3 / M4 · ✅

- **Owner:** Radya
- **Perubahan (repo `capstone-app`):**
  - `22458eb` feat: walking skeleton Quarkus (health, metrics, OpenAPI, Flyway V1 `units` dengan seed `tenant-a`/`tenant-b`, `GET /api/units`, 1 tes).
  - `8119bac` ops: Dockerfile, Java 21, DB tes CI (`campusdesk_test` via secret `TEST_DB_PW`).
  - `6aa3092` merge GitHub PR #1 (`feat/walking-skeleton`).
- **Hasil:** CI Gitea run #2 hijau (5m0s) dan commit GitOps `c8162ce` "deploy: capstone-app 6aa3092464c0" oleh *Capstone CI* (timestamp commit CI tercatat 14:50 dalam UTC, setara 21:50 WIB). `curl http://capstone.localhost:8088/api/units` mengembalikan 2 unit.
- **Bukti:** `05-ci-cd-gitops/Ci_ijo.png`, `05-ci-cd-gitops/commit_in_1st_week.png`, `03-application-data/api_test.txt` (dipindah dari `evidence/` pada 10 Nov).
- **Limitasi:** ketiga file bukti belum mencatat timestamp, versi, interpretasi, dan limitasi sesuai evidence standard; perlu dilengkapi.

### 2026-10-28 — DB_URL ke service `postgres` di `capstone-net` · M3 · ✅ (ADR 010 belum ditulis)

- **Owner:** Radya
- **Masalah:** configmap template memakai `host.k3d.internal`, padahal Postgres hanya bind ke `127.0.0.1`, sehingga koneksi dari pod ditolak (temuan T10).
- **Perubahan:** `ee56797` fix(configmap) → merge Gitea PR #1 `f7310f3` di repo `capstone-gitops`. `DB_URL` = `jdbc:postgresql://postgres:5432/capstone`.
- **Terbuka:** catat sebagai ADR 010 di M1 karena menyimpang dari template dosen.

### 2026-10-28 — Lab dosen dinyalakan dan diperbaiki · Minggu 1 · ✅

- **Owner:** Radya
- **Langkah:** `doctor` → `up-core` → `bootstrap-gitea` → `start-runner` → `create-cluster` → `smoke-test` → `bootstrap-project` → `install-argocd`.
- **Versi (2026-10-28 12:59 WIB):** Docker 29.5.3, k3d 5.9.0, k3s v1.35.5+k3s1, kubectl client 1.34.1, Gitea 28.2.0, runner 5.1.1, Postgres 17-alpine, Keycloak 26.8.1.
- **Perbaikan pada paket dosen** (detail di `Final_Project/CampusDesk_Rencana_Kerja.md` §4):
  - **T8:** fungsi `Compose` di `scripts/_common.ps1` membuat `-d` terbaca sebagai `-Debug`; diganti fungsi biasa yang meneruskan `@args`.
  - **T9:** Gitea tanpa `INSTALL_LOCK` menunggu wizard; ditambah `GITEA__security__INSTALL_LOCK: "true"`.
  - **T10:** `repoURL` Argo CD diubah ke `http://gitea:3000/...`.
- **Bukti:** `Final_Project/evidence-raw/01-doctor.txt` … `11-argocd-after-t10.txt`.
- **Terbuka:** T8–T10 mengubah folder milik dosen, jadi perlu dicatat sebagai keputusan/ADR di M1.

---

## Pekerjaan terbuka lintas milestone

| # | Item | Milestone | Owner |
|---|---|---|---|
| 1 | Merge PR A1 dan buktikan perilaku CI di Gitea | M4 | Radya, review B/C |
| 2 | Review dan kirim proposal M0 | M0 | C |
| 3 | Repo portofolio `cloud-capstone-<tim>` dari root `campusdesk/` dengan struktur Guideline §9.1 (tugas B1) | M0/M1 | B |
| 4 | Lengkapi 3 file bukti walking skeleton (`03-application-data/`, `05-ci-cd-gitops/`) dengan evidence standard | M3/M4 | Radya |
| 5 | ADR untuk T8–T10 dan DB_URL (ADR 010) | M1 | Radya + C |
| 6 | Bersihkan H2 (README), H3 (`.github/modernize/`), H5 (dependensi ganda) | M2/M4 | B / Radya |
| 7 | Buktikan A2 (readiness turun saat DB mati) | M3/M7 | Radya |
