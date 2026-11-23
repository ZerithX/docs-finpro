# PRD 05 · Capacity & FinOps + Roadmap

| Field | Isi |
|---|---|
| Owner | **C** (uji beban, biaya, roadmap). B: rightsizing di GitOps. Radya: data demo (BE-9) |
| Milestone | M8 Capacity & FinOps + Roadmap |
| Versi | v1.0, 23 Nov 2026 |
| Target | **Sab 28 Nov** |
| Folder evidence | `09-capacity-finops/` |
| Acuan | `docs/PRD_CampusDesk.md` §7 M8, §8 (QS4) · Guideline §17 (CloudStack) · Infrastructure Guide §24 |

---

## 1. Outcome

Saat defense, tim bisa menjelaskan **asumsi kapasitas dan biaya** (demo final #12) serta **dua risiko sisa dan roadmap** (demo final #13), dan menjawab: "Resource mana yang kelebihan atau kekurangan?" dan "Apa yang berubah kalau pindah dari k3d ke IaaS?" dengan angka hasil ukur.

## 2. Status per 23 Nov

Belum ada bukti. Data awal dari dasbor: memori sekitar 68 MiB dari request 192 Mi / limit 512 Mi, restart 0, trafik buatan sekitar 0,01 req/s.

## 3. Scope

**Wajib**
- CAP-1 Uji beban (QS4)
- CAP-2 Rightsizing sebelum/sesudah
- CAP-3 Model biaya per bulan, per tenant, per tiket
- CAP-4 Roadmap + risiko sisa + desain migrasi CloudStack

**Sebaiknya**
- CAP-5 Evaluasi satu kemampuan lanjutan (HPA, RLS, atau NetworkPolicy), cukup analisis tertulis

**Dipotong**: implementasi HPA atau autoscaling sungguhan (cukup dievaluasi di CAP-5).

## 4. Aturan

1. Setiap angka biaya menyebut **sumber dan tanggal** pengambilan harganya.
2. Uji beban dijalankan di lab resmi, dengan data demo (BE-9) bila sudah ada.
3. Rightsizing tidak boleh membuat pod gagal: buktikan pod tetap Ready dan SLO tetap terpenuhi setelah perubahan.

---

## 5. Requirement

### CAP-1 Uji beban · M8-1, QS4 · C · **Rab 25 – Kam 26**

- Alat: k6 (`winget install k6`) atau `hey`. Skenario: **20 pengguna bersamaan selama 2–3 menit** ke endpoint inti. Setelah BE-2, sertakan token `usera`; sebelum itu, pakai `GET /api/units` dan `GET /api/sla-policies` dan catat sebagai limitasi.
- Catat dari output alat: p95, error rate, jumlah request.
- Selama uji: `kubectl top pod -n capstone` setiap 15–30 detik, plus screenshot dasbor (p95, memori).

**Selesai jika:** tabel hasil (p95 vs target ≤ 500 ms, error rate vs < 1%, CPU dan memori puncak) dengan interpretasi.

### CAP-2 Rightsizing · M8-2 · B (berdasarkan data C) · **Jum 27**

| | Request CPU | Limit CPU | Request mem | Limit mem |
|---|---|---|---|---|
| Sebelum | 100m | 500m | 192Mi | 512Mi |
| Terpakai (puncak CAP-1) | | | | |
| Sesudah (usulan) | | | | |

Ubah lewat PR ke `capstone-gitops`, lalu jalankan ulang CAP-1 singkat untuk membuktikan p95 dan error rate tetap memenuhi target.

**Selesai jika:** tabel terisi, PR merged, dan uji ulang tercatat. Kalau keputusannya "tidak diubah", tulis alasannya berdasarkan data.

### CAP-3 Model biaya · M8-3 · C · **Jum 27**

1. Asumsi infrastruktur setara: misalnya 2 VM (control plane + worker) dan 1 VM database, ukuran sesuai hasil CAP-1/CAP-2. Ambil harga dari satu penyedia cloud publik (tulis nama, region, tanggal).
2. Biaya per bulan → **per unit (tenant)** → **per tiket** (asumsikan jumlah tiket per unit per bulan dan sebutkan dasarnya).
3. Bandingkan singkat dengan opsi CloudStack kampus (biaya jadi biaya operasional internal, bukan tagihan).

**Selesai jika:** worksheet dengan semua asumsi tertulis, sumber harga, dan hasil per tenant dan per tiket.

### CAP-4 Roadmap · M8-4 · C (semua berkontribusi) · **Sab 28**

- **Dua risiko sisa utama** (diambil dari SEC-5 dan REL), masing-masing dengan dampak dan langkah perbaikan.
- **Langkah prioritas berikutnya** (maksimal 5, berurutan).
- **Desain migrasi ke CloudStack**: apa yang berubah (VM, jaringan, volume, IP Ingress, database) dan apa yang tetap (repo, CI, Argo CD, manifest). Acuan Infrastructure Guide §24 dan diagram `02-architecture/diagrams/04-cloudstack-target.png`.
- Item yang dipotong dari PRD 01–04 masuk ke sini sebagai backlog.

**Selesai jika:** `09-capacity-finops/` memuat roadmap ini, dan setiap anggota bisa menyebut dua risiko sisa tanpa membaca.

### CAP-5 Evaluasi kemampuan lanjutan · M8-4 · C · *sebaiknya* · **Sab 28**

Pilih satu (saran: **HPA**, karena data CAP-1 sudah tersedia): manfaat, prasyarat (metrics-server, request CPU yang benar), risiko (migrasi saat scale-out sudah aman karena advisory lock), dan keputusan (terapkan sekarang / nanti / tidak).

---

## 6. Jadwal

| Hari | C | B | Radya |
|---|---|---|---|
| Rab 25 | CAP-1 versi awal (tanpa token) | — | — |
| Kam 26 | CAP-1 dengan token bila BE-2 sudah ada | — | — |
| Jum 27 | CAP-3 | CAP-2 | BE-9 seed data |
| Sab 28 | **CAP-4**, CAP-5 | Uji ulang CAP-2 | Review CAP-4 |

## 7. Evidence

`09-capacity-finops/`: skrip uji beban, output mentah, tabel hasil, tabel rightsizing, worksheet biaya dengan sumber, roadmap.

## 8. Risiko

| Risiko | Mitigasi |
|---|---|
| Laptop tidak kuat menjalankan uji beban sekaligus seluruh lab | Matikan runner CI selama uji; durasi pendek |
| Angka biaya tanpa sumber | Aturan §4.1; review oleh Radya |
| Endpoint inti (tiket) belum ada saat uji | Uji versi awal + ulang setelah BE selesai; catat limitasinya |
