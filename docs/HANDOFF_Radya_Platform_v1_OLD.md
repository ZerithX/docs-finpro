# Handoff Claude Code: Tugas Radya (Platform & Delivery) R1–R7

> Dibuat 10 Nov 2026. Sumber: `docs/TASKS_M2-M5.md` §3 dan `docs/PRD_CampusDesk.md` (M3, M4, sebagian M2). Aturan proyek: `AGENTS.md`.
> **Untuk Claude Code:** kerjakan **satu tugas per sesi/branch**, dengan plan mode dulu. Jangan menulis hasil yang tidak benar-benar dijalankan. Setelah tiap tugas, tambahkan entri di `docs/PROGRESS.md`. Item bertanda [CEK] adalah dugaan yang harus dibuktikan dulu sebelum ditulis sebagai fakta.

## Urutan dan Status Ketergantungan

| Urutan | Tugas | Bisa dikerjakan sekarang? | Ketergantungan |
|---|---|---|---|
| 1 | R1 Merge fix CI (A1) | ✅ Ya | Review oleh B/C (minta hari ini) |
| 2 | R2 Repo `campusdesk-docs` + perbaiki `CLAUDE.md` | ✅ Ya | n/a |
| 3 | R3 Fondasi auth (OIDC + TenantContext) | ✅ Sebagian besar | Tes di CI tidak butuh Keycloak. Uji end-to-end dengan token asli butuh mapper grup (C1). |
| 4 | R4 Environment dev/staging/prod | ✅ Ya | n/a |
| 5 | R5 Bukti M3 + `.gitattributes` + pin image + README | ✅ Ya | n/a |
| 6 | R6 Rilis, promosi, rollback | 🟡 Latihan dengan skeleton sekarang (`v0.1.0`); rilis sungguhan setelah freeze 17 Nov (`v0.2.0`) | M2 dari B |
| 7 | R7 ADR platform | ✅ Ya, bisa dicicil sambil jalan | n/a |

**Jangan mengambil tugas B (B1–B6) atau C (C0–C6)**, kecuali tim memutuskan ulang pembagiannya. B dan C belum punya commit, dan itu risiko nilai individu (Guideline §4). Yang boleh: membantu lewat review dan pairing.

---

## R1: Merge Fix CI A1 (M4)

1. Ada dua branch berisi perubahan yang identik: `fix/ci-publish-on-push` (`d8c8ba9`) dan `fix/ci-publish-push` (`b535a8d`). Pertahankan **`fix/ci-publish-on-push`**, karena nama ini yang dipakai di `PROGRESS.md`. Hapus yang lain, baik lokal maupun di `origin`.
2. Buka PR di GitHub (deskripsi PR sudah ada di chat sebelumnya). Minta B atau C me-review, karena itu juga menjadi kontribusi mereka.
3. **Agar run PR terbukti di Gitea**, branch juga harus di-push ke remote `gitea`, lalu PR dibuka di Gitea. CI hanya berjalan di Gitea.
4. Setelah merge: `git push gitea main`.

Selesai jika:
- Run PR di Gitea berhenti setelah *Verify application*.
- Run `main` menjalankan build, push, dan update GitOps.
- Kedua run dicatat di `evidence/` dengan evidence standard (scope, owner, versi, timestamp, method, observation, interpretation, limitation, decision).

## R2: Repo Dokumen (M0/M1)

1. `git init` di root `campusdesk/`. Isi `.gitignore` minimal: `capstone-app/`, `capstone-gitops/` (keduanya repo sendiri), `cloud-ai.zip`, `.claude/settings.local.json`, `.github/modernize/`, `evidence-raw/`.
2. Buat repo GitHub `campusdesk-docs` (private), lalu push. Undang B dan C.
3. `CLAUDE.md`: hapus rujukan `CampusDesk_Rencana_Kerja.md` dan arahkan ke `docs/PRD_CampusDesk.md` + `docs/TASKS_M2-M5.md`.

