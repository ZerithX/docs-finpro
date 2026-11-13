# ADR-001: Modular monolith

| Field | Isi |
|---|---|
| Status | Diusulkan |
| Tanggal | 2026-11-13 |
| Owner | Radya |
| Milestone | M1 |

> Draf disiapkan dengan bantuan Claude dari dokumen tim. Radya mereview, memastikan bisa menjelaskannya, lalu mengubah status menjadi *Diterima* lewat PR yang direview B atau C.

## Konteks
- Domain CampusDesk satu konteks bisnis: unit (tenant), kebijakan SLA, tiket, komentar, dan audit log. Kelimanya saling bergantung erat (tiket membutuhkan tenant dan SLA dalam satu transaksi).
- Tim 3 orang, ±4 minggu sampai defense (~2 Des), dengan feature freeze 17 Nov. Hanya satu orang yang menulis backend (lihat perubahan peran 10 Nov di `docs/PROGRESS.md`).
- PRD §4 menaruh *microservices* dan *message broker* di luar scope. Guideline tidak mewajibkan microservices; yang dinilai adalah apakah tim bisa menjelaskan batas dan trade-off.
- Kontrak platform yang sudah berjalan (satu image, satu Deployment, satu Service, satu Ingress per environment) dibangun di atas satu artefak.

## Keputusan
CampusDesk dibangun sebagai **satu aplikasi yang di-deploy sebagai satu unit (satu image, satu Deployment)**, dengan kode dipisah per modul domain di `src/modules/` (saat ini `unit/` dan `sla/`, nanti `ticket/`, `comment/`, `audit/`) dan kode lintas modul di `src/platform/` (health, metrics) serta `src/common/` (format error). Semua modul memakai satu database PostgreSQL.

## Alternatif yang dipertimbangkan
- **Microservices (mis. layanan tiket dan layanan SLA terpisah):** bisa di-scale dan di-deploy terpisah, tapi menambah pipeline CI, manifest, dan Argo CD Application per layanan, menambah kegagalan jaringan antar-layanan, dan butuh konsistensi data lintas layanan. Untuk tim 3 orang dan satu domain kecil, biayanya jauh lebih besar dari manfaatnya. Ditolak.
- **Monolith tanpa batas modul (semua route dan query dalam satu file):** paling cepat di awal, tapi tenant filter dan state machine tiket mudah tersebar dan sulit diuji. Ditolak.
- **Fungsi serverless (seperti lab Funqy):** cocok untuk event pendek, tapi alur tiket butuh transaksi dan state di DB; platform kursus juga berpusat pada Deployment di k3s. Ditolak.

## Konsekuensi
- **Positif:** satu pipeline CI, satu image ber-tag SHA, dan satu jalur GitOps per environment, sehingga traceability M4 sederhana; transaksi tiket + audit cukup satu transaksi DB; tes integrasi cukup memanggil `app.request()`.
- **Negatif / risiko sisa:**
  - seluruh aplikasi di-scale bersama; modul yang berat ikut membebani modul lain;
  - batas modul hanya dijaga konvensi kode dan review, bukan oleh jaringan;
  - satu bug yang membuat proses crash menjatuhkan semua fitur sekaligus.
- **Perlu dipantau / dibuktikan:**
  - aplikasi harus stateless supaya replica > 1 aman (breach SLA dihitung lewat query, lihat ADR-005; migrasi startup memakai advisory lock, lihat ADR-014);
  - scale 1→2 replica dan keduanya Ready (tugas B3, bukti di `04-platform-kubernetes/`).
