# BE-2 · Auth + TenantContext di cluster

| Field | Isi |
|---|---|
| Scope | `GET /api/units` dan `/q/health/ready` di cluster k3d dev |
| Owner | Radya (dibantu Claude Code) |
| Source / versi | `capstone-app` `0ccd99d` (GitHub PR #5), image `registry:5000/student/capstone-app:0ccd99d22fab`, GitOps `867a927` |
| Timestamp | 2026-11-23 21:44:52 WIB |
| Method | `curl` ke `http://capstone.localhost:8088` dengan access token Keycloak asli (password grant, client `capstone-app`). Token dan password tidak disimpan |
| Decision supported | ADR-012 (issuer OIDC), ADR-003 (tenant dari klaim grup) |

## Observasi

| Pemanggil | Token diambil dari | Endpoint | HTTP | Isi |
|---|---|---|---|---|
| tanpa token | - | `/api/units` | 401 | `UNAUTHORIZED` |
| `usera` | `localhost:8081` | `/api/units` | 200 | `tenant-a` saja |
| `userb` | `localhost:8081` | `/api/units` | 200 | `tenant-b` saja |
| `operator` | `localhost:8081` | `/api/units` | 200 | `tenant-a`, `tenant-b` |
| `appadmin` | `localhost:8081` | `/api/units` | 200 | `tenant-a`, `tenant-b` |
| `usera` | `127.0.0.1:8081` | `/api/units` | 401 | `UNAUTHORIZED` |
| tanpa token | - | `/q/health/ready` | 200 | database UP |

Log pod:

```
OIDC: JWKS http://keycloak:8080/realms/capstone/protocol/openid-connect/certs, issuer diterima http://localhost:8081/realms/capstone, client capstone-app
auth: token ditolak (ERR_JWT_CLAIM_VALIDATION_FAILED: unexpected "iss" claim value)
```

CI Gitea: run 6 (pull request, `23c8355`) sukses 39 detik; run 7 (push `main`, `0ccd99d`) gagal karena terputus saat Docker Desktop bermasalah (log berhenti di unduhan DB Trivy), lalu diulang dan sukses 54 detik. Argo CD Synced/Healthy di `867a927` setelah hard refresh manual.

## Interpretasi

- Pod mengambil kunci lewat `keycloak:8080` dan menerima `iss` `localhost:8081`: pemisahan ADR-012 bekerja di cluster.
- Token dari `127.0.0.1` ditolak karena `iss`, sesuai risiko yang ditulis di ADR-012.

## Limitasi

- Token kedaluwarsa, kunci palsu, dan user tanpa grup (403) hanya diuji otomatis (`test/auth.test.ts`), tidak di cluster.
- Isolasi baru terbukti untuk `/api/units`; tiket menunggu BE-4 dan BE-7.
- Lab memakai HTTP tanpa TLS. Review anggota lain untuk PR #5 belum diverifikasi.
