# 10 — Decisions (ADR)

**Milestone:** M1 (lalu bertambah sepanjang proyek) · Format: `TEMPLATE.md`

Nama file: `ADR-NNN-judul-singkat.md`, misalnya `ADR-001-modular-monolith.md`.

## Alur kerja

1. Owner mengisi bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* di branch `docs/adr-NNN-...`, lalu menghapus blok catatan dan *Pertanyaan pemandu*.
2. Buka PR; **anggota lain** mereview. Reviewer harus bisa menjelaskan ADR itu dalam ±1 menit (acceptance M1).
3. Setelah merge, ubah status menjadi *Diterima*. Keputusan yang berubah tidak dihapus: status lama menjadi *Diganti oleh ADR-xxx*, lalu tulis ADR baru.

Status: **Draf (menunggu owner)** = konteks sudah diisi, keputusan belum ditulis owner · **Diusulkan** = draf lengkap, menunggu review/bukti · **Diterima** = sudah di-merge dan didukung bukti.

| No | Keputusan | Owner | Status |
|---|---|---|---|
| [001](ADR-001-modular-monolith.md) | Modular monolith | Radya | Diusulkan |
| [002](ADR-002-shared-schema-tenant-id.md) | Shared schema + `tenant_id` | C | Draf (menunggu owner) |
| [003](ADR-003-oidc-tenant-dari-klaim-grup.md) | OIDC + tenant dari klaim grup (404 vs 403) | C | Draf (menunggu owner) |
| [004](ADR-004-operator-lintas-tenant-audit.md) | Operator lintas tenant + audit | C | Draf (menunggu owner) |
| [005](ADR-005-tenggat-sla-saat-create.md) | Tenggat SLA disimpan saat tiket dibuat | Radya | Diusulkan |
| [006](ADR-006-configmap-secret.md) | ConfigMap/Secret manual | B | Draf (menunggu owner) |
| [007](ADR-007-gitops-build-once-promote.md) | GitOps build once, promote many | B | Draf (menunggu owner) |
| [008](ADR-008-postgresql-di-luar-cluster.md) | PostgreSQL di luar cluster | B | Draf (menunggu owner) |
| [009](ADR-009-sla-24x7.md) | SLA 24x7 | Radya | Diusulkan (menunggu jawaban dosen) |
| [010](ADR-010-db-url-service-postgres.md) | `DB_URL` via service `postgres` di `capstone-net` | B | Draf (menunggu owner); perubahan sudah berjalan |
| [011](ADR-011-tiga-environment-satu-cluster.md) | Tiga environment dalam satu cluster | B | Draf (menunggu owner) |
| [012](ADR-012-issuer-oidc.md) | Issuer OIDC (discovery `keycloak:8080`, issuer token `localhost:8081`) | Radya | Diusulkan (belum diverifikasi di cluster) |
| [013](ADR-013-perubahan-paket-dosen.md) | Perubahan paket dosen (T2, T8–T10) | B | Draf (menunggu owner) |
| [014](ADR-014-substitusi-typescript.md) | Substitusi stack aplikasi ke TypeScript (Hono + Drizzle) | Radya | Diusulkan (perlu konfirmasi dosen) |
| [015](ADR-015-prometheus-scrape-nodeport.md) | Prometheus men-scrape lewat Service NodePort di `capstone-net` | C | Draf (menunggu owner) |
