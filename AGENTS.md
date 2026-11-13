# CampusDesk: Panduan untuk Agen AI

Proyek final Modern Cloud Computing (SI Semester V, 2026/2027). Tim: Radya (Application & Data), B (Platform & Delivery), C (Security & Operations); peran ditukar 10 Nov. Defense sekitar 2 Desember 2026. Scope dan milestone: `docs/PRD_CampusDesk.md`; pembagian tugas: `docs/TASKS_M2-M5.md` dan `docs/HANDOFF_*.md` (kecuali `*_OLD.md`); status: `docs/PROGRESS.md`. Temuan paket dosen (T1–T10): `../Final_Project/CampusDesk_Rencana_Kerja.md` §4.

## Gaya
- Balas dalam Bahasa Indonesia (istilah teknis boleh Inggris). Tim masih belajar: jelaskan *kenapa*, bukan hanya *apa*.
- Tandai jelas: **sudah diputuskan**, **usulan**, **perlu verifikasi**. Jangan mengarang output perintah, hasil scan, atau metrik.

## Proyek
- Multi-Tenant IT Service Desk; tenant = unit/fakultas. Workflow `OPEN -> ASSIGNED -> IN_PROGRESS -> RESOLVED -> CLOSED`, SLA per prioritas (24x7).
- Node.js 24 + TypeScript, Hono, Drizzle ORM (migrasi di `drizzle/`), Vitest, PostgreSQL 17, Keycloak OIDC, REST API + Swagger UI (tanpa frontend). Pindah dari Java/Quarkus pada 10 Nov (ADR-014). Pakai npm, bukan Bun (runner CI hanya punya Node).
- Modular monolith. Jangan usulkan microservices atau message broker.
- `tenant_id` HARUS dari klaim token, tidak pernah dari input pengguna. Role: `user`, `operator`, `admin`; grup: `tenant-a`, `tenant-b`.
- Di luar scope: notifikasi, SSO kampus, kalender jam kerja, mobile, broker. Fitur dibekukan akhir minggu 3.

## Lab (paket dosen di `../Final_Project`)
- Windows + PowerShell 7 (`pwsh`), jalankan `scripts/*.ps1` dari root `../Final_Project`.
- Port: Gitea 3001, Keycloak 8081, Postgres 5432, registry 5001, ingress 8088, Prometheus 9090, Grafana 3000. Dari cluster pakai nama service di jaringan `capstone-net`: `registry:5000`, `gitea:3000`, `postgres:5432`, `keycloak:8080` (bukan `host.k3d.internal`, yang ditolak karena layanan hanya bind ke localhost). Tetap bind ke localhost.
- Urutan setup: `Copy-Item infrastructure\.env.example infrastructure\.env` -> `doctor` -> `up-core` -> `bootstrap-gitea` -> `start-runner` -> `create-cluster` -> `bootstrap-project` -> `install-argocd` -> `up-observability` (saat milestone operasi). Cek: `status`, `smoke-test`.
- `infrastructure/`, `scripts/`, `templates/` milik dosen: ubah hanya dengan alasan dan catat sebagai keputusan. `reset-lab.*` (hapus cluster + volume) hanya dengan persetujuan eksplisit.
- Ubah satu hal per langkah, ulangi validasi yang sama, catat hasilnya.

## Delivery
- Repo `capstone-app` dan `capstone-gitops` terpisah; GitOps tanpa source aplikasi dan tanpa secret asli.
- CI: verify -> build image (tag short SHA) -> Trivy -> push -> update tag di repo GitOps. CI tidak `kubectl apply`; Argo CD yang deploy.
- Promosi: dev (otomatis) -> staging (PR) -> prod (PR + sync manual).
- `main` dilindungi, PR + 1 review. Branch `feat/`, `fix/`, `docs/`, `ops/`; commit `feat: ...`.

## Quality gate
- Secret dibuat lewat `kubectl` di cluster; repo hanya berisi contoh tanpa nilai.
- Jangan klaim HA, DR, zero trust, serverless, atau multi-tenancy tanpa bukti. File backup bukan bukti restore; pod jalan bukan bukti CI/CD, security, atau reliability.
- Kode buatan AI harus bisa dijelaskan tim; beri komentar singkat pada keputusan yang tidak jelas.
- Bukti disimpan di folder bernomor sesuai milestone (`01-business/` … `11-demo-defense/`, Guideline §9.1) dan mencatat: scope, owner, source/version, timestamp, method, observation, interpretation, limitation, decision supported. Redaksi password/token.
- Tugas besar: rencana dulu, minta persetujuan. Jalankan tes sebelum menyatakan selesai; sebutkan yang belum diverifikasi.
