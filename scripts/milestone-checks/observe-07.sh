#!/usr/bin/env bash
# M5 Operations & SLO: bukti ujung-ke-ujung curl -> aplikasi -> Prometheus -> Grafana.
# test-07 memeriksa kondisi; skrip ini MEMBUAT trafik lalu mengukur apakah trafik itu terdeteksi.
# Semua request GET (tidak menulis data). Tidak membuat 5xx: uji gangguan ada di REL-3.
#
#   bash scripts/milestone-checks/observe-07.sh                # 30 putaran (sekitar 1-2 menit)
#   bash scripts/milestone-checks/observe-07.sh --rounds 60 --no-log
#   GRAFANA_AUTH='admin:passwordmu' bash scripts/milestone-checks/observe-07.sh
#
# Hasil: 07-observability-slo/observations/observe-<waktu>.txt. Nama file sengaja TIDAK diawali
# OPS-1/OPS-2 supaya run-all.sh tidak menganggap dokumen SLO/runbook sudah dikerjakan.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
ROUNDS=30; LOG=1; DETECT_MAX=60   # QS7: terlihat <= 1 menit
while [ $# -gt 0 ]; do
  case $1 in
    --rounds) ROUNDS=${2:-}; shift; [[ "$ROUNDS" =~ ^[1-9][0-9]*$ ]] || { echo "--rounds butuh angka > 0"; exit 2; };;
    --no-log) LOG=0;;
    -h|--help) sed -n '2,11p' "$0"; exit 0;;
    *) echo "argumen tidak dikenal: $1"; exit 2;;
  esac; shift
done
if [ "$LOG" = 1 ]; then
  mkdir -p "$ROOT/07-observability-slo/observations"
  OUT="$ROOT/07-observability-slo/observations/observe-$(date '+%Y%m%d-%H%M%S').txt"
  exec > >(tee "$OUT") 2>&1
fi

SEL='job="capstone-app",route!~"/q/.*"'   # sama dengan panel dasbor
prom() { curl -s --max-time 10 -G "$PROM_URL/api/v1/query" --data-urlencode "query=$1" 2>/dev/null; }
# Nilai sampel pertama dari respons query (kosong jika tidak ada data).
val() { sed -n 's/.*"value":\[[^,]*,"\([^"]*\)".*/\1/p' | head -1; }
# Total counter API di aplikasi untuk satu status, dibaca langsung dari /q/metrics.
app_count() {
  awk -v s="status=\"$1\"" '/^http_server_requests_seconds_count\{/ && !/route="\/q\// && index($0,s) {n+=$NF} END{print n+0}' <<<"$METRICS"
}
read_metrics() { http GET "$APP_URL/q/metrics"; METRICS=$HTTP_BODY; [ "$HTTP_CODE" = 200 ]; }
stop() { finish; [ "$LOG" = 1 ] && echo "Hasil tersimpan: ${OUT#"$ROOT"/}"; exit 1; }

echo "CampusDesk - observasi M5 (curl -> Prometheus -> Grafana)"
echo "Waktu mulai : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Image       : $(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].image}')"
echo "Method      : $ROUNDS putaran GET (200, 401, 404) lewat ingress; counter aplikasi dibandingkan dengan Prometheus"

section "A. Komponen terjangkau"
if read_metrics && grep -q '^http_server_requests_seconds_count' <<<"$METRICS"; then ok "aplikasi: /q/metrics 200"; else bad "aplikasi: /q/metrics -> $HTTP_CODE"; stop; fi
http GET "$PROM_URL/-/ready"; expect "Prometheus ready" 200
[ "$HTTP_CODE" = 200 ] || stop
if [ "$(prom 'max(up{job="capstone-app"})' | val)" = 1 ]; then ok "Prometheus: target capstone-app UP"; else bad "Prometheus: target capstone-app tidak UP"; stop; fi
http GET "$GRAFANA_URL/api/health"
if [ "$HTTP_CODE" = 200 ] && grep -Eq '"database": *"ok"' <<<"$HTTP_BODY"; then ok "Grafana: hidup, database ok"; else bad "Grafana: /api/health -> $HTTP_CODE" "jalankan up-observability"; fi

