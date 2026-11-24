# ADR-010: `DB_URL` lewat service `postgres` di `capstone-net`

| Field | Isi |
|---|---|
| Status | Draf (menunggu review) |
| Tanggal | 2026-11-24 |
| Owner | B |
| Milestone | M1 / M3 |

## Konteks
**Ini sudah diterapkan dan berjalan**; ADR ini mencatat alasannya karena menyimpang dari template dosen.

- Template dosen (`templates/gitops-repo/base/configmap.yaml`) memakai `jdbc:postgresql://host.k3d.internal:5432/capstone`.
- Postgres hanya bind ke `127.0.0.1` di laptop, sehingga dari pod koneksi ke `host.k3d.internal` ditolak (temuan T10, diuji 28 Okt). Dari pod, `postgres:5432` lewat `capstone-net` open.
- Perubahan: commit `ee56797` fix(configmap) → merge Gitea PR #1 `f7310f3` di repo `capstone-gitops`. Nilai sekarang `DB_URL: jdbc:postgresql://postgres:5432/capstone`.
- Bukti hasil: walking skeleton `GET /api/units` mengembalikan 2 unit dari DB (`03-application-data/api_test.txt`).
- Rencana B2: nama DB berubah per env (`campusdesk_dev` dst.), host tetap `postgres:5432`.

## Keputusan
Aplikasi menggunakan `postgres:5432` sebagai host database pada `DB_URL`, karena PostgreSQL berada pada jaringan Docker `capstone-net` yang dapat diakses oleh pod. Pendekatan ini dipilih daripada membuka PostgreSQL ke host lain atau menggunakan `host.k3d.internal`.

## Alternatif yang dipertimbangkan
- **Alternatif A: Menggunakan `host.k3d.internal:5432`:** Sesuai dengan template awal dosen dan memungkinkan aplikasi mengakses PostgreSQL melalui host laptop. Namun, pendekatan ini gagal karena PostgreSQL hanya melakukan bind ke `127.0.0.1`, sehingga koneksi dari pod melalui `host.k3d.internal` ditolak. Alternatif ini tidak dipilih.

- **Alternatif B: Membuka PostgreSQL ke `0.0.0.0:5432`:** Memungkinkan koneksi dari jaringan lain, tetapi memperluas exposure PostgreSQL dan tidak diperlukan karena pod sudah dapat mengakses database melalui `capstone-net`. Alternatif ini tidak dipilih.

## Konsekuensi
- **Positif:** Aplikasi dapat mengakses PostgreSQL melalui nama host `postgres` tanpa membuka PostgreSQL ke seluruh interface host. Konfigurasi juga tetap konsisten dengan jaringan Docker yang digunakan oleh infrastruktur proyek.

- **Negatif / risiko sisa:** Kubernetes workload bergantung pada keterhubungan cluster k3d dengan jaringan `capstone-net`. Jika konfigurasi jaringan atau nama service PostgreSQL berubah, `DB_URL` pada konfigurasi aplikasi juga harus diperbarui.

- **Yang perlu dipantau atau dibuktikan:** Pastikan service/container PostgreSQL tetap tersedia dengan hostname `postgres` pada `capstone-net`. Perubahan `DB_URL` harus dilakukan melalui repository GitOps dan dibuktikan dengan koneksi aplikasi ke database, seperti endpoint `GET /api/units` yang berhasil mengembalikan data dari PostgreSQL.