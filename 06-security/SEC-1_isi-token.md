# SEC-1 Isi token per akun (sebagian: export realm belum)

| Field | Isi |
|---|---|
| Scope | Access token `usera`, `userb`, `operator`, `appadmin`; realm `capstone`, client `capstone-app` |
| Owner | C (SEC-1); verifikasi awal oleh penulis PR #5, pengukuran ulang di lab Radya dibantu Claude Code |
| Source / versi | Keycloak 26.8.1 (`quay.io/keycloak/keycloak:26.8.1`), lab Radya |
| Timestamp | 2026-11-24 13:45:51 WIB |
| Method | Password grant lewat `http://localhost:8081`; hanya payload yang di-decode, token dan signature tidak disimpan |
| Decision supported | ADR-003 (tenant dari klaim grup), ADR-012 (issuer OIDC) |

## Observation (lab resmi, port 8081)

| Akun | `realm_access.roles` | `groups` | `azp` | `iss` | `typ` | `iat` |
|---|---|---|---|---|---|---|
| `usera` | `user` | `/tenant-a` | `capstone-app` | `http://localhost:8081/realms/capstone` | Bearer | 1795502752 |
| `userb` | `user` | `/tenant-b` | `capstone-app` | `http://localhost:8081/realms/capstone` | Bearer | 1795502752 |
| `operator` | `operator` | tidak ada | `capstone-app` | `http://localhost:8081/realms/capstone` | Bearer | 1795502752 |
| `appadmin` | `admin` | tidak ada | `capstone-app` | `http://localhost:8081/realms/capstone` | Bearer | 1795502753 |

## Verifikasi terpisah (PR #5)

Dilaporkan penulis PR #5: Keycloak lokal 26.8.1 lewat `localhost:8082`, mapper dipasang lewat Admin Console. `userb` berisi role `user` dan grup `/tenant-b`; `operator` berisi role `operator` tanpa grup tenant. Waktu dan screenshot belum dilampirkan. Hasilnya konsisten dengan tabel di atas, dan bukan uji integrasi BE-2.

## Interpretation

- Tenant hanya ada pada akun unit; staf (`operator`, `appadmin`) tidak terikat grup tenant, sesuai rancangan lintas tenant.
- `iss` sama dengan `OIDC_TOKEN_ISSUER` di cluster. Token yang diambil lewat alamat lain berisi `iss` berbeda dan ditolak aplikasi (ADR-012).

## Limitation

- **Export realm tanpa secret belum ada**, jadi SEC-1 belum selesai. Mapper hanya ada di database Keycloak dan hilang jika realm diimpor ulang.
- Isi token tidak membuktikan penegakan di aplikasi; itu dibuktikan di `BE-5_BE-7_alur-authz.md`.
- Akun demo lab; password tidak dicantumkan.
