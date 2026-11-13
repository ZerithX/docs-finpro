# 07 — Observability & SLO

**Milestone:** M5 Operations & SLO · **Owner:** C (infra awal dikerjakan Radya 10 Nov; metrik bisnis R7: Radya)
Pertanyaan gate Guideline: *Can the team explain service health for a defined audience?*

## Status

| Bagian | Status |
|---|---|
| Prometheus + Grafana menyala (`up-observability`) | ✅ 10 Nov |
| Target `capstone-app` UP (perbaikan T2) | 🟡 terbukti dengan Service sementara; permanen setelah PR GitOps `service-metrics.yaml` di-merge |
| Dasbor *CampusDesk — Service Health* (dashboard as code) | ✅ dimuat otomatis; semua query mengembalikan data |
| Metrik bisnis tiket/SLA (R7) | ⬜ menunggu fitur tiket |
| SLI/SLO final, runbook, uji lonjakan 5xx (QS7) | ⬜ C (C6) |
| ADR-015 cara scrape (NodePort) | ⬜ C |

## Isi folder

- `grafana/campusdesk-service-health.json`: dasbor (salinan yang dinilai). Sumber yang dimuat Grafana ada di `../Final_Project/infrastructure/grafana/provisioning/dashboards/json/`. **Kalau mengubah salah satu, samakan keduanya.**
- `grafana/provider-campusdesk.yml`: konfigurasi provisioning Grafana.

## Arsitektur scrape (kenapa NodePort)

```
Prometheus (container, capstone-net)
   └─ scrape http://k3d-capstone-server-0:30081/q/metrics
         └─ Service capstone-app-metrics (NodePort 30081) → pod capstone-app:8080
```

- Konfigurasi asli dosen (`host.docker.internal:8088`) selalu 404, karena Ingress hanya melayani host `capstone.localhost` (T2).
- Header `Host` di Prometheus ditolak: `setting header "Host" is not allowed`.
- Rule Ingress tanpa host tidak dipakai, karena ingress ter-publish di `0.0.0.0:8088` (T11), sehingga metrik akan terbuka ke jaringan luar.
- NodePort hanya bisa dijangkau dari dalam `capstone-net` (container node k3d tidak mem-publish port ke host).

## Dasbor: audiens dan isi

**Audiens:** Kepala Unit TI kampus. **Pertanyaan:** apakah CampusDesk bisa dipakai sekarang, dan apakah memenuhi target layanan?

| Panel | Query inti | Kenapa penting bagi audiens |
|---|---|---|
| Status layanan | `max(up{job="capstone-app"})` | Apakah sistem terpantau dan hidup |
| Request API/detik | `rate(http_server_requests_seconds_count{route!~"/q/.*"}[5m])` | Seberapa banyak sistem dipakai (lalu lintas health/metrics tidak dihitung) |
| Non-5xx % | 1 − (5xx / total) | SLI ketersediaan (SLO usulan ≥ 99%) |
| Latensi p95 | `histogram_quantile(0.95, …bucket…)` | SLI kecepatan (SLO usulan ≤ 500 ms) |
| Per route & status | `sum by (route, status)` | Endpoint mana yang bermasalah |
| Restart proses | `changes(process_start_time_seconds[1h])` | Crash/OOM/rollout |
| Memori, event loop lag | `process_resident_memory_bytes`, `nodejs_eventloop_lag_p99_seconds` | Tanda sumber daya hampir habis (limit pod 512 MiB) |

Label `route` memakai **pola** route (misalnya `/api/units`, dan `/*` untuk route yang tidak ada), bukan URL mentah, supaya jumlah time series tetap kecil.

## SLO (usulan — difinalkan C di C6)

| SLI | Target | Jendela |
|---|---|---|
| Request API non-5xx | ≥ 99% | 7 hari |
| Latensi API p95 | ≤ 500 ms | 5 menit, dipantau terus |
| Tiket mendapat respon pertama sesuai SLA prioritas | ≥ 95% | 7 hari (butuh R7) |

## Catatan bukti

**10 Nov 2026, 14:08 WIB — target Prometheus dan dasbor** · Owner: Radya (dibantu Claude Code)
- **Source/version:** Prometheus 3.15.1, Grafana 13.2.4, image app `capstone-app:d35da363e4c2` (TypeScript).
- **Method:** `up-observability`; sebelum perbaikan, cek `/api/v1/targets`; Service NodePort sementara `metrics-verify-tmp` (30081, dihapus setelah uji); restart Prometheus/Grafana; sekitar 150 request ke `/api/units` lewat ingress; jalankan semua query panel lewat API Prometheus; cek `/api/search` Grafana.
- **Observation:**
  - sebelum: target `host.docker.internal:8088` DOWN, 404 (`Final_Project/evidence-raw/12-up-observability.txt`);
  - sesudah: target `k3d-capstone-server-0:30081` UP (`evidence-raw/13-prometheus-target-up.txt`);
  - nilai query: up = 1, request 0,42 req/s, non-5xx 100%, p95 4,8 ms, RSS sekitar 79 MB, event loop lag p99 10 ms, restart 0;
  - dasbor *CampusDesk — Service Health* termuat di folder *CampusDesk*, dan health check datasource Prometheus OK.
- **Interpretation:** jalur metrik aplikasi → Prometheus → Grafana berfungsi tanpa membuka port tambahan ke host. Dasbor sudah menjawab sisi teknis pertanyaan audiens.
- **Limitation:**
  - target permanen baru ada setelah PR GitOps di-merge;
  - lalu lintas uji buatan, dan p95 dari volume kecil belum representatif;
  - scrape lewat Service mengenai pod acak bila replica > 1 (perlu dikaji di B3);
  - satu target hanya untuk env dev (staging/prod menunggu B2, nodePort berbeda);
  - belum ada metrik bisnis SLA tiket;
  - screenshot dasbor belum diambil.
- **Decision supported:** ADR-015 (scrape lewat NodePort, bukan Ingress/host port); target SLO usulan di atas.
