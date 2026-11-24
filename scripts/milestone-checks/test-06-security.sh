#!/usr/bin/env bash
# M6 Security: token, penolakan 400/401/403/404/409, kebersihan repo, evidence. Demo final #7 dan #8.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_06() {
  section "06 Security (M6)"
  http GET "$APP_URL/api/tickets"; expect "tanpa token" 401
  http GET "$APP_URL/api/tickets" "bukan.token.asli"; expect "token palsu" 401

  load_tokens
  if [ -z "$TOK_USERA" ] || [ -z "$TOK_USERB" ] || [ -z "$TOK_OPERATOR" ]; then
    skip "pengecekan berbasis token" "gagal login ke $KC_URL"
  else
    local p; p=$(jwt_payload "$TOK_USERA")
    grep -q '"/tenant-a"' <<<"$p" && ok "token usera berisi groups /tenant-a (mapper BE-1)" || bad "claim groups /tenant-a tidak ada di token usera"
    grep -q '"user"' <<<"$p" && ok "token usera berisi role user (realm_access)" || bad "role user tidak ada di token usera"
    grep -q "\"azp\":\"$CLIENT_ID\"" <<<"$p" && ok "token dibuat untuk client $CLIENT_ID (azp)" || bad "azp bukan $CLIENT_ID"

    http POST "$APP_URL/api/tickets" "$TOK_USERA" '{"title":"x","description":"x","category":"JARINGAN","priority":"SUPER"}'
    expect "body tidak valid (prioritas SUPER)" 400

    local id; id=$(first_ticket_id "$TOK_USERA")
    if [ -z "$id" ]; then
      skip "uji lintas tenant" "usera belum punya tiket; jalankan test-03 dengan --write atau buat tiket di Swagger"
    else
      info "tiket tenant-a yang dipakai: id=$id"
      http GET "$APP_URL/api/tickets/$id" "$TOK_USERB"; expect "userb membuka tiket tenant-a" 404
      http GET "$APP_URL/api/tickets" "$TOK_USERB"
      grep -q '"unit":"tenant-a"' <<<"$HTTP_BODY" && bad "daftar tiket userb memuat tiket tenant-a (BOCOR)" || ok "daftar tiket userb tidak memuat tiket tenant-a"
      http POST "$APP_URL/api/tickets/$id/assign" "$TOK_USERA"; expect "usera (bukan operator) mencoba assign" 403
      http GET "$APP_URL/api/tickets/$id" "$TOK_OPERATOR"; expect "operator membuka tiket tenant-a (lintas tenant)" 200
    fi

    if [ "$WRITE" = 1 ]; then
      http POST "$APP_URL/api/tickets" "$TOK_USERA" '{"title":"[milestone-check] uji 409","description":"Dibuat otomatis oleh scripts/milestone-checks","category":"AKUN","priority":"RENDAH"}'
      local nid; nid=$(json_first "$HTTP_BODY" id)
      if [ "$HTTP_CODE" = 201 ] && [ -n "$nid" ]; then
        http POST "$APP_URL/api/tickets/$nid/status" "$TOK_OPERATOR" '{"status":"RESOLVED"}'
        expect "transisi tidak sah OPEN -> RESOLVED (tiket $nid)" 409
      else bad "gagal membuat tiket untuk uji 409 -> $HTTP_CODE"; fi
    else skip "uji 409 transisi tidak sah" "jalankan dengan --write"; fi
  fi

  # Kebersihan repo: tidak ada .env atau Secret asli yang ter-commit.
  local envs; envs=$(git -C "$APP_DIR" ls-files 2>/dev/null | grep -E '(^|/)\.env(\.test)?$')
  [ -z "$envs" ] && ok "tidak ada file .env yang ter-commit di capstone-app" || bad "file .env ter-commit: $envs"
  local sec; sec=$(cd "$GITOPS_DIR" 2>/dev/null && git ls-files | grep -v '\.example\.' | xargs -r grep -l '^kind: *Secret' 2>/dev/null)
  [ -z "$sec" ] && ok "repo GitOps hanya berisi Secret contoh (*.example.yaml)" || bad "Secret asli di repo GitOps: $sec"

  evidence 06-security BE-1 "mapper grup Keycloak" "Radya"
  evidence 06-security BE-7 "matriks tes negatif" "Radya"
  local realm; realm=$(ls "$ROOT"/06-security/keycloak/*.json "$ROOT"/06-security/*realm*.json 2>/dev/null | head -1)
  if [ -n "$realm" ]; then ok "export realm Keycloak ada: ${realm#$ROOT/}"; else bad "export realm Keycloak belum ada" "SEC-1 (C)"; fi
  evidence 06-security SEC-1 "isi token per user" "C"
  evidence 06-security SEC-2 "matriks authz + verifikasi" "C"
  evidence 06-security SEC-3 "analisis Trivy + perbaikan" "C"
  evidence 06-security SEC-4 "review secret di riwayat Git" "C"
  evidence 06-security SEC-5 "ancaman/kontrol B1-B7" "C"
}
run_if_main check_06 "${BASH_SOURCE[0]}" "$@"
