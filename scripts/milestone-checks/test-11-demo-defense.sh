#!/usr/bin/env bash
# FINAL: kelengkapan bahan demo dan submission.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_11() {
  section "11 Demo & Defense (FINAL)"
  file_ok 11-demo-defense/demo-script.md "FD-2 (B)"
  local api; api=$(ls "$ROOT"/11-demo-defense/api/* 2>/dev/null | head -1)
  [ -n "$api" ] && ok "koleksi API ada: ${api#$ROOT/}" || bad "koleksi API belum ada di 11-demo-defense/api/" "FD-2 (B)"
  file_ok 11-demo-defense/checklist.md "FD-8 (C)"
  local n; n=$(ls "$ROOT"/individual-reflections/*.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -ge 3 ] && ok "refleksi individu: $n" || bad "refleksi individu: $n dari 3" "FD-5 (semua)"
}
run_if_main check_11 "${BASH_SOURCE[0]}" "$@"
