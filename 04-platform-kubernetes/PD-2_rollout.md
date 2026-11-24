# PD-2 — Rollout Evidence

## Rollout History

Command:

`kubectl -n capstone rollout history deployment/capstone-app`

Output:

- Deployment: `capstone-app`
- Revision 1
- Revision 2

## Rollout Status

Command:

`kubectl -n capstone rollout status deployment/capstone-app`

Output:

`deployment "capstone-app" successfully rolled out`

## Interpretation

The deployment has rollout history and the current revision successfully reached the expected available state.

## Limitation

This is local k3d validation. Official rollout evidence must be captured again in the official lab environment.