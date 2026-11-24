# ADR-013: Perubahan pada paket infrastruktur dosen

| Field | Isi |
|---|---|
| Status | Draf (menunggu review) |
| Tanggal | 2026-11-24 |
| Owner | B |
| Milestone | M1 |

## Konteks
PRD §5 butir 7: paket dosen (`Final_Project/infrastructure`, `scripts`, `templates`) tidak diubah kecuali alasannya dicatat di ADR. Perubahan yang **sudah** dilakukan (detail: `Final_Project/CampusDesk_Rencana_Kerja.md` §4, bukti: `Final_Project/evidence-raw/`):

| # | File | Masalah | Perubahan | Tanggal |
|---|---|---|---|---|
| T8 | `scripts/_common.ps1` | Fungsi `Compose` menjadi *advanced function*, sehingga `-d` dibaca sebagai `-Debug`; `up-core`/`bootstrap-gitea` macet | Diganti fungsi biasa yang meneruskan `@args` | 28 Okt |
| T9 | `infrastructure/docker-compose.yml` | Gitea menunggu wizard (`INSTALL_LOCK=false`); user dan runner token tidak dibuat | Tambah `GITEA__security__INSTALL_LOCK: "true"` | 28 Okt |
| T10 | `templates/argocd/application.yaml` | `repoURL` ke `host.k3d.internal` ditolak dari pod | `repoURL: http://gitea:3000/student/capstone-gitops.git` | 28 Okt |
| T2 | `infrastructure/prometheus/prometheus.yml` (+ provisioning Grafana) | Target `host.docker.internal:8088` selalu 404 | Target `k3d-capstone-server-0:30081`; alasan detail di ADR-015 (owner C) | 10 Nov |

Diusulkan tapi belum dilakukan: **T11** (`create-cluster.ps1` mem-publish ingress di `0.0.0.0:8088`), dibahas C di M6, butuh membuat ulang cluster.

Penting untuk anggota lain: lab di laptop yang memakai paket dosen **asli** akan mengalami T8–T10 lagi. Lampirkan cara menerapkan perubahan yang sama (atau patch-nya).

## Keputusan

Perubahan T8–T10 dipertahankan karena perubahan tersebut diperlukan agar paket infrastruktur dapat berjalan pada lingkungan lab yang digunakan tim, sementara perubahan tidak dilakukan terhadap paket secara diam-diam. Setiap perubahan pada paket dosen dicatat melalui ADR dan harus disertai langkah atau patch yang dapat diterapkan kembali oleh anggota lain.

Untuk perubahan yang sudah diterapkan, tim menggunakan patch minimal yang hanya menyelesaikan masalah yang ditemukan tanpa mengubah arsitektur utama paket dosen. T11 tidak diterapkan karena masih berupa usulan dan membutuhkan pembuatan ulang cluster.

## Alternatif yang dipertimbangkan

- **Alternatif A: Menggunakan paket dosen tanpa perubahan**
  - **Kelebihan:** paket tetap identik dengan versi awal yang diberikan dosen dan tidak membutuhkan dokumentasi patch tambahan.
  - **Kekurangan:** masalah T8–T10 tetap muncul sehingga proses `up-core`, `bootstrap-gitea`, dan integrasi Argo CD tidak dapat berjalan sesuai kebutuhan lab.
  - **Alasan tidak dipilih:** kondisi tersebut menghambat reproduksi environment dan pekerjaan tim.

- **Alternatif B: Mengubah paket secara langsung tanpa ADR atau dokumentasi**
  - **Kelebihan:** paling cepat dilakukan ketika menemukan masalah.
  - **Kekurangan:** perubahan sulit dilacak, anggota lain dapat menggunakan paket yang berbeda tanpa mengetahui alasannya, dan perubahan dapat tertimpa ketika paket diperbarui.
  - **Alasan tidak dipilih:** bertentangan dengan aturan PRD yang mengharuskan perubahan terhadap paket dosen dicatat dan dapat dijelaskan.

- **Alternatif C: Melakukan patch minimal dan mendokumentasikan perubahan**
  - **Kelebihan:** masalah dapat diperbaiki tanpa mengubah struktur utama paket, perubahan dapat direproduksi, dan alasan teknisnya terdokumentasi.
  - **Kekurangan:** anggota lain tetap perlu menerapkan patch ketika menggunakan paket dosen asli.
  - **Alasan dipilih:** memberikan keseimbangan antara kebutuhan lab yang berjalan dan keterlacakan perubahan.

## Konsekuensi

- **Positif:**
  - Environment lab dapat digunakan tanpa mengulangi masalah T8–T10.
  - Perubahan terhadap paket dosen memiliki alasan dan riwayat yang terdokumentasi.
  - Anggota lain dapat menerapkan perubahan yang sama melalui langkah atau patch yang disediakan.
  - Perubahan tetap terbatas pada bagian yang diperlukan sehingga tidak mengubah arsitektur utama paket.

- **Negatif / risiko sisa:**
  - Paket dosen asli tetap mengandung masalah T8–T10 sehingga patch perlu diterapkan kembali pada laptop atau environment baru.
  - Pembaruan paket dosen berpotensi menimpa perubahan yang sudah dilakukan.
  - Terdapat perbedaan antara paket dosen asli dan environment yang digunakan tim sehingga troubleshooting perlu memperhatikan versi dan patch yang diterapkan.

- **Yang perlu dipantau atau dibuktikan:**
  - Setiap perubahan terhadap paket dosen harus tetap dicatat melalui ADR atau dokumentasi yang relevan.
  - Langkah atau patch T8–T10 harus tersedia agar anggota lain dapat mereproduksi environment yang sama.
  - Jika paket dosen diperbarui, lakukan pengecekan ulang apakah T8–T10 masih relevan atau sudah diperbaiki pada versi terbaru.
  - T11 tetap diperlakukan sebagai usulan sampai benar-benar diterapkan dan diuji.
  - Perubahan pada Prometheus dan provisioning Grafana mengikuti penjelasan lebih lanjut pada ADR-015 milik owner C.