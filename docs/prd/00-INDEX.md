# Set PRD CampusDesk per Area (23 Nov 2026 → Defense ±2 Des)

> Satu PRD = satu area kerja, berisi **semua** tugas area itu dari milestone mana pun.
> Set ini **menggantikan** `docs/TASKS_M2-M5.md` dan `docs/TASKS_M6-M8.md` (sekarang di `docs/archive/` sebagai riwayat).
> PRD tim `docs/PRD_CampusDesk.md` tetap menjadi acuan desain (peran, alur, kontrak API, quality scenario). Untuk **scope dan jadwal**, set ini yang terbaru.

## Daftar PRD

| File | Area | Owner | Milestone | Prefix | Selesai |
|---|---|---|---|---|---|
| [`01-backend.md`](01-backend.md) | Aplikasi: auth, tiket, alur status, SLA, metrik bisnis | **Radya** | M2 (+ M5, M6, M1) | BE- | Kam 26 (freeze), Sab 28 |
| [`02-platform-delivery.md`](02-platform-delivery.md) | Kubernetes, CI/CD, GitOps, rollback | **B** | M3, M4 (+ M1) | PD- | Jum 27 |
| [`03-security.md`](03-security.md) | Keycloak, matriks authz, Trivy, secret, B1–B7 | **C** | M6 (+ M1) | SEC- | Jum 27 |
| [`04-operations-reliability.md`](04-operations-reliability.md) | SLI/SLO, runbook, uji kegagalan, backup/restore | **B** (REL), **C** (OPS) | M5, M7 | REL-, OPS- | Kam 26 – Jum 27 |
| [`05-capacity-finops.md`](05-capacity-finops.md) | Uji beban, rightsizing, biaya, roadmap | **C** (+ B) | M8 | CAP- | Sab 28 |
| [`06-final-defense.md`](06-final-defense.md) | Approval M0, demo script, laporan, refleksi, gladi | **Semua** | M0, FINAL | FD- | Sel 1 Des |

## Status per ID (per 28 Nov 2026)

Dibuat dari isi repo (`docs-finpro` `origin/main` `ea8310c`, `helpdesk-campus` `754ea29`, `helpdesk-gitops` `d226e99`) dan `docs/PROGRESS.md`. **⬜ berarti belum ada bukti di repo**, bukan pasti belum dikerjakan: kalau sudah dikerjakan di luar repo, commit buktinya lalu ubah baris ini. Lab mati saat tabel ini dibuat, jadi kondisi cluster tidak dicek ulang.

Legenda: ✅ selesai dengan bukti · 🟡 sebagian / menunggu review · ⬜ belum ada bukti di repo · ✂️ dipotong

