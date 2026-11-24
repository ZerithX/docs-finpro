# PD-2 — Kubernetes Workload

## Scope

Local Kubernetes validation for `capstone-app`.

## Context

Command:

`kubectl config current-context`

Output:

`k3d-funqy-lab`

## Workload

Command:

`kubectl -n capstone get deploy,rs,pod,svc,ingress -o wide`

### Observed Workload

- Deployment: `capstone-app`
- ReplicaSet: `capstone-app`
- Pod: `capstone-app-85fc6d899c-4m6wx`
- Service: `capstone-app`
- Ingress: `capstone.localhost`

### Deployment

`capstone-app` — `1/1`

### Pod

`capstone-app-85fc6d899c-4m6wx` — `1/1 Running` — `0 restarts`

### Application Image

`registry:5000/student/capstone-app:bfe17734cc8c`

### Service

`capstone-app` — ClusterIP — port `80` → targetPort `8080`

### Ingress

- Host: `capstone.localhost`
- Ingress class: `traefik`

## Interpretation

The application workload is deployed and running successfully in the local k3d Kubernetes cluster.

## Limitation

This evidence represents local k3d validation. Official evidence must be captured again in the official lab environment.