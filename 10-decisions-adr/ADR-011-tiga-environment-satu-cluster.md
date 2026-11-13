# ADR-011: Tiga environment (dev/staging/prod) dalam satu cluster

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | B |
| Milestone | M1 / M4 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
- PRD §4 dan proposal: dev (sync otomatis), staging (promosi lewat PR), prod (PR + sync manual Argo CD), dalam **satu** cluster k3d.
- Rencana B2: namespace `campusdesk-dev/-staging/-prod`, DB `campusdesk_dev/_staging/_prod`, host `dev.capstone.localhost` / `staging.capstone.localhost` / `capstone.localhost`, 3 Argo CD Application. Saat ini baru ada `overlays/dev` dan `namespace` masih hard-coded di base (M3-4).
- Proposal §limitasi: pemisahan ini **logis** (namespace + DB), satu cluster dan satu server PostgreSQL, bukan isolasi fisik. Pertanyaan nomor 4 ke dosen masih menunggu jawaban.
- T5: nama `*.localhost` mungkin perlu ditambahkan ke file hosts Windows.

## Pertanyaan pemandu
1. Kenapa tidak tiga cluster terpisah? Apa batasan laptop yang memengaruhi keputusan ini?
2. Apa yang benar-benar terisolasi antar env, dan apa yang **tidak** (node, server DB, ingress controller, Argo CD)?
3. Bagaimana mencegah overlay dev tanpa sengaja menulis ke DB prod?
4. Kalau pindah ke CloudStack, apa yang akan berubah?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
