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
| helpdesk-campus | `754ea29` | 2026-11-24 | Merge PR #10 (BE-6, BE-8, BE-9); fitur dibekukan 26 Nov |
| helpdesk-gitops (Gitea, dibaca Argo CD) | `119082b` | 2026-11-24 | `deploy: capstone-app 754ea29d6a46` (CI run 13, lihat `docs/PROGRESS.md` 24 Nov) |
| helpdesk-gitops (GitHub) | `d226e99` | 2026-11-24 | Revert overlay staging/prod (PR #4). **Perlu verifikasi:** tag dev di GitHub masih `74e4beb9c509`; GitHub dan Gitea belum disatukan |

Riwayat: walking skeleton `6aa3092` → GitOps `c8162ce` (1 Nov).

Perbarui tabel ini setiap rilis. Belum ada tag rilis (PD-7); tag yang dinilai dipilih saat FD-6.

## Saat submission (Guideline §15)

Snapshot dari tag rilis dimasukkan dengan `git archive`, supaya kode yang diserahkan sama persis dengan yang di-deploy:
- `helpdesk-campus` → `source/`
- `helpdesk-gitops` → `deployment/`
- `ci.yml` + skrip lab → `automation/`
