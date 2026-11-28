# PRD 04 · Operations & Reliability (Observability + Pemulihan)

| Field | Isi |
|---|---|
| Owner | Observability: **C**. Reliability & recovery: **B**. Radya: pairing di lab resmi + metrik bisnis (BE-8) |
| Milestone | M5 Operations & SLO (sisa), M7 Reliability & Recovery |
| Versi | v1.0, 23 Nov 2026 |
| Target | REL wajib **Kam 26 Nov**; OPS wajib **Jum 27 Nov** |
| Folder evidence | `07-observability-slo/`, `08-reliability-recovery/` |
| Acuan | `docs/PRD_CampusDesk.md` §7 M5, M7, §8 (QS3, QS5, QS7) · `docs/archive/BRIEF_C_M5_Observability.md` (riwayat) · Infrastructure Guide §18 (backup/restore) |

---

## 1. Outcome

Saat defense, tim bisa:

- Menunjukkan dasbor dan menjelaskan **satu SLI/SLO** untuk Kepala Unit TI (demo final #9).
- **Menggagalkan satu komponen secara terkendali** dan menunjukkan pemulihannya (demo final #10).
- Menunjukkan **bukti restore** database yang divalidasi, bukan sekadar file backup (demo final #11).
- Menjawab: "Target pemulihan kalian berapa, dan sudah diuji?" dengan angka hasil ukur.

## 2. Status per 23 Nov

| Sudah ada | Belum |
|---|---|
| Prometheus target UP, dasbor "CampusDesk — Service Health" (dashboard as code) | Dokumen SLI/SLO + runbook |
| SLO teknis tampil: non-5xx (100%), p95 (23,5 ms) | Uji lonjakan error (QS7) |
| Readiness mengecek DB (kode `health.ts`) | Bukti readiness turun saat DB mati |
| Self-heal Argo CD aktif | Bukti hapus pod (QS3), drift, restore (QS5) |
| | Panel tiket per unit (menunggu BE-8) |

## 3. Scope

**Wajib**
- REL-1 Hapus pod → pulih (QS3)
- REL-2 Drift manual → self-heal
- REL-3 Database mati → readiness turun → pulih (sekaligus bahan QS7)
- REL-4 Backup → restore → validasi (QS5)
- OPS-1 Dokumen SLI/SLO
- OPS-2 Runbook singkat

**Sebaiknya**
- OPS-3 Panel tiket per unit di dasbor
- REL-5 Restore ulang setelah ada data tiket

**Dipotong**
| Item | Alasan | Dicatat sebagai |
|---|---|---|
| Log terpusat (Loki dsb.) | Di luar paket lab dan waktu | Limitasi; log dibaca lewat `kubectl logs` |
| Alerting otomatis | Sama | Roadmap |
| Histogram waktu respons pertama | Diganti gauge breach (BE-8) | Catatan M5 |

## 4. Aturan

1. Uji kegagalan dijalankan **di lab resmi (laptop Radya) secara berpasangan**. B atau C yang mengetik perintah dan mencatat.
2. Setiap uji dicatat dengan **waktu mulai, waktu pulih, perintah, output, dan interpretasi**. Jalankan `date` sebelum dan sesudah setiap langkah.
3. Restore **tidak pernah** menimpa database aktif: selalu ke database `*_restore_validation`.
4. Angka yang ditulis adalah hasil ukur, bukan perkiraan.

---

## 5. Requirement: Reliability (B)

### REL-1 Hapus pod · M7-1, QS3 · B · **Sel 24**

```bash
date; kubectl -n capstone delete pod -l app=capstone-app
kubectl -n capstone get pod -w        # sampai pod baru 1/1 Ready
date
curl -s http://capstone.localhost:8088/api/units
```
**Selesai jika:** waktu sampai Ready terukur (target ≤ 60 detik), data tetap ada, dan interpretasi menyebut jeda layanan karena replica hanya 1.

### REL-2 Drift → self-heal · M7-1 · B · **Sel 24**

```bash
date; kubectl -n capstone scale deploy capstone-app --replicas=3
kubectl -n capstone get pod -w        # Argo CD mengembalikan ke 1
date
```
Screenshot Argo CD saat *OutOfSync* lalu kembali *Synced*.

**Selesai jika:** waktu sampai kembali ke 1 replica terukur, dan interpretasi menjelaskan "sumber kebenaran adalah Git".

### REL-3 Database mati · M7-1, QS7 · B (+ C mengamati dasbor) · **Rab 25**

1. Jalankan trafik ringan (skrip `milestone_p13/07-observ/script.txt`).
2. `date; docker stop capstone-postgres`
3. Amati: `kubectl -n capstone get pod` (READY 0/1), `curl .../q/health/ready` (DOWN / 503), respons `/api/units`, dan dasbor (status layanan, non-5xx, request per status).
4. `date; docker start capstone-postgres` → tunggu pod Ready → `date`.

**Selesai jika:** tercatat (a) berapa detik sampai readiness turun, (b) apa yang dilihat pengguna (kode HTTP), (c) **apa yang tampil di dasbor dan berapa detik setelahnya** (QS7, target ≤ 1 menit), (d) waktu pulih. Catat jujur kalau yang terlihat di dasbor adalah status DOWN, bukan lonjakan 5xx: ketika pod keluar dari Service, request tidak sampai ke aplikasi.

### REL-4 Backup → restore → validasi · M7-2, M7-3, QS5 · B (pairing Radya) · **Kam 26**

Ikuti Infrastructure Guide §18. Skrip `.ps1` butuh **PowerShell 7** (`pwsh`, temuan T3).
1. Sebelum backup: catat `count(*)` tiap tabel + 3 baris bisnis (misalnya `sla_policy` KRITIS, dua unit).
2. `pwsh ./scripts/backup-postgres.ps1` → catat timestamp dan ukuran file.
3. `date; pwsh ./scripts/restore-postgres-validation.ps1 <file>.dump; date`
4. Query yang sama di `capstone_restore_validation` → bandingkan.
5. RTO terukur vs target ≤ 30 menit. RPO = umur backup terakhir. Tulis limitasi: satu node, satu database, tanpa HA, backup manual.

**Selesai jika:** tabel sebelum/sesudah identik, ada output query validasi (bukan hanya file `.dump`), dan RTO/RPO tertulis. Kalau skrip `.ps1` gagal, catat errornya sebagai temuan lalu pakai versi `.sh` lewat Git Bash.

### REL-5 Restore dengan data tiket · B · *sebaiknya* · **Sab 28**

Ulangi REL-4 setelah BE-9 (seed tiket) supaya validasi mencakup tiket dan `audit_log`.

---

## 6. Requirement: Operations (C)

### OPS-1 Dokumen SLI/SLO · M5-4 · C · **Kam 26**

| SLI | Definisi (query) | SLO | Audiens |
|---|---|---|---|
| Ketersediaan | % request `/api/*` non-5xx, 5 menit | ≥ 99% | Kepala Unit TI |
| Latensi | p95 durasi request `/api/*` | ≤ 500 ms | Kepala Unit TI |
| Bisnis | % tiket direspons dalam SLA per unit | ≥ 95% | Kepala Unit TI, pimpinan unit |

Jelaskan: kenapa `/q/*` dan 404 tidak dihitung, jendela pengukuran, dan bahwa trafik saat ini masih buatan. SLI bisnis diukur setelah BE-6/BE-8 ada.

**Selesai jika:** `07-observability-slo/` memuat tabel ini dengan query PromQL persisnya dan satu screenshot dasbor yang diinterpretasi.

### OPS-2 Runbook · M5-5 · C · **Kam 26**

Dua skenario, masing-masing 5–8 langkah: (1) status layanan DOWN atau non-5xx turun, (2) % SLA tiket turun. Gunakan hasil REL-3 sebagai contoh nyata.

### OPS-3 Panel tiket per unit · M5-3 · C · *sebaiknya* · **Jum 27**

Setelah BE-8: tambahkan panel `campusdesk_tickets_created_total` per tenant dan `campusdesk_sla_breached_tickets` ke JSON dasbor di repo (bukan lewat UI), lalu provisioning ulang Grafana.

---

## 7. Jadwal

| Hari | B | C | Pairing di lab Radya |
|---|---|---|---|
| Sel 24 | REL-1, REL-2 | Amati dasbor saat REL-1 | ✔ |
| Rab 25 | REL-3 | Amati dasbor + catat QS7 | ✔ |
| Kam 26 | **REL-4** | OPS-1, OPS-2 | ✔ (REL-4) |
| Jum 27 | Rapikan `08-` | OPS-3 | — |
| Sab 28 | REL-5 | — | ✔ |

## 8. Evidence

| Folder | Isi |
|---|---|
| `07-observability-slo/` | Tabel SLI/SLO + PromQL, runbook, screenshot dasbor saat normal dan saat REL-3, JSON dasbor |
| `08-reliability-recovery/` | REL-1 s.d. REL-4: perintah, timestamp, output, interpretasi, tabel restore sebelum/sesudah, RTO/RPO |

## 9. Risiko

| Risiko | Mitigasi |
|---|---|
| Skrip restore `.ps1` gagal (T3) | Siapkan `pwsh`; versi `.sh` sebagai cadangan; kegagalan itu sendiri dicatat sebagai temuan |
| Lab resmi rusak setelah uji | Jalankan REL-4 setelah REL-1–3; jangan pernah restore ke DB aktif |
| QS7 tidak terlihat sebagai lonjakan 5xx | Catat apa yang benar-benar terlihat (status DOWN) dan jelaskan kenapa |