section "B. Kirim trafik dengan curl"
TOK=$(get_token usera)
if [ -n "$TOK" ]; then ok "token usera didapat"; else bad "token usera gagal didapat dari $KC_URL"; stop; fi
START0=$(prom 'max(process_start_time_seconds{job="capstone-app"})' | val)
read_metrics
declare -A BEFORE SENT TARGET
for s in 200 401 404; do BEFORE[$s]=$(app_count $s); SENT[$s]=0; done
OTHER=0
hit() {
  http GET "$APP_URL$1" "${2:-}"
  case $HTTP_CODE in 200|401|404) SENT[$HTTP_CODE]=$(( SENT[$HTTP_CODE] + 1 ));; *) OTHER=$((OTHER+1));; esac
}
t0=$(date +%s)
for ((i=1; i<=ROUNDS; i++)); do
  hit /api/units "$TOK"; hit /api/tickets "$TOK"; hit /api/sla-policies "$TOK"
  hit /api/units                                    # tanpa token -> 401
  [ $((i % 5)) -eq 0 ] && hit /api/tickets/999999999 "$TOK"   # tidak ada -> 404
  sleep 0.5
done
t1=$(date +%s)
info "$ROUNDS putaran selesai dalam $((t1-t0)) detik: 200=${SENT[200]} 401=${SENT[401]} 404=${SENT[404]} lain=$OTHER"
if [ "$OTHER" = 0 ]; then ok "semua respons 200/401/404"; else bad "$OTHER respons di luar 200/401/404 (termasuk 000 = tidak terjangkau)"; fi

section "C. Terdeteksi di Prometheus"
read_metrics
for s in 200 401 404; do
  TARGET[$s]=$(app_count $s); d=$(( TARGET[$s] - BEFORE[$s] ))
  if [ "${SENT[$s]}" -eq 0 ]; then bad "tidak ada respons $s yang diuji" "naikkan --rounds (404 dikirim tiap 5 putaran)"
  elif [ "$d" -eq "${SENT[$s]}" ]; then ok "aplikasi menghitung status $s: +$d = jumlah curl"
  elif [ "$d" -gt "${SENT[$s]}" ]; then ok "aplikasi menghitung status $s: +$d >= curl ${SENT[$s]} (ada trafik lain)"
  else bad "aplikasi menghitung status $s: +$d, curl ${SENT[$s]}" "pod restart atau replica > 1?"; fi
done
while :; do
  hilang=""; el=$(( $(date +%s) - t1 ))
  for s in 200 401 404; do
    v=$(prom "sum(http_server_requests_seconds_count{$SEL,status=\"$s\"})" | val); v=${v:-0}
    [ "${v%.*}" -ge "${TARGET[$s]}" ] 2>/dev/null || hilang="$hilang $s"
  done
  [ -z "$hilang" ] && break
  [ "$el" -ge "$DETECT_MAX" ] && break
  sleep 1
done
if [ -z "$hilang" ]; then ok "Prometheus memuat semua request; terdeteksi ${el} detik setelah request terakhir (batas $DETECT_MAX)"
else bad "Prometheus belum memuat status:$hilang setelah ${el} detik"; fi
START1=$(prom 'max(process_start_time_seconds{job="capstone-app"})' | val)
if [ -n "$START0" ] && [ "$START0" = "$START1" ]; then ok "proses tidak restart selama uji"; else bad "proses restart selama uji; selisih counter tidak sah"; fi

