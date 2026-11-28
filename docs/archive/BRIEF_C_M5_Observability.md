# Brief untuk C: Infra Observability M5 (dikerjakan Radya, 10 Nov)

> Infra awal M5 (tugas C4) dikerjakan Radya bersama Claude Code supaya tidak menunggu. **Owner M5 tetap C.**
> Brief ini berisi apa yang sudah ada, cara menjelaskannya saat defense, dan tugas lanjutan C (yang menjadi kontribusi C sendiri).
> Bukti dan detail teknis: `07-observability-slo/README.md`. Temuan: `../Final_Project/CampusDesk_Rencana_Kerja.md` §4 (T2, T11).

## 1. Apa yang sudah jalan

| Komponen | Lokasi | Keterangan |
|---|---|---|
| Prometheus 3.15.1 + Grafana 13.2.4 | lab: `Final_Project/scripts/up-observability.ps1` | Prometheus `127.0.0.1:9090`, Grafana `127.0.0.1:3000` (login dari `infrastructure/.env`) |
| Konfigurasi scrape | `Final_Project/infrastructure/prometheus/prometheus.yml` | Target `k3d-capstone-server-0:30081` (job `capstone-app`, label `environment=dev`) |
| Service metrics | repo GitOps `base/service-metrics.yaml` | `capstone-app-metrics`, NodePort 30081. **Belum di-merge** (lihat tugas C-1) |
| Dasbor | `Final_Project/infrastructure/grafana/provisioning/dashboards/` (salinan di `07-observability-slo/grafana/`) | *CampusDesk — Service Health*, dimuat otomatis dari file |

## 2. Cerita yang perlu C kuasai saat defense

1. **Masalah awal (T2):** paket dosen men-scrape `host.docker.internal:8088`, hasilnya 404. Kenapa? Ingress Traefik memilih aplikasi berdasarkan header `Host`, dan hanya melayani `capstone.localhost`.
2. **Percobaan 1 gagal:** menambah header `Host` di Prometheus ditolak oleh `promtool` (`setting header "Host" is not allowed`). Pelajarannya: validasi konfigurasi sebelum dipakai.
3. **Alternatif yang ditolak:** rule Ingress tanpa host untuk `/q/metrics`. Ingress ter-publish di `0.0.0.0:8088` (T11), jadi metrik akan terbuka ke jaringan luar.
4. **Solusi:** Service NodePort. Prometheus dan node k3d sama-sama container di jaringan Docker `capstone-net`, sehingga Prometheus bisa memanggil `k3d-capstone-server-0:30081`. Port itu **tidak** di-publish ke laptop, sehingga tidak terekspos.
5. **Dasbor untuk audiens:** dibuat untuk *Kepala Unit TI*, bukan dasbor CPU bawaan. Setiap panel menjawab pertanyaan audiens (tabel di `07-observability-slo/README.md`).
6. **Batasan yang jujur:** lewat Service, scrape mengenai pod acak bila replica > 1; hanya env dev; metrik bisnis SLA belum ada; lalu lintas uji masih buatan.

Cara cepat mengecek sendiri:
- Prometheus → **Status → Targets** (http://127.0.0.1:9090/targets): `capstone-app` harus UP.
- Grafana → **Dashboards → CampusDesk → CampusDesk — Service Health**.

## 3. Tugas lanjutan C (kontribusi C)

| ID | Tugas | Selesai jika |
|---|---|---|
| C-1 | **Review PR GitOps** `service-metrics.yaml` (dibuat Radya). Setelah merge dan Argo sync, pastikan target UP **tanpa** Service sementara. | Screenshot halaman Targets UP, dicatat di `07-observability-slo/` |
| C-2 | **Tulis ADR-015** (scrape via NodePort) memakai `10-decisions-adr/TEMPLATE.md`, berdasarkan cerita di §2 | File ADR di `10-decisions-adr/` |
| C-3 | **Finalisasi SLI/SLO** (C6). Usulan ada di `07-observability-slo/README.md`. Tentukan jendela, cara hitung, dan apa yang terjadi bila SLO dilanggar. | `07-observability-slo/SLO.md` |
| C-4 | **Runbook singkat**: gejala → cek → tindakan. Contoh: target DOWN, p95 > 500 ms, restart > 0. | `07-observability-slo/RUNBOOK.md` |
| C-5 | **Uji QS7:** buat lonjakan 5xx (misalnya hentikan DB sebentar) dan ukur berapa detik sampai terlihat di dasbor (target ≤ 1 menit). Catat timestamp-nya. | Catatan bukti dengan angka nyata |
| C-6 | **Panel SLA bisnis** setelah Radya menyelesaikan R7 (`campusdesk_sla_breached_tickets`, dll.): breach per unit dan % tiket sesuai SLA. Ubah file JSON, bukan lewat UI. | Dasbor diperbarui + screenshot terinterpretasi |
| C-7 | **Target per env** setelah B2: tambah target staging/prod (nodePort berbeda) di `prometheus.yml`, label `environment`. | 3 target UP |
| C-8 | **T11 (M6):** usulkan dan jadwalkan pembatasan publish ingress ke `127.0.0.1` (butuh membuat ulang cluster). | Keputusan tercatat |

Catatan: `allowUiUpdates: false`. Dasbor yang diubah lewat UI Grafana **tidak tersimpan**. Ubah file JSON lalu restart Grafana (`docker restart capstone-grafana`). Ini disengaja supaya dasbor terlacak sebagai kode.
