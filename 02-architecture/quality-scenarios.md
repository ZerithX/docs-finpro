# Quality Scenario QS1–QS7 — CampusDesk

| Field | Isi |
|---|---|
| Scope | Atribut kualitas yang menjadi kriteria sukses terukur proyek |
| Owner | C; review: Radya, B |
| Source / version | `01-business/proposal.md` §6, `docs/PRD_CampusDesk.md` §8 |
| Timestamp | 17 Nov 2026 (v0.1) |
| Decision supported | Target angka yang dipakai di evidence M2–M8 dan di dasbor SLO |

Format mengikuti *quality attribute scenario*: **sumber → stimulus → artefak → lingkungan → respons → ukuran**.

| ID | Atribut | Sumber & stimulus | Artefak & lingkungan | Respons | Ukuran (target) | Milestone | Status |
|---|---|---|---|---|---|---|---|
| **QS1** | Isolasi tenant | `usera` (tenant-a) meminta tiket milik tenant-b | API + DB, operasi normal | Request ditolak oleh filter tenant terpusat | **404/403, 0 record bocor**, diuji otomatis di CI | M2 / M6 | ⬜ |
| **QS2** | Kebenaran SLA | Tiket KRITIS tidak di-assign melewati `response_due_at` | Modul SLA, jam diset tetap di tes | Tiket ditandai *breach* di laporan | Tes breach dengan clock tetap lulus | M2 | ⬜ |
| **QS3** | Pemulihan pod | Operator menjalankan `kubectl delete pod` | Deployment `capstone-app`, k3d | ReplicaSet membuat pod baru, data utuh | **Ready ≤ 60 detik** | M7 | ⬜ |
| **QS4** | Performa | 20 pengguna bersamaan memanggil endpoint inti | API + DB, load test k6 | Layanan tetap merespons | **p95 ≤ 500 ms**, error < 1% | M8 | ⬜ |
| **QS5** | Recoverability | Database rusak / hilang | PostgreSQL + backup | Restore ke DB validasi, cek jumlah baris dan 3 record bisnis | **RTO ≤ 30 menit** (diukur); RPO = umur backup terakhir | M7 | ⬜ |
| **QS6** | Deployability | Developer merge PR ke `main` | CI + GitOps + Argo CD | Versi baru Running di dev tanpa langkah manual | **Merge → Running ≤ 15 menit** | M4 | 🟡 run CI #4 = 3m21s; total ke Running [CEK] |
| **QS7** | Operabilitas | Lonjakan respons 5xx | Prometheus + Grafana | Lonjakan terlihat di panel non-5xx | **Terlihat ≤ 1 menit** | M5 | 🟡 dasbor ada; uji lonjakan 5xx belum |

## SLO turunan

| SLO | Target | Audiens | Sumber data |
|---|---|---|---|
| Bisnis: respon pertama sesuai SLA | **≥ 95%** tiket per unit per periode | Kepala Unit TI, pimpinan unit | Query laporan SLA + metrik `campusdesk_first_response_seconds` |
| Teknis: ketersediaan | **≥ 99%** respons non-5xx dalam jendela uji (tanpa `/q/*`) | Kepala Unit TI | Metrik HTTP di Prometheus |
| Teknis: latensi | **p95 ≤ 500 ms** | Kepala Unit TI | Histogram latensi di Prometheus |
