# Trust Boundary dan Failure Boundary — CampusDesk

| Field | Isi |
|---|---|
| Scope | Batas kepercayaan (B1–B7) dan batas kegagalan (F1–F7) pada lab k3d |
| Owner | C (Security & Operations); review: Radya, B |
| Source / version | `architecture.md` v0.1, diagram `02a-lab-runtime` dan `02b-lab-delivery` |
| Timestamp | 17 Nov 2026 (v0.1) |
| Decision supported | Menentukan kontrol yang diuji di M6 (security) dan skenario kegagalan yang diuji di M7 (reliability) |

> Kolom **Status kontrol**: ✅ sudah ada evidence · 🟡 sebagian · ⬜ rencana. Kolom **Diuji di** menunjukkan milestone yang wajib membuktikannya.

---

## 1. Trust boundary B1–B7

Trust boundary adalah garis di mana data berpindah dari pihak yang kurang dipercaya ke pihak yang lebih dipercaya, sehingga harus ada kontrol.

| ID | Batas | Ancaman utama | Kontrol | Status kontrol | Risiko sisa | Diuji di |
|---|---|---|---|---|---|---|
| **B1** | Klien → Traefik Ingress | Penyadapan, request dari siapa saja | Hanya host `capstone.localhost` yang dirutekan; endpoint terbuka hanya health/metrics/OpenAPI | 🟡 | **HTTP tanpa TLS di lab** → token bisa terbaca di jaringan. Target: TLS di LB CloudStack | M6 |
| **B2** | Ingress → pod aplikasi | Akses tanpa login, eskalasi role | Semua `/api/**` wajib JWT valid; role dicek per endpoint (`user`, `operator`, `admin`) | ⬜ [CEK] | Endpoint baru lupa diberi guard → mitigasi: auth default-deny + tes 401/403 di CI | M2, M6 |
| **B3** | Aplikasi ↔ Keycloak | Token palsu, issuer berbeda | Validasi signature via JWKS, `iss`, `exp`; role dari `realm_access.roles` | ⬜ [CEK] | Issuer token dari laptop (`localhost:8081`) bisa berbeda dengan yang dilihat pod → 401 massal | M2 |
| **B4** | Tenant A ↔ tenant B (di dalam DB) | Kebocoran data antar fakultas | `tenant_id` dari klaim `groups`, filter terpusat; lintas tenant → 404; aksi operator/admin dicatat di `audit_log` | ⬜ | Query baru lupa filter → mitigasi: tes negatif otomatis (QS1). Opsi lanjut: PostgreSQL RLS | M2, M6 |
| **B5** | Aplikasi → PostgreSQL | Kredensial bocor, hak DB berlebihan | Kredensial dari Kubernetes Secret (tidak di Git); DB hanya di `capstone-net` | 🟡 | App masih memakai **user superuser** (`POSTGRES_USER`) → perlu role non-superuser per environment | M6 |
| **B6** | Developer → Git → CI runner → registry | Kode/dependensi berbahaya, image diganti | PR + review anggota lain; CI verify + test + **Trivy**; tag image = short SHA + digest | ✅ (CI, digest) / 🟡 (kebijakan gagal-scan) | Runner memakai Docker socket host; registry lokal tanpa autentikasi | M4, M6 |
| **B7** | Repo GitOps → Argo CD → cluster | Perubahan cluster tanpa jejak | CI **tidak** menjalankan `kubectl apply`; hanya commit ke repo GitOps; Argo CD yang menerapkan | ✅ | Siapa pun yang bisa push ke repo GitOps bisa mengubah prod → target: prod sync manual + branch protection | M4 |

Catatan tambahan: endpoint `/q/metrics` (NodePort 30081) tidak memakai autentikasi. Isinya hanya metrik agregat tanpa data tiket. Ini diterima di lab dan dicatat sebagai risiko sisa.

## 2. Failure boundary F1–F7

Failure boundary menjawab: *kalau komponen ini gagal, apa yang ikut mati dan apa yang tetap jalan?*

| ID | Yang gagal | Dampak ke pengguna | Yang tetap jalan | Perilaku yang diharapkan | Status bukti | Diuji di |
|---|---|---|---|---|---|---|
| **F1** | Pod aplikasi dihapus/crash | API tidak tersedia selama pod baru start (`replicas: 1`) | DB, data, cluster | ReplicaSet membuat pod baru; Ready kembali **≤ 60 detik** (QS3); data utuh | ⬜ | M7 |
| **F2** | PostgreSQL berhenti | Request yang butuh data gagal | Pod tetap hidup | Readiness → NotReady sehingga Ingress berhenti mengirim trafik; liveness **tidak** me-restart pod; pulih otomatis saat DB kembali | ⬜ | M3/M7 |
| **F3** | Keycloak berhenti | Login baru gagal | Token yang sudah terbit tetap valid sampai `exp` (jika JWKS sudah di-cache) [CEK] | Error 401/503 yang terkendali, bukan crash | ⬜ | M7 |
| **F4** | Gitea / runner / registry / Argo CD berhenti | **Tidak ada** untuk pengguna | Workload yang sedang berjalan | Hanya delivery yang berhenti (*control plane delivery* ≠ *data plane*). Pull image saat pod restart bisa gagal kalau registry mati | ⬜ | M7 |
| **F5** | Prometheus / Grafana berhenti | Tidak ada | Aplikasi | Tim kehilangan visibilitas; SLO tidak terukur selama gangguan | ⬜ | M5 |
| **F6** | Satu node k3d (`agent-0`) berhenti | Pod di node itu hilang sementara | Node lain | Pod dijadwalkan ulang ke `server-0` | ⬜ | M7 (opsional) |
| **F7** | Laptop / Docker Desktop mati | **Seluruh layanan mati** | Tidak ada | Single point of failure. Pemulihan = nyalakan ulang + restore DB dari backup (QS5, RTO ≤ 30 menit) | ⬜ | M7 |

Kesimpulan: arsitektur lab **tahan terhadap F1, F2, dan F4** secara desain. F3 dan F7 adalah risiko yang diterima di lab dan dijawab di target CloudStack (`architecture.md` §5).
