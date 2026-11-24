# ADR-007: GitOps: build sekali, promosikan image yang sama

| Field | Isi |
|---|---|
| Status | Draf (menunggu review) |
| Tanggal | 2026-11-24 |
| Owner | B |
| Milestone | M1 / M4 |

## Konteks
- Alur CI dosen: verify → build image (tag = short SHA) → Trivy → push ke `registry:5000` → CI meng-update `newTag` di `overlays/dev`. CI **tidak** menjalankan `kubectl apply`; Argo CD yang me-reconcile (Infra Guide §12, PRD §5 butir 3).
- Bukti awal: CI run #2 hijau, commit GitOps `c8162ce` "deploy: capstone-app 6aa3092464c0" oleh Capstone CI. Tag dev saat ini `d35da363e4c2`.
- Temuan A1: step publish berjalan juga saat `pull_request`, sehingga kode yang belum direview bisa ter-deploy ke dev. Perbaikan ada di branch `fix/ci-publish-on-push` (`d8c8ba9`), belum di-merge.
- Rencana awal M4: promosi ke staging/prod dirancang melalui PR di repo GitOps yang menyalin tag dev tanpa rebuild, dengan prod sync manual. Namun, implementasi staging/prod kemudian dipotong dari proven scope karena keterbatasan waktu dan kebutuhan pengujian tambahan.
- Rollback dirancang menggunakan `git revert` terhadap perubahan GitOps; rilis `v0.1.0` dipetakan ke SHA image.

## Keputusan

Image aplikasi dibangun satu kali oleh CI menggunakan tag berdasarkan short SHA commit, kemudian image yang sama digunakan untuk deployment melalui GitOps tanpa melakukan rebuild untuk environment berikutnya. Perubahan environment dilakukan dengan memperbarui tag image pada repository GitOps, sedangkan cluster direkonsiliasi oleh Argo CD.

## Alternatif yang dipertimbangkan

- **Alternatif A: Build image ulang untuk setiap environment:** Memungkinkan konfigurasi build berbeda untuk setiap environment, tetapi berisiko menghasilkan image yang berbeda sehingga artifact yang diuji tidak identik dengan artifact yang dijalankan di environment berikutnya. Alternatif ini tidak dipilih karena mengurangi traceability antara source commit, image, dan deployment.

- **Alternatif B: Menggunakan tag `latest`:** Lebih sederhana karena tidak perlu memperbarui tag setiap build, tetapi sulit memastikan versi image yang sedang berjalan dan berisiko membuat deployment mengambil image yang berubah. Tidak dipilih karena project membutuhkan traceability berdasarkan commit.

## Konsekuensi

- **Positif:** Image yang diuji dan dipromosikan tetap merupakan artifact yang sama. Penggunaan short SHA memudahkan penelusuran dari commit source ke image dan deployment GitOps. Rollback juga dapat dilakukan dengan mengembalikan referensi image ke versi sebelumnya melalui perubahan GitOps.

- **Negatif / risiko sisa:** Repository GitOps harus diperbarui setiap kali image baru dipromosikan. Selain itu, penggunaan short SHA tetap merupakan tag, sehingga identifikasi artifact paling kuat tetap memerlukan verifikasi terhadap registry/digest jika diperlukan.

- **Yang perlu dipantau atau dibuktikan:** Pastikan CI hanya melakukan publish image pada push ke `main`, bukan pada `pull_request`. Buktikan hubungan commit source → tag image → commit GitOps → deployment melalui Argo CD. Untuk rollback, buktikan bahwa `git revert` terhadap perubahan GitOps dapat mengembalikan deployment ke image sebelumnya.