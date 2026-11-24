#!/usr/bin/env bash
# M0 Case Proposal: proposal ada dan persetujuan dosen tercatat.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_01() {
  section "01 Business (M0)"
  file_ok 01-business/proposal.md
  file_ok 01-business/approval.md
  local st; st=$(grep -m1 '| Status |' "$ROOT/01-business/approval.md" 2>/dev/null)
  if [ -z "$st" ]; then bad "baris Status tidak ditemukan di approval.md"
  elif grep -q 'PENDING' <<<"${st%%(*}"; then bad "approval.md masih PENDING" "FD-1 (C): catat jawaban dosen"
  else ok "status persetujuan tercatat: $(tr -d '*|' <<<"${st%%(*}" | sed -E 's/^ *Status *//; s/ +$//')"; fi
}
run_if_main check_01 "${BASH_SOURCE[0]}" "$@"
