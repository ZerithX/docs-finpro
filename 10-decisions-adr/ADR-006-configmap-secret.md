# ADR-006: Penanganan ConfigMap dan Secret

| Field | Isi |
|---|---|
| Status | Draf (menunggu owner) |
| Tanggal | 2026-11-13 |
| Owner | B |
| Milestone | M1 / M3 |

> **Catatan untuk owner:** bagian *Konteks* sudah diisi dari dokumen tim (PRD, PROGRESS, Rencana Kerja, proposal) supaya kamu tidak mulai dari nol. Bagian *Keputusan*, *Alternatif*, dan *Konsekuensi* **ditulis sendiri oleh owner**, karena di defense setiap anggota harus bisa menjelaskan ADR ini dalam ±1 menit. Pakai pertanyaan pemandu, lalu hapus blok ini dan bagian *Pertanyaan pemandu* sebelum PR. Kirim lewat branch `docs/adr-NNN-...` dan minta review dari anggota lain.

## Konteks
- Konfigurasi non-rahasia ada di `capstone-gitops/base/configmap.yaml` (`DB_URL`, `DB_USER`, `OIDC_ISSUER`).
- Password DB **tidak** di Git: Secret `capstone-app-secret` dibuat langsung dengan `kubectl create secret` (Infra Guide §13); repo hanya berisi `base/secret.example.yaml`.
- Secret CI ada di Gitea Actions: `GITOPS_PASSWORD` (CI menulis ke repo GitOps) dan `TEST_DB_PW` (DB tes `campusdesk_test`).
- Rencana B2: tiga namespace (`campusdesk-dev/-staging/-prod`) dengan DB dan Secret per namespace, sehingga Secret harus dibuat tiga kali dan tidak ikut sync Argo CD.
- PRD §5 butir 5: tidak ada password/token asli di Git; hanya `*.example.yaml`.

## Pertanyaan pemandu
1. Apa yang masuk ConfigMap dan apa yang masuk Secret? Apa kriterianya?
2. Kenapa Secret dibuat manual dengan `kubectl`, bukan di-commit (walau base64)?
3. Alternatif yang ada: Sealed Secrets, SOPS, External Secrets/Vault. Kenapa tidak dipakai sekarang?
4. Apa risikonya kalau cluster dibuat ulang (mis. untuk T11)? Bagaimana Secret dipulihkan?
5. Bagaimana membuktikan tidak ada secret di riwayat Git (hubungkan ke M6-4)?

## Keputusan
_Ditulis owner: apa yang dipilih, dalam satu atau dua kalimat tegas._

## Alternatif yang dipertimbangkan
- **Alternatif A:** _kelebihan, kekurangan, alasan tidak dipilih_
- **Alternatif B:** _..._

## Konsekuensi
- Positif: _..._
- Negatif / risiko sisa: _..._
- Yang perlu dipantau atau dibuktikan: _..._
