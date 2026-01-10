# Spring Kotlin App - Deployment Architecture

## Resource Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ISTIO INGRESS GATEWAY                            │
│                    (istio-system/istio-ingressgateway)                  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ HTTP Traffic
                                 │
                    ┌────────────▼────────────┐
                    │   Istio VirtualService  │
                    │  (Traffic Routing Rules)│
                    │                         │
                    │  Canary Strategy:       │
                    │  - Stable: 90%          │
                    │  - Canary: 10%          │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Istio DestinationRule  │
                    │  (Traffic Policies)     │
                    │                         │
                    │  Features:              │
                    │  - Circuit Breaker      │
                    │  - Connection Pool      │
                    │  - Subsets (stable/canary)
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Kubernetes Service    │
                    │   (spring-kotlin-app)   │
                    │   ClusterIP: 80 → 8080  │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │     Argo Rollout        │
                    │  (Progressive Delivery) │
                    │                         │
                    │  Strategy: Canary       │
                    │  Replicas: 3            │
                    │  Steps: 10→25→50→75→100%│
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │         PODS            │
                    │  (3 replicas)           │
                    │                         │
                    │  ┌──────────────────┐   │
                    │  │ Container 1:     │   │
                    │  │ spring-kotlin-app│   │
                    │  │ Port: 8080       │   │
                    │  │                  │   │
                    │  │ Health Checks:   │   │
                    │  │ /actuator/health │   │
                    │  └──────────────────┘   │
                    │  ┌──────────────────┐   │
                    │  │ Container 2:     │   │
                    │  │ istio-proxy      │   │
                    │  │ (Envoy Sidecar)  │   │
                    │  │                  │   │
                    │  │ Features:        │   │
                    │  │ - mTLS           │   │
                    │  │ - Traffic Mgmt   │   │
                    │  │ - Metrics        │   │
                    │  └──────────────────┘   │
                    └─────────────────────────┘
```

## Security Layer

```
┌─────────────────────────────────────────────────────────────────┐
│                    Istio PeerAuthentication                     │
│                      (mTLS: STRICT Mode)                        │
│                                                                 │
│  - Enforces mutual TLS for all service-to-service traffic      │
│  - Automatic certificate management by Istio                   │
│  - Identity: cluster.local/ns/spring-kotlin-app/sa/...         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       Pod Security                              │
│                                                                 │
│  - runAsNonRoot: true (UID: 1000)                              │
│  - readOnlyRootFilesystem: true                                │
│  - No privilege escalation                                     │
│  - Drop all capabilities                                       │
└─────────────────────────────────────────────────────────────────┘
```

## Multi-Environment Pipeline (Kargo)

```
┌─────────────┐      ┌──────────────┐      ┌──────────────┐
│   DEV       │      │   STAGING    │      │   PRODUCTION │
│             │      │              │      │              │
│  Auto       │─────▶│   Manual     │─────▶│   Manual     │
│  Promote    │      │   Promote    │      │   Promote    │
│             │      │              │      │              │
│  Namespace: │      │  Namespace:  │      │  Namespace:  │
│  *-dev      │      │  *-staging   │      │  *-prod      │
└─────────────┘      └──────────────┘      └──────────────┘
       ▲                    ▲                     ▲
       │                    │                     │
       │                    │                     │
┌──────┴────────────────────┴─────────────────────┴──────┐
│              Kargo Freight (Artifacts)                  │
│                                                         │
│  - Git Commit SHA                                       │
│  - Container Image: nijogeorgep/spring-kotlin-app:TAG  │
│  - Helm Chart Version                                   │
└─────────────────────────────────────────────────────────┘
```

## Canary Deployment Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                      Rollout Timeline                            │
└──────────────────────────────────────────────────────────────────┘

Time: 0m        │ Action: Deploy new version
                │ Traffic: Stable 100%, Canary 0%
                │ ▓▓▓▓▓▓▓▓▓▓ (Stable)
                │
Time: 0m        │ Action: Set weight 10%
                │ Traffic: Stable 90%, Canary 10%
                │ ▓▓▓▓▓▓▓▓▓░ (Stable) █ (Canary)
                │
Time: 2m        │ Action: Pause - Observe metrics
                │
                │
Time: 2m        │ Action: Set weight 25%
                │ Traffic: Stable 75%, Canary 25%
                │ ▓▓▓▓▓▓▓░░░ (Stable) ██░ (Canary)
                │
Time: 5m        │ Action: Pause - Observe metrics
                │
                │
Time: 5m        │ Action: Set weight 50%
                │ Traffic: Stable 50%, Canary 50%
                │ ▓▓▓▓▓░░░░░ (Stable) █████ (Canary)
                │
Time: 10m       │ Action: Pause - Observe metrics
                │
                │
Time: 10m       │ Action: Set weight 75%
                │ Traffic: Stable 25%, Canary 75%
                │ ▓▓░░░░░░░░ (Stable) ███████░ (Canary)
                │
Time: 15m       │ Action: Pause - Observe metrics
                │
                │
Time: 15m       │ Action: Set weight 100%
                │ Traffic: Stable 0%, Canary 100%
                │ ░░░░░░░░░░ (Old) ██████████ (New)
                │
Time: 15m       │ Action: Rollout Complete!
                │ Old version scaled down
```

