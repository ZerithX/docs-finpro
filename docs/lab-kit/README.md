# Lab Kit CampusDesk: Menyamakan Lab Anggota dengan Lab Radya

> Disusun 17 Nov 2026 dari perbandingan `Final_Project/` (lab Radya) dengan paket asli dosen.
> Untuk: B dan C. Waktu: sekitar 60–90 menit (sebagian besar menunggu download image).
> Hasil akhir: `curl http://capstone.localhost:8088/api/units` di laptopmu mengembalikan `tenant-a` dan `tenant-b`, dideploy oleh CI dan Argo CD milikmu sendiri.

## Apa yang tersinkron, apa yang tidak

| Bagian | Cara sinkron |
|---|---|
| Kode aplikasi, manifest GitOps, dokumen | **GitHub** (`ZerithX/helpdesk-campus`, `ZerithX/helpdesk-gitops`, `ZerithX/docs-finpro`) |
| Perbaikan paket dosen (T2, T8, T9, T10) + dasbor Grafana | **Kit ini** (`apply-lab-kit.ps1`) |
| Gitea, registry, cluster k3d, PostgreSQL, Keycloak, Grafana | **Lokal di laptop masing-masing**, tidak tersinkron. Dibangun ulang lewat langkah di bawah. |
| Skema DB dan data seed (`tenant-a`, `tenant-b`) | Otomatis: migrasi jalan saat aplikasi start |
| Secret (`DB_PASSWORD`, `TEST_DB_PW`) | Dibuat manual, **tidak pernah di Git** |
| Mapper grup Keycloak | Menyusul lewat export realm (tugas C1) |

## Isi kit

| File | Perubahan | Alasan (detail di ADR-013, ADR-015) |
|---|---|---|
| `scripts/_common.ps1` | **T8** fungsi `Compose` biasa | Versi asli membaca `-d` sebagai `-Debug`, sehingga `up-core` macet |
| `infrastructure/docker-compose.yml` | **T9** `GITEA__security__INSTALL_LOCK: "true"` | Tanpa ini Gitea menunggu wizard, user dan token runner tidak dibuat |
| `templates/argocd/application.yaml` | **T10** `repoURL: http://gitea:3000/...` | `host.k3d.internal:3001` ditolak dari pod |
| `infrastructure/prometheus/prometheus.yml` | **T2** target `k3d-capstone-server-0:30081` | Target asli `host.docker.internal:8088` selalu 404 |
| `infrastructure/grafana/provisioning/dashboards/` | Dasbor "CampusDesk — Service Health" | Dashboard as code, sama dengan dasbor di presentasi |

`lab.patch` berisi perubahan yang sama dalam format diff, untuk dibaca atau direview. Yang dipakai untuk menerapkan adalah `apply-lab-kit.ps1`.

---

## Langkah

### 0. Prasyarat

- Docker Desktop (WSL2), Git, kubectl, k3d 5.9.0. RAM minimal 8 GB, disarankan 16 GB.
- Sudah diundang sebagai collaborator di ketiga repo GitHub `ZerithX/...` (minta ke Radya).
- Paket dosen asli: folder `Cloud_Computing_Common_Capstone_Infrastructure_Package`. Salin ke tempat kerja, misalnya `D:\CloudCapstone\Final_Project`.

### 1. Terapkan kit ke paket dosen

```powershell
cd <folder campusdesk>\docs\lab-kit
./apply-lab-kit.ps1 -PackageDir "D:\CloudCapstone\Final_Project"
```

Script menyalin 6 file, mencadangkan file asli ke `.lab-kit-backup-<tanggal>`, dan membuat `infrastructure\.env` dari `.env.example` bila belum ada. Kalau PowerShell menolak menjalankan script: `Set-ExecutionPolicy -Scope Process Bypass`.

### 2. Nyalakan lab (urutan sama dengan Radya, 28 Okt)

```powershell
cd D:\CloudCapstone\Final_Project
./scripts/doctor.ps1
./scripts/up-core.ps1
./scripts/bootstrap-gitea.ps1
./scripts/start-runner.ps1
./scripts/create-cluster.ps1
./scripts/smoke-test.ps1
./scripts/bootstrap-project.ps1
```

`bootstrap-project` membuat repo `capstone-app` dan `capstone-gitops` di Gitea lokal berisi **template dosen** dan mengisi secret CI `GITOPS_PASSWORD`. Template ini ditimpa dengan kode tim di langkah 4 dan 6.

### 3. Siapkan database tes dan Secret cluster

```powershell
# DB untuk tes otomatis di CI (namanya wajib berakhiran _test)
docker exec capstone-postgres psql -U capstone -c "CREATE DATABASE campusdesk_test;"

# Secret aplikasi di cluster (nilai = POSTGRES_PASSWORD di infrastructure\.env)
kubectl create namespace capstone --dry-run=client -o yaml | kubectl apply -f -
kubectl -n capstone create secret generic capstone-app-secret --from-literal=DB_PASSWORD=capstone
```

