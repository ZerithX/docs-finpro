# M0 — Proposal Kasus: CampusDesk (Multi-Tenant IT Service Desk)

| Field | Isi |
|---|---|
| Mata kuliah | Modern Cloud Computing — Final Capstone (SI Semester V, 2026/2027) |
| Track | **IT Service: Multi-Tenant Service Desk** (ticket → assignment → resolution → SLA summary) |
| Tim | Radya (Application & Data), B (Platform & Delivery), C (Security & Operations) |
| Owner dokumen | C (penulis/editor), direview Radya dan B |
| Versi | v0.1 draf, 3 Nov 2026 |
| Status | **Draf — belum diajukan ke dosen** (respon dicatat di `approval.md`) |
| Sumber | `docs/PRD_CampusDesk.md` v1.0, `Final_Project/CampusDesk_Rencana_Kerja.md`, Guideline §5.1 dan §12 (Deliverable A) |

> Label: **[PUTUS]** sudah diputuskan tim · **[USUL]** usulan, perlu disetujui dosen · **[ASUMSI]** dipakai sampai dikonfirmasi.

---

## 1. Ringkasan

CampusDesk adalah **satu platform service desk TI yang dipakai bersama oleh banyak unit kampus** (fakultas, program studi, unit pendukung). Setiap unit adalah *tenant*: pengguna unit hanya melihat tiket unitnya sendiri, sedangkan teknisi TI pusat menangani tiket semua unit dengan jejak audit. Setiap tiket memiliki tenggat SLA berdasarkan prioritas, dan kepala TI mendapat ringkasan pencapaian SLA per unit.

Fokus proyek adalah **rekayasa cloud**: aplikasi sengaja kecil (5 entitas, 3 role, 1 workflow utama) agar waktu tim dipakai untuk membuktikan deployment berulang, GitOps, isolasi tenant, observability/SLO, keamanan, pemulihan data, dan alasan biaya.

## 2. Masalah

Saat ini (gambaran kasus; **[ASUMSI]** belum diukur di kampus nyata):

1. Permintaan bantuan TI masuk lewat WhatsApp, email, atau lisan, sehingga **mudah hilang** dan tidak ada nomor tiket untuk ditelusuri.
2. **Waktu respon dan penyelesaian tidak diukur**, sehingga tidak ada dasar untuk menyatakan layanan TI "baik" atau "buruk".
3. **Data antar unit tidak terpisah**; permintaan satu fakultas bisa terlihat oleh fakultas lain.
4. Kepala TI **tidak punya ringkasan layanan** per unit untuk evaluasi dan perencanaan kapasitas tim.

## 3. Jawaban atas 7 Pertanyaan Guideline §5.1

### 3.1 Siapa pengguna dan stakeholder?

| Persona | Role / grup Keycloak | Boleh | Tidak boleh |
|---|---|---|---|
| Staf/dosen/mahasiswa unit | `user` + grup `tenant-x` | Membuat tiket, melihat dan mengomentari tiket **unitnya sendiri**, melihat ringkasan SLA unitnya | Melihat tiket unit lain; assign atau menutup tiket orang lain |
| Teknisi TI | `operator` (tanpa grup tenant) | Melihat tiket **semua** unit, assign, mengubah status, berkomentar. Setiap aksi lintas tenant dicatat di audit log | Mengelola unit dan kebijakan SLA |
| Kepala TI | `admin` | Mengelola unit dan kebijakan SLA, melihat laporan semua unit | — |

Stakeholder tambahan (tidak login ke sistem): pimpinan unit (konsumen laporan SLA unitnya), dan tim platform kampus (yang menjalankan layanan).

Akun lab untuk demo: `usera` (tenant-a), `userb` (tenant-b), `operator`, `appadmin`.

### 3.2 Proses bisnis apa yang diperbaiki?

Proses **penanganan permintaan/insiden TI** dengan alur:

```
OPEN → ASSIGNED → IN_PROGRESS → RESOLVED → CLOSED
                       ↑              │
                       └── reopen ────┘ (oleh pelapor)
```

| Transisi | Pelaku |
|---|---|
| (buat tiket) → OPEN | user |
| OPEN → ASSIGNED | operator (dicatat sebagai *first response*) |
| ASSIGNED → IN_PROGRESS | operator |
| IN_PROGRESS → RESOLVED | operator |
| RESOLVED → CLOSED | pelapor atau operator |
| RESOLVED → IN_PROGRESS | pelapor (reopen) |

Transisi lain ditolak (HTTP 409). Hasil akhirnya adalah **ringkasan SLA per unit** per periode: jumlah tiket, rata-rata dan p95 waktu respon pertama, serta persentase tiket yang memenuhi SLA.

