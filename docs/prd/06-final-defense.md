# PRD 06 · Final Submission & Defense

| Field | Isi |
|---|---|
| Owner | **Semua**. Koordinator: Radya. Demo script + koleksi API: B. Checklist §16: C |
| Milestone | M0 (penutupan), FINAL Demo & Defense |
| Versi | v1.0, 23 Nov 2026 |
| Target | Dokumen lengkap **Sel 1 Des**; defense **±2 Des** |
| Folder | `01-business/`, `11-demo-defense/`, laporan final, refleksi individu |
| Acuan | Guideline §12 (deliverable), §13 (13 langkah demo + bank pertanyaan), §14.2 (quality gate), §15 (struktur submission), §15.1 (outline laporan), §16 (checklist akhir) |

---

## 1. Outcome

Tanggal 2 Desember: tim menjalankan **13 langkah demo §13** secara live dalam 20–25 menit tanpa berhenti untuk debugging, **setiap anggota** bisa menjawab pertanyaan §13.1 tentang bagian mana pun, dan seluruh deliverable §12 sudah dikumpulkan.

## 2. Status per 23 Nov

| Ada | Belum |
|---|---|
| Struktur folder `01-` s.d. `11-`, README tiap folder | `approval.md` masih PENDING |
| Proposal M0 v0.1 | Demo script, koleksi API |
| Arsitektur (`02-architecture/`), ADR 001–015 (draf) | Laporan final, refleksi individu |
| Evidence M3–M5 sebagian (`milestone_p13/`) | Evidence belum memakai standar (scope, timestamp, interpretasi, limitasi); dua screenshot 17 Nov belum dipindahkan |
| | Commit B dan C = 0 (risiko Guideline §4) |

## 3. Scope

**Wajib**
- FD-1 Tutup M0 (approval)
- FD-2 Koleksi API + demo script 13 langkah
- FD-3 Rapikan evidence ke standar
- FD-4 Laporan final 12 bagian
- FD-5 Refleksi individu + log kontribusi
- FD-6 Struktur submission §15
- FD-7 Dua kali gladi + bank pertanyaan
- FD-8 Checklist §16 dengan tautan bukti

**Dipotong**: video demo lengkap. Cukup screenshot cadangan per langkah demo.

## 4. Aturan

1. Tidak ada screenshot, output, metrik, atau hasil scan yang dikarang (quality gate §14.2). Yang belum terbukti ditulis sebagai limitasi.
2. Setiap anggota punya **minimal satu PR sendiri yang sudah di-merge** sebelum 1 Des, dan log kontribusinya cocok dengan riwayat Git.
3. Klaim di laporan harus menautkan bukti di folder evidence.

---

## 5. Requirement

### FD-1 Tutup M0 · C · **Sel 24**

Isi `01-business/approval.md` dengan jawaban dosen yang sebenarnya (presentasi 17 Nov): status persetujuan, jawaban 6 pertanyaan konfirmasi, dan keputusan soal substitusi teknologi. Kalau belum ada jawaban tertulis, kirim proposal hari ini dan catat tanggalnya. Perbarui `proposal.md` bila ada revisi.

**Selesai jika:** status di `approval.md` bukan PENDING, atau tercatat tanggal pengiriman dan media.

### FD-2 Koleksi API + demo script · B · koleksi **Kam 26**, script **Min 29**

1. **Koleksi API** (`11-demo-defense/api/campusdesk.http` untuk VS Code REST Client, atau Bruno/Postman): ambil token `usera`, `userb`, `operator`, `appadmin`; semua endpoint di PRD 01 §6; kasus yang harus ditolak (401, 403, 404, 409).
2. **Demo script** (`11-demo-defense/demo-script.md`): 13 langkah §13. Setiap langkah berisi: siapa yang bicara, apa yang dibuka, **perintah persis**, hasil yang diharapkan, dan **screenshot cadangan**. Sumber bukti tiap langkah:

| # | Langkah §13 | Dari |
|---|---|---|
| 1 | Masalah + alasan cloud | Proposal |
| 2 | Login + transaksi inti | PRD 01 (BE-2, BE-4, BE-5) |
| 3 | Data persist | REL-1 |
| 4 | Workload + endpoint | PD-2 |
| 5 | CI + image immutable | PD-3 |
| 6 | GitOps + rollout | PD-3, PD-4 |
| 7 | Aksi ditolak | BE-7, SEC-2 |
| 8 | Temuan scan prioritas | SEC-3 |
| 9 | Dasbor + SLI/SLO | OPS-1 |
| 10 | Gagalkan komponen → pulih | REL-1, REL-2, REL-3 |
| 11 | Backup → restore | REL-4 |
| 12 | Kapasitas + biaya | CAP-1, CAP-3 |
| 13 | Risiko sisa + roadmap | CAP-4 |

