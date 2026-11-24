# 04 — Platform Kubernetes

**Milestone:** M3 Platform & Delivery  
**Owner:** B  
**Scope:** Kubernetes workload, probes, resources, rollout, runtime configuration, dan recovery validation.

## Evidence Files

| File | Evidence |
|---|---|
| `PD-2_workload.md` | Kubernetes objects dan workload |
| `PD-2_rollout.md` | Rollout history dan rollout status |
| `PD-2_probes-resources.md` | Probe dan resource configuration |
| `PD-2_runtime.md` | Runtime state pod |
| `PD-2_logs.md` | Application runtime log |
| `PD-2_configmap.md` | Runtime configuration melalui ConfigMap |
| `PD-2_recovery.md` | Local pod recovery test |

## 1. Kubernetes Workload

Workload `capstone-app` berhasil berjalan pada namespace `capstone`.

Deployment memiliki satu replica dan pod berada pada status `Running` serta `Ready`.

Detail object Kubernetes dicatat pada `PD-2_workload.md`.

## 2. Rollout

Deployment memiliki rollout history dan rollout terakhir berhasil mencapai kondisi `successfully rolled out`.

Detail rollout dicatat pada `PD-2_rollout.md`.

## 3. Probes & Resources

Deployment menggunakan:

- Liveness probe: `/q/health/live`
- Readiness probe: `/q/health/ready`
- CPU request: `100m`
- Memory request: `192Mi`
- CPU limit: `500m`
- Memory limit: `512Mi`

Detail configuration dicatat pada `PD-2_probes-resources.md`.

## 4. Runtime

Pod `capstone-app` berjalan menggunakan image:

`registry:5000/student/capstone-app:bfe17734cc8c`

Runtime state dan image digest dicatat pada `PD-2_runtime.md`.

## 5. Application Runtime

Application berhasil start dan listen pada:

`http://0.0.0.0:8080`

Detail log dicatat pada `PD-2_logs.md`.

## 6. Runtime Configuration

ConfigMap `capstone-app-config` menyediakan konfigurasi database dan OIDC.

Nilai OIDC yang digunakan:

- `OIDC_ISSUER=http://keycloak:8080/realms/capstone`
- `OIDC_TOKEN_ISSUER=http://localhost:8081/realms/capstone`

Detail configuration dicatat pada `PD-2_configmap.md`.

## 7. Recovery Validation

Local validation dilakukan dengan menghapus pod dan mengamati apakah Deployment membuat replacement pod secara otomatis.

Replacement pod berhasil kembali ke kondisi `Running` dan `Ready`.

Detail test dicatat pada `PD-2_recovery.md`.

## 8. Limitation

Evidence pada folder ini merupakan hasil validasi local k3d lab.

Evidence ini digunakan untuk memvalidasi konfigurasi dan perilaku workload sebelum official lab validation. Official evidence tetap mengikuti scope dan environment yang ditentukan pada PRD.

## 9. Decision

Konfigurasi Kubernetes dan runtime behavior telah divalidasi pada local k3d lab. Evidence official dapat menggantikan atau melengkapi evidence local ketika validasi dilakukan pada official lab.