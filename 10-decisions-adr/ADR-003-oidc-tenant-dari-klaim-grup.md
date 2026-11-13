# ADR-003: OIDC Keycloak, tenant dari klaim `groups`, akses lintas tenant → 404

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | C |
| Milestone | M1 / M2 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
- Realm `capstone` dosen punya role `user`, `operator`, `admin`, tetapi **tidak punya mapper grup** ke token (T1). Tugas C1: tambah *Group Membership mapper* (claim `groups`) di client `capstone-app`, export realm tanpa secret, decode token `usera`/`userb`/`operator` sebagai bukti di `06-security/`.
- Setelah mapper aktif, token berisi `groups: ["/tenant-a"]`. Role dibaca dari `realm_access.roles`, **bukan** dari `groups` (TASKS temuan 6). Pemetaan tenant: `/tenant-a` → `units.code = tenant-a`.
- Proposal: authZ berbasis role **[PUTUS]**; akses `user` ke tiket unit lain menghasilkan **404** agar tidak membocorkan keberadaan tiket **[USUL]**, difinalkan di ADR ini. Acceptance M2 menulis "404 (atau 403, sesuai ADR 003)".
- Detail issuer token/JWKS dicatat terpisah di ADR-012 (Radya).

## Pertanyaan pemandu
1. Kenapa tenant diambil dari token, dan apa serangan yang terjadi kalau tenant diambil dari header/query?
2. 404 atau 403 untuk tiket tenant lain? Apa yang bocor dengan 403? Apa kerugian 404 (debugging, kejelasan bagi pengguna)?
3. Apa yang terjadi kalau user tidak punya grup, atau punya dua grup?
4. Kenapa role tidak diambil dari `groups`?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
