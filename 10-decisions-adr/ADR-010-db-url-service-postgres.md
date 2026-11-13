# ADR-010: `DB_URL` lewat service `postgres` di `capstone-net`

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) — perubahannya sudah berjalan sejak 28 Okt |
| Tanggal | 2026-11-13 |
| Owner | B |
| Milestone | M1 / M3 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
**Ini sudah diterapkan dan berjalan**; ADR ini mencatat alasannya karena menyimpang dari template dosen.

- Template dosen (`templates/gitops-repo/base/configmap.yaml`) memakai `jdbc:postgresql://host.k3d.internal:5432/capstone`.
- Postgres hanya bind ke `127.0.0.1` di laptop, sehingga dari pod koneksi ke `host.k3d.internal` ditolak (temuan T10, diuji 28 Okt). Dari pod, `postgres:5432` lewat `capstone-net` open.
- Perubahan: commit `ee56797` fix(configmap) → merge Gitea PR #1 `f7310f3` di repo `capstone-gitops`. Nilai sekarang `DB_URL: jdbc:postgresql://postgres:5432/capstone`.
- Bukti hasil: walking skeleton `GET /api/units` mengembalikan 2 unit dari DB (`03-application-data/api_test.txt`).
- Rencana B2: nama DB berubah per env (`campusdesk_dev` dst.), host tetap `postgres:5432`.

## Pertanyaan pemandu
1. Kenapa `host.k3d.internal` gagal? Apa artinya "bind ke 127.0.0.1"?
2. Kenapa memakai nama service Docker lebih baik daripada membuka Postgres ke `0.0.0.0`?
3. Apa ketergantungan baru yang muncul (cluster k3d harus ikut `capstone-net`)?
4. Bukti apa yang menunjukkan perubahan ini benar? Status ADR ini apa (*Diterima*)?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
