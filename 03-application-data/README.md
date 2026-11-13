# 03 — Application & Data

**Milestone:** M2 Application MVP · **Owner:** Radya, direview B · matriks authz: C

Isi yang diharapkan:
- Model data/ERD: `units`, `sla_policy`, `tickets`, `ticket_comments`, `audit_log`.
- State machine tiket `OPEN → ASSIGNED → IN_PROGRESS → RESOLVED → CLOSED` dan aturan transisinya.
- Pendekatan tenancy (Opsi A): tenant dari klaim token, filter terpusat, uji negatif lintas tenant.
- Matriks uji authz C2 (role × endpoint × tenant) + hasil tes dari CI.
- Bukti persistensi: data tetap ada setelah pod restart.

File saat ini:
- `api_test.txt`: output `curl` ke `/api/units` lewat ingress (1 Nov, walking skeleton). **Belum memenuhi evidence standard** (belum ada timestamp, versi, interpretasi, limitasi).
