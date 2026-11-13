# ADR-013: Perubahan pada paket infrastruktur dosen

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | B |
| Milestone | M1 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
PRD §5 butir 7: paket dosen (`Final_Project/infrastructure`, `scripts`, `templates`) tidak diubah kecuali alasannya dicatat di ADR. Perubahan yang **sudah** dilakukan (detail: `Final_Project/CampusDesk_Rencana_Kerja.md` §4, bukti: `Final_Project/evidence-raw/`):

| # | File | Masalah | Perubahan | Tanggal |
|---|---|---|---|---|
| T8 | `scripts/_common.ps1` | Fungsi `Compose` menjadi *advanced function*, sehingga `-d` dibaca sebagai `-Debug`; `up-core`/`bootstrap-gitea` macet | Diganti fungsi biasa yang meneruskan `@args` | 28 Okt |
| T9 | `infrastructure/docker-compose.yml` | Gitea menunggu wizard (`INSTALL_LOCK=false`); user dan runner token tidak dibuat | Tambah `GITEA__security__INSTALL_LOCK: "true"` | 28 Okt |
| T10 | `templates/argocd/application.yaml` | `repoURL` ke `host.k3d.internal` ditolak dari pod | `repoURL: http://gitea:3000/student/capstone-gitops.git` | 28 Okt |
| T2 | `infrastructure/prometheus/prometheus.yml` (+ provisioning Grafana) | Target `host.docker.internal:8088` selalu 404 | Target `k3d-capstone-server-0:30081`; alasan detail di ADR-015 (owner C) | 10 Nov |

Diusulkan tapi belum dilakukan: **T11** (`create-cluster.ps1` mem-publish ingress di `0.0.0.0:8088`), dibahas C di M6, butuh membuat ulang cluster.

Penting untuk anggota lain: lab di laptop yang memakai paket dosen **asli** akan mengalami T8–T10 lagi. Lampirkan cara menerapkan perubahan yang sama (atau patch-nya).

## Pertanyaan pemandu
1. Untuk tiap perubahan: kenapa tidak bisa diselesaikan tanpa mengubah paket dosen?
2. Bagaimana anggota lain/dosen bisa mereproduksi lab dengan perubahan yang sama (patch, diff, atau langkah)?
3. Apakah ada perubahan yang sebaiknya dilaporkan ke dosen sebagai bug paket?
4. Apa risiko kalau paket dosen diperbarui dan perubahan ini tertimpa?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
