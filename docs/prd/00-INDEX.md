# Set PRD CampusDesk per Area (23 Nov 2026 → Defense ±2 Des)

> Satu PRD = satu area kerja, berisi **semua** tugas area itu dari milestone mana pun.
> Set ini **menggantikan** `docs/TASKS_M2-M5.md` dan `docs/TASKS_M6-M8.md` (tetap disimpan sebagai riwayat).
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
