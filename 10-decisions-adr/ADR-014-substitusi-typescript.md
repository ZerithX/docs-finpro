# ADR-014: Substitusi stack aplikasi dari Java/Quarkus ke TypeScript (Hono + Drizzle)

| Field | Isi |
|---|---|
| Status | Diusulkan (perlu disebut di proposal M0 dan dikonfirmasi dosen) |
| Tanggal | 2026-11-10 |
| Owner | Radya |
| Milestone | M1 (keputusan), M2 (dampak) |

## Konteks
- Stack awal adalah Java 21 + Quarkus, karena template CI dosen mengasumsikan proyek Maven. Pada 10 Nov peran ditukar: Radya memegang Application & Data. Radya jauh lebih paham TypeScript daripada Java, sedangkan B tidak menulis backend.
- Quality gate Guideline: kode buatan AI tetap harus bisa dijelaskan dan dipertahankan tim. Kode yang tidak dipahami pemiliknya adalah risiko langsung saat defense.
- Guideline §8 mengizinkan substitusi teknologi asalkan ada rationale singkat tentang kecocokan dengan capability wajib dan dampaknya pada perbandingan evidence.
- Pada saat keputusan, aplikasi masih walking skeleton (1 entity, 1 endpoint, 1 migrasi, 1 tes), sehingga biaya pindah paling kecil. Proposal M0 belum dikirim ke dosen.

## Keputusan
Aplikasi ditulis ulang dengan **Node.js 24 + TypeScript, Hono (HTTP + OpenAPI), Drizzle ORM (migrasi SQL), Vitest, dan prom-client**. Kontrak ke platform dipertahankan: port 8080, `/q/health/live`, `/q/health/ready`, `/q/metrics`, `/q/openapi`, `/q/swagger-ui`, serta env `DB_URL` (format JDBC diterima), `DB_USER`, `DB_PASSWORD`. Karena itu repo GitOps dan konfigurasi Prometheus tidak berubah.

## Kecocokan dengan capability wajib
| Capability | Java/Quarkus (sebelumnya) | TypeScript (sekarang) |
|---|---|---|
| REST API + Swagger UI | RESTEasy + SmallRye OpenAPI | Hono + `@hono/zod-openapi` + `@hono/swagger-ui` |
| Persistensi + migrasi berversi | Hibernate Panache + Flyway | Drizzle ORM + file migrasi `drizzle/` (dijalankan saat startup dengan advisory lock) |
| Health untuk probe | SmallRye Health | `/q/health/*` (ready mengecek DB) |
| Metrik Prometheus | Micrometer | prom-client |
| Auth OIDC (Keycloak) | `quarkus-oidc` | `jose` (verifikasi JWT via JWKS) — R2 |
| Tes otomatis di CI | JUnit + RestAssured | Vitest + `app.request()` |
| Container image | `eclipse-temurin:21-jre` | `node:24-alpine` multi-stage, user non-root |

CI tetap memakai urutan dosen: verify → build image → Trivy → push → update GitOps. Hanya step verify yang diganti (`npm ci`, `typecheck`, `test`), sesuai petunjuk README template dosen. Runner CI sudah menyediakan Node 24 + npm, sehingga paket dosen tidak diubah.

## Alternatif yang dipertimbangkan
- **Tetap Java/Quarkus:** tanpa biaya migrasi dan sesuai jalur referensi kursus, tapi pemilik kode kesulitan menjelaskan dan mengembangkannya dalam waktu sekitar 6 hari menuju freeze.
- **NestJS + Prisma:** struktur modul/DI mirip Quarkus, tapi lebih berat dan kurang familiar bagi pemilik kode dibanding Hono + Drizzle.
- **Bun sebagai runtime:** ditolak, karena runner CI hanya punya Node/npm. Memakai Bun berarti mengubah Dockerfile runner milik dosen, atau memasang Bun lewat internet di setiap run CI.

## Konsekuensi
- **Positif:** kode bisa dijelaskan pemiliknya; tes lebih cepat (sekitar 2,5 detik lokal untuk 7 tes); kontrak platform tidak berubah, sehingga bukti M3/M4 yang sudah ada tetap relevan.
- **Negatif / risiko sisa:** menyimpang dari jalur referensi kursus (Quarkus), sehingga evidence kurang bisa dibandingkan langsung dengan tim lain; perlu konfirmasi dosen; satu hari kerja dipakai untuk migrasi menjelang freeze 17 Nov.
- **Perlu dipantau/dibuktikan:**
  - ukuran image (294 MB lokal) dan hasil Trivy image Node, untuk M6 dan M8;
  - migrasi saat startup dengan replica > 1 (advisory lock) di B3;
  - tabel `flyway_schema_history` yang tersisa di DB `capstone` lama (tidak dipakai lagi; DB itu diganti `campusdesk_dev` di B2).
