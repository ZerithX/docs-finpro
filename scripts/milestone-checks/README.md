# Pengecekan Milestone CampusDesk

Skrip yang memeriksa **kondisi lab yang sedang jalan** dan **isi folder evidence** untuk setiap milestone, lalu mencetak PASS / FAIL / SKIP. Hasilnya bisa disimpan sebagai evidence dan dijalankan ulang saat demo.

## Cara menjalankan (Git Bash, di laptop yang menjalankan lab)

```bash
cd "/d/Semester_5/Cloud Computing/campusdesk"
./scripts/milestone-checks/run-all.sh              # semua, hanya membaca
./scripts/milestone-checks/run-all.sh 03 06        # milestone tertentu
./scripts/milestone-checks/run-all.sh --write      # + transaksi inti OPEN->CLOSED dan uji 409
./scripts/milestone-checks/run-all.sh 08 --chaos   # + hapus pod (QS3) dan uji self-heal
bash scripts/milestone-checks/test-06-security.sh  # satu file saja
```

Hasil tersimpan di `11-demo-defense/checks/run-<waktu>.txt` (matikan dengan `--no-log`).

Prasyarat: lab menyala (`up-core`, cluster k3d, Keycloak; `up-observability` untuk 07), `kubectl` dengan context `k3d-capstone`, `curl`, `docker`. Tidak butuh `jq`.

## Arti hasil

| Hasil | Arti |
|---|---|
| PASS | Diperiksa langsung dan sesuai harapan |
| FAIL | Tidak sesuai, **atau tugasnya memang belum dikerjakan**. Pesan FAIL menyebut ID tugas di `docs/prd/` (misalnya `REL-4 (B)`) |
| SKIP | Prasyarat tidak tersedia (Prometheus mati, belum login, flag `--write`/`--chaos` tidak dipakai) |

Pada 24 Nov, sebagian besar FAIL masih wajar: sebagian besar menunjuk tugas B dan C yang belum dikerjakan. Tujuannya justru menjadi daftar periksa yang jujur.

## Aturan penamaan evidence (wajib agar terdeteksi)

Bukti setiap tugas ditulis di folder evidence-nya dengan nama file **diawali ID tugas** dari `docs/prd/`:

```
08-reliability-recovery/REL-1_hapus-pod.md
08-reliability-recovery/REL-4_restore-validasi.md
06-security/SEC-3_trivy.md
06-security/BE-5_BE-7_alur-authz.md     (satu file untuk dua tugas juga boleh)
```

README folder (template rencana isi) **tidak** dihitung sebagai bukti. Screenshot boleh memakai awalan yang sama (`REL-1_pod-ready.png`), tapi yang diperiksa skrip adalah keberadaan file catatannya.

## Isi per milestone

| File | Yang diperiksa | Demo final §13 |
|---|---|---|
| `test-01-business.sh` | Proposal ada, `approval.md` tidak PENDING | #1 |
| `test-02-architecture.sh` | Dokumen arsitektur, diagram, QS1–QS7, B1–B7 | — |
| `test-03-application-data.sh` | Readiness + DB, login 4 akun, isolasi `/api/units`, 4 kebijakan SLA, data di PostgreSQL; `--write`: tiket KRITIS dibuat (tenggat +30 menit), assign → IN_PROGRESS → RESOLVED → CLOSED, audit_log | #2, #3 |
| `test-04-platform-kubernetes.sh` | Node, deployment Ready, tag = SHA, probe, requests/limits, ingress, ConfigMap OIDC, Secret ada, jumlah ReplicaSet | #4 |
| `test-05-cicd-gitops.sh` | Guard CI, Trivy, tanpa `kubectl apply`, run CI terakhir, Argo CD Synced/Healthy + selfHeal, revisi Argo = HEAD GitOps, image cluster = `newTag`, tag → commit | #5, #6 |
| `test-06-security.sh` | 401 tanpa token/token palsu, isi token (groups, role, azp), 400, 404 lintas tenant, daftar userb tanpa tiket tenant-a, 403 assign, operator 200; `--write`: 409; tidak ada `.env`/Secret asli di Git | #7, #8 |
| `test-07-observability.sh` | Metrik HTTP dan metrik bisnis, target Prometheus UP, dasbor Grafana terpasang, dokumen SLO dan runbook | #9 |
| `test-08-reliability.sh` | `--chaos`: hapus pod (detik sampai Ready, data utuh) dan drift replica (detik sampai Argo CD mengembalikan); DB restore ada | #10, #11 |
| `test-09-capacity-finops.sh` | `kubectl top` vs requests/limits; evidence uji beban, biaya, roadmap | #12, #13 |
| `test-10-decisions-adr.sh` | Jumlah ADR dan yang masih draf | — |
| `test-11-demo-defense.sh` | Demo script, koleksi API, checklist, refleksi | — |

## Observasi M5 (`observe-07.sh`)

`test-07` memeriksa kondisi; `observe-07.sh` mengirim trafik curl lalu membuktikan trafik itu muncul di Prometheus dan Grafana, kemudian mencetak nilai panel dasbor. Hanya GET. Tidak ikut dijalankan `run-all.sh`.

```bash
bash scripts/milestone-checks/observe-07.sh
GRAFANA_AUTH='admin:<password>' bash scripts/milestone-checks/observe-07.sh   # kalau bukan admin/admin
```

Hasil: `07-observability-slo/observations/observe-<waktu>.txt` (matikan dengan `--no-log`).

## Catatan

- `--write` membuat tiket berjudul `[milestone-check] …` di unit tenant-a. Tiket ini tetap tersimpan (berguna juga sebagai data demo).
- `--chaos` menghapus satu pod dan menaikkan replica sementara. Karena replica hanya 1, layanan jeda beberapa detik. Jangan jalankan di tengah demo kecuali memang untuk langkah #10.
- Password akun uji memakai default paket dosen. Kalau berbeda: `export PW_usera=...` (juga `PW_userb`, `PW_operator`, `PW_appadmin`).
- Alamat lab bisa diganti lewat variabel lingkungan (lihat bagian atas `_common.sh`).
