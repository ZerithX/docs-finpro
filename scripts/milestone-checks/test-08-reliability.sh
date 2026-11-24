#!/usr/bin/env bash
# M7 Reliability & Recovery. Dengan --chaos: hapus pod (QS3) dan drift replica (self-heal),
# diukur dalam detik. Demo final #10. Bukti restore (REL-4) dicek dari DB dan evidence. Demo final #11.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

wait_ready() { # batas-detik -> cetak detik sampai deployment Ready penuh, atau -1
  local limit=$1 s=0 want got
  want=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.replicas}')
  while [ "$s" -lt "$limit" ]; do
    got=$(k get deploy "$DEPLOY" -o jsonpath='{.status.readyReplicas}')
    upd=$(k get deploy "$DEPLOY" -o jsonpath='{.status.updatedReplicas}')
    avail=$(k get pod -l app=capstone-app --no-headers 2>/dev/null | grep -c ' 1/1 ')
    [ "${got:-0}" = "$want" ] && [ "$avail" = "$want" ] && { echo "$s"; return; }
    sleep 1; s=$((s+1))
  done
  echo -1
}

check_08() {
  section "08 Reliability & Recovery (M7)"
  if [ "$CHAOS" = 1 ]; then
    if ! kube_ready; then skip "uji kegagalan" "kubectl/context tidak siap"
    else
      local before old t
      before=$(psql_q 'select count(*) from tickets'); old=$(k get pod -l app=capstone-app -o jsonpath='{.items[0].metadata.name}')
      info "$(date '+%H:%M:%S') hapus pod $old"
      k delete pod "$old" --wait=false >/dev/null
      sleep 2; t=$(wait_ready 120)
      if [ "$t" -ge 0 ] && [ "$t" -le 60 ]; then ok "pod pengganti Ready dalam ~$((t+2)) detik (QS3 <= 60 s)"
      elif [ "$t" -gt 60 ]; then bad "pod pengganti Ready dalam ~$((t+2)) detik (melebihi QS3 60 s)"
      else bad "pod pengganti tidak Ready dalam 120 detik"; fi
      if pg_ready; then
        [ "$(psql_q 'select count(*) from tickets')" = "$before" ] && ok "data tiket utuh setelah pod diganti ($before tiket)" || bad "jumlah tiket berubah setelah pod diganti"
      fi

      local want s=0 r; want=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.replicas}')
      info "$(date '+%H:%M:%S') drift manual: scale ke $((want+2)) replica"
      k scale deploy "$DEPLOY" --replicas=$((want+2)) >/dev/null
      while [ "$s" -lt 180 ]; do
        r=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.replicas}'); [ "$r" = "$want" ] && break; sleep 1; s=$((s+1))
      done
      if [ "$r" = "$want" ]; then ok "Argo CD mengembalikan replica ke $want dalam ~$s detik (self-heal)"
      else bad "replica tidak kembali ke $want dalam 180 detik" "cek selfHeal Argo CD; kembalikan manual: kubectl -n $NS scale deploy $DEPLOY --replicas=$want"; fi
    fi
  else skip "uji hapus pod dan self-heal" "jalankan dengan --chaos (layanan jeda beberapa detik karena replica 1)"; fi

  if pg_ready; then
    local dbs; dbs=$(docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_DB" -tAc "select datname from pg_database where datname like '%restore%'" 2>/dev/null | tr -d '\r' | tr '\n' ' ')
    [ -n "${dbs// /}" ] && ok "database hasil restore ada: $dbs" || bad "belum ada database hasil restore" "REL-4 (B)"
  else skip "cek database restore" "PostgreSQL tidak terjangkau"; fi
  evidence 08-reliability-recovery REL-1 "hapus pod (QS3)" "B"
  evidence 08-reliability-recovery REL-2 "drift -> self-heal" "B"
  evidence 08-reliability-recovery REL-3 "database mati (QS7)" "B"
  evidence 08-reliability-recovery REL-4 "backup -> restore -> validasi (QS5)" "B"
}
run_if_main check_08 "${BASH_SOURCE[0]}" "$@"
