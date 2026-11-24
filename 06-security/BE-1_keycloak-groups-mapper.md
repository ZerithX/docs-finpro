# BE-1 · Mapper grup Keycloak: token `usera` berisi `groups`

| Field | Isi |
|---|---|
| Scope | Realm `capstone`, client `capstone-app` |
| Owner bukti awal | Radya (dibantu Claude Code) |
| Sumber bukti awal | Keycloak 26.8.1; realm dari `Final_Project/infrastructure/keycloak/realm-capstone.json` |
| Waktu bukti awal | 2026-11-23 04:37:11 WIB |
| Metode bukti awal | `kcadm.sh` di container; token diambil melalui `localhost:8081` dengan password grant |
| Verifikasi tambahan | Token `userb` dan `operator` diperiksa pada Keycloak lokal 26.8.1 melalui `localhost:8082` |
| Keputusan yang didukung | BE-2 dapat membaca tenant dari klaim `groups` dan role dari `realm_access.roles` (ADR-003, ADR-012) |

## Kondisi awal

- Client `capstone-app` belum memiliki protocol mapper untuk mengirim grup ke token.
- Grup dan keanggotaan sudah benar: `usera` → `/tenant-a`, `userb` → `/tenant-b`; `operator` dan `appadmin` tidak memiliki grup tenant.
- Profil user hasil import belum lengkap.

## Perubahan

1. Mapper **Group Membership** ditambahkan pada client `capstone-app`:

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

2. Profil `usera`, `userb`, `operator`, dan `appadmin` dilengkapi agar Keycloak dapat menerbitkan token melalui password grant.

## Observasi

### Token `usera` — bukti awal 

Percobaan pertama ditolak karena profil akun belum lengkap:

```json
{
  "error": "invalid_grant",
  "error_description": "Account is not fully set up"
}
```

Setelah profil dilengkapi, token `usera` memuat klaim penting berikut. Informasi yang tidak diperlukan untuk bukti, seperti ID akun dan email, tidak dicantumkan.

```json
{
  "iss": "http://localhost:8081/realms/capstone",
  "typ": "Bearer",
  "azp": "capstone-app",
  "realm_access": { "roles": ["user"] },
  "groups": ["/tenant-a"],
  "preferred_username": "usera"
}
```

### Verifikasi tambahan: `userb` dan `operator`

Token diperiksa pada Keycloak lokal 26.8.1 melalui `localhost:8082`, setelah mapper grup diaktifkan melalui Admin Console.

| Akun | Role di token | Grup tenant di token |
|---|---|---|
| `userb` | `user` | `/tenant-b` |
| `operator` | `operator` | Tidak ada |

Hasil ini sesuai harapan: `userb` dikenali sebagai user tenant B, sedangkan `operator` dikenali berdasarkan role-nya dan tidak terikat pada tenant tertentu.

## Interpretasi

- Token `usera` memuat grup `/tenant-a` dan role `user`.
- Token `userb` memuat grup `/tenant-b` dan role `user`.
- Token `operator` memuat role `operator` dan tidak memiliki grup tenant.
- `iss` token `usera` adalah `http://localhost:8081/realms/capstone`, sesuai dengan `OIDC_TOKEN_ISSUER` pada ADR-012.
- `azp` bernilai `capstone-app`; BE-2 dapat memeriksa bahwa token ditujukan untuk aplikasi tersebut.
- Pengujian tambahan melalui port `8082` memeriksa isi token. Pengujian itu bukan pengujian integrasi BE-2.
- Penolakan awal terjadi karena profil akun belum lengkap. Password grant tidak dapat menampilkan form *Verify Profile*, sehingga Keycloak menolak login.

## Limitasi dan tindak lanjut

- Token `usera` dibuktikan dalam pengujian. Token `userb` dan `operator` sudah diperiksa pada verifikasi lokal di atas. Token `appadmin` belum diperiksa.
- Mapper sudah dikonfigurasi pada database Keycloak yang sedang berjalan, tetapi belum disimpan ke file realm. Jika realm diimpor ulang atau data lab di-reset, konfigurasi ini dapat hilang.
- Tindak lanjut: simpan konfigurasi mapper ke repo infrastruktur dalam file realm yang tidak memuat password, secret, token, atau data pribadi.
- Screenshot bukti awal: `BE-1_usera-token-decoded.png`, BE-1_userb-token-decoded.png, dan BE-1_operator-token-decoded.png (token operator berisi role operator tanpa grup tenant).
- Akun yang digunakan adalah akun demo lab. Password tidak dicantumkan.
