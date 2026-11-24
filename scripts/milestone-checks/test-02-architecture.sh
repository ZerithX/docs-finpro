#!/usr/bin/env bash
# M1 Architecture: view arsitektur, boundary, quality scenario, diagram.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_02() {
  section "02 Architecture (M1)"
  file_ok 02-architecture/architecture.md
  file_ok 02-architecture/boundaries.md
  file_ok 02-architecture/quality-scenarios.md
  local n; n=$(ls "$ROOT"/02-architecture/diagrams/*.png 2>/dev/null | wc -l | tr -d ' ')
  if [ "$n" -ge 4 ]; then ok "diagram PNG: $n file"; else bad "diagram PNG hanya $n (harapan >= 4)"; fi
  local qs; qs=$(grep -Eo 'QS[1-7]' "$ROOT/02-architecture/quality-scenarios.md" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  if [ "$qs" -eq 7 ]; then ok "quality scenario QS1-QS7 lengkap"; else bad "quality scenario yang ditemukan: $qs dari 7"; fi
  local b; b=$(grep -Eo 'B[1-7]' "$ROOT/02-architecture/boundaries.md" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  if [ "$b" -eq 7 ]; then ok "trust boundary B1-B7 lengkap"; else bad "trust boundary yang ditemukan: $b dari 7"; fi
}
run_if_main check_02 "${BASH_SOURCE[0]}" "$@"
