# ADR-004: Operator dan admin lintas tenant dengan audit log

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | C |
| Milestone | M1 / M2 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
- Persona Teknisi TI (`operator`) melihat dan menangani tiket **semua** unit; Kepala TI (`admin`) mengelola unit dan kebijakan SLA serta melihat laporan semua unit (PRD §3).
- Akun `operator` dan `appadmin` di realm dosen tidak masuk grup tenant mana pun (T1).
- Proposal: akses lintas tenant hanya untuk `operator`/`admin`, dan **setiap baca/tulis tiket oleh mereka dicatat di `AuditLog`** (aktor, aksi, tiket, unit target, waktu) **[PUTUS]**.
- PRD M2-3: operator/admin tidak memakai filter tenant; M6-1 meminta matriks uji role × endpoint × tenant.

## Pertanyaan pemandu
1. Kenapa operator butuh akses lintas tenant (alur bisnis), dan kenapa itu tetap aman?
2. Apa yang dicatat di audit log, dan apa yang **tidak** (mis. isi tiket)? Siapa yang boleh membaca audit log?
3. Apakah membaca daftar tiket juga diaudit, atau hanya baca detail dan perubahan? Apa dampaknya ke volume data?
4. Audit log disimpan di DB yang sama: apa limitasinya (bisa diubah oleh superuser DB, lihat T6)?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
