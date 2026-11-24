# ADR-011: Tiga environment (dev/staging/prod) dalam satu cluster

| Field | Isi |
|---|---|
| Status | Draf (menunggu review) |
| Tanggal | 2026-11-24 |
| Owner | B |
| Milestone | M1 / M4 |

## Konteks
- PRD §4 dan proposal: dev (sync otomatis), staging (promosi lewat PR), prod (PR + sync manual Argo CD), dalam **satu** cluster k3d.
- Rencana B2: namespace `campusdesk-dev/-staging/-prod`, DB `campusdesk_dev/_staging/_prod`, host `dev.capstone.localhost` / `staging.capstone.localhost` / `capstone.localhost`, 3 Argo CD Application. Saat ini baru ada `overlays/dev` dan `namespace` masih hard-coded di base (M3-4).
- Proposal §limitasi: pemisahan ini **logis** (namespace + DB), satu cluster dan satu server PostgreSQL, bukan isolasi fisik. Pertanyaan nomor 4 ke dosen masih menunggu jawaban.
- T5: nama `*.localhost` mungkin perlu ditambahkan ke file hosts Windows.

## Keputusan
Environment dev, staging, dan prod dirancang dalam satu cluster k3d dengan pemisahan secara logis menggunakan namespace, konfigurasi, database, dan hostname masing-masing environment. Pendekatan ini dipilih karena kebutuhan proyek tidak memerlukan tiga cluster terpisah dan keterbatasan resource laptop membuat satu cluster lebih praktis untuk lingkungan pengembangan.

## Alternatif yang dipertimbangkan
- **Alternatif A: Menggunakan tiga cluster Kubernetes terpisah untuk dev, staging, dan prod:** Memberikan isolasi yang lebih kuat antar-environment dan mengurangi risiko gangguan antar-environment dalam satu cluster. Namun, membutuhkan resource CPU, memory, storage, dan pengelolaan cluster yang lebih besar. Alternatif ini tidak dipilih karena scope proyek menggunakan satu cluster k3d dan keterbatasan resource lingkungan pengembangan.

- **Alternatif B: Menggunakan satu cluster tanpa pemisahan namespace:** Lebih sederhana dari sisi konfigurasi, tetapi resource dan konfigurasi antar-environment menjadi bercampur sehingga meningkatkan risiko perubahan pada satu environment memengaruhi environment lainnya. Alternatif ini tidak dipilih karena setiap environment membutuhkan pemisahan logis yang jelas.

## Konsekuensi
- **Positif:** Penggunaan satu cluster mengurangi kebutuhan resource dan mempermudah pengelolaan lingkungan pengembangan. Namespace, database, konfigurasi, dan hostname yang berbeda memberikan batas logis antar-environment.

- **Negatif / risiko sisa:** Pemisahan ini bukan isolasi fisik. Dev, staging, dan prod tetap berbagi cluster, node, ingress controller, Argo CD, serta server PostgreSQL yang sama. Gangguan pada komponen bersama dapat memengaruhi lebih dari satu environment.

- **Yang perlu dipantau atau dibuktikan:** Pastikan setiap overlay menggunakan namespace, `DB_URL`, dan hostname yang sesuai dengan environment-nya sehingga dev tidak mengarah ke database prod. Perlu dibuktikan pula bahwa konfigurasi dan deployment setiap environment tetap terpisah secara logis. Implementasi staging dan prod yang belum termasuk proven scope harus dibedakan dari keputusan desain ini.