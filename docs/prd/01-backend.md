# PRD 01 · Backend (Application & Data)

| Field | Isi |
|---|---|
| Owner | Radya (Application & Data) |
| Reviewer | B (setiap PR backend), C (matriks authz, BE-7) |
| Versi | v1.1, 23 Nov 2026 (bagian dari set PRD per area, lihat `00-INDEX.md`) |
| Target | Fitur dibekukan **Kam 26 Nov**; dokumen final **Sel 1 Des**; defense **±2 Des** |
| Repo | `capstone-app` (GitHub `helpdesk-campus`), mirror Gitea untuk CI |
| Acuan | `docs/PRD_CampusDesk.md` §3, §4, §7 M2 · `docs/HANDOFF_Radya_Backend.md` (langkah teknis) · ADR 001, 003, 005, 009, 012 |
| Bergantung pada | PD-1 (ConfigMap OIDC, PRD 02) untuk uji di cluster |
| Dipakai oleh | SEC-2 (PRD 03), OPS-3 (PRD 04), CAP-1 (PRD 05), FD-2 (PRD 06) |
| Aturan | Jika dokumen ini bertentangan dengan Guideline, Guideline yang menang. Jika bertentangan dengan PRD tim soal **scope**, dokumen ini yang terbaru (scope sudah dipotong per 23 Nov). |

---

## 1. Outcome

Saat defense, di depan dosen dan dalam satu alur tanpa jeda:

1. `usera` (Fakultas A) **login** dan **membuat tiket** prioritas KRITIS. Tenggat respons dan penyelesaian langsung terisi.
2. `operator` **meng-assign** tiket itu (respons pertama tercatat), lalu menyelesaikannya.
3. `userb` (Fakultas B) mencoba membuka tiket itu dan **ditolak (404)**. Request tanpa login **ditolak (401)**. `usera` mencoba assign **ditolak (403)**.
4. Data tetap ada setelah pod dihapus.
5. Dasbor menampilkan jumlah tiket per unit.

Semua kasus di atas juga **dites otomatis di CI**. Ini menjawab langkah demo final #2, #3, dan #7 (Guideline §13) serta quality scenario QS1 dan QS2.

## 2. Status per 23 Nov

