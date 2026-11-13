# Handoff: Tugas B (Platform & Delivery) B1–B6

> Dibuat 10 Nov 2026 (v2, setelah peran ditukar). Sumber: `docs/TASKS_M2-M5.md` §3 dan `docs/PRD_CampusDesk.md` (M3, M4). Aturan proyek: `AGENTS.md`.
> **Untuk B dan Claude Code:** kerjakan **satu tugas per branch/PR**, plan mode dulu. Jangan menulis hasil yang tidak benar-benar dijalankan. Setelah tiap tugas, tambahkan entri di `docs/PROGRESS.md`. Item [CEK] harus dibuktikan dulu.
> Repo utama B: **`capstone-gitops`** (desired state Kubernetes) dan repo portofolio **`cloud-capstone-<tim>`** (B1). B tidak perlu menulis Java.

## Sebelum Mulai: Pahami Alurnya (30 Menit)

```
push ke main (capstone-app) → Gitea CI: test → build image (tag = SHA) → Trivy → push ke registry
    → CI mengubah newTag di capstone-gitops/overlays/dev → Argo CD melihat commit baru → deploy ke k3d
```

- **Kustomize:** `base/` berisi manifest bersama; `overlays/<env>/` berisi perbedaan per environment.
- **Argo CD:** membaca repo GitOps dan menyamakan isi cluster dengan isi repo. Mengubah cluster langsung dengan `kubectl edit` akan dikembalikan (self-heal).
- **Lab resmi ada di laptop Radya**, karena Gitea, registry, dan cluster hanya terikat ke localhost. B mengubah manifest lewat **PR ke repo GitOps**. Langkah yang dijalankan langsung di cluster (buat DB, Secret, Argo Application) dikerjakan **berpasangan di laptop Radya**, atau B berlatih dulu di lab sendiri lalu Radya mengulanginya dari catatan B.
- Saran: jalankan lab sendiri (`Final_Project/scripts/*.ps1`, dari `doctor` sampai `smoke-test`) untuk latihan tanpa takut merusak lab resmi.

## Urutan dan Ketergantungan

| Urutan | Tugas | Ketergantungan |
|---|---|---|
| 1 | B1 Repo portofolio | Nama tim disepakati |
| 2 | B2 Tiga environment | Sesi pairing di laptop Radya (DB, Secret, Argo) |
| 3 | B3 Bukti M3 + kebersihan repo | n/a |
| 4 | B5 ADR platform | Bisa dicicil kapan saja |
| 5 | B4 Rilis, promosi, rollback | B2; `v0.2.0` menunggu freeze M2 (17 Nov) |
| 6 | B6 Koleksi request API | Endpoint dari Radya (bertahap) |

---

## B1: Repo Portofolio `cloud-capstone-<tim>` (Sel 11 Nov)

**Kenapa:** Guideline §9.1 meminta *evidence portfolio* kumulatif dengan struktur `01-business/` … `11-demo-defense/` + `source/`. Repo ini menjadi pintu masuk untuk dosen. Kode **tetap** di dua repo terpisah (`capstone-app`, `capstone-gitops`), karena CI menulis tag ke repo GitOps dan Argo CD membacanya. Kalau digabung, setiap commit `deploy:` dari CI akan memicu CI lagi.

Susunan repo GitHub (semua private):

| Repo | Isi |
|---|---|
| `capstone-app` | Source TypeScript (Hono + Drizzle), Dockerfile, `ci.yml` |
| `capstone-gitops` | Manifest Kustomize + Argo CD Application |
| **`cloud-capstone-<tim>`** | Portofolio §9.1 (root folder `campusdesk/`), **dibuat di B1** |
| `campusdesk-lab` | *Opsional, keputusan tim:* paket dosen + perbaikan T8–T10, supaya lab B dan C sama dengan lab resmi. Kalau dibuat: commit pertama = zip asli dosen, lalu satu commit per perbaikan. Jangan pernah dijadikan public (materi dosen). |

> **Status 10 Nov:** langkah 2 (isi `.gitignore`), 3–7 sudah dikerjakan Radya di folder `campusdesk/` (lihat `docs/PROGRESS.md`). Yang tersisa untuk B: langkah 1, `git init`, 8, dan 9.

Langkah:

1. Sepakati nama tim, lalu nama repo menjadi `cloud-capstone-<tim>`.
2. `git init -b main` di root `campusdesk/`. Isi `.gitignore`:
   ```gitignore
   # Repo kerja punya Git sendiri
   capstone-app/
   capstone-gitops/
   # Arsip, output mentah, dan file lokal
   cloud-ai.zip
   evidence-raw/
   .claude/settings.local.json
   .github/modernize/
   ```
