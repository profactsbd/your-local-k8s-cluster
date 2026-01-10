# Helm Chart Templates - Inline Documentation Reference

This document provides an overview of all inline documentation added to the Helm chart templates across all subcharts.

## Purpose of Inline Documentation

Each template file now includes comprehensive inline comments that explain:
- **What the resource does** - High-level purpose and functionality
- **When it renders** - Conditions that control template rendering
- **Key configuration options** - Important fields and their meanings
- **Integration points** - How resources work together
- **Best practices** - Recommendations for usage

## Documentation Structure

All templates follow a consistent documentation pattern:

```yaml
#
# RESOURCE TYPE - MODE/PURPOSE
# Purpose: Brief description of what it does
# Renders: Conditions that control when this template renders
#
# What it does:
# - Bullet point list of functionality
# - Integration with other resources
# - Use cases and scenarios
#
# Key concepts:
# - Important fields with explanations
# - Configuration options and their meanings
# - Best practices and recommendations
#
apiVersion: ...
kind: ...
# Inline comments throughout the spec explaining each field
```

## Main Chart Templates

### 1. Deployment (`templates/deployment.yaml`)

**Purpose**: Standard Kubernetes Deployment for basic application deployments

**Rendering Condition**: `argo-rollouts.enabled=false`

**Key Documentation Points**:
- When to use Deployment vs Argo Rollouts
- HPA integration (replicas field omitted when autoscaling enabled)
- Pod template specification (containers, probes, resources)
- Scheduling configuration (nodeSelector, affinity, tolerations)
- Security contexts (pod-level and container-level)
- Health checks (liveness and readiness probes)

**Alternative**: Argo Rollouts for progressive delivery

### 2. HorizontalPodAutoscaler (`templates/hpa.yaml`)

**Purpose**: Automatically scales pod replicas based on CPU/Memory utilization

**Rendering Condition**: `argo-rollouts.enabled=false AND autoscaling.enabled=true`

**Key Documentation Points**:
- **Intelligent API Version Detection**:
  - `autoscaling/v2` (Kubernetes 1.23+): Full feature set
  - `autoscaling/v2beta2` (K8s 1.18-1.22): Memory metrics
  - `autoscaling/v2beta1` (K8s <1.18): CPU only
- Metric types (CPU, Memory) as percentage of requests
- Scaling behavior policies (rate limiting, stabilization)
- Best practices for threshold configuration

**Requirements**: Resource requests must be set on containers

### 3. Service (`templates/service.yaml`)

**Purpose**: Exposes pods via stable network endpoint with load balancing

**Rendering Condition**: Always (required for pod networking)

**Key Documentation Points**:
- Service types (ClusterIP, NodePort, LoadBalancer, ExternalName)
- Port vs targetPort configuration
- Port naming for Istio protocol detection
- DNS name format (`service-name.namespace.svc.cluster.local`)
- Integration with Istio service mesh

### 4. ServiceAccount (`templates/serviceaccount.yaml`)

**Purpose**: Provides identity for pods to interact with Kubernetes API and other services

**Rendering Condition**: `serviceAccount.create=true`

**Key Documentation Points**:
- RBAC authorization with Roles/ClusterRoles
- Istio workload identity (SPIFFE ID format)
- Cloud IAM integration annotations (AWS IRSA, GCP Workload Identity)
- AuthorizationPolicy integration for access control
- Certificate identity for mTLS connections

## Argo Rollouts Subchart Templates

### 5. Rollout (`charts/argo-rollouts/templates/rollout.yaml`)

**Purpose**: Advanced deployment controller for canary, blue-green, and analysis-driven rollouts

**Rendering Condition**: `argo-rollouts.enabled=true`

**Key Documentation Points**:
- **Progressive Delivery Strategies**:
  - **Canary**: Gradual traffic shifting (10% → 25% → 50% → 100%)
  - **Blue-Green**: All-at-once switch with preview environment
  - **Analysis**: Automated rollback based on metrics
- **Istio Integration**:
  - Automatic VirtualService weight updates
  - DestinationRule subset routing (stable/canary)
  - Zero-downtime deployments with real traffic validation
- Canary steps (setWeight, pause, analysis)
- Manual approval gates
- Revision history for rollback

**Monitoring Commands**:
```bash
kubectl argo rollouts get rollout <name>
kubectl argo rollouts status <name>
kubectl argo rollouts promote <name>  # manual progression
kubectl argo rollouts abort <name>    # rollback
```

## Istio Routing Subchart Templates

All Istio templates are extensively documented. See [charts/istio-routing/TEMPLATE-DOCUMENTATION.md](charts/istio-routing/TEMPLATE-DOCUMENTATION.md) for complete details.

