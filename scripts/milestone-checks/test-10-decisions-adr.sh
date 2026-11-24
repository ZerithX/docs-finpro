#!/usr/bin/env bash
# M1 Decisions: setiap ADR punya status final, bukan draf.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_10() {
  section "10 Decisions (ADR)"
  local f n=0 acc=0 drafts=""
  for f in "$ROOT"/10-decisions-adr/ADR-[0-9]*.md; do
    [ -e "$f" ] || continue; n=$((n+1))
    local st; st=$(grep -m1 '| Status |' "$f")
    if grep -qi 'Diterima' <<<"$st"; then acc=$((acc+1))
    elif grep -qi 'Draf' <<<"$st"; then drafts="$drafts $(basename "$f" | cut -d- -f1-2)"; fi
  done
  [ "$n" -gt 0 ] && ok "jumlah ADR: $n" || { bad "tidak ada ADR di 10-decisions-adr/"; return; }
  info "berstatus Diterima: $acc dari $n"
  [ -z "$drafts" ] && ok "tidak ada ADR berstatus draf" || bad "ADR masih draf:$drafts" "PD-5 (B), SEC-6 (C)"
}
run_if_main check_10 "${BASH_SOURCE[0]}" "$@"
