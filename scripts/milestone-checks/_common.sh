#!/usr/bin/env bash
# Helper bersama untuk skrip pengecekan milestone CampusDesk.
# Dipakai lewat `source`. Jalankan dari Git Bash (Windows) di laptop yang menjalankan lab.
#
# Prinsip:
# - Setiap pengecekan memeriksa kondisi NYATA (lab yang sedang jalan atau file evidence di repo),
#   bukan sekadar mencetak teks. Hasil: PASS, FAIL, atau SKIP (prasyarat tidak tersedia).
# - FAIL bukan berarti skrip rusak: sering artinya tugas di docs/prd/ memang belum dikerjakan.
#   Pesan FAIL menyebut ID tugasnya.
# - Tidak ada yang ditulis ke cluster/DB kecuali dengan --write (membuat tiket uji)
#   atau --chaos (menghapus pod dan mengubah replica sementara).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$ROOT/capstone-app"
GITOPS_DIR="$ROOT/capstone-gitops"

# Alamat lab (bisa diganti lewat environment variable).
APP_URL="${APP_URL:-http://capstone.localhost:8088}"
KC_URL="${KC_URL:-http://localhost:8081/realms/capstone}"
CLIENT_ID="${CLIENT_ID:-capstone-app}"
NS="${NS:-capstone}"
DEPLOY="${DEPLOY:-capstone-app}"
ARGO_APP="${ARGO_APP:-capstone-app}"
KUBE_CONTEXT="${KUBE_CONTEXT:-k3d-capstone}"
PG_CONTAINER="${PG_CONTAINER:-capstone-postgres}"
PG_USER="${PG_USER:-capstone}"
PG_DB="${PG_DB:-capstone}"
PROM_URL="${PROM_URL:-http://127.0.0.1:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://127.0.0.1:3000}"
GRAFANA_AUTH="${GRAFANA_AUTH:-admin:admin}"
GITEA_URL="${GITEA_URL:-http://127.0.0.1:3001}"
GITEA_USER="${GITEA_USER:-student}"
DASHBOARD_UID="${DASHBOARD_UID:-campusdesk-service-health}"

WRITE="${WRITE:-0}"   # 1 = boleh membuat tiket uji (transaksi inti, 409)
CHAOS="${CHAOS:-0}"   # 1 = boleh hapus pod dan uji self-heal

PASS=0; FAIL=0; SKIP=0