### 6. Gateway (`charts/istio-routing/templates/gateway.yaml`)
- Configures how external traffic enters the service mesh at the edge
- Defines ingress points for HTTP/HTTPS/TCP
- TLS configuration for HTTPS termination

### 7. VirtualService (`charts/istio-routing/templates/virtualservice.yaml`)
- **Canary Mode**: Routes traffic to multiple versions (stable/canary) for progressive delivery
- **Standard Mode**: Routes all traffic to single version
- Advanced features: retry, timeout, CORS, headers, fault injection, mirroring

### 8. DestinationRule (in `virtualservice.yaml`)
- Defines subsets (versions) and traffic policies
- Circuit breaker, load balancer, connection pool configuration
- TLS for upstream connections

### 9. ServiceEntry (`charts/istio-routing/templates/serviceentry.yaml`)
- Makes external services accessible from within the mesh
- DNS/STATIC resolution modes
- mTLS certificate validation

### 10. PeerAuthentication (`charts/istio-routing/templates/peerauthentication.yaml`)
- Configures mutual TLS (mTLS) for service-to-service communication
- Modes: STRICT, PERMISSIVE, DISABLE
- Port-level mTLS overrides

### 11. AuthorizationPolicy (`charts/istio-routing/templates/authorizationpolicy.yaml`)
- Fine-grained access control for service-to-service communication
- WHO can access (service identity/principal)
- WHAT operations are allowed (HTTP methods, paths)
- Actions: ALLOW, DENY, AUDIT

### 12. Sidecar (`charts/istio-routing/templates/sidecar.yaml`)
- Optimizes Envoy proxy resource usage
- Limits traffic scope (egress hosts whitelist)
- outboundTrafficPolicy: ALLOW_ANY vs REGISTRY_ONLY

## Kargo Config Subchart Templates

### 13. Stage (`charts/kargo-config/templates/stages.yaml`)

**Purpose**: Defines deployment stage in multi-environment promotion pipeline

**Rendering Condition**: One Stage resource per entry in `.Values.stages` array

**Key Documentation Points**:
- **Multi-Stage Pipeline** (dev → staging → prod):
  - dev: Auto-promote new commits from main branch
  - staging: Manual promotion from dev after testing
  - prod: Manual promotion from staging with approvals
- **Promotion Flow**:
  1. Freight (artifact bundle) created from Git commit/image/chart
  2. Stage requests specific Freight (by origin, stage, or warehouse)
  3. Promotion approved (manual or automatic)
  4. Kargo executes promotion mechanisms (Git PR, ArgoCD sync)
  5. Stage tracks deployed Freight version
- **Promotion Mechanisms**:
  - `gitRepoUpdates`: Updates manifest files in Git (GitOps workflow)
  - `argoCDAppUpdates`: Triggers ArgoCD application sync
- Integration with Git, ArgoCD, and Argo Rollouts

**Monitoring**:
- Kargo UI: `http://localhost:8081` (via port-forward)
- `kubectl get stages -n <namespace>`
- `kubectl describe stage <name> -n <namespace>`

## Template Relationships and Integration

### Deployment Workflow

#### Standard Deployment (No Progressive Delivery)
```
Deployment → HPA (optional) → Service → Istio VirtualService (optional)
     ↓
ServiceAccount (for RBAC and Istio identity)
```

#### Progressive Delivery with Argo Rollouts
```
Rollout → Service → Istio VirtualService + DestinationRule
  ↓
ServiceAccount (for RBAC and Istio identity)
  ↓
Istio traffic management (canary weights)
```

#### Multi-Environment Pipeline with Kargo
```
Kargo Stages (dev → staging → prod)
     ↓
  Argo Rollouts (progressive delivery per stage)
     ↓
  Istio (traffic management)
```

### Istio Service Mesh Integration

```
Gateway (ingress) → VirtualService (routing) → DestinationRule (policies)
                                                      ↓
                                        Service → Pods (with sidecar)
                                                      ↓
PeerAuthentication (mTLS) + AuthorizationPolicy (access control)
```

### External Service Access

```
ServiceEntry (register external service)
     ↓
DestinationRule (circuit breaker, retry)
     ↓
Application calls external service
```

## Using the Documentation

### Reading Templates

When editing template files:
1. Read the block comment at the top to understand the resource
2. Check rendering conditions to know when it applies
3. Review inline comments for specific field explanations
4. Check integration notes for how it works with other resources

### Debugging with Helm Template

Run `helm template` to see rendered YAML with inline comments:

```powershell
cd helm-charts/app-template

# Basic rendering
helm template test .

# With Istio routing
helm template test . --set istio-routing.enabled=true

# With Argo Rollouts canary
helm template test . --set argo-rollouts.enabled=true,argo-rollouts.strategy.type=canary

# With Kargo stages
helm template test . --set kargo-config.enabled=true
```

