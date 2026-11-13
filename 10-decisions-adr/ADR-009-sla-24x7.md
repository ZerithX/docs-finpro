# ADR-009: SLA dihitung 24x7 tanpa kalender jam kerja

| Field | Isi |
|---|---|
| Status | Diusulkan |
| Tanggal | 2026-11-13 |
| Owner | Radya |
| Milestone | M1 |

> Draf disiapkan dengan bantuan Claude dari dokumen tim. Menunggu jawaban dosen (pertanyaan nomor 5 di proposal).

## Konteks
- Layanan TI kampus pada kenyataannya punya jam kerja dan hari libur. Menghitung tenggat berdasarkan jam kerja butuh kalender kerja, hari libur nasional/kampus, dan aturan jeda.
- PRD §4 menaruh *business-hours calendar/holidays* di luar scope. Feature freeze 17 Nov.
- Yang ingin dibuktikan di capstone adalah SLA sebagai tujuan bisnis yang terukur (SLO ≥ 95% respon pertama tepat waktu), bukan kerumitan aturan kalender.

## Keputusan
Tenggat SLA dihitung **24 jam × 7 hari**: `due_at = created_at + menit_kebijakan`, tanpa memperhitungkan jam kerja atau hari libur. Batasan ini ditulis eksplisit di proposal dan laporan akhir.

## Alternatif yang dipertimbangkan
- **Kalender jam kerja penuh (Senin–Jumat 08–16 + hari libur):** paling realistis, tapi butuh tabel kalender, logika lintas hari, dan banyak kasus uji tepi. Tidak muat sebelum freeze. Ditolak untuk MVP, masuk roadmap.
- **Campuran (KRITIS 24x7, prioritas lain jam kerja):** lebih realistis untuk insiden kritis, tapi tetap membutuhkan logika kalender. Ditolak untuk MVP.

## Konsekuensi
- **Positif:** aritmetika tenggat sederhana dan mudah diuji; laporan SLA mudah dijelaskan.
- **Negatif / risiko sisa:** tiket yang masuk di luar jam kerja (mis. Jumat malam) akan tercatat breach walaupun secara operasional wajar. Persentase SLA cenderung lebih rendah daripada kenyataan.
- **Perlu dipantau:** jawaban dosen; kalau ditolak, ADR ini diganti ADR baru. Kalender jam kerja dicatat di roadmap M8.