3. Buat folder §9.1 yang belum ada: `02-architecture/` … `11-demo-defense/` dan `source/`. Git tidak menyimpan folder kosong, jadi isi setiap folder dengan `README.md` satu-dua baris: isi folder dan milestone/owner-nya (misalnya `05-ci-cd-gitops/`: M4, B).
4. Pindahkan isi folder `evidence/` lama ke folder bernomor: `Ci_ijo.png` dan `commit_in_1st_week.png` ke `05-ci-cd-gitops/`, `api_test.txt` ke `03-application-data/`. Setelah itu hapus `evidence/`. File-file ini **belum** memenuhi evidence standard; tandai di README foldernya.
5. `README.md` di root: ringkasan kasus, anggota + peran, tabel repo di atas (dengan tautan), status milestone (rujuk `docs/PROGRESS.md`), dan catatan bahwa `docs/` berisi dokumen kerja tim (PRD, tugas, handoff), bukan bukti.
6. `source/README.md`: tautan ke `capstone-app` dan `capstone-gitops`, plus tag/commit yang sedang dinilai. Jangan memakai git submodule.
7. Perbaiki rujukan `CampusDesk_Rencana_Kerja.md` (file itu tidak ada di folder ini) di `CLAUDE.md` dan `AGENTS.md` baris 3. Arahkan ke `docs/PRD_CampusDesk.md`, `docs/TASKS_M2-M5.md`, dan file handoff.
8. Sebelum push, jalankan `git status --ignored`. Pastikan `capstone-app/`, `capstone-gitops/`, dan `evidence-raw/` ada di bagian *Ignored*, dan tidak ada file berisi password atau token.
9. Commit (misalnya `docs: struktur portofolio sesuai guideline 9.1`), buat repo GitHub private, push, lalu undang Radya dan C.

Selesai jika: Radya dan C sudah clone, struktur §9.1 terlihat di GitHub, dan tidak ada file rahasia di repo.

**Catatan submission (1 Des):** struktur §9.1 nanti dipetakan ke §15: `01`–`09` → `evidence/<domain>/`, `02-architecture/` → `architecture/`, `10-decisions-adr/` → `decisions/`, `11-demo-defense/` → `demo/`. Snapshot `capstone-app` dan `capstone-gitops` pada tag rilis (`git archive`) masuk ke `source/` dan `deployment/`, `ci.yml` + skrip lab ke `automation/`, ditambah `final-report.pdf` dan `individual-reflections/`.

## B2: Tiga Environment (M4, Sab 15 Nov)

1. Base: hapus `namespace:` dari semua manifest, dan hapus `namespace.yaml` dari `base/kustomization.yaml`.
2. Overlay `dev`, `staging`, `prod`. Masing-masing:
   - `namespace: campusdesk-<env>`;
   - patch ConfigMap: `DB_URL=jdbc:postgresql://postgres:5432/campusdesk_<env>`, `OIDC_ISSUER`, `OIDC_TOKEN_ISSUER` (nilainya dari Radya, R2; usulan `http://keycloak:8080/realms/capstone` dan `http://localhost:8081/realms/capstone`, **bukan** `host.k3d.internal`, karena dari pod alamat itu ditolak);
   - patch host Ingress: `dev.capstone.localhost`, `staging.capstone.localhost`, `capstone.localhost`;
   - blok `images:` sendiri. CI hanya mengubah `overlays/dev`, dan pola `sed` di CI (`newName:`/`newTag:`) harus tetap cocok.
3. Cek hasil render sebelum PR: `kubectl kustomize overlays/staging`.
4. *(Pairing di laptop Radya)* Buat database:
   `docker exec capstone-postgres psql -U capstone -c "CREATE DATABASE campusdesk_dev;"` (ulangi untuk staging dan prod). User DB non-superuser adalah tugas C di M6; catat sebagai limitasi untuk sekarang.
5. *(Pairing)* Secret per namespace:
   `kubectl create namespace campusdesk-dev --dry-run=client -o yaml | kubectl apply -f -`, lalu
   `kubectl -n campusdesk-dev create secret generic capstone-app-secret --from-literal=DB_PASSWORD=... --dry-run=client -o yaml | kubectl apply -f -`.
   **Jangan di-commit.**
