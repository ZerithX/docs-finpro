# PRD 03 · Security

| Field | Isi |
|---|---|
| Owner | **C** (Security & Operations). Radya: tes otomatis authz (BE-7) dan perubahan kode |
| Milestone | M6 Security, ADR keamanan (M1) |
| Versi | v1.0, 23 Nov 2026 |
| Target | Semua wajib selesai **Jum 27 Nov** |
| Folder evidence | `06-security/`, `10-decisions-adr/`, `02-architecture/boundaries.md` |
| Acuan | `docs/PRD_CampusDesk.md` §7 M6 · `02-architecture/boundaries.md` (B1–B7) · temuan T6, T11 di `Final_Project/CampusDesk_Rencana_Kerja.md` |

---

## 1. Outcome

Saat defense, C bisa:

- Menunjukkan **satu aksi yang ditolak** dan menjelaskan kenapa ditolak (demo final #7).
- Membuka hasil scan dan **menjelaskan temuan prioritas tertinggi**, bukan membacakan laporan (demo final #8).
- Menjawab: "Secret mana yang paling berbahaya kalau bocor?", "Bagaimana membuktikan isolasi tenant?", "Scan membuktikan apa dan tidak membuktikan apa?" (§13.1).

## 2. Status per 23 Nov

| Sudah ada | Belum |
|---|---|
| Trivy jalan di setiap run CI (mode laporan, `--exit-code 0`) | Analisis temuan Trivy |
| Secret DB dibuat lewat `kubectl`, hanya `secret.example.yaml` di Git | Review secret di riwayat Git |
| Boundary B1–B7 di `02-architecture/boundaries.md` (draf) | Catatan kontrol + risiko sisa per boundary |
| Desain: tenant dari token, 404 lintas tenant (ADR-003, draf) | Mapper Keycloak, tes authz (menunggu BE-1/BE-2) |
| | ADR 002, 003, 004, 015 (masih draf); commit C = 0 |

## 3. Scope

**Wajib**
- SEC-1 Export realm Keycloak + bukti token
- SEC-2 Matriks authz + bukti tes
- SEC-3 Analisis Trivy + satu perbaikan
- SEC-4 Review secret di riwayat Git
- SEC-5 Catatan ancaman/kontrol B1–B7
- SEC-6 ADR keamanan

**Sebaiknya**
- SEC-7 User database non-superuser

**Dipotong**
| Item | Alasan | Dicatat sebagai |
|---|---|---|
| Trivy sebagai gate yang memblokir build | Butuh proses pengecualian; berisiko memblokir rilis menjelang defense | Roadmap |
| TLS di Ingress, NetworkPolicy | Di luar waktu | Risiko sisa di SEC-5 |
| Ingress hanya bind `127.0.0.1` (T11) | Butuh membuat ulang cluster | Risiko sisa di SEC-5 |

## 4. Aturan

1. Jangan pernah menempel nilai secret, token utuh, atau password ke evidence. Sensor bagian tanda tangan token.
2. Temuan scan dijelaskan dengan keputusan (perbaiki / terima / tunda) dan alasannya.
3. Setiap evidence: scope, timestamp, versi commit/image, perintah, output, interpretasi, limitasi.

---

## 5. Requirement

### SEC-1 Export realm Keycloak + bukti token · M2-1 · C · **Sel 24**

Radya memasang mapper grup (BE-1, Sen 23). C kemudian:
1. Mengekspor realm `capstone` **tanpa secret** dan menyimpannya di repo (misalnya `06-security/keycloak/realm-capstone.json`), supaya lab lain bisa mereproduksinya.
2. Mengambil token `usera`, `userb`, `operator`, `appadmin`, lalu men-decode **bagian payload saja** (jwt.io atau `base64 -d`).

**Selesai jika:** `06-security/` memuat export realm dan tabel isi token per user: `groups`, `realm_access.roles`, `azp`, `iss`.

### SEC-2 Matriks authz · M6-1 · C (isi matriks) + Radya (tes) · **Jum 27**

C menyusun tabel role × endpoint × tenant berdasarkan kontrak API di PRD 01 §6. Minimal:

| Aktor | Kasus | Harapan |
|---|---|---|
| anonim | `GET /api/tickets` | 401 |
| `usera` | `GET /api/tickets/{id}` milik tenant-b | 404 |
| `usera` | `GET /api/tickets` | tidak ada tiket tenant-b |
| `usera` | `POST /api/tickets/{id}/assign` | 403 |
| `operator` | `GET /api/tickets/{id}` milik tenant mana pun | 200 |
| `operator` | assign | 200 + baris `audit_log` |

Radya menulis tesnya (BE-7). C memeriksa **setiap baris punya tes yang lulus**, lalu menjalankan 2–3 kasus secara manual di cluster dengan token asli (koleksi API, PRD 06).

**Selesai jika:** matriks di `06-security/` dengan kolom "nama tes" dan "hasil CI", plus output `curl` manual untuk 401, 403, dan 404.

### SEC-3 Analisis Trivy + perbaikan · M6-3 · C · **Rab 25**

1. Ambil output Trivy dari log run CI terbaru (step *Build, scan, publish*).
2. Tabel semua temuan HIGH/CRITICAL: CVE, paket, versi terpasang, versi perbaikan.
3. Pilih **3 prioritas teratas** dengan alasan (bisa dieksploitasi dari luar? ada di runtime atau hanya build?). Keputusan per temuan: perbaiki / terima / tunda.
4. Terapkan **satu perbaikan** (misalnya update base image `node:24-alpine` ke patch terbaru atau `npm audit fix` untuk satu dependensi) lewat PR, lalu bandingkan jumlah temuan sebelum/sesudah.
5. Tulis "scan membuktikan apa, dan tidak membuktikan apa".

**Selesai jika:** tabel, 3 keputusan beralasan, dan angka sebelum/sesudah ada di `06-security/`. Kalau tidak ada temuan HIGH/CRITICAL, catat itu dengan versi image dan versi database Trivy, lalu analisis temuan MEDIUM teratas.

### SEC-4 Review secret · M6-4 · C · **Rab 25**

Di ketiga repo, **termasuk seluruh riwayat Git**:
```bash
git log -p --all | grep -n -i -E "password|secret|token|BEGIN .*PRIVATE KEY" | grep -v example
```
atau `gitleaks detect` bila tersedia. Periksa juga `capstone-app/.env*` tidak ikut ter-commit.

**Selesai jika:** hasil per repo tercatat. Kalau ada secret asli yang pernah ter-commit, catat, ganti nilainya, dan dokumentasikan.

### SEC-5 Catatan ancaman/kontrol B1–B7 · M6-5 · C · **Kam 26**

Untuk setiap boundary di `02-architecture/boundaries.md`: ancaman utama, kontrol yang **sudah ada dan terbukti** (tautkan bukti), dan risiko sisa. Risiko sisa minimum yang harus disebut:
- Runner CI memakai Docker socket host (bisa mengendalikan Docker di laptop).
- HTTP tanpa TLS di semua layanan lab.
- Ingress ter-publish di `0.0.0.0:8088` (T11).
- User database aplikasi adalah superuser (T6), kecuali SEC-7 selesai.
- Kredensial tulis repo GitOps (`GITOPS_PASSWORD`): siapa pun yang memegangnya bisa mengganti image di cluster.

**Selesai jika:** tabel B1–B7 lengkap dan tiap kontrol punya tautan bukti.

### SEC-6 ADR keamanan · M1 · C · **Rab 25**

ADR 002 (shared schema + `tenant_id`), 003 (tenant dari klaim grup, 404 vs 403), 004 (operator lintas tenant + audit), 015 (Prometheus scrape lewat NodePort). Satu PR per ADR, review oleh B.

**Selesai jika:** 4 PR merged; C bisa menjelaskan tiap ADR dalam ±1 menit.

### SEC-7 User database non-superuser · M6-2 · C (pairing Radya) · *sebaiknya* · **Jum 27**

Buat role `campusdesk_app` (bukan superuser) yang memiliki schema aplikasi, ganti `DB_USER` di ConfigMap dan password di Secret, lalu pastikan migrasi dan aplikasi tetap jalan.

**Selesai jika:** `\du` menunjukkan role tanpa atribut Superuser, aplikasi Ready, migrasi berikutnya sukses. Kalau tidak sempat: tetap tercatat sebagai risiko sisa di SEC-5.

---

## 6. Jadwal

| Hari | C | Bergantung pada |
|---|---|---|
| Sen 23 | Siapkan lab sendiri; ambil log Trivy (SEC-3 langkah 1–2) | — |
| Sel 24 | SEC-1 | BE-1 (Radya, Sen 23) |
| Rab 25 | SEC-3, SEC-4, **SEC-6 selesai** | — |
| Kam 26 | SEC-5, susun matriks SEC-2 | — |
| Jum 27 | SEC-2 verifikasi, SEC-7 bila sempat | BE-7 (Radya, Kam 26) |

## 7. Evidence

`06-security/`: export realm, isi token, matriks authz + hasil, tabel Trivy + keputusan + sebelum/sesudah, hasil review secret, tabel B1–B7 + risiko sisa.

## 8. Risiko

| Risiko | Mitigasi |
|---|---|
| BE-2/BE-7 terlambat sehingga SEC-2 tidak bisa diverifikasi | Matriks tetap disusun Kam 26; verifikasi menyusul begitu tes ada |
| Perbaikan Trivy merusak build | Lewat PR biasa; CI harus hijau sebelum merge |
| Token atau secret ikut tertempel di evidence | Aturan §4.1; review oleh B sebelum merge |
