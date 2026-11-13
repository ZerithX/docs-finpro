# Handoff Claude Code: Tugas Radya (Application & Data) R1–R8

> Dibuat 10 Nov 2026 (v2, setelah peran ditukar). Sumber: `docs/TASKS_M2-M5.md` §3 dan `docs/PRD_CampusDesk.md` §7 (M2). Aturan proyek: `AGENTS.md`.
> **Untuk Claude Code:** kerjakan **satu tugas per sesi/branch**, plan mode dulu. Jangan menulis hasil yang tidak benar-benar dijalankan. Setelah tiap tugas, tambahkan entri di `docs/PROGRESS.md`. Item [CEK] harus dibuktikan dulu.
> Repo: `capstone-app` (GitHub `helpdesk-campus`). **Sejak 10 Nov: Node.js 24 + TypeScript, Hono, Drizzle ORM, Vitest, prom-client** (ADR-014; sebelumnya Java/Quarkus). Skema DB hanya berubah lewat file migrasi **baru** di `drizzle/` (`npm run db:generate`); migrasi lama tidak diedit.

## Urutan dan Ketergantungan

| Urutan | Tugas | Ketergantungan |
|---|---|---|
| 1 | R1 Merge fix CI | Review B/C |
| 2 | R2 Fondasi auth | Tes CI tidak butuh Keycloak. Uji token asli butuh C1 (mapper grup). |
| 3 | R3 Migrasi | n/a (boleh paralel dengan R2) |
| 4 | R4 Tiket + filter tenant | R2, R3 |
| 5 | R5 Workflow + komentar + audit | R4 |
| 6 | R6 SLA breach + laporan + tes matriks C2 | R5, tabel C2 |
| 7 | R7 Metrik bisnis | R4–R6 |
| 8 | R8 ADR | Bisa dicicil kapan saja |

Struktur folder yang disarankan (modular monolith; satu modul = satu folder di `src/modules/`; boleh disesuaikan, tapi catat alasannya):
`unit/` (sudah ada), `auth/` (middleware JWT + TenantContext), `sla/`, `ticket/`, `audit/`, `report/`, dan `src/common/` (error mapping). Pola tiap modul: `*.routes.ts` (route + skema zod/OpenAPI) dan `*.repository.ts` (query Drizzle); tambahkan `*.service.ts` bila ada logika bisnis.

---

## R1: Merge Fix CI A1 (M4)

> **Status 10 Nov:** di-merge sebagai GitHub PR #2 (`4d3e23a`, branch `fix/ci-publish-push`; duplikatnya dihapus) dan dicerminkan ke Gitea. Bukti kedua run CI masih perlu dicatat di `05-ci-cd-gitops/`.

1. Pertahankan satu branch, hapus duplikatnya, baik lokal maupun di `origin`.
2. Buka PR di GitHub; reviewer B atau C.
3. Agar run PR terbukti di Gitea, push branch juga ke remote `gitea` dan buka PR di Gitea.
4. Setelah merge: `git push gitea main`.

Selesai jika: run PR di Gitea berhenti setelah *Verify application*, run `main` sampai update GitOps, dan keduanya dicatat di `05-ci-cd-gitops/`.

## R2: Fondasi Auth (Jalur Kritis, Rabu 12 Nov)

1. Dependensi `jose` (verifikasi JWT + JWKS). Modul baru `src/modules/auth/`.
2. Konfigurasi di `src/config.ts` (nilai dari ConfigMap):
   - `OIDC_ISSUER`: base URL realm untuk discovery/JWKS dari pod. JWKS: `${OIDC_ISSUER}/protocol/openid-connect/certs` lewat `createRemoteJWKSet` (jose menyimpan cache kunci).
   - `OIDC_TOKEN_ISSUER`: nilai `iss` yang diterima di `jwtVerify(..., { issuer })`; default sama dengan `OIDC_ISSUER` (lihat poin 7).
   - Token Keycloak biasanya ber-`aud: "account"`. Cek klien lewat claim `azp === "capstone-app"`, bukan `aud`. [CEK dengan token asli]
   - Role dibaca dari `realm_access.roles`, **bukan** dari `groups`. Setelah mapper grup aktif, `/tenant-a` tidak boleh dianggap role.
3. Middleware `requireAuth` dipasang di `app.use('/api/*', ...)`. `/q/health`, `/q/metrics`, `/q/openapi`, dan Swagger UI tetap terbuka. Token hilang/rusak/kedaluwarsa → 401. Tambahkan security scheme `bearerAuth` di OpenAPI supaya tombol *Authorize* muncul di Swagger UI.
4. `TenantContext` disimpan di context Hono (`c.set('auth', ...)`, tipe lewat `Variables`):
   - Membaca claim `groups`, mengambil entri berawalan `/tenant-`, membuang `/`, lalu mencocokkannya dengan `units.code`.
   - `user` tanpa grup → 403.
   - `operator`/`admin` → lintas tenant.
   - Helper `requireTenant(c)`, `isCrossTenant(c)`, `currentUnit(c)`.
