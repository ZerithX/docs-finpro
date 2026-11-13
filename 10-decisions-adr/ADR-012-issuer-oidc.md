# ADR-012: Issuer OIDC: discovery lewat `keycloak:8080`, issuer token `localhost:8081`

| Field | Isi |
|---|---|
| Status | Diusulkan |
| Tanggal | 2026-11-13 |
| Owner | Radya |
| Milestone | M2 (R2) |

> Draf disiapkan dengan bantuan Claude dari dokumen tim. **Belum diverifikasi di cluster.** Status baru boleh menjadi *Diterima* setelah bukti di bagian akhir ada.

## Konteks
- Pod di k3d tidak bisa menjangkau `host.k3d.internal:8081`, karena Keycloak hanya bind ke `127.0.0.1` di laptop (temuan T10, diuji 28 Okt). Dari pod, `keycloak:8080` di jaringan `capstone-net` bisa dijangkau.
- Token untuk demo diambil dari laptop lewat `http://localhost:8081`, sehingga klaim `iss` di token berisi `http://localhost:8081/realms/capstone`.
- Akibatnya URL yang dipakai aplikasi untuk mengambil kunci (discovery/JWKS) berbeda dengan issuer di token. Kalau aplikasi memakai satu nilai untuk keduanya, semua request ditolak 401.
- Configmap saat ini masih `OIDC_ISSUER: http://host.k3d.internal:8081/realms/capstone` (`capstone-gitops/base/configmap.yaml`).

## Keputusan
Konfigurasi OIDC dipisah menjadi dua variabel di ConfigMap:
- `OIDC_ISSUER=http://keycloak:8080/realms/capstone`: dipakai aplikasi untuk discovery dan mengambil JWKS;
- `OIDC_TOKEN_ISSUER=http://localhost:8081/realms/capstone`: nilai `iss` yang **diterima** saat memverifikasi token.

Tanda tangan, `iss`, `exp`, dan role (`realm_access.roles`) tetap diverifikasi; tidak ada pemeriksaan yang dimatikan.

## Alternatif yang dipertimbangkan
- **Tetap `host.k3d.internal:8081`:** sesuai template dosen, tapi terbukti *connection refused* dari pod (T10). Ditolak.
- **Set hostname tetap di Keycloak (`KC_HOSTNAME`) supaya `iss` selalu sama dari mana pun:** paling bersih, tapi mengubah `docker-compose.yml` milik dosen dan butuh nama host yang bisa di-resolve dari laptop dan pod. Disimpan sebagai opsi kalau pendekatan dua variabel gagal (perlu dicatat juga di ADR-013).
- **Mematikan validasi issuer:** paling mudah, tapi token dari issuer lain ikut diterima. Ditolak karena melemahkan boundary autentikasi.

## Konsekuensi
- **Positif:** tidak mengubah paket dosen; validasi token tetap lengkap.
- **Negatif / risiko sisa:**
  - `localhost` dan `127.0.0.1` menghasilkan `iss` yang **berbeda**. Token yang diambil lewat `http://127.0.0.1:8081` akan ditolak; skrip demo dan dokumentasi harus konsisten memakai `localhost`;
  - nilai ini khusus lab lokal; di CloudStack (desain) Keycloak akan punya hostname tetap dan cukup satu variabel.
- **Bukti yang dibutuhkan (R2):** `curl` dengan token `usera` ke `/api/units` di cluster → 200 (bukan 401); token dari `127.0.0.1` → 401 (membuktikan risiko di atas); disimpan di `03-application-data/` dengan evidence standard.
