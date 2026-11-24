# ADR-008: PostgreSQL di luar cluster

| Field | Isi |
|---|---|
| Status | Draf (menunggu review) |
| Tanggal | 2026-11-24 |
| Owner | B |
| Milestone | M1 |

## Konteks
- Paket dosen menjalankan PostgreSQL 17 sebagai container Docker (`infrastructure/docker-compose.yml`) di jaringan `capstone-net`, **di luar** k3d. Pod menjangkaunya lewat `postgres:5432` (lihat ADR-010).
- Skrip backup/restore dosen (`backup-postgres`, `restore-postgres-validation`) bekerja terhadap container ini (dipakai di M7). T3: versi `.ps1` butuh PowerShell 7.
- Rencana B2: satu server PostgreSQL berisi `campusdesk_dev/_staging/_prod` (ditambah `campusdesk_test` untuk CI).
- T6: `POSTGRES_USER=capstone` adalah superuser; user aplikasi non-superuser per env direncanakan di M6-2.

## Keputusan
PostgreSQL dijalankan sebagai container Docker di luar cluster k3d dan digunakan oleh workload aplikasi di Kubernetes melalui jaringan `capstone-net`. Database tidak dijalankan sebagai StatefulSet atau database operator di dalam cluster karena desain ini mengikuti paket infrastruktur yang sudah disediakan dan mendukung pemisahan lifecycle database dari lifecycle cluster Kubernetes.

## Alternatif yang dipertimbangkan
- **Alternatif A: Menjalankan PostgreSQL sebagai StatefulSet di dalam k3d:** Database dapat dikelola bersama resource Kubernetes dan lifecycle-nya mengikuti cluster. Namun, data menjadi lebih terikat pada cluster dan membutuhkan pengelolaan persistent storage, backup, serta recovery di dalam Kubernetes. Alternatif ini tidak dipilih karena PostgreSQL sudah disediakan di luar k3d dan skrip backup/restore yang digunakan proyek bekerja terhadap container PostgreSQL tersebut.

- **Alternatif B: Menggunakan database operator seperti CloudNativePG:** Operator dapat menyediakan mekanisme pengelolaan PostgreSQL yang lebih terintegrasi dengan Kubernetes, tetapi menambah komponen dan kompleksitas operasional. Alternatif ini tidak dipilih karena belum diperlukan untuk scope proyek dan PostgreSQL yang digunakan saat ini sudah disediakan sebagai container di luar cluster.

## Konsekuensi
- **Positif:** Lifecycle PostgreSQL terpisah dari lifecycle k3d sehingga penghapusan atau pembuatan ulang cluster tidak secara langsung menghapus container database. Mekanisme backup dan restore yang sudah disediakan dapat digunakan untuk kebutuhan recovery.

- **Negatif / risiko sisa:** PostgreSQL di luar cluster tetap menjadi dependency utama dan dapat menjadi single point of failure. Desain ini tidak boleh dianggap sebagai High Availability karena hanya menggunakan satu instance PostgreSQL.

- **Yang perlu dipantau atau dibuktikan:** Pastikan workload Kubernetes tetap dapat mengakses `postgres:5432` melalui jaringan yang digunakan. Backup dan restore perlu diuji sesuai prosedur proyek, termasuk validasi hasil restore tanpa menimpa database aktif.