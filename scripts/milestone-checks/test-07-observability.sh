#!/usr/bin/env bash
# M5 Operations & SLO: metrik, target Prometheus, dasbor, dokumen SLO. Demo final #9.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_07() {
  section "07 Observability & SLO (M5)"
  http GET "$APP_URL/q/metrics"
  grep -q 'http_server_requests_seconds_count' <<<"$HTTP_BODY" && ok "aplikasi mengekspor metrik HTTP (/q/metrics)" || bad "/q/metrics -> $HTTP_CODE tanpa metrik HTTP"
  grep -q 'campusdesk_tickets_created_total' <<<"$HTTP_BODY" && ok "metrik bisnis campusdesk_tickets_created_total ada" || bad "metrik bisnis tiket belum ada" "BE-8 (Radya)"

  local out; out=$(curl -s --max-time 10 -G "$PROM_URL/api/v1/query" --data-urlencode 'query=up{job="capstone-app"}' 2>/dev/null)
  if [ -z "$out" ]; then skip "target Prometheus" "Prometheus tidak terjangkau di $PROM_URL (jalankan up-observability)"
  elif grep -q '"1"\]' <<<"$out"; then ok "Prometheus: target capstone-app UP"
  else bad "Prometheus: target capstone-app tidak UP" "$(head -c 200 <<<"$out")"; fi

  local code; code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -u "$GRAFANA_AUTH" "$GRAFANA_URL/api/dashboards/uid/$DASHBOARD_UID" 2>/dev/null)
  case $code in
    200) ok "Grafana: dasbor $DASHBOARD_UID terpasang";;
    000) skip "dasbor Grafana" "Grafana tidak terjangkau di $GRAFANA_URL";;
    *)   bad "Grafana: dasbor $DASHBOARD_UID -> $code";;
  esac
  file_ok 07-observability-slo/grafana/campusdesk-service-health.json
  evidence 07-observability-slo OPS-1 "dokumen SLI/SLO" "C"
  evidence 07-observability-slo OPS-2 "runbook" "C"
}
run_if_main check_07 "${BASH_SOURCE[0]}" "$@"