section() { printf '\n== %s ==\n' "$1"; }
ok()   { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$1"; [ -n "${2:-}" ] && printf '         -> %s\n' "$2"; return 0; }
skip() { SKIP=$((SKIP+1)); printf '  [SKIP] %s\n' "$1"; [ -n "${2:-}" ] && printf '         -> %s\n' "$2"; return 0; }
info() { printf '         %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Password akun uji lab: default sama dengan username (akun bawaan paket dosen,
# Infrastructure Guide §16). Kalau berbeda: export PW_usera=... dst.
pw_for() { local v="PW_$1"; printf '%s' "${!v:-$1}"; }

# --- file / evidence ---------------------------------------------------------
file_ok() {   # path-relatif-ROOT  [pesan-jika-gagal]
  if [ -s "$ROOT/$1" ]; then ok "ada: $1"; else bad "belum ada / kosong: $1" "${2:-}"; fi
}
file_has() {  # path  regex  deskripsi  [pesan-jika-gagal]
  if [ -s "$ROOT/$1" ] && grep -Eqi "$2" "$ROOT/$1"; then ok "$3"; else bad "$3" "${4:-}"; fi
}

# Bukti per tugas: file di folder evidence yang namanya memuat ID tugas,
# misalnya 08-reliability-recovery/REL-4_restore.md atau 06-security/BE-5_BE-7_alur-authz.md.
# README template TIDAK dihitung sebagai bukti.
evidence() {  # folder  ID  deskripsi  pemilik
  local f; f=$(ls "$ROOT/$1"/*"$2"[_.-]* 2>/dev/null | grep -v '/README\.md$' | head -1)
  if [ -n "$f" ]; then ok "$2 $3: ${f#$ROOT/}"; else bad "$2 $3: belum ada file $1/$2_*" "${4:-}"; fi
}

# --- HTTP ---------------------------------------------------------------------
# Hasil: variabel global HTTP_CODE dan HTTP_BODY.
http() {      # METHOD URL [TOKEN] [JSON-BODY]
  local m=$1 url=$2 tok=${3:-} data=${4:-} out
  local args=(-s --max-time 15 -X "$m" -w '\n%{http_code}')
  [ -n "$tok" ] && args+=(-H "Authorization: Bearer $tok")
  [ -n "$data" ] && args+=(-H 'Content-Type: application/json' --data "$data")
  out=$(curl "${args[@]}" "$url" 2>/dev/null) || out=$'\n000'
  HTTP_CODE=${out##*$'\n'}
  HTTP_BODY=${out%$'\n'*}
}
expect() {    # deskripsi  kode-harapan
  if [ "$HTTP_CODE" = "$2" ]; then ok "$1 -> $HTTP_CODE"; else bad "$1 -> $HTTP_CODE (harapan $2)" "$(printf '%s' "$HTTP_BODY" | head -c 200)"; fi
}

# Nilai pertama dari field JSON sederhana (string/angka). Cukup untuk respons API ini; tanpa jq.
json_first() { grep -o "\"$2\":\"\{0,1\}[^\",}]*" <<<"$1" | head -1 | sed -E "s/^\"$2\":\"?//"; }
json_count() { grep -o "\"$2\":" <<<"$1" | wc -l | tr -d ' '; }

# --- Keycloak -----------------------------------------------------------------
get_token() { # username -> access token (kosong jika gagal)
  curl -s --max-time 15 -d "client_id=$CLIENT_ID" -d grant_type=password \
    -d "username=$1" --data-urlencode "password=$(pw_for "$1")" \
    "$KC_URL/protocol/openid-connect/token" 2>/dev/null \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'
}
jwt_payload() { # token -> JSON payload (signature tidak pernah dicetak)
  local p; p=$(printf '%s' "$1" | cut -d. -f2 | tr '_-' '/+')
  while [ $(( ${#p} % 4 )) -ne 0 ]; do p="$p="; done
  printf '%s' "$p" | base64 -d 2>/dev/null
}
TOKENS_LOADED=0
load_tokens() {
  [ "$TOKENS_LOADED" = 1 ] && return 0
  TOK_USERA=$(get_token usera); TOK_USERB=$(get_token userb)
  TOK_OPERATOR=$(get_token operator); TOK_ADMIN=$(get_token appadmin)
  TOKENS_LOADED=1
}

# --- kubectl / psql -----------------------------------------------------------
KUBE_OK=""
kube_ready() {
  if [ -z "$KUBE_OK" ]; then
    if have kubectl && [ "$(kubectl config current-context 2>/dev/null)" = "$KUBE_CONTEXT" ] \
       && kubectl get ns "$NS" >/dev/null 2>&1; then KUBE_OK=1; else KUBE_OK=0; fi
  fi
  [ "$KUBE_OK" = 1 ]
}
k() { kubectl -n "$NS" "$@" 2>/dev/null; }
psql_q() { docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_DB" -tAc "$1" 2>/dev/null | tr -d '\r'; }
pg_ready() { have docker && docker exec "$PG_CONTAINER" pg_isready -U "$PG_USER" >/dev/null 2>&1; }

# Ambil id tiket pertama yang terlihat oleh token tertentu (kosong jika tidak ada).
first_ticket_id() { http GET "$APP_URL/api/tickets" "$1"; json_first "$HTTP_BODY" id; }

finish() {
  printf '\nRingkasan: %s PASS, %s FAIL, %s SKIP\n' "$PASS" "$FAIL" "$SKIP"
  [ "$FAIL" -eq 0 ]
}

# Dipanggil di akhir setiap file test-*.sh: jalankan fungsinya kalau file dieksekusi langsung.
run_if_main() { # nama-fungsi  file-pemanggil
  if [ "${2}" = "${0}" ]; then
    for a in "${@:3}"; do case $a in --write) WRITE=1;; --chaos) CHAOS=1;; esac; done
    "$1"; finish
  fi
}