The output includes all documentation comments, making it easy to understand what each section does.

### Understanding Conditional Rendering

Templates use Helm conditionals to control what gets rendered:

- **Deployment** renders when `argo-rollouts.enabled=false`
- **Rollout** renders when `argo-rollouts.enabled=true`
- **HPA** renders when `autoscaling.enabled=true AND argo-rollouts.enabled=false`
- **Istio resources** render when `istio-routing.enabled=true` and specific sub-features enabled
- **Kargo Stages** render when `kargo-config.enabled=true`

This ensures you only deploy what you need.

## Common Configuration Patterns

### 1. Basic Application (Standard Deployment)
```yaml
# Uses: Deployment + Service + ServiceAccount
argo-rollouts:
  enabled: false
  replicas: 3

autoscaling:
  enabled: false

service:
  type: ClusterIP
  port: 80
```

### 2. Autoscaling Application (Deployment + HPA)
```yaml
# Uses: Deployment (no replicas) + HPA + Service
argo-rollouts:
  enabled: false

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### 3. Canary Deployment with Istio (Progressive Delivery)
```yaml
# Uses: Rollout + VirtualService + DestinationRule + Service
argo-rollouts:
  enabled: true
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 10
        - pause: {duration: 5m}
        - setWeight: 50
        - pause: {duration: 10m}
        - setWeight: 100

istio-routing:
  enabled: true
  trafficRouting:
    enabled: true
```

### 4. Multi-Environment Pipeline (Kargo + Argo Rollouts + Istio)
```yaml
# Uses: Rollout + Istio + Kargo Stages
argo-rollouts:
  enabled: true
  strategy:
    type: canary

istio-routing:
  enabled: true
  trafficRouting:
    enabled: true

kargo-config:
  enabled: true
  stages:
    - name: dev
      # Auto-promote from Git
    - name: staging
      # Manual promotion from dev
    - name: prod
      # Manual promotion from staging
```

## Best Practices

### Resource Configuration
- **Always set resource requests** for HPA to work correctly
- **Use readiness probes** to prevent traffic to unready pods
- **Use liveness probes** to restart unhealthy containers
- **Set appropriate timeouts** for probes based on app startup time

### Progressive Delivery
- **Start with small canary weights** (5-10%) to minimize risk
- **Add pause steps** for observation and validation
- **Use analysis** for automated rollback on metrics failure
- **Test in lower environments** before production

### Service Mesh (Istio)
- **Enable sidecar injection** for all mesh services
- **Use STRICT mTLS** in production for security
- **Configure circuit breakers** to prevent cascading failures
- **Set appropriate retry policies** for transient errors
- **Use timeouts** to prevent hanging requests

### Multi-Stage Deployments (Kargo)
- **Auto-promote in dev** for fast feedback
- **Manual promotion in prod** for control and validation
- **Use Git as source of truth** (GitOps pattern)
- **Track Freight versions** across environments

## Troubleshooting

### Deployment Not Rendering
- Check: `argo-rollouts.enabled=false`
- HPA requires: `autoscaling.enabled=true`

### Rollout Not Progressing
- Check steps configuration
- Verify Istio VirtualService exists if using traffic routing
- Use: `kubectl argo rollouts status <name>`

### HPA Not Scaling
- Verify resource requests are set
- Check metrics server is running: `kubectl get deployment metrics-server -n kube-system`
- View HPA status: `kubectl describe hpa <name>`

### Istio Features Not Working
- Verify Istio sidecar is injected: `kubectl get pod <name> -o jsonpath='{.spec.containers[*].name}'`
- Check for `istio-proxy` container
- Review Istio documentation in `charts/istio-routing/TEMPLATE-DOCUMENTATION.md`

## Additional Resources

- **Main Chart**: [README.md](README.md)
- **Istio Routing**: [charts/istio-routing/README.md](charts/istio-routing/README.md)
- **Istio Quick Reference**: [ISTIO-QUICK-REFERENCE.md](ISTIO-QUICK-REFERENCE.md)
- **Deployment Guide**: [DEPLOYMENT-QUICKSTART.md](DEPLOYMENT-QUICKSTART.md)
- **HPA Guide**: [DEPLOYMENT-HPA-ENHANCEMENT.md](DEPLOYMENT-HPA-ENHANCEMENT.md)
- **Values Documentation**: [values.yaml](values.yaml)

## Contributing

When adding new templates or updating existing ones:
1. Add block comment at the top explaining the resource
2. Add inline comments for complex logic or important fields
3. Explain conditional rendering with `{{- if }}` blocks
4. Document integration points with other resources
5. Include examples in comments when helpful
6. Follow the documentation pattern shown in this guide
7. Test with `helm template` to verify comments render correctly
8. Run `helm lint` to ensure syntax is valid
