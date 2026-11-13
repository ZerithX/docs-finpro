# ADR-005: Tenggat SLA dihitung dan disimpan saat tiket dibuat

| Field | Isi |
|---|---|
| Status | Diusulkan |
| Tanggal | 2026-11-13 |
| Owner | Radya |
| Milestone | M1 (keputusan), M2 (implementasi R4) |

> Draf disiapkan dengan bantuan Claude dari dokumen tim. Fitur tiket belum diimplementasikan; keputusan ini dipakai sebagai acuan R4.

## Konteks
- SLA berdasarkan prioritas (KRITIS/TINGGI/SEDANG/RENDAH). Tabel `sla_policy` sudah ada (`drizzle/0001_sla_policy.sql`, branch `feat/sla-policy`), dengan nilai usulan 30/240, 60/480, 240/1440, 480/4320 menit (respon/selesai).
- Admin bisa mengubah kebijakan SLA (`PUT /api/sla-policies`). Kalau tenggat dihitung ulang dari kebijakan terkini, tiket lama ikut berubah status SLA-nya.
- Laporan SLA per unit dan metrik `campusdesk_sla_breached_tickets` harus konsisten walaupun aplikasi berjalan dengan lebih dari satu replica.

## Keputusan
Saat tiket dibuat, aplikasi membaca kebijakan untuk prioritas tiket lalu **menyimpan `response_due_at` dan `resolve_due_at`** di baris tiket. `first_response_at` diisi pada transisi pertama `OPEN → ASSIGNED`. Tiket dinyatakan **breach lewat query** (`now() > due_at` dan timestamp pasangannya masih kosong), bukan lewat job terjadwal yang menulis flag.

## Alternatif yang dipertimbangkan
- **Hitung tenggat setiap kali dibaca dari kebijakan terkini:** tidak ada kolom tambahan, tapi perubahan kebijakan mengubah riwayat secara diam-diam, sehingga laporan SLA bulan lalu bisa berbeda kalau dibuka hari ini. Ditolak karena merusak audit.
- **Scheduler yang menandai `breached = true`:** query laporan lebih sederhana, tapi dengan replica > 1 setiap pod menjalankan job yang sama (butuh leader election atau lock), dan nilai bisa basi di antara dua jadwal. Ditolak.
- **Simpan `policy_id` saja dan join saat dibaca:** tetap ikut berubah kalau baris kebijakan di-update. Ditolak.

## Konsekuensi
- **Positif:** riwayat SLA stabil dan bisa diaudit; tidak ada job latar sehingga aman di banyak replica; breach bisa dites deterministik dengan jam tetap (fixed clock).
- **Negatif / risiko sisa:** perubahan kebijakan hanya berlaku untuk tiket baru (harus dijelaskan ke admin); dua kolom tambahan per tiket; query laporan sedikit lebih kompleks.
- **Perlu dibuktikan:** tes "tiket melewati `response_due_at` tanpa assign → breach" dengan jam tetap (acceptance M2, QS2); tiket yang dibuat sebelum dan sesudah perubahan kebijakan punya tenggat berbeda.
