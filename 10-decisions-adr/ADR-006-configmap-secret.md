# ADR-006: Penanganan ConfigMap dan Secret

| Field | Isi |
|---|---|
| Status | Draf (menunggu review) |
| Tanggal | 2026-11-24 |
| Owner | B |
| Milestone | M1 / M3 |

## Konteks
- Konfigurasi non-rahasia ada di `capstone-gitops/base/configmap.yaml` (`DB_URL`, `DB_USER`, `OIDC_ISSUER`).
- Password DB **tidak** di Git: Secret `capstone-app-secret` dibuat langsung dengan `kubectl create secret` (Infra Guide §13); repo hanya berisi `base/secret.example.yaml`.
- Secret CI ada di Gitea Actions: `GITOPS_PASSWORD` (CI menulis ke repo GitOps) dan `TEST_DB_PW` (DB tes `campusdesk_test`).
- Rencana B2: tiga namespace (`campusdesk-dev/-staging/-prod`) dengan DB dan Secret per namespace, sehingga Secret harus dibuat tiga kali dan tidak ikut sync Argo CD.
- PRD §5 butir 5: tidak ada password/token asli di Git; hanya `*.example.yaml`.

## Keputusan
Konfigurasi non-rahasia seperti `DB_URL`, `DB_USER`, dan `OIDC_ISSUER` disimpan menggunakan ConfigMap, sedangkan password dan token disimpan menggunakan Secret. Secret dibuat dan dikelola di cluster tanpa menyimpan nilai rahasianya di Git, sehingga repository hanya berisi template atau contoh konfigurasi.

## Alternatif yang dipertimbangkan
- **Sealed Secrets:** Memungkinkan Secret disimpan dalam bentuk terenkripsi di Git dan didekripsi oleh controller di cluster. Tidak dipilih karena menambah komponen dan alur operasional baru yang belum diperlukan untuk scope proyek saat ini.
- **SOPS:** Memungkinkan file Secret terenkripsi dikelola melalui Git. Tidak dipilih karena membutuhkan pengelolaan kunci serta workflow tambahan, sementara kebutuhan proyek saat ini masih dapat dipenuhi dengan Secret yang dibuat langsung di cluster.
- **External Secrets/Vault:** Memisahkan penyimpanan secret dari cluster dan menggunakan secret manager eksternal. Tidak dipilih karena menambah dependensi infrastruktur dan kompleksitas operasional yang belum diperlukan dalam scope proyek.

## Konsekuensi
- **Positif:** Nilai password dan token tidak tersimpan sebagai plaintext di repository. ConfigMap dapat dikelola melalui GitOps, sementara Secret tetap berada di lingkungan cluster.
- **Negatif / risiko sisa:** Secret harus dibuat kembali ketika cluster atau namespace dibuat ulang. Pada skenario tiga environment, Secret juga perlu tersedia secara terpisah pada masing-masing namespace.
- **Yang perlu dipantau atau dibuktikan:** Pastikan tidak ada nilai secret yang masuk ke Git, termasuk pada riwayat commit. Perlu dilakukan pemeriksaan terhadap repository dan riwayat Git sebagai bagian dari pembuktian M6-4.