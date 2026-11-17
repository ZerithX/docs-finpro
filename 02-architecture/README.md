# 02 — Architecture

**Milestone:** M1 Architecture · **Owner:** C (trust boundary, quality scenario), Radya (diagram aplikasi & lab) · review: B

**Pertanyaan milestone:** *Can the team explain boundaries and trade-offs?*

| File | Isi |
|---|---|
| [`architecture.md`](architecture.md) | View provider-neutral, implementasi lab (runtime + delivery), alur data, target CloudStack (desain), asumsi |
| [`boundaries.md`](boundaries.md) | Trust boundary B1–B7 dan failure boundary F1–F7 |
| [`quality-scenarios.md`](quality-scenarios.md) | QS1–QS7 dalam format quality attribute scenario + SLO turunan |
| `diagrams/*.mmd` | Sumber diagram (Mermaid). Edit file ini, bukan PNG-nya |
| `diagrams/*.png` | Hasil render |
| `02_evidence.jpg` | Ringkasan satu gambar untuk portofolio evidence |

ADR ada di `10-decisions-adr/`, bukan di sini.

## Cara render ulang diagram

```bash
npm i -g @mermaid-js/mermaid-cli
cd 02-architecture/diagrams
for f in *.mmd; do mmdc -i "$f" -o "${f%.mmd}.png" -s 2 -b white -w 1600; done
```

Alternatif tanpa instalasi: tempel isi `.mmd` ke https://mermaid.live lalu export PNG.

Status: **v0.1 draf (17 Nov 2026)**. Bagian bertanda [CEK] perlu dibuktikan atau dikoreksi tim.
