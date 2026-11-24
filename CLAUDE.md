# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Khusus Claude Code
- Mulai sesi perencanaan dengan membaca `docs/PROGRESS.md` (status) dan handoff yang relevan di `docs/`; gunakan plan mode sebelum perubahan besar.
- Dokumen (ADR, proposal, laporan) ditulis sebagai markdown di folder evidence Guideline (`01-business/` ... `11-demo-defense/`).
- Tanyakan dulu jika keputusan tidak bisa dibatalkan atau bisa dibaca dua cara.

## Product requirements
- Scope, tugas, dan jadwal terbaru ada di `docs/prd/` (baca `00-INDEX.md`, lalu PRD area yang relevan). Kerjakan **satu ID tugas per sesi** (misalnya BE-2) dan penuhi kriteria "Selesai jika" di PRD-nya.
- Desain lengkap (peran, alur status, kontrak API) ada di `docs/PRD_CampusDesk.md`. Kalau scope di sana berbeda dengan `docs/prd/`, `docs/prd/` yang berlaku.
- Kode aplikasi ada di `capstone-app/` dan manifest di `capstone-gitops/`. Keduanya repo Git terpisah dari root ini: jalankan perintah git di dalam folder masing-masing.
- Jangan push, merge, atau membuat PR tanpa diminta. Setelah tugas selesai, tambahkan entri di `docs/PROGRESS.md` dengan ID tugasnya.
The lab package (scripts, infrastructure) is in `../Final_Project`.