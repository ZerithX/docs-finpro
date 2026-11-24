# PD-2 — Runtime Configuration

## Command

`kubectl -n capstone get configmap capstone-app-config -o yaml`

## Relevant Configuration

### DB_URL

`jdbc:postgresql://postgres:5432/capstone`

### DB_USER

`capstone`

### OIDC_ISSUER

`http://keycloak:8080/realms/capstone`

### OIDC_TOKEN_ISSUER

`http://localhost:8081/realms/capstone`

## Interpretation

The application receives runtime configuration from the Kubernetes ConfigMap.

The OIDC values match the required Platform & Delivery configuration for the local validation.

## Limitation

This evidence represents the local k3d environment.