### 3.3 Data apa yang harus persisten?

| Entitas | Isi utama | Alasan harus persisten |
|---|---|---|
| `Unit` (tenant) | kode (= nama grup Keycloak), nama | Kunci isolasi data |
| `SlaPolicy` | prioritas, target respon, target penyelesaian | Dasar perhitungan tenggat; bisa diubah admin |
| `Ticket` | unit, pelapor, judul, kategori, prioritas, status, `response_due_at`, `resolve_due_at`, `first_response_at`, `resolved_at` | Rekam layanan; dasar laporan SLA |
| `TicketComment` | tiket, penulis, isi, waktu | Riwayat komunikasi |
| `AuditLog` | aktor, aksi, tiket, unit target, waktu | Akuntabilitas akses lintas tenant oleh operator/admin |

Laporan SLA **dihitung dari query**, tidak disimpan. Tenggat SLA **dihitung dan disimpan saat tiket dibuat**, sehingga perubahan kebijakan tidak mengubah tiket lama. Kehilangan data tiket berarti kehilangan rekam layanan, sehingga backup **dan uji restore** wajib (lihat §6).

Nilai SLA awal **[USUL]** (24x7, tanpa kalender jam kerja):

| Prioritas | Respon pertama | Penyelesaian | Contoh |
|---|---|---|---|
| KRITIS | 30 menit | 4 jam | Jaringan satu gedung mati saat ujian |
| TINGGI | 1 jam | 8 jam | Lab komputer tidak bisa login |
| SEDANG | 4 jam | 24 jam | Printer unit rusak |
| RENDAH | 8 jam | 72 jam | Permintaan instal software |

### 3.4 Keputusan autentikasi/otorisasi apa saja?

- **AuthN:** Keycloak (OIDC). Aplikasi memvalidasi JWT (issuer, signature, masa berlaku). Semua endpoint `/api/**` wajib token; hanya health, metrics, dan OpenAPI/Swagger yang terbuka. **[PUTUS]**
- **AuthZ berbasis role:** `user`, `operator`, `admin` (realm role). **[PUTUS]**
- **Tenant berasal dari klaim `groups` di token** (`/tenant-a` → `units.code = tenant-a`), **tidak pernah dari input pengguna** (body, query, atau header). Filter tenant diterapkan di **satu tempat terpusat**. **[PUTUS]**
- **Akses lintas tenant** hanya untuk `operator`/`admin`, dan setiap baca/tulis tiket oleh mereka dicatat di `AuditLog`. **[PUTUS]**
- Akses `user` ke tiket unit lain menghasilkan **404** agar tidak membocorkan keberadaan tiket. **[USUL]**, difinalkan di ADR 003.
- Celah yang sudah diketahui: realm lab dari dosen belum punya *Group Membership mapper*, jadi klaim `groups` belum ada di token. Ini dikerjakan pertama di M2 (temuan T1).

### 3.5 Kenapa butuh karakteristik cloud, bukan sekadar hosting?

| Karakteristik cloud | Kenapa relevan untuk CampusDesk |
|---|---|
| **Multi-tenancy / resource pooling** | Satu platform dan satu database melayani banyak unit; isolasi harus ditegakkan oleh aplikasi dan dibuktikan dengan uji negatif, bukan dengan memberi tiap unit server sendiri |
| **Elastisitas** | Beban tidak merata: lonjakan saat awal semester, registrasi, dan ujian. Deployment harus bisa diskalakan (replika) tanpa mengubah kode, dan logika SLA dirancang aman untuk lebih dari satu replika (breach dihitung lewat query, bukan scheduler) |
| **Layanan terukur (measured service)** | SLA adalah tujuan bisnis yang terukur; metrik per tenant dan SLO menjadi bukti kualitas layanan, sekaligus dasar *cost per tenant* |
| **Otomasi delivery** | Perubahan harus bisa berpindah dari commit ke runtime secara terlacak (CI → image immutable → GitOps → Argo CD), dengan promosi dev → staging → prod dan rollback lewat `git revert` |
| **Recoverability** | Riwayat tiket adalah rekam layanan; pemulihan harus dibuktikan dengan restore dan validasi, bukan sekadar file backup |

Hosting biasa (satu VM + aplikasi) bisa menjalankan aplikasinya, tapi tidak membuktikan isolasi tenant, deployment berulang, observability per tenant, atau pemulihan terukur — padahal itulah kebutuhan nyata kasus ini.

### 3.6 Concern teknis apa yang membuat proyek bermakna?

