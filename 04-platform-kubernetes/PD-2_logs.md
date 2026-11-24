# PD-2 — Application Logs

## Command

`kubectl -n capstone logs deployment/capstone-app --tail=100`

## Relevant Output

`CampusDesk listening on http://0.0.0.0:8080`

## Interpretation

The CampusDesk application successfully started and is listening on port `8080` inside the Kubernetes pod.