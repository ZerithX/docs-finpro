# ADR-015: Prometheus men-scrape lewat Service NodePort di `capstone-net`

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | C |
| Milestone | M5 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
Analisis teknis sudah ditulis Radya saat memperbaiki T2 (10 Nov); lihat `07-observability-slo/README.md` bagian *Arsitektur scrape* dan *Catatan bukti*. Ringkasan fakta:

- Konfigurasi asli dosen men-scrape `host.docker.internal:8088/q/metrics`; hasilnya DOWN, HTTP 404, karena Ingress hanya melayani host `capstone.localhost` (`Final_Project/evidence-raw/12-up-observability.txt`).
- Mengirim header `Host` dari Prometheus ditolak: `setting header "Host" is not allowed`.
- Rule Ingress tanpa host akan membuat metrik terbuka ke jaringan luar, karena ingress ter-publish di `0.0.0.0:8088` (T11).
- Perbaikan: Service `capstone-app-metrics` NodePort 30081 (`capstone-gitops/base/service-metrics.yaml`, belum di-merge), target `k3d-capstone-server-0:30081`. Target UP saat diuji dengan Service sementara (`evidence-raw/13-prometheus-target-up.txt`).
- Limitasi yang sudah tercatat: scrape lewat Service mengenai pod acak bila replica > 1; staging/prod butuh nodePort berbeda.

## Pertanyaan pemandu
1. Kenapa tiga opsi lain (host port + Ingress, header `Host`, Ingress tanpa host) ditolak?
2. Kenapa NodePort tidak membuka metrik ke luar laptop?
3. Apa masalahnya kalau replica > 1, dan alternatif apa yang lebih tepat (mis. service discovery Kubernetes di Prometheus, scrape per pod)?
4. Bagaimana target untuk staging/prod akan diatur?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