Selesai jika: B dan C sudah bisa clone repo.

## R3: Fondasi Auth (M2, Jalur Kritis, Target Rabu 12 Nov)

Tujuan: B bisa langsung menulis fitur tiket yang sadar tenant tanpa memikirkan OIDC.

1. Tambah dependensi `quarkus-oidc` dan, untuk tes, `quarkus-test-security-oidc`.
2. Konfigurasi (nilai dari ConfigMap, tidak ada URL hard-coded):
   - `%prod.quarkus.oidc.auth-server-url=${OIDC_ISSUER}`, `quarkus.oidc.client-id=capstone-app`, `quarkus.oidc.application-type=service`.
   - **Penting:** `quarkus.oidc.roles.role-claim-path=realm_access/roles`. Quarkus secara default membaca role dari claim `groups` kalau claim itu ada. Setelah mapper C1 aktif, `/tenant-a` akan dianggap role, dan `@RolesAllowed("user")` akan gagal. [CEK di dokumentasi Quarkus untuk versi `3.40.x`]
   - Di profil test dan dev, matikan Dev Services Keycloak kalau tidak dibutuhkan, supaya CI tidak menarik image Keycloak. [CEK nama properti yang tepat]
3. Semua `/api/**` wajib terautentikasi. `/q/health`, `/q/metrics`, `/q/openapi`, dan Swagger UI tetap terbuka.
4. Bean `TenantContext` (`@RequestScoped`):
   - Membaca claim `groups` dan memilih entri berawalan `/tenant-`, membuang `/`, lalu mencocokkannya dengan `units.code`.
   - `user` tanpa grup tenant → 403.
   - `operator`/`admin` → tenant `null` (lintas tenant; audit ditangani B3).
   - Sediakan `requireTenant()` dan `isCrossTenant()` agar B tinggal memakainya.
5. `GET /api/units`: `admin` dan `operator` melihat semua unit; `user` hanya unitnya sendiri. Ubah respons dari entity ke DTO.
6. Tes dengan `@TestSecurity` + `@OidcSecurity(claims = @Claim(key="groups", value="/tenant-a"))`:
   - tanpa token → 401,
   - `usera` → hanya `tenant-a`,
   - `appadmin` → 2 unit,
   - `user` tanpa grup → 403.
7. **[CEK] Masalah issuer:** token yang diambil dari laptop (`http://localhost:8081/...`) membawa `iss` `localhost`, sedangkan pod mengakses Keycloak lewat `host.k3d.internal:8081`.
   - Solusi paling sederhana: pod tetap memakai `host.k3d.internal` untuk discovery dan JWKS, dan menerima issuer `localhost` lewat `quarkus.oidc.token.issuer=http://localhost:8081/realms/capstone` (nilai dari ConfigMap, misal `OIDC_TOKEN_ISSUER`).
   - Buktikan dengan `curl` + token `usera` ke `dev.capstone.localhost:8088/api/units`, lalu catat sebagai ADR.
8. Cara mengambil token untuk demo/uji manual (client publik, direct access grant aktif):
   `curl.exe -s -d "client_id=capstone-app" -d "grant_type=password" -d "username=usera" -d "password=usera" http://localhost:8081/realms/capstone/protocol/openid-connect/token`
9. Mapper grup adalah tugas **C1**. Karena lab resmi ada di laptop Radya, konfigurasi C harus berakhir di Keycloak Radya, lewat export realm dari C atau dibuat bersama. Sampai mapper itu ada, tes otomatis tetap bisa jalan karena memakai `@OidcSecurity`.

Selesai jika: semua tes di poin 6 hijau di CI, dan satu `curl` dengan token asli berhasil di cluster (setelah C1).

## R4: Tiga Environment (M4)