5. `GET /api/units`: admin/operator melihat semua; user hanya unitnya. Skema respons zod yang sudah ada tetap dipakai sebagai DTO.
6. Tes tanpa Keycloak: `createApp` menerima dependensi verifikasi token (JWKS + issuer). Di tes, buat pasangan kunci dengan `generateKeyPair('RS256')`, pakai `createLocalJWKSet`, lalu tandatangani token tes dengan claim `groups`/`realm_access` lewat `SignJWT`. Kasus: tanpa token → 401; token issuer lain → 401; `usera` → hanya tenant-a; `appadmin` → 2 unit; `user` tanpa grup → 403.
7. **[CEK] Issuer (dikoreksi 10 Nov):** pod **tidak bisa** memakai `host.k3d.internal:8081`. Keycloak hanya bind ke `127.0.0.1:8081` di host, sehingga dari pod hasilnya *connection refused*, sama seperti Postgres di temuan T10 (`Final_Project/CampusDesk_Rencana_Kerja.md` §4). Uji 28 Okt dari pod: `keycloak:8080` open lewat jaringan `capstone-net`.
   - **Discovery/JWKS dari pod:** `OIDC_ISSUER=http://keycloak:8080/realms/capstone`.
   - **Issuer yang diterima:** Keycloak mode dev mengambil `iss` dari host request, jadi token yang diambil di laptop berisi `http://localhost:8081/realms/capstone` atau `http://127.0.0.1:8081/realms/capstone`, tergantung URL yang dipakai. Tetapkan satu (usulan: `localhost`, dan selalu ambil token lewat `localhost:8081`), lalu isi `OIDC_TOKEN_ISSUER` dengan nilai itu.
   - Tambahkan kedua variabel ke ConfigMap; koordinasikan dengan B karena overlay adalah tugas B. Buktikan dengan `curl` + token ke cluster (harus 200, bukan 401), lalu tulis ADR 012.
8. Ambil token (manual/demo):
   `curl.exe -s -d "client_id=capstone-app" -d "grant_type=password" -d "username=usera" -d "password=usera" http://localhost:8081/realms/capstone/protocol/openid-connect/token`

## R3: Migrasi (M2)

Cara kerja: tambahkan tabel di `src/db/schema.ts`, jalankan `npm run db:generate -- --name <nama>`, periksa SQL di `drizzle/`, lalu commit. Seed referensi (misalnya `sla_policy`) ditulis manual di file migrasi yang sama, atau lewat `npx drizzle-kit generate --custom`.

- `sla_policy`: `priority` (KRITIS/TINGGI/SEDANG/RENDAH, unik), `response_minutes`, `resolve_minutes`. Seed: 30/240, 60/480, 240/1440, 480/4320.
- `tickets`: `unit_id` (FK, NOT NULL), `title`, `description`, `category` (JARINGAN/AKUN/PERANGKAT/APLIKASI/LAINNYA), `priority`, `status`, `reporter` (username dari token), `assignee`, `created_at`, `response_due_at`, `resolve_due_at`, `first_response_at`, `resolved_at`, `closed_at`, `version` (optimistic lock). Index `(unit_id, status)`.
- `ticket_comments`, `audit_log` (`actor`, `role`, `action`, `ticket_id`, `unit_id`, `at`).
- Seed tiket demo **jangan** dimasukkan ke migrasi, karena migrasi juga berjalan di staging/prod. Pakai skrip terpisah, misalnya `npm run db:seed:dev`.

## R4: Tiket + Filter Tenant (M2)

- `POST /api/tickets` (role user): unit diambil dari `TenantContext`, **tidak dari body**. Due time dihitung dari `sla_policy` saat dibuat.
- `GET /api/tickets`, `GET /api/tickets/{id}`: semua query lewat **satu** repository/service yang menerapkan filter unit. Tiket unit lain → **404** (sesuai ADR 003 dari C).
- DTO request/response sebagai skema zod di `createRoute` (`@hono/zod-openapi`). Body yang tidak valid otomatis → 400, dan skemanya ikut muncul di Swagger.
- Tes: usera membuat → 201 tenant-a + due time benar; usera GET tiket tenant-b → 404; list usera tanpa tiket tenant-b.

## R5: Workflow + Komentar + Audit (M2)

- Transisi yang diizinkan: `OPEN→ASSIGNED` (operator), `ASSIGNED→IN_PROGRESS` (operator), `IN_PROGRESS→RESOLVED` (operator), `RESOLVED→CLOSED` (pelapor atau operator), `RESOLVED→IN_PROGRESS` (reopen oleh pelapor). Selain itu → 409.
- `POST /api/tickets/{id}/assign`, `POST /api/tickets/{id}/status`, `POST/GET /api/tickets/{id}/comments`.
- `first_response_at` diisi pada transisi pertama ke ASSIGNED. Aksi operator/admin ditulis ke `audit_log`.
- Tes untuk setiap transisi valid dan tidak valid, plus user memanggil assign → 403.

## R6: SLA Breach + Laporan (M2, Freeze Sen 17 Nov)

- Breach dihitung **lewat query** (`now > due` dan timestamp yang sesuai masih kosong), tanpa scheduler, supaya aman bila replica > 1.
- Sediakan fungsi `now: () => Date` di dependensi `createApp`, supaya tes breach memakai waktu tetap.
- `GET /api/reports/sla?from=&to=`: per unit, jumlah tiket, rata-rata dan p95 waktu respon pertama, % sesuai SLA. User melihat unitnya; admin melihat semua.
- Seed data demo sekitar 20 tiket (dev saja).
- Tulis tes untuk setiap baris matriks authz C2.

## R7: Metrik Bisnis (M5, Rab 19 Nov)

- prom-client (registry yang sama di `src/platform/metrics.ts`): counter `campusdesk_tickets_created_total{tenant,priority}`, histogram `campusdesk_first_response_seconds{tenant}`, gauge `campusdesk_sla_breached_tickets{tenant}` (nilai dari query lewat callback `collect()`).
- Catat risiko kardinalitas label `tenant` di ADR atau catatan M5.

## R8: ADR (M1, Kam 13 Nov)

001 modular monolith, 005 tenggat SLA disimpan saat create, 009 SLA 24x7, 012 issuer OIDC, 014 substitusi teknologi ke TypeScript (draf sudah ada di `10-decisions-adr/`). Format: `10-decisions-adr/TEMPLATE.md`.
