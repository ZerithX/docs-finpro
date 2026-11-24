# PD-2 — Probes & Resources

## Command

`kubectl -n capstone describe deployment/capstone-app`

## Relevant Configuration

### Image

`registry:5000/student/capstone-app:bfe17734cc8c`

### Resource Requests

- CPU: `100m`
- Memory: `192Mi`

### Resource Limits

- CPU: `500m`
- Memory: `512Mi`

### Liveness Probe

Path: `/q/health/live`

### Readiness Probe

Path: `/q/health/ready`

### Configuration Source

- ConfigMap: `capstone-app-config`
- Secret: `capstone-app-secret`

### Application Container Port

`8080`

## Interpretation

The workload defines both liveness and readiness probes and has explicit CPU and memory requests/limits.

The readiness probe is used to determine whether the application is ready to receive traffic, while the liveness probe checks application health.

## Limitation

The evidence shown here is the relevant configuration from the local deployment description.