section "D. Terdeteksi lewat Grafana"
g() { curl -s --max-time 10 -u "$GRAFANA_AUTH" -w '\n%{http_code}' "$@" 2>/dev/null; }
r=$(g "$GRAFANA_URL/api/dashboards/uid/$DASHBOARD_UID"); c=${r##*$'\n'}
if [ "$c" = 401 ]; then
  skip "dasbor dan datasource Grafana" "login ditolak (401): set GRAFANA_AUTH=admin:<password> atau reset password"
else
  if [ "$c" = 200 ]; then ok "dasbor $DASHBOARD_UID terpasang"; else bad "dasbor -> $c"; fi
  r=$(g -G "$GRAFANA_URL/api/datasources/proxy/uid/prometheus/api/v1/query" --data-urlencode "query=sum(http_server_requests_seconds_count{$SEL})")
  c=${r##*$'\n'}; gv=$(val <<<"$r"); total=$(( TARGET[200] + TARGET[401] + TARGET[404] ))
  if [ "$c" = 200 ] && [ "${gv%.*}" -ge "$total" ] 2>/dev/null; then ok "Grafana membaca data yang sama lewat datasource Prometheus: $gv request"
  else bad "query lewat datasource Grafana -> $c, nilai '${gv}' (harapan >= $total)"; fi
fi

section "E. Observasi (query panel dasbor, jendela 5 menit)"
sleep 10   # satu scrape lagi supaya rate() memuat akhir trafik
R="http_server_requests_seconds"
rps=$(prom "sum(rate(${R}_count{$SEL}[5m])) or vector(0)" | val)
avail=$(prom "100 * (1 - ((sum(rate(${R}_count{$SEL,status=~\"5..\"}[5m])) or vector(0)) / clamp_min(sum(rate(${R}_count{$SEL}[5m])) or vector(0), 1e-9)))" | val)
p95=$(prom "1000 * histogram_quantile(0.95, sum by (le) (rate(${R}_bucket{$SEL}[5m])))" | val)
rss=$(prom 'max(process_resident_memory_bytes{job="capstone-app"}) / 1048576' | val)
lag=$(prom 'max(1000 * nodejs_eventloop_lag_p99_seconds{job="capstone-app"})' | val)
rst=$(prom 'sum(changes(process_start_time_seconds{job="capstone-app"}[1h])) or vector(0)' | val)
row() { awk -v n="$1" -v v="${2:-}" -v u="$3" 'BEGIN{ if (v=="" || v=="NaN") x="tidak ada data"; else x=sprintf("%.2f %s",v,u); printf "         %-28s %s\n",n,x }'; }
row "Request API" "$rps" "req/s"; row "Non-5xx" "$avail" "%"; row "Latensi p95" "$p95" "ms"
row "Memori (RSS)" "$rss" "MiB (limit 512)"; row "Event loop lag p99" "$lag" "ms"; row "Restart proses 1 jam" "$rst" "kali"
slo() { # nama nilai operator target
  if [ -z "$2" ] || [ "$2" = NaN ]; then bad "SLO $1: tidak ada data"
  elif awk -v v="$2" -v t="$4" -v o="$3" 'BEGIN{exit !((o==">=") ? v+0>=t+0 : v+0<=t+0)}'; then ok "SLO $1 $3 $4 (usulan, belum final)"
  else bad "SLO $1 $3 $4 tidak terpenuhi (terukur $2)"; fi
}
# Tanpa trafik, rumus non-5xx selalu 100%, jadi wajib ada trafik di jendela ukur.
if awk -v v="${rps:-0}" 'BEGIN{exit !(v+0>0)}'; then slo "non-5xx %" "$avail" ">=" 99; else bad "SLO non-5xx: tidak ada trafik terukur"; fi
slo "p95 ms" "$p95" "<=" 500

echo
echo "Waktu selesai: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Limitation   : trafik buatan, volume kecil, hanya GET, satu pod di dev; jendela 5 menit bisa memuat trafik sebelum uji."
echo "               Tidak menguji 5xx/gangguan (REL-3) dan bukan uji beban (CAP-1)."
finish; rc=$?
[ "$LOG" = 1 ] && echo "Hasil tersimpan: ${OUT#"$ROOT"/}"
exit $rc
