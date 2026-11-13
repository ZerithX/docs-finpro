# ADR-002: Shared database, shared schema, kolom `tenant_id`

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | C |
| Milestone | M1 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
- PRD §4: *Tenancy Option A*, tenant ditentukan dari token, query sadar-tenant, dan tes isolasi negatif otomatis. PRD §5 butir 2: satu DB dan satu schema bersama dengan `tenant_id`; tenant **tidak boleh** berasal dari input request.
- Tabel `units` sudah ada dengan seed `tenant-a` dan `tenant-b` (`drizzle/0000_create_units.sql`). Tiket dan komentar akan menyimpan referensi unit.
- PRD M2-3: filter tenant diterapkan di **satu tempat terpusat**; operator/admin tanpa filter tetapi tercatat di audit (ADR-004).
- Risiko di PRD §9: sebuah query lupa filter tenant → mitigasi filter terpusat + tes negatif di CI (QS1: 0 record bocor).
- Roadmap M8-4 menyebut PostgreSQL Row-Level Security sebagai kapabilitas lanjutan yang bisa dievaluasi.

## Pertanyaan pemandu
1. Bandingkan tiga model: shared schema + `tenant_id`, schema per tenant, DB per tenant. Apa trade-off isolasi, biaya, dan kerumitan migrasi?
2. Kenapa model ini cukup untuk CampusDesk (jumlah unit, sensitivitas data)?
3. Apa satu-satunya kontrol yang mencegah kebocoran data antar tenant di model ini? Bagaimana membuktikannya (QS1)?
4. Apakah RLS layak sebagai lapisan kedua? Kenapa belum sekarang?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
