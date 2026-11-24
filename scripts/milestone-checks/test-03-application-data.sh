#!/usr/bin/env bash
# M2 Application MVP: health, auth, isolasi tenant di /api/units, data persist,
# dan (dengan --write) transaksi inti OPEN -> CLOSED. Demo final #2 dan #3.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_03() {
  section "03 Application & Data (M2)"
  check_03_evidence
  http GET "$APP_URL/q/health/ready"
  if [ "$HTTP_CODE" = 200 ] && grep -q '"name":"database","status":"UP"' <<<"$HTTP_BODY"; then
    ok "readiness UP dan database UP"
  else bad "readiness -> $HTTP_CODE" "aplikasi atau database belum siap; cek kubectl -n $NS get pod"; return; fi

  load_tokens
  if [ -z "$TOK_USERA" ] || [ -z "$TOK_ADMIN" ]; then
    skip "pengecekan yang butuh login" "gagal mengambil token dari $KC_URL (Keycloak mati atau password berbeda)"; return
  fi
  ok "login Keycloak berhasil (usera, userb, operator, appadmin)"

  http GET "$APP_URL/api/units" "$TOK_USERA"
  if [ "$HTTP_CODE" = 200 ] && grep -q tenant-a <<<"$HTTP_BODY" && ! grep -q tenant-b <<<"$HTTP_BODY"; then
    ok "usera hanya melihat unit tenant-a"
  else bad "GET /api/units sebagai usera -> $HTTP_CODE" "$HTTP_BODY"; fi
  http GET "$APP_URL/api/units" "$TOK_ADMIN"
  if [ "$HTTP_CODE" = 200 ] && grep -q tenant-a <<<"$HTTP_BODY" && grep -q tenant-b <<<"$HTTP_BODY"; then
    ok "appadmin melihat kedua unit"
  else bad "GET /api/units sebagai appadmin -> $HTTP_CODE"; fi
  http GET "$APP_URL/api/sla-policies" "$TOK_USERA"
  if [ "$HTTP_CODE" = 200 ] && [ "$(json_count "$HTTP_BODY" priority)" -eq 4 ]; then ok "kebijakan SLA: 4 prioritas"
  else bad "GET /api/sla-policies -> $HTTP_CODE"; fi

  if pg_ready; then
    ok "data di PostgreSQL: $(psql_q 'select count(*) from units') unit, $(psql_q 'select count(*) from tickets') tiket, $(psql_q 'select count(*) from audit_log') baris audit"
  else skip "cek langsung ke PostgreSQL" "container $PG_CONTAINER tidak terjangkau"; fi

  if [ "$WRITE" != 1 ]; then
    skip "transaksi inti OPEN -> CLOSED" "jalankan dengan --write (membuat 1 tiket uji berlabel [milestone-check])"; return
  fi
  http POST "$APP_URL/api/tickets" "$TOK_USERA" \
    '{"title":"[milestone-check] uji transaksi inti","description":"Dibuat otomatis oleh scripts/milestone-checks","category":"JARINGAN","priority":"KRITIS"}'
  expect "usera membuat tiket KRITIS" 201
  [ "$HTTP_CODE" = 201 ] || return
  local id created due; id=$(json_first "$HTTP_BODY" id)
  created=$(json_first "$HTTP_BODY" createdAt); due=$(json_first "$HTTP_BODY" responseDueAt)
  info "tiket uji id=$id"
  [ "$(json_first "$HTTP_BODY" unit)" = tenant-a ] && ok "unit diambil dari token: tenant-a" || bad "unit tiket bukan tenant-a"
  local d; d=$(( $(date -d "$due" +%s 2>/dev/null || echo 0) - $(date -d "$created" +%s 2>/dev/null || echo 0) ))
  if [ "$d" -eq 1800 ]; then ok "tenggat respons = dibuat + 30 menit (ADR-005)"; else bad "selisih tenggat respons ${d}s (harapan 1800)"; fi

  http POST "$APP_URL/api/tickets/$id/assign" "$TOK_OPERATOR"; expect "operator assign (OPEN -> ASSIGNED)" 200
  [ -n "$(json_first "$HTTP_BODY" firstResponseAt)" ] && [ "$(json_first "$HTTP_BODY" firstResponseAt)" != null ] \
    && ok "firstResponseAt terisi saat assign" || bad "firstResponseAt kosong setelah assign"
  http POST "$APP_URL/api/tickets/$id/status" "$TOK_OPERATOR" '{"status":"IN_PROGRESS"}'; expect "operator -> IN_PROGRESS" 200
  http POST "$APP_URL/api/tickets/$id/status" "$TOK_OPERATOR" '{"status":"RESOLVED"}'; expect "operator -> RESOLVED" 200
  http POST "$APP_URL/api/tickets/$id/status" "$TOK_USERA" '{"status":"CLOSED"}'; expect "pelapor (usera) -> CLOSED" 200
  if pg_ready; then
    local a; a=$(psql_q "select count(*) from audit_log where ticket_id=$id")
    [ "${a:-0}" -ge 3 ] && ok "audit_log mencatat $a aksi operator untuk tiket $id" || bad "audit_log untuk tiket $id: ${a:-0} baris (harapan >= 3)"
  fi
}
# Bukti tertulis tugas backend (lihat docs/prd/01-backend.md)
check_03_evidence() {
  evidence 03-application-data BE-2 "auth di cluster" "Radya"
  evidence 03-application-data BE-3 "migrasi tiket" "Radya"
  evidence 03-application-data BE-4 "tiket + filter tenant" "Radya"
}
run_if_main check_03 "${BASH_SOURCE[0]}" "$@"
