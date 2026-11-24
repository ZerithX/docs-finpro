#!/usr/bin/env bash
# M3 Cloud-Native Platform: node, workload, probe, resources, konfigurasi, ekspos. Demo final #4.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_04() {
  section "04 Platform Kubernetes (M3)"
  if ! kube_ready; then evidence 04-platform-kubernetes PD-2 "bukti M3 (rollout, scale 1->2, troubleshooting)" "B"; skip "semua pengecekan cluster" "kubectl tidak ada, context bukan $KUBE_CONTEXT, atau namespace $NS tidak ada"; return; fi
  ok "context kubectl: $KUBE_CONTEXT"
  local ready total; total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
  ready=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2=="Ready"' | wc -l | tr -d ' ')
  if [ "$total" -gt 0 ] && [ "$ready" = "$total" ]; then ok "node Ready: $ready/$total"; else bad "node Ready: $ready/$total"; fi

  local want got; want=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.replicas}')
  got=$(k get deploy "$DEPLOY" -o jsonpath='{.status.readyReplicas}')
  if [ -n "$want" ] && [ "${got:-0}" = "$want" ]; then ok "deployment $DEPLOY Ready ${got}/${want}"; else bad "deployment $DEPLOY Ready ${got:-0}/${want:-?}"; fi

  local img tag; img=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].image}'); tag=${img##*:}
  if [[ "$tag" =~ ^[0-9a-f]{7,40}$ ]]; then ok "tag image = commit SHA ($tag), bukan latest"; else bad "tag image '$tag' bukan commit SHA"; fi

  local rp lp
  rp=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}')
  lp=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}')
  if [ "$rp" = /q/health/ready ]; then ok "readinessProbe $rp"; else bad "readinessProbe: '${rp}'"; fi
  if [ "$lp" = /q/health/live ]; then ok "livenessProbe $lp"; else bad "livenessProbe: '${lp}'"; fi

  local res; res=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].resources}')
  if grep -q '"requests"' <<<"$res" && grep -q '"limits"' <<<"$res"; then ok "requests dan limits diset: $res"; else bad "resources belum lengkap: ${res:-kosong}"; fi

  local host; host=$(k get ingress -o jsonpath='{.items[0].spec.rules[0].host}')
  if [ -n "$host" ]; then ok "ingress host: $host"; else bad "ingress tidak ditemukan"; fi
  local iss; iss=$(k get configmap capstone-app-config -o jsonpath='{.data.OIDC_ISSUER}')
  if [[ "$iss" == *keycloak:8080* ]]; then ok "ConfigMap OIDC_ISSUER lewat keycloak:8080 (ADR-012)"; else bad "OIDC_ISSUER: '${iss}'" "PD-1"; fi
  if k get secret capstone-app-secret >/dev/null; then ok "Secret capstone-app-secret ada (nilainya tidak dicetak)"; else bad "Secret capstone-app-secret tidak ada"; fi

  local rs; rs=$(k get rs -l app=capstone-app --no-headers | wc -l | tr -d ' ')
  if [ "$rs" -ge 2 ]; then ok "riwayat rollout: $rs ReplicaSet (versi lama tersimpan untuk rollback)"; else bad "hanya $rs ReplicaSet"; fi

  evidence 04-platform-kubernetes PD-2 "bukti M3 (rollout, scale 1->2, troubleshooting)" "B"
}
run_if_main check_04 "${BASH_SOURCE[0]}" "$@"
