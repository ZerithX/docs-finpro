# ADR-007: GitOps: build sekali, promosikan image yang sama

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | B |
| Milestone | M1 / M4 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
- Alur CI dosen: verify → build image (tag = short SHA) → Trivy → push ke `registry:5000` → CI meng-update `newTag` di `overlays/dev`. CI **tidak** menjalankan `kubectl apply`; Argo CD yang me-reconcile (Infra Guide §12, PRD §5 butir 3).
- Bukti awal: CI run #2 hijau, commit GitOps `c8162ce` "deploy: capstone-app 6aa3092464c0" oleh Capstone CI. Tag dev saat ini `d35da363e4c2`.
- Temuan A1: step publish berjalan juga saat `pull_request`, sehingga kode yang belum direview bisa ter-deploy ke dev. Perbaikan ada di branch `fix/ci-publish-on-push` (`d8c8ba9`), belum di-merge.
- Rencana M4: promosi ke staging/prod = PR di repo GitOps yang menyalin tag dev (tanpa rebuild); prod sync manual; rollback = `git revert` commit promosi; rilis `v0.1.0` dipetakan ke SHA image.

## Pertanyaan pemandu
1. Kenapa image tidak di-build ulang untuk staging/prod? Apa yang dijamin dengan memakai image yang sama?
2. Kenapa tag memakai SHA, bukan `latest`? Apa bedanya tag dan digest?
3. Kenapa CI tidak boleh `kubectl apply`? Siapa "sumber kebenaran" keadaan cluster?
4. Kenapa prod disinkronkan manual, sedangkan dev/staging otomatis?
5. Bagaimana rollback dilakukan, dan apa yang membuktikannya (M4-5)?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