Lalu di Gitea (`http://127.0.0.1:3001`, login `student` / `student`): repo **capstone-app** → Settings → Actions → Secrets → tambah `TEST_DB_PW` = `capstone`.

### 4. Isi repo GitOps lokal dengan versi tim

```powershell
git clone https://github.com/ZerithX/helpdesk-gitops.git capstone-gitops
cd capstone-gitops
git remote add gitea http://127.0.0.1:3001/student/capstone-gitops.git
git push gitea main --force     # login student / student
```

### 5. Pasang Argo CD

```powershell
cd D:\CloudCapstone\Final_Project
./scripts/install-argocd.ps1
```

Argo CD langsung membaca `overlays/dev`. Pod akan **ImagePullBackOff** dulu: tag di repo GitOps menunjuk image yang hanya ada di registry Radya. Ini normal dan selesai di langkah 6.

### 6. Isi repo aplikasi, biarkan CI yang deploy

```powershell
git clone https://github.com/ZerithX/helpdesk-campus.git capstone-app
cd capstone-app
git remote add gitea http://127.0.0.1:3001/student/capstone-app.git
git push gitea main --force
```

Push ke `main` memicu CI di Gitea (Actions): verify → test → build → Trivy → push image → commit tag baru ke `capstone-gitops`. Argo CD lalu men-deploy image buatan laptopmu sendiri. Satu run sekitar 3–5 menit.

### 7. Cek hasil

```powershell
kubectl -n capstone get deploy,rs,pod
curl.exe http://capstone.localhost:8088/q/health/ready     # status UP, database UP
curl.exe http://capstone.localhost:8088/api/units          # tenant-a dan tenant-b
```

Swagger: `http://capstone.localhost:8088/q/swagger-ui`. Argo CD UI: `./scripts/argocd-ui.ps1`.

### 8. Observability (hanya saat dibutuhkan)

```powershell
./scripts/up-observability.ps1
```

Grafana di `http://127.0.0.1:3000` (`admin` / `admin`) → Dashboards → CampusDesk → **CampusDesk — Service Health**. Prometheus di `http://127.0.0.1:9090/targets`: job `capstone-app` harus **UP**.

---

## Aturan wajib setelah lab jalan

1. **GitHub adalah sumber kebenaran.** Kerja di branch dari `main` GitHub, kirim lewat PR di GitHub, direview anggota lain.
2. **Jangan pernah push repo GitOps dari Gitea lokal ke GitHub.** Commit `deploy: capstone-app <sha>` dari CI-mu menunjuk image yang hanya ada di laptopmu. Untuk perubahan manifest yang disengaja (overlay staging, resources), buat branch dari `origin/main`, bukan dari `gitea/main`.
3. **Update lab setelah ada merge di GitHub:**
   ```powershell
   cd capstone-app; git checkout main; git pull origin main; git push gitea main
   ```
   CI lokal akan build dan deploy versi terbaru.
4. **Evidence dari lab sendiri boleh**, asal dicatat: laptop siapa, versi commit aplikasi, timestamp, dan versi tool (lihat evidence standard di `README.md` root). Demo final tetap di lab Radya.
5. **Hemat RAM:** `docker compose ... stop` bila tidak dipakai. Nyalakan runner hanya saat CI, observability hanya saat mengambil bukti M5/M8.

## Kalau macet

| Gejala | Penyebab paling mungkin | Cek |
|---|---|---|
| `up-core` diam / error `-Debug` | T8 belum terpasang | `scripts/_common.ps1` berisi komentar `[CampusDesk T8]` |
| `bootstrap-gitea` gagal membuat user | T9 belum terpasang, atau Gitea sempat start tanpa T9 | Komentar `[CampusDesk T9]` di compose; kalau perlu `reset-lab.ps1` lalu ulang |
| Argo CD `ComparisonError` / repo tidak terjangkau | T10 | `kubectl -n argocd get application capstone-app -o yaml` → `repoURL` harus `http://gitea:3000/...` |
| Pod `CreateContainerConfigError` | Secret `capstone-app-secret` belum dibuat | Langkah 3 |
| Pod tetap `ImagePullBackOff` setelah CI hijau | CI belum menulis tag ke GitOps, atau Argo belum sync | Log CI baris `deploy: capstone-app ...`; Refresh di Argo CD |
| CI gagal di step Verify (tes) | DB `campusdesk_test` atau secret `TEST_DB_PW` belum ada | Langkah 3 |
| Target Prometheus DOWN | Service NodePort belum ter-deploy, atau T2 belum terpasang | `kubectl -n capstone get svc capstone-app-metrics` (port 30081) |
| `restore-postgres-validation.ps1` error | Temuan paket: butuh PowerShell 7, posisi parameter | Pakai `pwsh`; catat sebagai bukti di folder 08 (tugas B8) |

Masih macet: catat perintah dan output-nya, kirim ke grup. Jangan ubah file paket dosen lain tanpa dicatat di ADR-013.
