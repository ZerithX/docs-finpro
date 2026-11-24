# BE-6 dan BE-8: laporan SLA dan metrik bisnis di cluster

| Field | Isi |
|---|---|
| Scope | `GET /api/reports/sla` dan metrik `campusdesk_*` di namespace `capstone` |
| Owner | Radya (dibantu Claude Code) |
| Source / versi | `capstone-app` `754ea29` (PR #10), image `754ea29d6a46`, GitOps Gitea `119082b`, CI run 13 sukses |
| Timestamp | 2026-11-24 13:45-13:46 WIB |
| Method | `curl` dengan token Keycloak asli lewat ingress; query API Prometheus; query tabel `tickets` |
| Decision supported | ADR-005 (breach lewat query), QS2 |

## Observation

- Argo CD Synced/Healthy; pod 1/1 Ready, restart 0.
- Data: 4 tiket KRITIS. Tiket 1 dan 2 OPEN, tenggat respons 2026-11-23 22:39:43 WIB, belum direspons. Tiket 3 dan 4 direspons sebelum tenggat.
- Laporan: `usera` hanya tenant-a, `userb` hanya tenant-b, `appadmin` keduanya, `operator` 403, anonim 401. Setiap unit: 2 tiket, 1 breach, 50% sesuai SLA.
- Prometheus: `campusdesk_sla_breached_tickets` = 1 per unit; 8 seri `campusdesk_tickets_created_total` (2 unit x 4 prioritas).

## Interpretation

Tiket KRITIS yang lewat tenggat tanpa respons terdeteksi sebagai breach di cluster, dan angka laporan cocok dengan isi tabel (1 dari 2). Kriteria "metrik muncul di `/q/metrics` dan di Prometheus" (BE-8) terpenuhi.

## Limitation

Data hanya 4 tiket; seed demo belum dijalankan di cluster. Counter tiket masih 0 karena belum ada tiket baru sejak pod mulai. Panel dasbor (OPS-3) belum ada.
