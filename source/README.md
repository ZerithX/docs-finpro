# Source

Kode **tidak** disimpan di repo portofolio ini. Kode ada di dua repo terpisah karena CI menulis tag image ke repo GitOps dan Argo CD membacanya. Kalau digabung, setiap commit `deploy:` dari CI akan memicu CI lagi.

| Repo GitHub | Folder lokal | Isi |
|---|---|---|
| [ZerithX/helpdesk-campus](https://github.com/ZerithX/helpdesk-campus) | `capstone-app/` | Source TypeScript (Hono + Drizzle), tes Vitest, migrasi `drizzle/`, Dockerfile, `.gitea/workflows/ci.yml` (sebelum 10 Nov: Java/Quarkus, lihat ADR-014) |
| [ZerithX/helpdesk-gitops](https://github.com/ZerithX/helpdesk-gitops) | `capstone-gitops/` | Manifest Kustomize (`base/`, `overlays/`) + Argo CD Application |

Di lab, CI berjalan di Gitea lokal (`http://127.0.0.1:3001/student/capstone-app`), dan Argo CD membaca `http://gitea:3000/student/capstone-gitops`. GitHub dipakai untuk kolaborasi dan PR; `main` dicerminkan ke Gitea secara manual.

## Versi yang sedang dinilai

| Repo | Commit / tag | Tanggal | Keterangan |
|---|---|---|---|
| helpdesk-campus | `6aa3092` | 2026-11-01 | Walking skeleton (merge PR #1) |
| helpdesk-gitops | `c8162ce` | 2026-11-01 | `deploy: capstone-app 6aa3092464c0` |

Perbarui tabel ini setiap rilis (`v0.1.0`, `v0.2.0`).

## Saat submission (Guideline §15)

Snapshot dari tag rilis dimasukkan dengan `git archive`, supaya kode yang diserahkan sama persis dengan yang di-deploy:
- `helpdesk-campus` → `source/`
- `helpdesk-gitops` → `deployment/`
- `ci.yml` + skrip lab → `automation/`
