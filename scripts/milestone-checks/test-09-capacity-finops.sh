#!/usr/bin/env bash
# M8 Capacity & FinOps: pemakaian vs alokasi, dan evidence uji beban/biaya. Demo final #12.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_09() {
  section "09 Capacity & FinOps (M8)"
  if kube_ready; then
    local top req lim
    top=$(k top pod -l app=capstone-app --no-headers)
    req=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].resources.requests}')
    lim=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].resources.limits}')
    if [ -n "$top" ]; then ok "pemakaian sekarang (kubectl top): $(awk '{print $1": CPU "$2", memori "$3}' <<<"$top" | paste -sd ';' -)"
      info "requests: $req"; info "limits:   $lim"
    else skip "kubectl top" "metrics-server belum siap"; fi
  else skip "pemakaian resource" "kubectl/context tidak siap"; fi
  evidence 09-capacity-finops CAP-1 "uji beban (QS4)" "C"
  evidence 09-capacity-finops CAP-2 "rightsizing" "B"
  evidence 09-capacity-finops CAP-3 "model biaya" "C"
  evidence 09-capacity-finops CAP-4 "roadmap + risiko sisa" "C"
}
run_if_main check_09 "${BASH_SOURCE[0]}" "$@"