1. **Keamanan / isolasi tenant:** satu query yang lupa filter tenant = kebocoran data antar fakultas. Mitigasi: filter terpusat + uji negatif otomatis di CI.
2. **Ketersediaan & pemulihan:** pod harus pulih sendiri setelah gagal; database harus bisa di-restore dengan RTO terukur. Limitasi jujur: single node, single DB, **tanpa klaim HA**.
3. **Skalabilitas:** lonjakan musiman diuji dengan load test 20 pengguna bersamaan dan rightsizing requests/limits.
4. **Operabilitas:** pemilik layanan (kepala TI) butuh dasbor SLA dan error rate yang bisa dibaca, bukan dasbor default.

### 3.7 Apa yang bisa didemokan dalam semester ini dengan infrastruktur yang tersedia?

Semua berjalan di lab lokal paket dosen (Docker Desktop + k3d, Gitea + runner, registry lokal, Keycloak, PostgreSQL, Argo CD, Prometheus/Grafana):

1. Login sebagai `usera`, membuat tiket, melihat tenggat SLA terisi otomatis.
2. Operator meng-assign dan menyelesaikan tiket; laporan SLA unit diperbarui.
3. `userb` ditolak saat mengakses tiket tenant-a.
4. Commit → CI (test, build, Trivy, push) → Argo CD deploy ke dev → promosi ke staging/prod lewat PR.
5. Dasbor SLA/SLO, satu kegagalan terkendali dan pemulihannya, restore database tervalidasi, serta perhitungan biaya per tenant.

Yang **sudah berjalan** per 3 Nov 2026: walking skeleton Quarkus (health, metrics, OpenAPI, Flyway `units`) terdeploy ke k3d melalui CI Gitea dan Argo CD (`capstone-app@6aa3092`, GitOps commit `c8162ce`). CloudStack hanya sebagai **desain dan roadmap**. **[USUL]**

## 4. Perbedaan dengan Track Campus Services (M0-2)

| Aspek | Campus Services (contoh Guideline) | CampusDesk |
|---|---|---|
| Domain | Reservasi & pemakaian laboratorium | **IT Service Management** (insiden/permintaan TI) |
| Workflow | request → approval → usage → report | **ticket → assignment → resolution → SLA summary** (persis baris IT Service) |
| Objek inti | Ruang/lab dan jadwal | Tiket, kebijakan SLA, audit log |
| Ukuran keberhasilan | Pemanfaatan ruang | **Pencapaian SLA** (waktu respon & penyelesaian) |
| Tenancy | Umumnya tidak multi-tenant | **Multi-tenant**: tiap unit adalah tenant terisolasi |

Kata "kampus" hanya menjelaskan **siapa tenant-nya** (unit/fakultas), bukan jenis layanannya. Tidak ada fitur reservasi, jadwal, atau fasilitas.

## 5. Justifikasi API-only + Swagger UI (M0-3)

- Fokus penilaian adalah **keputusan dan bukti rekayasa cloud**, bukan UI (Guideline §1, §6: API-only diterima jika dijustifikasi dan didemokan).
- Seluruh alur bisnis bisa didemokan lewat **Swagger UI** dan **skrip `curl`/HTTP yang bisa diulang**. Skrip yang sama dipakai untuk uji otomatis positif dan negatif (termasuk uji isolasi tenant), sehingga demo dan bukti konsisten.
- Tanpa frontend, permukaan serangan dan beban build lebih kecil, sehingga waktu tim dialihkan ke security, observability, dan recovery.
- Frontend dicatat sebagai **roadmap**, bukan bagian MVP.

## 6. Kriteria Sukses Terukur

| ID | Atribut | Ukuran | Milestone |
|---|---|---|---|
| QS1 | Isolasi tenant | Baca lintas tenant → 404/403, **0 record bocor**, diuji otomatis di CI | M2/M6 |
| QS2 | Kebenaran SLA | Tiket melewati `response_due_at` tanpa assign ditandai *breach* (uji dengan clock tetap) | M2 |
| QS3 | Pemulihan pod | Pod dihapus → Ready kembali **≤ 60 detik** | M7 |
| QS4 | Performa | 20 pengguna bersamaan, **p95 ≤ 500 ms** | M8 |
| QS5 | Recoverability | **RTO ≤ 30 menit** (diukur saat restore); RPO = umur backup terakhir | M7 |
| QS6 | Deployability | Merge → Running di dev **≤ 15 menit** | M4 |
| QS7 | Operabilitas | Lonjakan 5xx terlihat di dasbor **≤ 1 menit** | M5 |
| SLO bisnis | SLA | **≥ 95%** tiket memenuhi target respon pertama per unit per periode | M5 |
| SLO teknis | Ketersediaan | **≥ 99%** respons non-5xx selama jendela uji | M5 |