1. Base: hapus `namespace:` dari semua manifest dan hapus `namespace.yaml` dari `base/kustomization.yaml`.
2. Overlay `dev`, `staging`, `prod`. Masing-masing berisi:
   - `namespace: campusdesk-<env>`,
   - patch ConfigMap (`DB_URL=jdbc:postgresql://postgres:5432/campusdesk_<env>`, `OIDC_ISSUER`, `OIDC_TOKEN_ISSUER`),
   - patch host Ingress (`dev.capstone.localhost`, `staging.capstone.localhost`, `capstone.localhost`),
   - blok `images:` sendiri.
   CI tetap hanya mengubah `overlays/dev`, dan pola `sed` yang sudah ada harus tetap cocok.
3. Buat database: `docker exec capstone-postgres psql -U capstone -c "CREATE DATABASE campusdesk_dev;"` (ulangi untuk staging dan prod). User DB non-superuser adalah tugas C di M6; untuk sekarang masih memakai `capstone`, dan ini dicatat sebagai limitasi.
4. Buat Secret per namespace dengan `kubectl create secret ... --dry-run=client -o yaml | kubectl apply -f -`. **Jangan di-commit.**
5. Tiga Argo CD Application di folder `argocd/` repo GitOps. `campusdesk-dev` dan `campusdesk-staging` memakai auto-sync + selfHeal + prune. `campusdesk-prod` **tanpa `automated`** (sync manual sebagai approval gate). Hapus Application lama `capstone-app` (namespace `capstone`) setelah dev baru Running, dan catat migrasinya.
6. Windows hosts: tambahkan `dev.capstone.localhost` dan `staging.capstone.localhost` kalau tidak ter-resolve.
7. Catatan untuk C4: target scrape Prometheus nanti perlu disesuaikan dengan host per env.

Selesai jika: tiga namespace Running dan `curl` ke tiap host merespons. Prod hanya berubah setelah sync manual.

## R5: Bukti M3 + Kebersihan Repo

1. `.gitattributes` di kedua repo: `* text=auto eol=lf`, `*.cmd text eol=crlf`, `*.ps1 text eol=crlf`, lalu `git add --renormalize .`.
2. Pin base image: `docker pull eclipse-temurin:21-jre`, ambil digest (`docker inspect --format "{{index .RepoDigests 0}}"`), lalu tulis `FROM eclipse-temurin:21-jre@sha256:...`.
3. README `capstone-app`: cara build, test, run lokal, env var yang dipakai, dan endpoint.
4. Bukti di `04-platform-kubernetes/`: nodes, objek, probe, resources, `rollout status/history`, scale 1→2 (keduanya Ready), dan **A2**: hentikan postgres, lalu pastikan pod menjadi NotReady dan pulih saat postgres hidup lagi. Ukur waktunya. Tambahkan satu catatan troubleshooting nyata.

## R6: Rilis, Promosi, Rollback (M4)

1. **Latihan sekarang:** tag `v0.1.0` pada commit skeleton + R3, lalu promosikan tag image dev ke staging lewat PR GitOps. Untuk prod, merge PR lalu sync manual di Argo CD.
2. Rollback: `git revert` commit promosi, lalu pastikan Argo kembali ke image sebelumnya. Catat waktunya.
3. Tabel traceability: commit → run CI → tag/digest image → commit GitOps → revisi Argo → image di pod.
4. Ukur waktu merge → Running di dev (QS6, target ≤ 15 menit).
5. **Ulangi untuk `v0.2.0` setelah freeze M2 (17 Nov).** Ini yang ditunjukkan saat demo.

## R7: ADR Platform (M1)

Format setiap ADR: konteks, keputusan, alternatif, konsekuensi, status. Tulis di `10-decisions-adr/`:
- 006 ConfigMap/Secret manual
- 007 GitOps build once/promote
- 008 PostgreSQL di luar cluster
- 010 `DB_URL` via service `postgres` di `capstone-net`
- 011 tiga env dalam satu cluster
- 012 issuer OIDC (hasil R3 poin 7)
- 013 perubahan paket dosen (T8–T10)
