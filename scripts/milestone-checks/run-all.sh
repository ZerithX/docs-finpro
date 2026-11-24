#!/usr/bin/env bash
# Jalankan pengecekan milestone CampusDesk dan simpan hasilnya sebagai evidence.
#
# Pemakaian (Git Bash, dari folder mana saja):
#   ./scripts/milestone-checks/run-all.sh                 # semua milestone, hanya membaca
#   ./scripts/milestone-checks/run-all.sh 03 06           # milestone tertentu
#   ./scripts/milestone-checks/run-all.sh --write         # + transaksi inti dan uji 409 (membuat tiket uji)
#   ./scripts/milestone-checks/run-all.sh 08 --chaos      # + hapus pod dan uji self-heal
#   ./scripts/milestone-checks/run-all.sh --no-log        # tanpa menyimpan file hasil
#
# Hasil disimpan ke 11-demo-defense/checks/run-<waktu>.txt.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/_common.sh"
for f in "$DIR"/test-*.sh; do source "$f"; done

ALL=(01 02 03 04 05 06 07 08 09 10 11)
SEL=(); LOG=1
for a in "$@"; do
  case $a in
    --write) WRITE=1;; --chaos) CHAOS=1;; --no-log) LOG=0;;
    [0-9][0-9]) SEL+=("$a");;
    -h|--help) sed -n '2,12p' "$0"; exit 0;;
    *) echo "argumen tidak dikenal: $a"; exit 2;;
  esac
done
[ ${#SEL[@]} -eq 0 ] && SEL=("${ALL[@]}")

if [ "$LOG" = 1 ]; then
  mkdir -p "$ROOT/11-demo-defense/checks"
  OUT="$ROOT/11-demo-defense/checks/run-$(date '+%Y%m%d-%H%M%S').txt"
  exec > >(tee "$OUT") 2>&1
fi

ver() { git -C "$1" log -1 --format='%h (%cd)' --date=format:'%Y-%m-%d %H:%M' 2>/dev/null || echo '-'; }
echo "CampusDesk - pengecekan milestone"
echo "Waktu          : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Repo portofolio: $(ver "$ROOT")"
echo "capstone-app   : $(ver "$APP_DIR")"
echo "capstone-gitops: $(ver "$GITOPS_DIR")"
echo "kubectl context: $(kubectl config current-context 2>/dev/null || echo '-')"
echo "Milestone      : ${SEL[*]}   --write=$WRITE   --chaos=$CHAOS"

declare -a ROWS
for m in "${SEL[@]}"; do
  fn="check_$m"
  if ! declare -F "$fn" >/dev/null; then echo; echo "milestone $m tidak dikenal"; continue; fi
  p0=$PASS; f0=$FAIL; s0=$SKIP
  "$fn"
  ROWS+=("$(printf '%-4s %5s %5s %5s' "$m" $((PASS-p0)) $((FAIL-f0)) $((SKIP-s0)))")
done

echo; echo "== Ringkasan per milestone =="
printf '%-4s %5s %5s %5s\n' "MS" PASS FAIL SKIP
printf '%s\n' "${ROWS[@]}"
finish; rc=$?
[ "$LOG" = 1 ] && echo "Hasil tersimpan: ${OUT#$ROOT/}"
exit $rc
