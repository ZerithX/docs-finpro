# BE-1 · Mapper grup Keycloak: token membawa klaim `groups`

| Field | Isi |
|---|---|
| Scope | Realm `capstone`, client `capstone-app` |
| Owner bukti awal | Radya |
| Sumber bukti awal | Keycloak 26.8.1, token `usera` diambil melalui `localhost:8081` |
| Verifikasi tambahan | Keycloak lokal 26.8.1 dari paket infrastruktur dosen, token `userb` dan `operator` diambil melalui `localhost:8082` |
| Keputusan yang didukung | Backend dapat membaca tenant dari klaim `groups` dan role dari `realm_access.roles` (ADR-003, ADR-012) |

## Kondisi awal

- Client `capstone-app` belum memiliki protocol mapper untuk grup.
- Grup dan keanggotaan sudah tersedia:
  - `usera` → `/tenant-a`
  - `userb` → `/tenant-b`
  - `operator` dan `appadmin` tidak memiliki grup tenant.
- Profil akun hasil import belum lengkap, sehingga pengambilan token dengan password grant awalnya ditolak.

## Perubahan

Mapper **Group Membership** ditambahkan untuk mengirim grup ke token. Pengaturannya mencakup:

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

Profil akun lab juga dilengkapi agar Keycloak dapat menerbitkan token melalui password grant.

## Observasi

### Token `usera` — bukti awal Radya

Token access `usera` memuat klaim penting berikut:

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

Token diperiksa secara lokal pada Keycloak 26.8.1 melalui `localhost:8082`.

| Akun | Role di token | Grup tenant di token |
|---|---|---|
| `userb` | `user` | `/tenant-b` |
| `operator` | `operator` | Tidak ada |

## Interpretasi

- Token `usera` membawa `/tenant-a`, dan token `userb` membawa `/tenant-b`. Ini menunjukkan grup yang sesuai masuk ke token masing-masing.
- Token `operator` membawa role `operator` dan tidak menunjukkan grup tenant.
- Aplikasi menggunakan klaim ini untuk mengenali tenant dan role. Hasil decode token membuktikan isi token; pengujian hak akses API dilakukan melalui tes authz terpisah.
- Bukti tambahan `userb` dan `operator` diambil melalui port `8082`; bukti awal `usera` menggunakan port `8081`.

## Limitasi dan tindak lanjut

- Token `usera`, `userb`, dan `operator` sudah diperiksa. Token `appadmin` belum diperiksa.
- Mapper saat ini sudah dikonfigurasi pada database Keycloak lokal, tetapi belum disimpan dalam file realm yang aman. Jika realm diimpor ulang atau data lab di-reset, konfigurasi ini dapat hilang.
- Tindak lanjut: simpan konfigurasi mapper ke repo infrastruktur dalam file realm yang tidak memuat password, secret, token, atau data akun pribadi.
- Jangan commit file realm paket dosen apa adanya karena berisi kredensial demo.
