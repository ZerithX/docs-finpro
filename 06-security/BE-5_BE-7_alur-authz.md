# BE-5 dan BE-7 · Alur status, audit, dan tes negatif authz

| Field | Isi |
|---|---|
| Scope | `POST /api/tickets/{id}/assign`, `/status`, `audit_log`, matriks BE-7 |
| Owner | Radya (dibantu Claude Code); pemeriksaan matriks oleh C (SEC-2) belum dilakukan |
| Source / versi | `capstone-app` `496d0a0` (GitHub PR #8, #9), image tag `496d0a0f10f0`, GitOps `6d59b60` |
| Timestamp | CI tes 2026-11-23 23:17:58 WIB; uji cluster 2026-11-23 23:21:00 WIB |
| Method | CI Gitea run 11; skrip HTTP dengan token Keycloak asli ke cluster k3d dev; `psql` baca saja. Token dan password tidak disimpan |
| Decision supported | ADR-003 (404 lintas tenant); masukan untuk ADR-004 (audit operator) |

## CI

Run 11 (push `main`, `496d0a0`) sukses 2m21s: `Test Files 8 passed (8)`, `Tests 149 passed (149)`.

## Matriks BE-7: nama tes (`test/authz-matrix.test.ts`)

| Sel | Nama tes |
|---|---|
| `usera`, GET unit lain | `usera × GET tiket tenant-b → 404` |
| `userb`, GET unit lain | `userb × GET tiket tenant-a → 404` |
| `operator`, GET | `operator × GET tiket tenant-a dan tenant-b → 200` |
| `usera`, assign | `usera × assign tiket sendiri dan unit lain → 403` |
| `userb`, assign | `userb × assign tiket sendiri dan unit lain → 403` |
| `operator`, assign | `operator × assign tiket tenant-a dan tenant-b → 200` |
| anonim, tanpa token | `anonim × <method> <path> → 401` (8 endpoint) |

## Uji di cluster (tiket A = id 3 tenant-a, B = id 4 tenant-b)

| Aktor | Aksi | Hasil |
|---|---|---|
| anonim | assign A | 401 |
| `usera`, `userb`, `appadmin` | assign A | 403, 403, 403 |
| `userb` / `usera` | GET A / GET B | 404 / 404 |
| `userb` | tutup A | 404 |
| `operator` | A OPEN → RESOLVED | 409 |
| `operator` | assign A, lalu assign lagi | 200, 409 |
| `usera` | A → IN_PROGRESS | 403 |
| `operator` | A → IN_PROGRESS → RESOLVED | 200, 200 |
| `usera` (pelapor) | A → CLOSED | 200 |
| `operator` | A CLOSED → OPEN | 409 |
| `operator` | B assign → IN_PROGRESS → RESOLVED → CLOSED | 200 semua |
| `operator` | status `SELESAI` | 400 |

`audit_log` berisi 7 baris: A (tenant-a) 3 baris `ASSIGN`, `STATUS_IN_PROGRESS`, `STATUS_RESOLVED`; B (tenant-b) 4 baris termasuk `STATUS_CLOSED`. Semua `actor` dan `role` = `operator`. Aksi yang ditolak dan penutupan oleh pelapor tidak menambah baris.

## Interpretasi

Akses lintas tenant, aksi tanpa hak, dan transisi tidak sah ditolak dengan kode berbeda (404, 403, 409). Tiap aksi operator yang berhasil punya tepat satu baris audit.

## Limitasi

- Log CI hanya memuat total tes; nama tes di atas dari run lokal pada kode yang sama (reporter verbose).
- Aksi bersamaan dan pembatalan transaksi dites otomatis, tidak di cluster.
- Pembacaan tiket oleh operator dan aksi pelapor tidak diaudit; audit tidak dilindungi dari superuser DB (T6).
- Pelapor dikenali dari `preferred_username` + unit, bukan `sub`.
- PR #8 dan #9 di-merge sebelum CI PR terlihat selesai; CI `main` lulus sesudahnya. Review anggota lain belum diverifikasi.
- Tiket uji id 3 dan 4 masih ada di DB dev.