6. Tiga Argo CD Application di folder `argocd/` repo GitOps. Gunakan `Final_Project/templates/argocd/application.yaml` sebagai contoh:
   - `campusdesk-dev` dan `campusdesk-staging`: auto-sync + selfHeal + prune;
   - `campusdesk-prod`: **tanpa `automated`** (sync manual = approval gate).
   *(Pairing)* `kubectl apply -f argocd/`. Hapus Application lama `capstone-app` (namespace `capstone`) setelah dev baru Running, dan catat migrasinya.
7. Windows hosts: jika `dev.` atau `staging.capstone.localhost` tidak ter-resolve, tambahkan `127.0.0.1 dev.capstone.localhost staging.capstone.localhost` ke `C:\Windows\System32\drivers\etc\hosts` (Notepad sebagai Administrator).
8. Beri tahu C bahwa target scrape Prometheus (C4) perlu menyesuaikan host per environment.

Selesai jika: tiga namespace Running, `curl` ke tiap host merespons, dan prod hanya berubah setelah sync manual.

## B3: Bukti M3 + Kebersihan Repo (Sab 15 Nov)

1. `.gitattributes` di **kedua** repo: `* text=auto eol=lf`, `*.cmd text eol=crlf`, `*.ps1 text eol=crlf`, lalu `git add --renormalize .`. Satu PR per repo.
2. Pin base image di `capstone-app/Dockerfile` (sejak ADR-014 memakai `node:24-alpine` di **dua** baris `FROM`): `docker pull node:24-alpine`, ambil digest dengan `docker inspect --format "{{index .RepoDigests 0}}" node:24-alpine`, lalu tulis `FROM node:24-alpine@sha256:...` di kedua stage. PR ini direview Radya.
3. Bukti di `04-platform-kubernetes/` (pairing di laptop Radya):
   - nodes, objek (`kubectl -n campusdesk-dev get all,ingress`), probe, resources;
   - `kubectl rollout status` dan `rollout history`;
   - scale 1→2 lewat patch di overlay (bukan `kubectl scale`, karena Argo akan mengembalikannya), lalu kedua pod Ready;
   - **A2:** `docker stop capstone-postgres`, pastikan pod NotReady, `docker start`, pastikan pulih. Ukur waktunya.
   - satu catatan troubleshooting nyata.
   Setiap file mengikuti evidence standard (scope, owner, versi, timestamp, method, observation, interpretation, limitation, decision).

## B4: Rilis, Promosi, Rollback (M4, Sen 17 – Sel 18 Nov)

1. **Latihan `v0.1.0`:** Radya membuat tag di `capstone-app`. B membuat PR GitOps yang menyalin `newTag` dev ke `overlays/staging`, merge, dan memastikan Argo staging sync. Lakukan hal yang sama untuk prod, lalu sync manual di UI Argo CD (`Final_Project/scripts/argocd-ui.ps1`).
2. Rollback: `git revert` commit promosi, lalu pastikan Argo kembali ke image sebelumnya. Catat waktunya.
3. Tabel traceability: commit app → run CI → tag/digest image → commit GitOps → revisi Argo → image di pod (`kubectl get pod -o jsonpath="{.items[*].spec.containers[*].image}"`).
4. Ukur waktu merge → Running di dev (QS6, target ≤ 15 menit).
5. **Ulangi untuk `v0.2.0` setelah freeze (17 Nov).** Versi ini yang ditunjukkan saat demo.

Bukti di `05-ci-cd-gitops/`.

## B5: ADR Platform (M1, Kam 13 Nov)

Format setiap ADR: konteks, keputusan, alternatif, konsekuensi, status. Tulis di `10-decisions-adr/`:
- 006 ConfigMap/Secret manual
- 007 GitOps build once/promote
- 008 PostgreSQL di luar cluster
- 010 `DB_URL` via service `postgres` di `capstone-net`
- 011 tiga env dalam satu cluster
- 013 perubahan paket dosen (T8–T10; lihat log di `docs/PROGRESS.md`)

## B6: Koleksi Request API (M2/FINAL, Sel 18 Nov)

1. File `api/campusdesk.http` (VS Code REST Client) atau koleksi Bruno di repo portofolio (`11-demo-defense/api/`).
2. Isinya:
   - ambil token `usera`, `userb`, `operator`, `appadmin`;
   - setiap endpoint (daftar di PRD M2);
   - **kasus ditolak**: tanpa token, lintas tenant, user memanggil assign.
3. Jalankan terhadap dev setiap kali Radya merge fitur baru. Hasilnya menjadi bukti M2 (bersama Radya).
4. Nanti dipakai untuk menyusun demo script FINAL (13 langkah Guideline §13).
