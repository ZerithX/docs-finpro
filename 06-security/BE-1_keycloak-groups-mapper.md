# BE-1 · Mapper grup Keycloak: token `usera` berisi `groups`

| Field | Isi |
|---|---|
| Scope | Realm `capstone`, client `capstone-app` (Keycloak lab lokal, container `capstone-keycloak`) |
| Owner | Radya (dibantu Claude Code) |
| Source / versi | Keycloak 26.8.1 (`quay.io/keycloak/keycloak:26.8.1`); realm dari `Final_Project/infrastructure/keycloak/realm-capstone.json` |
| Timestamp | Token diterbitkan 2026-11-23 04:37:11 WIB (`iat` = 1795383431) |
| Method | `kcadm.sh` di dalam container (via `docker exec`), token lewat `http://localhost:8081` dengan password grant |
| Decision supported | BE-2 dapat mengambil tenant dari klaim `groups` dan role dari `realm_access.roles` (ADR-003, ADR-012) |

## Kondisi awal (dibaca sebelum mengubah apa pun)

- Client `capstone-app`: `publicClient=true`, `directAccessGrantsEnabled=true`, **tanpa protocol mapper**.
- Grup: `/tenant-a`, `/tenant-b`. Keanggotaan sudah benar: `usera` → `/tenant-a`, `userb` → `/tenant-b`, `operator` dan `appadmin` tanpa grup. Tidak diubah.
- Semua user tanpa `email`/`firstName`/`lastName`.

## Perubahan

1. Protocol mapper baru di client `capstone-app` (setara "dedicated scope" di UI):

   ```json
   {
     "name": "groups",
     "protocol": "openid-connect",
     "protocolMapper": "oidc-group-membership-mapper",
     "config": {
       "claim.name": "groups",
       "full.path": "true",
       "access.token.claim": "true",
       "id.token.claim": "true",
       "userinfo.token.claim": "true",
       "introspection.token.claim": "true"
     }
   }
   ```

2. Profil 4 user diisi (`email=<username>@campusdesk.local`, `firstName`, `lastName`, `emailVerified=true`) untuk `usera`, `userb`, `operator`, `appadmin`.

## Observasi

Percobaan pertama ambil token ditolak:

```
{"error":"invalid_grant","error_description":"Account is not fully set up"}
```

Setelah profil diisi, payload access token `usera` (header dan signature tidak disertakan):

```json
{
  "exp": 1795383731,
  "iat": 1795383431,
  "iss": "http://localhost:8081/realms/capstone",
  "sub": "51c3a08f-63e4-436b-b547-5bd3e0ad2965",
  "typ": "Bearer",
  "azp": "capstone-app",
  "realm_access": { "roles": ["user"] },
  "scope": "email profile",
  "email_verified": true,
  "name": "User FakultasA",
  "groups": ["/tenant-a"],
  "preferred_username": "usera",
  "email": "usera@campusdesk.local"
}
```

(Klaim `jti`, `sid`, `acr`, `allowed-origins`, `given_name`, `family_name` ada di token asli, dihilangkan di sini agar ringkas.)

## Interpretasi

- `"groups": ["/tenant-a"]` dan `realm_access.roles` berisi `user` → kriteria "Selesai jika" BE-1 terpenuhi.
- `iss` = `http://localhost:8081/realms/capstone` karena token diambil lewat port host; inilah nilai `OIDC_TOKEN_ISSUER` di ADR-012.
- `azp` = `capstone-app` → BE-2 bisa memeriksa `azp`.
- **Penyebab penolakan pertama:** Keycloak 26 mewajibkan email/nama depan/nama belakang (user profile). User hasil import realm dosen tidak punya field itu, sehingga Keycloak menuntut *Verify Profile*. Password grant tidak bisa menampilkan form, jadi login ditolak. Ini temuan lingkungan lab (nomor T menyusul).

## Limitasi

- Dokumen ini hanya memuat payload token `usera`. Isi token keempat akun: `SEC-1_isi-token.md`.
- Perubahan hanya ada di database Keycloak. **Hilang jika realm di-import ulang / lab di-reset**, karena `realm-capstone.json` milik dosen tidak diubah. C perlu mengekspor realm (SEC-1) agar perubahan tersimpan di repo.
- Screenshot: `BE-1_usera-token-decoded.png` (decode lokal di PowerShell, token kedua dengan `iat` 2026-11-23 04:52:29 WIB; salinan dari `docs/01-backend/be-1keycloak.png`).
- Akun yang dipakai adalah akun default paket lab dosen; password tidak dicantumkan (PRD 03 §4.1).
