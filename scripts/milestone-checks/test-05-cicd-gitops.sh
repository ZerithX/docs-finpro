#!/usr/bin/env bash
# M4 Delivery Automation: CI terkendali, artefak immutable, GitOps tersinkron. Demo final #5 dan #6.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
check_05() {
  section "05 CI/CD & GitOps (M4)"
  evidence 05-ci-cd-gitops PD-3 "tabel traceability + QS6" "B"
  evidence 05-ci-cd-gitops PD-4 "latihan rollback" "B"
  local ci="$APP_DIR/.gitea/workflows/ci.yml"
  if [ -s "$ci" ]; then
    grep -q "refs/heads/main" "$ci" && ok "CI hanya publish setelah merge ke main" || bad "guard publish ke main tidak ditemukan di ci.yml"
    grep -qi trivy "$ci" && ok "CI menjalankan Trivy" || bad "Trivy tidak ada di ci.yml"
    grep -q "kubectl apply" "$ci" && bad "ci.yml menjalankan kubectl apply (seharusnya Argo CD yang deploy)" || ok "CI tidak menyentuh cluster (tanpa kubectl apply)"
  else skip "isi ci.yml" "$ci tidak ditemukan"; fi

  # Run CI terakhir lewat API Gitea (dilewati bila endpoint tidak tersedia di versi Gitea ini).
  http GET "$GITEA_URL/api/v1/repos/$GITEA_USER/capstone-app/actions/tasks?limit=1"
  if [ "$HTTP_CODE" = 200 ] && grep -q '"status"' <<<"$HTTP_BODY"; then
    local st sha; st=$(json_first "$HTTP_BODY" status); sha=$(json_first "$HTTP_BODY" head_sha)
    [ "$st" = success ] && ok "run CI terakhir: success (commit ${sha:0:12})" || bad "run CI terakhir: $st (commit ${sha:0:12})"
  else skip "status run CI terakhir" "API Actions Gitea -> $HTTP_CODE; cek manual di $GITEA_URL/$GITEA_USER/capstone-app/actions"; fi

  if ! kube_ready; then skip "pengecekan Argo CD dan cluster" "kubectl/context tidak siap"; return; fi
  local sync health rev heal
  sync=$(kubectl -n argocd get application "$ARGO_APP" -o jsonpath='{.status.sync.status}' 2>/dev/null)
  health=$(kubectl -n argocd get application "$ARGO_APP" -o jsonpath='{.status.health.status}' 2>/dev/null)
  rev=$(kubectl -n argocd get application "$ARGO_APP" -o jsonpath='{.status.sync.revision}' 2>/dev/null)
  heal=$(kubectl -n argocd get application "$ARGO_APP" -o jsonpath='{.spec.syncPolicy.automated.selfHeal}' 2>/dev/null)
  [ "$sync" = Synced ] && [ "$health" = Healthy ] && ok "Argo CD $ARGO_APP: Synced, Healthy di ${rev:0:7}" || bad "Argo CD $ARGO_APP: ${sync:-?} / ${health:-?}"
  [ "$heal" = true ] && ok "Argo CD selfHeal aktif" || bad "selfHeal tidak aktif"

  http GET "$GITEA_URL/api/v1/repos/$GITEA_USER/capstone-gitops/branches/main"
  local head; head=$(grep -o '"id":"[0-9a-f]\{40\}"' <<<"$HTTP_BODY" | head -1 | cut -d'"' -f4)
  if [ -n "$head" ]; then
    [ "$head" = "$rev" ] && ok "revisi Argo CD = HEAD repo GitOps (${head:0:7})" || bad "Argo CD di ${rev:0:7}, HEAD GitOps ${head:0:7}" "tunggu sync atau Refresh di Argo CD"
  else skip "bandingkan revisi Argo CD dengan HEAD GitOps" "API branch Gitea -> $HTTP_CODE"; fi

  http GET "$GITEA_URL/$GITEA_USER/capstone-gitops/raw/branch/main/overlays/dev/kustomization.yaml"
  local want run; want=$(sed -n 's/^ *newTag: *//p' <<<"$HTTP_BODY" | tr -d '\r"' | head -1)
  run=$(k get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].image}'); run=${run##*:}
  if [ -n "$want" ]; then
    [ "$want" = "$run" ] && ok "image di cluster ($run) = newTag di repo GitOps" || bad "cluster $run, repo GitOps $want"
  else skip "bandingkan image dengan repo GitOps" "tidak bisa membaca kustomization.yaml dari Gitea"; fi
  if git -C "$APP_DIR" cat-file -e "${run}^{commit}" 2>/dev/null; then
    ok "tag $run menunjuk commit: $(git -C "$APP_DIR" log -1 --format='%h %s' "$run")"
  else skip "telusuri tag ke commit aplikasi" "commit $run belum ada di clone lokal (git -C capstone-app fetch --all)"; fi


}
run_if_main check_05 "${BASH_SOURCE[0]}" "$@"
