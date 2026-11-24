# PD-2 — Pod Recovery Validation

## Scope

Local Kubernetes recovery test.

## Initial Condition

The `capstone-app` pod was running and Ready.

## Initial Validation

Command:

`kubectl -n capstone get pods -l app=capstone-app`

Observation:

The application pod was in `Running/Ready` state.

## Recovery Test

Command:

`kubectl -n capstone delete pod -l app=capstone-app`

## Expected Behavior

The Deployment controller creates a replacement pod automatically.

## Validation

Command:

`kubectl -n capstone rollout status deployment/capstone-app`

Then:

`kubectl -n capstone get pods -l app=capstone-app -o wide`

## Observed Result

The deleted pod was replaced by a new `capstone-app` pod.

Replacement pod:

`capstone-app-85fc6d899c-nbx9n`

Status:

`1/1 Running`

## Interpretation

The Kubernetes Deployment successfully recreated the application pod after the original pod was deleted.

This demonstrates the basic self-healing behavior of the Kubernetes Deployment.

## Limitation

This was a local validation test and is not the official reliability failure-test evidence defined for the official lab.