| ID | Tugas | Owner | Status | Bukti / catatan |
|---|---|---|---|---|
| BE-1 | Mapper grup Keycloak | Radya | ✅ | `06-security/BE-1_keycloak-groups-mapper.md`; hilang jika realm di-import ulang sampai SEC-1 ekspor realm |
| BE-2 | Auth + TenantContext | Radya | ✅ | app PR #5; `03-application-data/BE-2_auth-cluster.md`; ADR-012 Diterima |
| BE-3 | Migrasi `tickets` + `audit_log` | Radya | ✅ | app PR #6; `03-application-data/BE-3_BE-4_tiket-cluster.md` |
| BE-4 | Tiket + filter tenant | Radya | ✅ | app PR #7; file sama dengan BE-3 |
| BE-5 | Alur status + assign + audit | Radya | 🟡 | app PR #8; `06-security/BE-5_BE-7_alur-authz.md`; kesesuaian ADR-004 menunggu C |
| BE-6 | Laporan SLA | Radya | ✅ | app PR #10; `07-observability-slo/BE-8_BE-6_metrik-laporan-cluster.md` |
| BE-7 | Tes negatif authz | Radya | 🟡 | app PR #9 (14 tes matriks); pemeriksaan matriks oleh C (SEC-2) belum |
| BE-8 | Metrik bisnis | Radya | ✅ | app PR #10; file sama dengan BE-6 |
| BE-9 | Seed data demo | Radya | 🟡 | `npm run db:seed:dev` terbukti lokal; seed di DB cluster belum |
| BE-10 | ADR backend | Radya | 🟡 | ADR-001, 012 Diterima; 005 Diusulkan; 009, 014 menunggu dosen |
| PD-1 | ConfigMap OIDC | Radya (ganti B) | ✅ | gitops Gitea PR #2 `da85b12` |
| PD-2 | Bukti M3 | B | 🟡 | `04-platform-kubernetes/PD-2_*.md` (7 file, 24 Nov); file menyebut lab lokal B, belum lab resmi |
| PD-3 | Traceability + QS6 | B | ⬜ | `05-ci-cd-gitops/` hanya README + 2 screenshot 1 Nov |
| PD-4 | Latihan rollback | B + Radya | ⬜ | |
| PD-5 | ADR platform | B | 🟡 | ADR 006, 007, 008, 010, 011, 013 ditulis (PR #4 docs), status Draf menunggu review |
| PD-6 | `.gitattributes` | B | ✅ | app `70ef050`, gitops PR #3 (GitHub). menurut ref `gitea/main` terakhir yang ter-fetch, Gitea gitops belum menerima commit ini (perlu verifikasi saat lab menyala) |
| PD-7 | Tag rilis | B | ⬜ | belum ada tag di kedua repo |
| SEC-1 | Export realm + bukti token | C | 🟡 | docs PR #5, `06-security/SEC-1_isi-token.md`; export realm belum |
| SEC-2 | Matriks authz | C + Radya | ⬜ | tes ada (BE-7), dokumen matriks C belum |
| SEC-3 | Analisis Trivy | C | ⬜ | data awal di PROGRESS (run 11: 6 HIGH, 0 CRITICAL) |
| SEC-4 | Review secret | C | ⬜ | |
| SEC-5 | Ancaman/kontrol B1–B7 | C | ⬜ | `02-architecture/boundaries.md` masih draf |
| SEC-6 | ADR keamanan | C | ⬜ | ADR 002, 003, 004, 015 masih Draf (menunggu owner) |
| SEC-7 | User DB non-superuser | C + Radya | ⬜ | *sebaiknya* |
| REL-1 | Hapus pod | B | ⬜ | ada `04-platform-kubernetes/PD-2_recovery.md` (lab lokal), belum sebagai bukti REL-1 |
| REL-2 | Drift → self-heal | B | ⬜ | |
| REL-3 | Database mati | B (+ C) | ⬜ | bug `pool.on('error')` sudah diperbaiki di BE-6 (PR #10) |
| REL-4 | Backup → restore → validasi | B + Radya | ⬜ | **quality gate**: wajib ada sebelum defense |
| REL-5 | Restore dengan data tiket | B | ⬜ | *sebaiknya* |
| OPS-1 | Dokumen SLI/SLO | C | ⬜ | data pendukung: `07-observability-slo/observations/observe-20261124-130215.txt` |
| OPS-2 | Runbook | C | ⬜ | |
| OPS-3 | Panel tiket per unit | C | ⬜ | metrik BE-8 sudah tersedia |
| CAP-1 | Uji beban | C | ⬜ | |
| CAP-2 | Rightsizing | B | ⬜ | |
| CAP-3 | Model biaya | C | ⬜ | |
| CAP-4 | Roadmap | C | ⬜ | |
| CAP-5 | Evaluasi kemampuan lanjutan | C | ⬜ | *sebaiknya* |
| FD-1 | Tutup M0 | C | ⬜ | `01-business/approval.md` masih PENDING |
| FD-2 | Koleksi API + demo script | B | ⬜ | skrip bantu demo ada di `scripts/milestone-checks/` (sebagian belum di-commit) |
| FD-3 | Rapikan evidence | pemilik folder | 🟡 | 28 Nov: `docs/` dirapikan; `milestone_p13/` belum dipindah (lihat README-nya) |
| FD-4 | Laporan final | semua | ⬜ | |
| FD-5 | Refleksi individu | masing-masing | ⬜ | |
| FD-6 | Struktur submission | Radya | ⬜ | |
| FD-7 | Gladi | semua | ⬜ | jadwal Min 29 dan Sel 1 Des |
| FD-8 | Checklist §16 | C | ⬜ | |

## Ketergantungan utama

```
BE-1 mapper Keycloak (Radya, Sen 23)
 ├─► SEC-1 export realm + isi token (C)
 └─► BE-2 auth ◄── PD-1 ConfigMap OIDC (B, Sel 24)
      └─► BE-4 tiket ─► BE-5 alur status ─► BE-7 tes negatif ─► SEC-2 matriks authz (C)
           │                                                   └─► FD-2 demo #2, #7
           ├─► BE-8 metrik ─► OPS-3 panel tiket (C)
           └─► BE-9 seed data ─► CAP-1 uji beban (C), REL-5 restore ulang (B)

REL-1..4 (B) dan PD-2..4 (B): tidak bergantung pada backend, bisa mulai sekarang.
SEC-3..6 (C), OPS-1..2 (C), CAP-3..4 (C): tidak bergantung pada backend.
```

## Kalender gabungan

| Hari | Radya | B | C |
|---|---|---|---|
| **Sen 23** | BE-1, mulai BE-2 | Lab sendiri, mulai PD-5 | Lab sendiri, ambil log Trivy |
| **Sel 24** | BE-2, BE-3 | PD-1; **REL-1, REL-2** (pairing) | **FD-1**, SEC-1 |
| **Rab 25** | BE-4 | PD-2, PD-3, **PD-5 selesai**; REL-3 (pairing) | SEC-3, SEC-4, **SEC-6 selesai**; CAP-1 awal |
| **Kam 26** | BE-5, BE-7 → **freeze** | PD-4; **REL-4** (pairing); FD-2 koleksi API | SEC-5, OPS-1, OPS-2; CAP-1 |
| **Jum 27** | BE-6, BE-8, BE-9 | PD-6, PD-7, CAP-2 | SEC-2 verifikasi, SEC-7, OPS-3, CAP-3 |
| **Sab 28** | BE-10; laporan bag. 1, 3, 4 | REL-5; laporan bag. 5, 6, 9 | **CAP-4**, CAP-5; laporan bag. 2, 7, 8, 10, 12 |
| **Min 29** | FD-3; **gladi 1** | FD-2 demo script; FD-3; gladi 1 | FD-3; gladi 1 |
| **Sen 30** | Gabung laporan, bag. 11 | Perbaiki demo script | FD-8 checklist |
| **Sel 1 Des** | FD-6 kumpulkan; **gladi 2** | FD-5; gladi 2 | FD-5; gladi 2 |

**Pairing di laptop Radya:** Sel 24 (REL-1, REL-2), Rab 25 (REL-3, scale 1→2), Kam 26 (REL-4, rollback PD-4).

## Aturan bersama

1. Satu ID = satu branch = satu PR, atas nama yang mengerjakan, direview anggota lain.
2. Setiap evidence: scope, timestamp (WIB), versi commit, perintah, output, interpretasi, limitasi.
3. Tidak ada hasil yang dikarang. Yang belum terbukti ditulis sebagai limitasi.
4. Item yang selesai dicatat di `docs/PROGRESS.md` dengan ID-nya (misalnya "BE-2 selesai, PR #5").
5. Item yang dipotong tidak dihapus: pindahkan ke roadmap (CAP-4) dan laporan bagian 11.
6. **Nama file evidence diawali ID tugas**, misalnya `08-reliability-recovery/REL-4_restore-validasi.md` atau `06-security/SEC-3_trivy.md`. README folder bukan bukti.
7. Cek posisi tim kapan saja: `./scripts/milestone-checks/run-all.sh` (PASS / FAIL / SKIP per milestone, FAIL menyebut ID tugas). Lihat `scripts/milestone-checks/README.md`.