**Selesai jika:** koleksi API jalan terhadap cluster, dan script sudah dijalankan penuh sekali tanpa improvisasi.

### FD-3 Rapikan evidence · pemilik masing-masing folder · **Sen 30**

- Pindahkan isi `milestone_p13/` ke folder bernomor (`03-`, `04-`, `05-`, `07-`), termasuk `03_evidence(01).png` → `03-application-data/` dan `07_argoCD(#4).png` → `05-ci-cd-gitops/`.
- Setiap folder punya README dengan tabel bukti: scope, owner, versi/commit, timestamp, metode, observasi, interpretasi, limitasi, keputusan yang didukung.
- Commit `docs/PROGRESS.md` yang tertunda.

### FD-4 Laporan final · semua · draf **Min 29**, final **Sel 1 Des**

Mengikuti outline §15.1. Pembagian penulis (setiap bagian menautkan evidence):

| Bagian | Penulis | Sumber |
|---|---|---|
| 1 Executive Summary | Radya | Semua |
| 2 Problem & Cloud Rationale | C | Proposal |
| 3 Architecture | Radya | `02-architecture/`, ADR |
| 4 Application & Data | Radya | PRD 01 |
| 5 Platform & Deployment | B | PRD 02 |
| 6 Delivery Automation | B | PRD 02 |
| 7 Security | C | PRD 03 |
| 8 Operations & Observability | C | PRD 04 (OPS) |
| 9 Reliability & Recovery | B | PRD 04 (REL) |
| 10 Capacity & FinOps | C | PRD 05 |
| 11 Limitations & Residual Risk | Semua | Bagian "dipotong" PRD 01–05 + SEC-5 |
| 12 Improvement Roadmap | C | CAP-4 |

Diekspor ke `final-report.pdf`.

### FD-5 Refleksi individu + log kontribusi · masing-masing · **Sel 1 Des**

Setiap anggota menulis (Guideline §12-H): kontribusi (tautkan PR), pembelajaran teknis, satu keputusan desain atau perbedaan pendapat (misalnya pertukaran peran 10 Nov, substitusi stack, scope yang dipotong), dan perbaikan berikutnya.

### FD-6 Struktur submission · Radya · **Sel 1 Des**

Petakan folder kerja ke struktur §15 (`architecture/`, `source/`, `deployment/`, `automation/`, `evidence/<domain>/`, `decisions/`, `demo/`, `individual-reflections/`, `final-report.pdf`). Sumber kode cukup ditautkan ke repo `helpdesk-campus` dan `helpdesk-gitops` pada commit final, lewat `source/README.md`.

### FD-7 Gladi · semua · **Min 29** dan **Sel 1 Des**

Dua kali gladi penuh dengan demo script, diukur waktunya (target 20–25 menit). Setelah tiap gladi: 15 menit tanya jawab acak dari bank §13.1, **ditanyakan ke anggota yang bukan pemilik bagiannya**. Catat pertanyaan yang tidak terjawab dan perbaiki sebelum gladi berikutnya.

### FD-8 Checklist §16 · C · **Sel 1 Des**

Salin 18 butir Guideline §16 ke `11-demo-defense/checklist.md`. Setiap butir dicentang hanya dengan **tautan ke bukti**. Butir yang tidak bisa dicentang ditulis sebagai limitasi di laporan bagian 11.

---

## 6. Jadwal

| Hari | Radya | B | C |
|---|---|---|---|
| Sel 24 | — | — | **FD-1** |
| Kam 26 | — | FD-2 koleksi API | — |
| Sab 28 | Bagian 1, 3, 4 | FD-2 demo script; bagian 5, 6, 9 | Bagian 2, 7, 8, 10, 12 |
| Min 29 | FD-3 bagian sendiri; **gladi 1** | FD-2 selesai; FD-3; gladi 1 | FD-3; gladi 1 |
| Sen 30 | Gabung laporan, bagian 11 | Perbaiki demo script | FD-8 |
| **Sel 1 Des** | FD-6, kumpulkan; **gladi 2** | FD-5; gladi 2 | FD-5; gladi 2 |

## 7. Risiko

| Risiko | Mitigasi |
|---|---|
| Lab gagal saat defense | Screenshot cadangan per langkah di demo script; nyalakan lab 1 jam sebelumnya |
| Anggota tidak bisa menjawab di luar bagiannya | Gladi dengan pertanyaan silang (FD-7) |
| Kontribusi B/C tidak terlihat di Git | Semua pekerjaan PRD 02–05 lewat PR atas nama masing-masing |
| Laporan tidak cocok dengan kondisi sebenarnya | Setiap klaim wajib menautkan bukti (aturan §4.3) |
