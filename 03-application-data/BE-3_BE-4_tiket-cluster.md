# BE-3 dan BE-4 · Migrasi tiket dan filter tenant di cluster

| Field | Isi |
|---|---|
| Scope | Migrasi `0002_tickets`, `POST/GET /api/tickets`, `GET /api/tickets/{id}` di cluster k3d dev |
| Owner | Radya (dibantu Claude Code) |
| Source / versi | `capstone-app` `74e4beb` (GitHub PR #6, #7), image tag `74e4beb9c509`, GitOps `ebf661a` |
| Timestamp | 2026-11-23 22:09:42 WIB |
| Method | Skrip HTTP ke `http://capstone.localhost:8088` dengan token Keycloak asli dari `localhost:8081`; `psql` baca saja. Token dan password tidak disimpan |
| Decision supported | ADR-003 (404 lintas tenant), ADR-005 (tenggat disimpan saat dibuat) |

## Observasi

CI Gitea run 10 (push `main`) sukses, 1m39s. Argo CD Synced/Healthy di `ebf661a`. `drizzle.__drizzle_migrations` berisi 3 baris; tabel `tickets` memuat 15 kolom, FK `unit_id`, index `(unit_id, status)`, dan CHECK `tickets_due_order`.

| Aktor | Aksi | Hasil |
|---|---|---|
| `usera` | POST KRITIS, body menyelipkan `unit: tenant-b` | 201, `unit = tenant-a`, OPEN, tenggat +30 / +240 menit |
| `userb` | POST | 201, `tenant-b` |
| `usera` | GET tiket A / tiket B / id tidak ada | 200 / 404 / 404 (isi 404 identik) |
| `userb` | GET tiket A | 404 |
| `operator` | GET tiket A dan B | 200 |
| `appadmin` | GET tiket B | 200 |
| anonim | GET tiket A, GET daftar | 401 |
| `usera` / `userb` | GET daftar | 1 tiket, hanya unitnya |
| `operator` / `appadmin` | GET daftar | 2 tiket, kedua unit |
| `operator` | POST | 403 |
| `usera` | POST prioritas `SUPER`, judul kosong | 400, 400 |

## Interpretasi

Migrasi berjalan di cluster, tenant tidak bisa dipilih lewat body, dan tiket unit lain tidak bisa dibedakan dari tiket yang tidak ada.

## Limitasi

- Uji mencakup dua tenant dan dua tiket. Alur status dan isi `audit_log` belum ada (BE-5; saat ini 0 baris).
- Tiket uji (id 1 dan 2, "Uji BE-4") masih ada di DB dev.
- Review anggota lain untuk PR #6 dan #7 belum diverifikasi.
