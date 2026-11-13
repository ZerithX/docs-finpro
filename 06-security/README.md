# 06 — Security

**Milestone:** M6 Security (C1 dikerjakan di M2) · **Owner:** C

Isi yang diharapkan:
- C1: mapper grup Keycloak, export realm tanpa secret, token `usera`/`userb`/`operator` yang sudah di-decode.
- Hasil Trivy + prioritas temuan (bukan sekadar laporan mentah).
- Uji authz positif dan negatif.
- Review repo dari secret; Secret hanya dibuat lewat `kubectl`.
- User DB non-superuser per environment (temuan T6).
- Catatan ancaman/kontrol untuk trust boundary B1–B7, termasuk risiko sisa.