## 7. Scope

**Masuk scope:** 5 entitas di §3.3, workflow §3.2, SLA per prioritas (24x7), laporan SLA per unit, tenancy Opsi A (shared schema + `tenant_id`, tenant dari token), REST API + Swagger UI, tiga environment (dev/staging/prod) dalam satu cluster.

**Di luar scope (tidak dibangun):** frontend, notifikasi email/SMS, SSO/LDAP kampus, aplikasi mobile, kalender jam kerja/hari libur, message broker, microservices, lampiran file, klaim high availability.

Arsitektur: **modular monolith** (Node.js 24 + TypeScript dengan Hono dan Drizzle ORM, PostgreSQL 17, Keycloak). Detail dan alasan akan ditulis di ADR (M1). **[USUL — diubah 10 Nov oleh Radya]** Stack berbeda dari jalur referensi kursus (Quarkus); rationale substitusi sesuai Guideline §8 ada di `10-decisions-adr/ADR-014-substitusi-typescript.md`. Mohon dikonfirmasi dosen.

## 8. Peran Tim

| Anggota | Area | Tanggung jawab utama |
|---|---|---|
| Radya | Application & Data | OIDC/tenant context, entitas, workflow, logika SLA, filter tenant, tes; host lab resmi |
| B | Platform & Delivery | Repo, environment dev/staging/prod (Kustomize), Argo CD, rilis/promosi/rollback, bukti Kubernetes, koleksi request API dan demo script |
| C | Security & Operations | Proposal M0, mapper Keycloak, uji authz, user DB non-superuser, Trivy, metrik/dasbor/SLO, backup/restore, FinOps |

Aturan kolaborasi: `main` dilindungi, setiap perubahan lewat PR dengan **1 review dari anggota lain**; setiap anggota wajib punya PR yang di-merge. Semua anggota menjalankan lab lengkap agar bisa menjawab pertanyaan defense acak.

## 9. Risiko Awal

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Kontribusi tidak merata (per 10 Nov semua commit masih oleh Radya) | Nilai individu dan defense | B memegang PR GitOps/M3/M4, C memegang PR M0/M5/M6; review silang (B mereview PR backend) |
| Klaim `groups` tidak ada di JWT (realm dosen tanpa mapper) | Isolasi tenant tidak bisa ditegakkan | Mapper ditambahkan di awal M2, diverifikasi dengan decode token |
| Query lupa filter tenant | Kebocoran data antar unit | Filter terpusat + uji negatif di CI |
| Skrip restore PowerShell dari paket lab gagal di Windows | Bukti recovery tidak ada | Diuji di minggu 2, bukan minggu 4 |
| Lab hanya ada di satu laptop (Gitea bind ke localhost) | Ketergantungan pada satu orang | Kolaborasi via GitHub; tiap anggota menjalankan lab sendiri untuk latihan |
| Over-scope | Milestone inti tertunda | Feature freeze 17 Nov; item out-of-scope ditolak saat review |

## 10. Asumsi dan Limitasi

- SLA dihitung **24x7**; kalender jam kerja menjadi limitasi yang dicatat.
- dev/staging/prod adalah **pemisahan logis** (namespace + database berbeda) dalam **satu cluster dan satu server PostgreSQL**, bukan isolasi fisik.
- Single node, single DB: **tidak ada klaim HA atau DR**.
- *First response* = transisi pertama ke `ASSIGNED`.
- CloudStack hanya desain/roadmap.

## 11. Pertanyaan Konfirmasi untuk Dosen

| # | Pertanyaan | Asumsi tim sampai dijawab |
|---|---|---|
| 1 | Apakah case IT Service Desk dengan tenant unit/fakultas kampus cukup berbeda dari track Campus Services? | Ya (lihat §4) |
| 2 | Apakah API-only dengan Swagger UI diterima? | Ya (lihat §5) |
| 3 | Apakah riwayat PR di GitHub diterima sebagai bukti kolaborasi, dengan CI/GitOps tetap di Gitea lab? | Ya, keduanya ditunjukkan |
| 4 | Apakah dev/staging/prod berupa namespace + database terpisah dalam satu cluster lab sudah cukup? | Ya, dengan limitasi tertulis |
| 5 | Apakah SLA 24x7 tanpa kalender jam kerja diterima untuk MVP? | Ya |
| 6 | Apakah bagian CloudStack cukup berupa desain dan roadmap? | Ya |
