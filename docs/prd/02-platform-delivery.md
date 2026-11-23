# PRD 02 · Platform & Delivery (Kubernetes + CI/CD/GitOps)

| Field | Isi |
|---|---|
| Owner | **B** (Platform & Delivery). Radya: pairing di lab resmi dan review |
| Milestone | M3 Cloud-Native Platform, M4 Delivery Automation, ADR platform (M1) |
| Versi | v1.0, 23 Nov 2026 |
| Target | Semua wajib selesai **Jum 27 Nov** |
| Repo | `capstone-gitops` (GitHub `helpdesk-gitops`), `capstone-app` (`.gitea/workflows/ci.yml`), `campusdesk` (evidence) |
| Folder evidence | `04-platform-kubernetes/`, `05-ci-cd-gitops/`, `10-decisions-adr/` |
| Acuan | `docs/PRD_CampusDesk.md` §7 M3, M4 · `docs/HANDOFF_B_Platform.md` · `docs/lab-kit/README.md` |

---

## 1. Outcome

Saat defense, B bisa menunjukkan dan menjelaskan sendiri:

- Workload di Kubernetes beserta probe, resource, dan konfigurasinya (demo final #4).
- Run CI otomatis dan image immutable-nya (demo final #5).
- Status GitOps, hasil rollout, dan **rollback** (demo final #6).
- Satu tabel yang menelusuri satu perubahan dari commit sampai pod.

## 2. Status per 23 Nov

| Sudah terbukti | Belum |
|---|---|
| Deployment, Service, Ingress, probe, resources, ConfigMap/Secret | Bukti scale 1→2, `rollout history`, catatan troubleshooting |
| Image tag = commit SHA; 4 ReplicaSet | Tabel traceability tertulis |
| CI → registry → GitOps → Argo CD (PR #3 dan #4) | Latihan rollback |
| Self-heal Argo CD aktif (`selfHeal: true`) | Waktu merge → Running terukur (QS6) |
| | ADR 006, 007, 008, 010, 011, 013 (masih draf) |
| | Commit B = 0 |

## 3. Scope

**Wajib**
- PD-1 ConfigMap OIDC (dibutuhkan BE-2)
- PD-2 Bukti M3 lengkap
- PD-3 Tabel traceability + QS6
- PD-4 Latihan rollback
- PD-5 ADR platform

**Sebaiknya**
- PD-6 `.gitattributes` di kedua repo
- PD-7 Tag rilis `v0.1.0`

**Dipotong** (dijelaskan sebagai desain di ADR-011 dan roadmap)
| Item | Alasan |
|---|---|
| Overlay `staging` dan `prod`, 3 Argo CD Application, promosi lewat PR | Butuh namespace, DB, Secret, dan host baru per environment; tidak sempat diuji dengan benar sebelum defense. Mekanisme yang sama (build once, ubah tag lewat Git) sudah terbukti di dev. |
| Menghapus `namespace:` hard-coded di base | Hanya diperlukan untuk multi-environment |

## 4. Aturan

1. Cluster hanya diubah lewat Git (repo GitOps). Pengecualian: perintah uji yang memang sengaja (scale untuk uji self-heal, delete pod).
2. Secret tidak pernah di-commit. Hanya `*.example.yaml`.
3. Setiap perubahan manifest lewat PR di GitHub, direview anggota lain, lalu dicerminkan ke Gitea.
4. Setiap bukti dicatat dengan: scope, timestamp (WIB), versi commit, perintah, output, interpretasi, limitasi.
5. Langkah yang mengubah lab resmi dijalankan **berpasangan di laptop Radya**. Latihan boleh di lab sendiri (`docs/lab-kit/`).

---

## 5. Requirement

### PD-1 ConfigMap OIDC · M3-1 · B (atau Radya bila B belum siap) · **Sel 24**

Tambahkan ke `base/configmap.yaml`:
```yaml
OIDC_ISSUER: http://keycloak:8080/realms/capstone
OIDC_TOKEN_ISSUER: http://localhost:8081/realms/capstone
```
Ganti nilai lama `OIDC_ISSUER: http://host.k3d.internal:8081/...` (tidak terjangkau dari pod, ADR-012).

**Selesai jika:** PR merged, Argo CD Synced, dan `kubectl -n capstone get configmap capstone-app-config -o yaml` memuat kedua nilai.

### PD-2 Bukti M3 · M3-2, M3-3 · B · **Rab 25**

| Bukti | Perintah |
|---|---|
| Objek + registry path | `kubectl -n capstone get deploy,rs,pod,svc,ingress -o wide` |
| Riwayat rollout | `kubectl -n capstone rollout history deploy/capstone-app` + `rollout status` |
| Probe + resources | `kubectl -n capstone describe deploy capstone-app` |
| Log | `kubectl -n capstone logs deploy/capstone-app --tail=50` |
| Scale 1→2 | Ubah `replicas` di `overlays/dev` lewat PR (bukan `kubectl scale`, karena Argo CD akan mengembalikannya) → kedua pod Ready → cek log keduanya: migrasi hanya jalan sekali (advisory lock) → kembalikan ke 1 lewat PR |
| Troubleshooting | Satu kasus nyata yang pernah terjadi (misalnya T10: `DB_URL` ke `host.k3d.internal` ditolak dari pod), ditulis: gejala → penyebab → perbaikan → bukti |

**Selesai jika:** `04-platform-kubernetes/README.md` memuat semua bukti di atas, masing-masing dengan interpretasi.

### PD-3 Tabel traceability + QS6 · M4 · B · **Rab 25**

Satu tabel untuk PR #3 dan PR #4:

| Commit app | Run CI | Image tag | Digest | Commit GitOps | Revisi Argo CD | ReplicaSet |
|---|---|---|---|---|---|---|
| `d35da36` | #? | `d35da363e4c2` | `sha256:ce653b…` | `6f24740` | `6f24740` | `5bf4449848` |
| `bfe1773` | #? | `bfe17734cc8c` | dari log CI | `17d1dea` | `17d1dea` | `85fc6d899c` |

Lalu ukur **QS6** pada merge berikutnya (misalnya PR BE-2): waktu merge di GitHub → `git push gitea` → CI selesai → Argo CD Synced → pod Ready. Target ≤ 15 menit.

**Selesai jika:** tabel lengkap tanpa sel kosong; satu pengukuran QS6 dengan 5 timestamp.

### PD-4 Latihan rollback · M4-5 · B (pairing Radya) · **Kam 26**

1. Catat image yang sedang jalan.
2. Di `capstone-gitops`: `git revert <commit deploy terakhir>` lewat PR → merge → `git push gitea main`.
3. Argo CD sync → ReplicaSet lama aktif lagi → catat image dan waktunya.
4. Revert balik (roll forward) dengan cara yang sama.

**Selesai jika:** `05-ci-cd-gitops/` berisi timestamp tiap langkah, image sebelum/sesudah, dan interpretasi: "rollback = perubahan Git, bukan `kubectl`".

### PD-5 ADR platform · M1 · B · **Rab 25**

ADR 006 (ConfigMap/Secret), 007 (GitOps build once), 008 (PostgreSQL di luar cluster), 010 (`DB_URL` via service `postgres`), 011 (satu environment di lab, desain 3 environment), 013 (perubahan paket dosen, lampirkan `docs/lab-kit/lab.patch`). Satu PR per ADR, review oleh C.

**Selesai jika:** 6 PR merged dan B bisa menjelaskan tiap ADR dalam ±1 menit.

### PD-6 `.gitattributes` · M4-6 · B · *sebaiknya* · **Jum 27**

`* text=auto eol=lf` (+ `*.ps1 text eol=crlf`) di `capstone-app` dan `capstone-gitops`, supaya CRLF tidak masuk ke runner dan tidak muncul lagi perubahan palsu seperti `overlays/dev/kustomization.yaml` pada 17 Nov.

### PD-7 Tag rilis · M4-4 · B · *sebaiknya* · **Jum 27**

Setelah freeze (BE selesai): `git tag v0.1.0` di commit `main` app, push ke GitHub dan Gitea, catat pemetaan `v0.1.0` → SHA → image tag.

---

## 6. Jadwal

| Hari | B | Pairing dengan Radya |
|---|---|---|
| Sen 23 | Jalankan lab sendiri (`docs/lab-kit/`); mulai PD-5 | — |
| Sel 24 | PD-1 (PR), PD-5 | — |
| Rab 25 | PD-2, PD-3, **PD-5 selesai** | Scale 1→2 |
| Kam 26 | PD-4 | Rollback |
| Jum 27 | PD-6, PD-7, rapikan `04-` dan `05-` | — |

## 7. Evidence

| Folder | Isi |
|---|---|
| `04-platform-kubernetes/` | Objek, probe, resources, rollout history, scale 1→2, troubleshooting |
| `05-ci-cd-gitops/` | Tabel traceability, QS6, rollback, tag rilis |
| `10-decisions-adr/` | ADR 006, 007, 008, 010, 011, 013 |

## 8. Risiko

| Risiko | Mitigasi |
|---|---|
| B belum bisa menjalankan lab sendiri | Kerjakan bukti di laptop Radya secara pairing; B yang mengetik dan mencatat |
| Rollback meninggalkan cluster di versi lama | Langkah 4 (roll forward) wajib, cek image sesudahnya |
| Scale 2 replica memicu migrasi ganda | Advisory lock sudah ada; ini justru yang dibuktikan di PD-2 |
