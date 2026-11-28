# docs/: Dokumen Kerja Tim

Folder ini berisi dokumen **kerja** (rencana, tugas, status). Isinya **bukan evidence**: bukti disimpan di folder bernomor `01-business/` … `11-demo-defense/` di root repo.

## Urutan baca

| Urutan | File | Isi | Kapan dipakai |
|---|---|---|---|
| 1 | [`PROGRESS.md`](PROGRESS.md) | Status milestone, log per ID tugas, pekerjaan terbuka | Awal setiap sesi kerja |
| 2 | [`prd/00-INDEX.md`](prd/00-INDEX.md) | Daftar PRD per area, **status per ID tugas**, kalender, aturan bersama | Memilih tugas berikutnya |
| 3 | `prd/01-…06-*.md` | Requirement + kriteria "Selesai jika" per ID (BE-, PD-, SEC-, REL-, OPS-, CAP-, FD-) | Saat mengerjakan satu ID |
| 4 | [`PRD_CampusDesk.md`](PRD_CampusDesk.md) | Desain: peran, alur status, kontrak API, quality scenario QS1–QS7 | Acuan desain. Untuk **scope dan jadwal**, `prd/` yang berlaku |
| 5 | [`HANDOFF_Radya_Backend.md`](HANDOFF_Radya_Backend.md) | Langkah teknis backend (R1–R8, sebelum ada ID BE-) | Detail teknis auth/tiket |
| 6 | [`lab-kit/`](lab-kit/README.md) | Kit untuk menyamakan lab B dan C dengan lab Radya | Menyiapkan lab di laptop lain |

## Riwayat

[`archive/`](archive/README.md): pembagian tugas lama (`TASKS_M2-M5`, `TASKS_M6-M8` + PDF), handoff B dan handoff platform v1, brief M5 untuk C. Semua sudah digantikan oleh `prd/`. Disimpan untuk menjelaskan riwayat keputusan saat defense; **jangan dipakai sebagai acuan scope**.

## Aturan singkat

- Kalau dua dokumen berbeda soal scope: Guideline dosen > `prd/` > `PRD_CampusDesk.md` > `archive/`.
- Setiap tugas selesai dicatat di `PROGRESS.md` dengan ID-nya, lalu status di `prd/00-INDEX.md` diperbarui.
- Jangan menulis hasil yang tidak benar-benar dijalankan; yang belum terbukti ditulis sebagai limitasi.