| Sudah ada di `main` dan di cluster | Belum ada |
|---|---|
| `GET /api/units`, `GET /api/sla-policies`, `GET /api/sla-policies/{priority}` | Login / verifikasi token |
| Tabel `units`, `sla_policy` (migrasi `0000`, `0001`) | Tabel `tickets`, `audit_log` |
| Health, metrics, Swagger, 12 tes di CI | Semua endpoint tiket, alur status |
| Pipeline CI → GitOps → Argo CD terbukti (PR #4) | Mapper grup Keycloak (C1) |

Tidak ada commit sejak 17 Nov. Sisa waktu kerja fitur: **4 hari** (23–26 Nov).

## 3. Scope

### 3.1 Wajib (tidak boleh dipotong: quality gate Guideline)
- **BE-1** Mapper grup Keycloak
- **BE-2** Auth + TenantContext
- **BE-3** Migrasi `tickets` + `audit_log`
- **BE-4** Buat, daftar, detail tiket dengan filter tenant terpusat
- **BE-5** Alur status minimal + assign + audit
- **BE-7** Tes negatif authz (401 / 403 / 404 / 409)

### 3.2 Sebaiknya (dikerjakan jika BE wajib selesai)
- **BE-6** Laporan SLA sederhana per unit + breach lewat query
- **BE-8** Metrik bisnis untuk dasbor
- **BE-9** Seed data demo

### 3.3 Dipotong (dicatat sebagai keputusan, bukan dilupakan)
| Item | Alasan | Dicatat di |
|---|---|---|
| Komentar tiket (`ticket_comments`, `/comments`) | Tidak dibutuhkan alur demo | PROGRESS + laporan final §limitasi |
| p95 di laporan SLA | Rata-rata + % sesuai SLA sudah cukup menjawab pertanyaan Kepala Unit TI | Sama |
| Histogram `first_response_seconds` | Diganti gauge breach yang lebih mudah dibaca | Catatan M5 |
| Reopen (`RESOLVED → IN_PROGRESS`) | Opsional; dikerjakan hanya jika BE-5 selesai lebih cepat | Sama |
| `PUT /api/sla-policies` (admin) | Kebijakan cukup diubah lewat migrasi | ADR-005 |

## 4. Aturan yang berlaku untuk semua item

1. **Tenant tidak pernah diambil dari input request** (body, query, header). Hanya dari token.
2. Filter tenant untuk tiket ada di **satu fungsi repository**. Route tidak boleh menulis query tiket sendiri.
3. Skema DB berubah **hanya** lewat file migrasi baru di `drizzle/`. Migrasi lama tidak diedit.
4. Respons memakai skema zod (DTO), bukan baris tabel mentah.
5. Satu item = satu branch = satu PR kecil, direview B. Setelah merge: `git push gitea main`, tunggu Argo CD Synced, lalu catat di `docs/PROGRESS.md`.
6. Tes di CI **tidak** memanggil Keycloak sungguhan: token dibuat di tes dengan kunci lokal (`jose`).
7. Tidak menulis hasil yang tidak benar-benar dijalankan.

---

## 5. Requirement

### BE-1 Mapper grup Keycloak · M2-1 · target **Sen 23**

Dikerjakan Radya sendiri (tidak menunggu C). C mendokumentasikan dan mengekspor realm sebagai kontribusinya.

- Keycloak (`http://localhost:8081`, realm `capstone`) → Clients → `capstone-app` → Client scopes → dedicated scope → **Add mapper → Group Membership**: name `groups`, token claim name `groups`, *Full group path* ON, masuk ke access token.
- Pastikan `usera` anggota grup `tenant-a`, `userb` anggota `tenant-b`. `operator` dan `appadmin` tanpa grup tenant.

**Selesai jika:** token `usera` yang di-decode berisi `"groups": ["/tenant-a"]` dan `realm_access.roles` berisi `user`. Screenshot hasil decode disimpan ke `06-security/`.

### BE-2 Auth + TenantContext · M2-2, M2-3 · target **Sel 24**

- Modul `src/modules/auth/`: middleware `requireAuth` di `/api/*`. `/q/*` dan Swagger tetap terbuka. Tombol *Authorize* (bearer) tampil di Swagger.
- Verifikasi JWT: tanda tangan (JWKS), issuer, masa berlaku, `azp === "capstone-app"`.
- Konfigurasi (ADR-012): `OIDC_ISSUER=http://keycloak:8080/realms/capstone` (JWKS dari pod), `OIDC_TOKEN_ISSUER=http://localhost:8081/realms/capstone` (nilai `iss` yang diterima). Ditambahkan ke ConfigMap lewat PR ke `capstone-gitops`.
- Role dari `realm_access.roles`. Tenant dari `groups` (`/tenant-a` → `units.code = tenant-a`).
- `GET /api/units`: user hanya unitnya; operator/admin semua.

| Kasus | Hasil |
|---|---|
| Tanpa token / token rusak / kedaluwarsa / issuer lain | **401** |
| Role `user` tanpa grup tenant | **403** |
| `usera` → `GET /api/units` | 200, hanya `tenant-a` |
| `appadmin` → `GET /api/units` | 200, 2 unit |

**Selesai jika:** semua kasus di atas punya tes yang lulus di CI, **dan** `curl` dengan token asli `usera` ke `http://capstone.localhost:8088/api/units` di cluster mengembalikan 200. ADR-012 diubah ke *Diterima*.

### BE-3 Migrasi tiket · M2-4 · target **Sel 24**

| Tabel | Kolom |
|---|---|
| `tickets` | `id`, `unit_id` (FK, NOT NULL), `title`, `description`, `category` (JARINGAN / AKUN / PERANGKAT / APLIKASI / LAINNYA), `priority` (enum yang sudah ada), `status` (OPEN / ASSIGNED / IN_PROGRESS / RESOLVED / CLOSED), `reporter`, `assignee`, `created_at`, `response_due_at`, `resolve_due_at`, `first_response_at`, `resolved_at`, `closed_at`. Index `(unit_id, status)` |
| `audit_log` | `id`, `actor`, `role`, `action`, `ticket_id`, `unit_id`, `at` |

**Selesai jika:** migrasi `0002_...` berjalan di CI dan di cluster tanpa error, migrasi lama tidak berubah.

### BE-4 Tiket + filter tenant · M2-3, M2-6, M2-8 · target **Rab 25**

| Endpoint | Role | Aturan |
|---|---|---|
| `POST /api/tickets` | user | Unit dari token. `response_due_at` dan `resolve_due_at` = `created_at` + menit dari `sla_policy` (ADR-005). Status awal OPEN. |
| `GET /api/tickets` | user (unitnya), operator, admin | Filter `status` opsional |
| `GET /api/tickets/{id}` | user (unitnya), operator, admin | Tiket unit lain → **404** (ADR-003) |

**Selesai jika (tes CI):**
- `usera` membuat tiket KRITIS → 201, `unit = tenant-a`, tenggat = +30 menit / +240 menit.
- Body tidak valid (prioritas `SUPER`, judul kosong) → 400.
- `usera` membuka tiket milik tenant-b → **404**.
- Daftar tiket `usera` berisi **nol** tiket tenant-b.
- `operator` melihat tiket kedua unit.

### BE-5 Alur status + assign + audit · M2-5 · target **Kam 26 (freeze)**

| Transisi | Siapa | Efek |
|---|---|---|
| OPEN → ASSIGNED | operator (`POST /api/tickets/{id}/assign`) | `assignee` = operator, `first_response_at` = sekarang (hanya pertama kali) |
| ASSIGNED → IN_PROGRESS | operator (`POST /api/tickets/{id}/status`) | — |
| IN_PROGRESS → RESOLVED | operator | `resolved_at` = sekarang |
| RESOLVED → CLOSED | pelapor tiket atau operator | `closed_at` = sekarang |
| Lainnya | — | **409** |

Setiap aksi operator/admin dicatat ke `audit_log`.

**Selesai jika (tes CI):** satu tes per transisi valid; OPEN → RESOLVED → 409; `usera` memanggil assign → **403**; satu baris `audit_log` tercipta per aksi operator.

### BE-6 Breach + laporan SLA · M2-6, M2-7 · *sebaiknya* · **Jum 27**

- Breach dihitung lewat query: respons terlambat jika `now > response_due_at` dan `first_response_at` kosong (atau lebih lambat dari tenggat). Tanpa scheduler, aman dengan banyak replica.
- `GET /api/reports/sla`: per unit → jumlah tiket, rata-rata waktu respons pertama (menit), % respons sesuai SLA. User melihat unitnya, admin semua.
- `createApp` menerima `now: () => Date` agar tes memakai jam tetap.

**Selesai jika:** tes dengan jam tetap: tiket KRITIS yang belum di-assign 31 menit setelah dibuat terhitung breach (QS2); angka laporan cocok dengan hitungan manual.

### BE-7 Tes negatif authz · M2 / M6 · bersamaan dengan BE-2–BE-5

Matriks minimum (C memeriksa kelengkapannya, Radya menulis tesnya):

| Aktor | `GET /api/tickets/{id}` unit lain | `POST …/assign` | Tanpa token |
|---|---|---|---|
| `usera` | 404 | 403 | — |
| `userb` | 404 | 403 | — |
| `operator` | 200 | 200 | — |
| (anonim) | — | — | 401 |

**Selesai jika:** setiap sel punya tes yang lulus di CI; output run CI disimpan sebagai bukti di `06-security/`.

### BE-8 Metrik bisnis · M5 · *sebaiknya* · **Jum 27**

- Counter `campusdesk_tickets_created_total{tenant,priority}` (naik saat tiket dibuat).
- Gauge `campusdesk_sla_breached_tickets{tenant}` (dari query BE-6 saat scrape).
- Satu panel baru di dasbor C: tiket per unit.

**Selesai jika:** metrik muncul di `/q/metrics` dan di Prometheus.

### BE-9 Seed data demo · *sebaiknya* · **Jum 27**

Skrip terpisah `npm run db:seed:dev` (bukan migrasi): sekitar 20 tiket campuran prioritas dan status untuk kedua unit, sebagian sengaja breach. Dipakai untuk demo dan uji beban M8 (C).

### BE-10 ADR backend · M1 · **Sab 28**

Finalisasi ADR 001 (modular monolith), 005 (tenggat disimpan saat create), 009 (SLA 24x7), 012 (issuer OIDC), 014 (substitusi stack). Status diubah ke *Diterima* hanya setelah ada bukti (ADR-012 setelah BE-2 terbukti di cluster). Review oleh B atau C lewat PR.

**Selesai jika:** kelima ADR berstatus *Diterima* dan reviewer bisa menjelaskan masing-masing dalam ±1 menit.

---

## 6. Kontrak API akhir

| Method | Path | Role | Kode sukses | Kode gagal |
|---|---|---|---|---|
| GET | `/api/units` | semua (user: unitnya) | 200 | 401 |
| GET | `/api/sla-policies[/{priority}]` | semua | 200 | 400, 401, 404 |
| POST | `/api/tickets` | user | 201 | 400, 401, 403 |
| GET | `/api/tickets` | semua (user: unitnya) | 200 | 401 |
| GET | `/api/tickets/{id}` | semua (user: unitnya) | 200 | 401, **404** |
| POST | `/api/tickets/{id}/assign` | operator | 200 | 401, **403**, 404, **409** |
| POST | `/api/tickets/{id}/status` | operator; pelapor untuk CLOSE | 200 | 401, 403, 404, **409** |
| GET | `/api/reports/sla` | user (unitnya), admin | 200 | 401 |

## 7. Jadwal

| Hari | Kerjakan | Output yang bisa ditunjukkan |
|---|---|---|
| **Sen 23** | BE-1, mulai BE-2 (kode + tes dengan token lokal) | Token `usera` berisi `groups` |
| **Sel 24** | BE-2 selesai, PR ConfigMap OIDC, BE-3 | `curl` token asli → 200; tanpa token → 401 |
| **Rab 25** | BE-4 | Tiket dibuat lewat Swagger; tenant-b → 404 |
| **Kam 26** | BE-5, BE-7 → **freeze fitur** | Alur demo §1 berjalan penuh di cluster |
| **Jum 27** | BE-6, BE-8, BE-9 (sebisanya) | Laporan SLA, panel tiket per unit |
| **Sab 28** | Perbaikan bug, bantu M8, ADR 001/005/009/012/014 → *Diterima* | — |
| **Min 29 – Sen 30** | Laporan final bab aplikasi, demo script langkah #2/#3/#7, refleksi individu | Draf laporan |
| **Sel 1 Des** | Kumpulkan dokumen, 2× gladi | — |

**Aturan potong:** jika Rab 25 malam BE-4 belum selesai, BE-6 dan BE-9 dibatalkan. Jika Kam 26 malam BE-5 belum selesai, cukup OPEN → ASSIGNED → RESOLVED.

## 8. Evidence yang dihasilkan

| Folder | Isi | Dari |
|---|---|---|
| `03-application-data/` | Swagger alur tiket lengkap, output tes CI, catatan scope yang dipotong | BE-3, BE-4, BE-5 |
| `06-security/` | Token yang di-decode, run CI dengan tes 401/403/404, matriks authz | BE-1, BE-7 |
| `07-observability-slo/` | Metrik tiket di Prometheus dan dasbor | BE-8 |
| `10-decisions-adr/` | ADR 001, 005, 009, 012, 014 berstatus *Diterima* | — |

Setiap evidence memuat: scope, timestamp (WIB), versi commit, interpretasi, limitasi.

## 9. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Issuer token tidak cocok di cluster → semua request 401 | BE-2 macet | Uji `curl` dengan token asli di hari yang sama dengan BE-2; ambil token selalu lewat `localhost:8081` |
| Role terbaca dari `groups` | Isolasi rusak | Role hanya dari `realm_access.roles`; ada tes khusus |
| Satu query tiket lupa difilter | Data bocor antarunit | Satu fungsi repository + tes "daftar usera berisi nol tiket tenant-b" |
| Waktu habis | Demo #2/#7 gagal | Aturan potong di §7; BE wajib dikerjakan berurutan sebelum yang lain |
| Hanya Radya yang paham backend | Risiko defense | B mereview setiap PR dan harus bisa menjelaskan alur tiket dalam 1 menit |

## 10. Pertanyaan terbuka

| # | Pertanyaan | Asumsi sampai dijawab |
|---|---|---|
| 1 | Apakah dosen menerima track dan substitusi teknologi (`approval.md` masih PENDING)? | Ya; jawaban dicatat C |
| 2 | Respons pertama = assign atau komentar pertama operator? | Assign (`OPEN → ASSIGNED`) |
| 3 | Apakah admin boleh membuat tiket? | Tidak; hanya role `user` |
