# 05 — CI/CD & GitOps

**Milestone:** M4 Delivery Automation · **Owner:** B (perbaikan CI A1: Radya)

Isi yang diharapkan:
- Run CI: verify → build image (tag SHA) → Trivy → push → commit `deploy:` di repo GitOps.
- A1: run untuk PR berhenti setelah verify; run `main` sampai update GitOps.
- Promosi dev → staging → prod lewat PR GitOps (prod sync manual), latihan rollback dengan `git revert`.
- Tabel traceability: commit app → run CI → image → commit GitOps → revisi Argo CD → image di pod.
- Waktu merge → Running di dev (QS6).

File saat ini (walking skeleton, 1 Nov). **Belum memenuhi evidence standard**:
- `Ci_ijo.png`: run CI Gitea #2 hijau.
- `commit_in_1st_week.png`: commit minggu pertama.