## Resource Requests and Limits

```
┌─────────────────────────────────────────────────────────┐
│                    Per Pod Resources                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Requests (Guaranteed):                                 │
│    CPU:    500m (0.5 cores)                            │
│    Memory: 512Mi                                        │
│                                                         │
│  Limits (Maximum):                                      │
│    CPU:    1000m (1 core)                              │
│    Memory: 1Gi                                          │
│                                                         │
│  Total for 3 replicas:                                  │
│    CPU Request:    1.5 cores                           │
│    CPU Limit:      3 cores                             │
│    Memory Request: 1.5Gi                               │
│    Memory Limit:   3Gi                                 │
└─────────────────────────────────────────────────────────┘
```

## Traffic Management Features

```
┌─────────────────────────────────────────────────────────┐
│                  Circuit Breaker                        │
├─────────────────────────────────────────────────────────┤
│  Consecutive Errors: 5                                  │
│  Interval: 30s                                          │
│  Base Ejection Time: 30s                               │
│  Max Ejection %: 50%                                    │
│  Min Health %: 50%                                      │
│                                                         │
│  Connection Pool:                                       │
│    TCP Max Connections: 100                            │
│    HTTP1 Max Pending: 50                               │
│    HTTP2 Max Requests: 100                             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Retry Policy                         │
├─────────────────────────────────────────────────────────┤
│  Attempts: 3                                            │
│  Per Try Timeout: 5s                                    │
│  Retry On: 5xx, reset, connect-failure, refused-stream │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                       Timeout                           │
├─────────────────────────────────────────────────────────┤
│  Request Timeout: 30s                                   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    CORS Policy                          │
├─────────────────────────────────────────────────────────┤
│  Allow Origins: localhost:3000, localhost:8080          │
│  Allow Methods: GET, POST, PUT, DELETE, OPTIONS         │
│  Allow Headers: Content-Type, Authorization             │
│  Max Age: 24h                                           │
│  Allow Credentials: true                                │
└─────────────────────────────────────────────────────────┘
```

## Monitoring and Observability

```
┌─────────────────────────────────────────────────────────┐
│                    Metrics Collection                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Spring Boot Actuator:                                  │
│    /actuator/prometheus  → Application Metrics          │
│    /actuator/health      → Health Status                │
│    /actuator/info        → Application Info             │
│                                                         │
│  Istio Metrics:                                         │
│    - Request latency (p50, p90, p99)                   │
│    - Request rate (requests/sec)                        │
│    - Error rate (4xx, 5xx)                             │
│    - Traffic flow between services                      │
│                                                         │
│  Argo Rollouts Metrics:                                 │
│    - Rollout status and progression                     │
│    - Canary vs Stable traffic split                    │
│    - Deployment history                                 │
└─────────────────────────────────────────────────────────┘
```

## Access Points

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Access                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Local Port Forward:                                        │
│    kubectl port-forward svc/spring-kotlin-app 8080:80      │
│    → http://localhost:8080                                  │
│                                                             │
│  Istio Ingress (kind cluster):                             │
│    kubectl port-forward svc/istio-ingressgateway 8080:80   │
│    → http://spring-kotlin-app.local:8080                    │
│                                                             │
│  Argo Rollouts Dashboard:                                   │
│    kubectl-argo-rollouts dashboard                          │
│    → http://localhost:3100                                  │
│                                                             │
│  Kargo UI:                                                  │
│    kubectl port-forward svc/kargo-api 8081:80 -n kargo     │
│    → http://localhost:8081                                  │
│                                                             │
│  Kiali (Service Mesh Dashboard):                           │
│    kubectl port-forward svc/kiali 20001:20001 -n istio-sys │
│    → http://localhost:20001                                 │
│                                                             │
│  Grafana (Metrics Dashboard):                              │
│    kubectl port-forward svc/grafana 3000:3000 -n istio-sys │
│    → http://localhost:3000                                  │
└─────────────────────────────────────────────────────────────┘
```

## Files Created

- **values-spring-kotlin-app.yaml** - Complete Helm values configuration
- **SPRING-KOTLIN-APP-DEPLOYMENT.md** - Comprehensive deployment guide
- **DEPLOY-COMMANDS.md** - Quick reference commands
- **ARCHITECTURE.md** - This file

## Quick Deploy

```bash
# 1. Create namespace with Istio injection
kubectl create namespace spring-kotlin-app
kubectl label namespace spring-kotlin-app istio-injection=enabled

# 2. Deploy application
cd helm-charts/app-template
helm install spring-kotlin-app . -f values-spring-kotlin-app.yaml -n spring-kotlin-app

# 3. Watch rollout
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch

# 4. Access application
kubectl port-forward svc/spring-kotlin-app 8080:80 -n spring-kotlin-app
```
