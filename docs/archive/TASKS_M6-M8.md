# CampusDesk: Audit 17 Nov dan Pembagian Tugas M2-sisa, M6–M8, FINAL

> Disusun 17 Nov 2026 (hari presentasi progres) dari audit folder `campusdesk` (git log `capstone-app`, `capstone-gitops`, root; `docs/PROGRESS.md`; isi folder 01–11).
> Lanjutan dari `docs/TASKS_M2-M5.md` (v2). Peran tetap: **Radya = Application & Data**, **B = Platform & Delivery**, **C = Security & Operations**.
> Deadline acuan: M6 & M7 **Sel 24 Nov**, M8 **Sab 28 Nov**, FINAL **1–2 Des**.

---

## 1. Hasil Audit (per 17 Nov)

| Milestone | Status | Bukti / catatan |
|---|---|---|
| M0 Proposal | 🟡 | `approval.md` masih **PENDING**, belum dikirim. Manfaatkan sesi presentasi hari ini untuk menanyakan 6 pertanyaan konfirmasi + substitusi TypeScript (ADR-014). |
| M1 Arsitektur | 🟡 | `02-architecture/` (diagram, B1–B7, QS1–QS7) dibuat 17 Nov, **belum di-commit**. ADR 001–015 ada; 4 milik Radya "Diusulkan", **10 milik B/C masih "Draf (menunggu owner)"**. |
| M2 Aplikasi | 🔴 | Hari ini jadwal freeze, tapi baru `units` + `sla_policy` (branch `feat/sla-policy`, belum di-merge). OIDC, tiket, tenant filter, state machine **belum ada**. |
| M3 Platform | 🟡 | Deployment/Service/Ingress/probe/resources jalan; image tag = SHA; 3 ReplicaSet. Belum: scale 1→2, readiness saat DB mati, catatan troubleshooting. |
| M4 Delivery | 🟡 | CI → registry → GitOps → Argo CD dev jalan (PR #3 → `6f24740`). Belum: staging/prod, promosi, rollback, tabel traceability. |
| M5 Observability | 🟡 | Dasbor Grafana + target Prometheus UP (PR GitOps #1 `d18d7c1`). Belum: metrik bisnis (R7), runbook, uji lonjakan 5xx. |
| M6 / M7 / M8 | ⬜ | Folder 06, 08, 09 baru berisi README. |

**Temuan kritis**

1. **Commit B dan C masih 0** di ketiga repo (semua commit oleh Radya/Radders/CI). Ini risiko terbesar untuk nilai individu dan defense (Guideline §4). Mulai minggu ini **setiap orang wajib punya minimal 3 PR sendiri** (ADR + evidence + satu perubahan teknis).
2. M2 belum mencapai fondasi auth, padahal tes negatif M6 (401/403/404) bergantung padanya.
3. Banyak pekerjaan di root `campusdesk/` belum di-commit (02-architecture).

---

## 2. Prinsip Pembagian (17 Nov)

- **Freeze diundur ke Jum 20 Nov, scope dipotong** (lihat §5 TASKS_M2-M5). Yang tidak boleh dipotong: OIDC + tenant filter + uji negatif, CI/GitOps, restore DB.
- Folder bertanda dosen (**06, 08, 09, 10**) dibagi rata: **06 → C**, **08 → B**, **09 → C (data) + B (rightsizing)**, **10 → semua owner masing-masing**.
- M7 (08) dipindah dari "C + Radya" ke **B**, karena isinya `kubectl`, Argo CD, dan `pg_dump`, yang memang ranah platform. Radya tetap pasangan saat dijalankan di lab resmi.
- Lab resmi di laptop Radya. B dan C: **latih dulu di lab sendiri** (paket dosen), lalu jalankan versi resmi saat sesi pairing (Rab 18 & Sen 23 Nov).
- Setiap evidence ditulis dengan 4 kolom: **scope, timestamp (WIB), interpretation, limitation**. Satu tugas = satu branch = satu PR, direview anggota lain.

---

## 3. Tugas per Orang

### Radya: Application & Data (selesaikan M2) + M5 metrik bisnis

| ID | Tugas | Selesai jika | Target |
|---|---|---|---|
| R0 | Merge `feat/sla-policy` (review: B). Commit `02-architecture/`. | PR merged, CI hijau | Sel 17 |
| R2 | OIDC (Hono JWT/JWKS), auth wajib di `/api/**`, `TenantContext` dari claim `groups`, role dari `realm_access.roles`, issuer sesuai ADR-012 | Tanpa token → 401; `usera` hanya tenant-a; `appadmin` semua; uji `curl` di cluster → 200 | **Kam 19** |
| R4 | Tiket: create + list/get difilter tenant di satu tempat, tenggat SLA dihitung saat create | usera POST → 201 tenant-a; usera GET tiket tenant-b → **404** | Jum 20 |
| R5-min | Transisi status minimal (OPEN→ASSIGNED→RESOLVED), invalid → 409, `audit_log` untuk aksi operator. Komentar & p95 laporan **dipotong**. | Tes per transisi | Jum 20 (**freeze**) |
| R7 | Metrik bisnis `campusdesk_tickets_created_total{tenant}`, `campusdesk_sla_breached_tickets{tenant}` → panel SLA per unit di dasbor | Muncul di `/q/metrics` dan Grafana | Sab 21 |
| R9 | Pairing M7 dengan B (DB mati, restore) + M8 (seed data untuk uji beban) | Bukti di 08/09 | Sen 23 |
| R10 | Finalisasi ADR 001, 005, 009, 012, 014 (status → Diterima setelah bukti) | PR merged | Sen 23 |

### B: Platform & Delivery → **08-reliability-recovery (M7)**, M4 sisa, ADR platform

| ID | Tugas | Selesai jika | Target |
|---|---|---|---|
| B5 | **ADR 006, 007, 008, 010, 011, 013**: isi Keputusan/Alternatif/Konsekuensi, hapus pertanyaan pemandu, PR terpisah per ADR (review: C) | 6 PR merged, B bisa menjelaskan tiap ADR ±1 menit | **Kam 19** |
| B7 | **M7 kegagalan terkontrol** (latih di lab sendiri dulu): (a) `kubectl delete pod` → ukur detik sampai Ready; (b) ubah replicas manual → Argo CD self-heal mengembalikan; (c) matikan Postgres → readiness 503, pod keluar dari endpoint, trafik 503; nyalakan → pulih | Output + timestamp + interpretasi di `08-reliability-recovery/` | Sab 21 |
| B8 | **M7 backup → restore → validasi**: `pg_dump` DB `capstone`, restore ke DB baru (`capstone_restore`), bandingkan `count(*)` tiap tabel, ukur durasi. Tetapkan **RTO/RPO** target vs terukur. Catat skrip restore `.ps1` dosen bila error (temuan paket). | Tabel jumlah baris sebelum = sesudah; RTO/RPO tertulis | **Sen 23** (pairing di lab resmi) |
| B3 | Sisa M3: scale 1→2 (cek advisory lock migrasi), `rollout history`, satu catatan troubleshooting | Bukti di `04-platform-kubernetes/` | Sab 21 |
| B4-min | Overlay **staging** saja (prod dipotong → cukup dijelaskan di ADR-011), promosi dev→staging lewat PR GitOps, rollback `git revert`, **tabel traceability** commit → run CI → digest → commit GitOps → ReplicaSet | Bukti di `05-ci-cd-gitops/` | Rab 25 |
| B6 | Koleksi request API (`.http`/Bruno/Postman): token tiap user + semua endpoint + kasus ditolak. Dipakai C untuk 06 dan untuk demo. | Di `11-demo-defense/api/`, jalan terhadap dev | Sab 21 (setelah R2) |
| B9 | Kontribusi M8: rightsizing requests/limits berdasarkan data C, PR GitOps perubahan resources | PR merged + alasan | Jum 27 |

### C: Security & Operations → **06-security (M6)**, **09-capacity-finops (M8)**, M5 sisa, ADR security

| ID | Tugas | Selesai jika | Target |
|---|---|---|---|
| C0 | Kirim/konfirmasi proposal M0 **hari ini di kelas**; isi `approval.md` dengan jawaban asli (termasuk TypeScript) | `approval.md` bukan PENDING | **Sel 17** |
| C3 | **ADR 002, 003, 004, 015** diisi owner + PR (review: B). Review `02-architecture/boundaries.md` dan `quality-scenarios.md` (C owner B1–B7, QS1–QS7) | 4 PR merged | **Kam 19** |
| C1 | Keycloak: mapper Group Membership (`groups`) di `capstone-app`, export realm tanpa secret, decode token `usera`/`userb`/`operator` | Token berisi `groups: ["/tenant-a"]`, screenshot di `06-security/` | **Rab 18** (blocker R2!) |
| C2 | Matriks authz (role × endpoint × tenant) + jalankan via koleksi B6: tanpa token → 401, role salah → 403, tenant-a ke tiket tenant-b → 404 | Tabel hasil lulus/gagal + tes otomatis Radya | Sen 23 |
| C7 | **Trivy**: ambil hasil scan dari CI, pilih 1–2 temuan prioritas, jelaskan keputusan (fix / terima risiko) | Tabel temuan + alasan | Sab 21 |
| C8 | **Secret & hardening**: review repo dari secret (`git log -p` grep), Secret hanya via `kubectl`, user DB non-superuser (T6), Ingress `0.0.0.0:8088` (T11) → keputusan + risiko sisa | Catatan kontrol per boundary B1–B7 | Sel 24 |
| C6 | M5 sisa: dokumen SLI/SLO, runbook singkat, uji lonjakan 5xx terlihat ≤ 1 menit (QS7) | `07-observability-slo/` lengkap | Sab 21 |
| C9 | **M8 Capacity**: uji beban sederhana (k6/`hey`/loop curl), `kubectl top` + data Grafana vs requests/limits, headroom node | Tabel pemakaian vs alokasi | Rab 25 |
| C10 | **M8 FinOps**: estimasi biaya bulanan (mis. VM cloud setara 2 node + DB), biaya per tenant/tiket, sumber angka transparan; roadmap ke CloudStack | `09-capacity-finops/` | **Sab 28** |

---

## 4. Kalender

| Hari | Radya | B | C |
|---|---|---|---|
| Sel 17 | Presentasi; R0 | Presentasi; mulai B5 | Presentasi; **C0 tanya dosen** |
| Rab 18 | R2 | B5, latih B7 di lab sendiri | **C1 (pairing di laptop Radya)**, C3 |
| Kam 19 | **R2 selesai** | **B5 selesai** | **C3 selesai** |
| Jum 20 | R4, R5-min → **freeze** | B6 (mulai) | C7 |
| Sab 21 | R7 | B7, B3 | C6, C7 |
| Sen 23 | R9, R10 | **B8 pairing restore** | C2 |
| Sel 24 | **Review M6/M7** | 08 lengkap | 06 lengkap (C8) |
| Rab 25 – Sab 28 | Bantu M8, laporan | B4-min, B9 | C9, C10 → **M8** |
| 29 Nov – 2 Des | Demo script, gladi, pertanyaan defense acak antar anggota (`11-demo-defense/`) | | |

**Sinkron 15 menit:** Kam 19 (cek auth + ADR), Sel 24 (review M6/M7), Sab 28 (M8 + gladi pertama).
