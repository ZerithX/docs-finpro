# ADR-008: PostgreSQL di luar cluster

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | B |
| Milestone | M1 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
- Paket dosen menjalankan PostgreSQL 17 sebagai container Docker (`infrastructure/docker-compose.yml`) di jaringan `capstone-net`, **di luar** k3d. Pod menjangkaunya lewat `postgres:5432` (lihat ADR-010).
- Skrip backup/restore dosen (`backup-postgres`, `restore-postgres-validation`) bekerja terhadap container ini (dipakai di M7). T3: versi `.ps1` butuh PowerShell 7.
- Rencana B2: satu server PostgreSQL berisi `campusdesk_dev/_staging/_prod` (ditambah `campusdesk_test` untuk CI).
- T6: `POSTGRES_USER=capstone` adalah superuser; user aplikasi non-superuser per env direncanakan di M6-2.

## Pertanyaan pemandu
1. Apa keuntungan DB di luar cluster dibanding StatefulSet/operator (mis. CloudNativePG) di dalam k3d?
2. Apa yang terjadi pada data kalau cluster k3d dihapus dan dibuat ulang?
3. Apa titik kegagalan tunggal (single point of failure) di desain ini, dan bagaimana menuliskannya tanpa mengklaim HA?
4. Kalau pindah ke CloudStack (desain), DB ini akan jadi apa (VM terpisah? layanan terkelola?)

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
