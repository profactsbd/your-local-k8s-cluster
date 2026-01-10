# Helm Chart Modular Architecture

## Chart Structure Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      app-template (v2.0.0)                      │
│                    Main Application Chart                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Core Resources (Always Deployed):                              │
│  • Rollout/Deployment  - Application pods                       │
│  • Service            - ClusterIP service                       │
│  • ServiceAccount     - Pod identity                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
         ┌──────────▼──────────┐    ┌──▼───────────────────┐
         │  istio-routing      │    │  kargo-config        │
         │     (v1.0.0)        │    │    (v1.0.0)          │
         │   [OPTIONAL]        │    │   [OPTIONAL]         │
         ├─────────────────────┤    ├──────────────────────┤
         │                     │    │                      │
         │ • VirtualService    │    │ • Stages (dev/       │
         │ • DestinationRule   │    │   staging/prod)      │
         │                     │    │ • Warehouse          │
         │ Modes:              │    │ • Freight            │
         │ - Basic routing     │    │                      │
         │ - Canary subsets    │    │ Integrates with:     │
         │                     │    │ - ArgoCD             │
         │ Gateway:            │    │ - Git repos          │
         │ istio-system/       │    │                      │
         │ main-gateway        │    │                      │
         │                     │    │                      │
         └─────────────────────┘    └──────────────────────┘
```

## Component Relationships

### Deployment Flow

```
User runs helm install
       │
       ▼
Chart.yaml reads dependencies
       │
       ├─────────────────┬─────────────────┐
       ▼                 ▼                 ▼
Main Chart      istio-routing      kargo-config
(always)        (if enabled)       (if enabled)
       │                 │                 │
       ▼                 ▼                 ▼
Creates:         Creates:          Creates:
- Rollout        - VirtualService  - Stage (dev)
- Service        - DestinationRule - Stage (staging)
- ServiceAccount                   - Stage (prod)
```

### Traffic Routing Integration

```
                    Istio Gateway
                  (main-gateway)
                         │
                         ▼
              ┌──────────────────────┐
              │   VirtualService      │
              │  (istio-routing)     │
              │                      │
              │  Path: /myapp        │
              └──────────┬───────────┘
                         │
           ┌─────────────┴─────────────┐
           │                           │
    Basic Mode                  Canary Mode
           │                           │
           ▼                           ▼
    ┌──────────┐         ┌──────────────────────┐
    │ Service  │         │  DestinationRule     │
    │          │         │                      │
    │ 100%     │         │  Subsets:           │
    │ traffic  │         │  - stable (100%)    │
    └──────────┘         │  - canary (0%)      │
                         │                      │
                         │  Controlled by:     │
                         │  Argo Rollouts      │
                         └─────────────────────┘
```

### Kargo Promotion Flow

```
                  Git Repository
                         │
                         ▼
                  Kargo Warehouse
                   (monitors)
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
   Stage: dev      Stage: staging    Stage: prod
   namespace: dev  namespace: staging namespace: prod
        │                │                │
        │                │                │
        ▼                ▼                ▼
   ArgoCD App      ArgoCD App        ArgoCD App
   myapp-dev       myapp-staging     myapp-prod
        │                │                │
        ▼                ▼                ▼
   helm install    helm install      helm install
   (auto sync)     (auto sync)       (auto sync)
```

## Usage Patterns

### Pattern 1: Simple Deployment
```yaml
# Minimal configuration
istio-routing:
  enabled: true
  ingress:
    path: /app

kargo-config:
  enabled: false
```

**Result**: Core app + Istio routing

### Pattern 2: Progressive Delivery
```yaml
# Canary deployments
rollout:
  enabled: true
  strategy:
    type: canary

istio-routing:
  enabled: true
  trafficRouting:
    enabled: true  # Enables DestinationRule subsets

kargo-config:
  enabled: false
```

**Result**: Core app + Istio canary routing + Argo Rollouts

### Pattern 3: Full GitOps
```yaml
# Multi-stage with Kargo
rollout:
  enabled: true

istio-routing:
  enabled: true
  trafficRouting:
    enabled: true

kargo-config:
  enabled: true
  project:
    name: myproject
  stages:
    - name: dev
    - name: staging
    - name: prod
```

**Result**: Complete pipeline with automated promotions

### Pattern 4: Subchart Isolation
```yaml
# Disable all subcharts
istio-routing:
  enabled: false

kargo-config:
  enabled: false
```

**Result**: Vanilla Kubernetes deployment (no service mesh)

## File Organization

```
helm-charts/app-template/
│
├── Chart.yaml                    # Main chart metadata + dependencies
├── values.yaml                   # Default values (main + subcharts)
├── values-examples.yaml          # Usage examples
├── README.md                     # Documentation
│
├── templates/                    # Main chart templates
│   ├── _helpers.tpl             # Template functions
│   ├── rollout.yaml             # Argo Rollout or Deployment
│   ├── service.yaml             # Kubernetes Service
│   └── serviceaccount.yaml      # Service Account
│
└── charts/                       # Subcharts directory
    │
    ├── istio-routing/           # Istio subchart
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   └── templates/
    │       ├── _helpers.tpl
    │       └── virtualservice.yaml  # VirtualService + DestinationRule
    │
    └── kargo-config/            # Kargo subchart
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── _helpers.tpl
            └── stages.yaml      # Kargo Stages
```

## Value Override Hierarchy

```
1. Command line --set flags
   helm install --set image.tag=v2

2. Values files (-f)
   helm install -f custom-values.yaml

3. Subchart values in main values.yaml
   istio-routing:
     ingress:
       path: /custom

4. Subchart default values
   charts/istio-routing/values.yaml

5. Main chart defaults
   values.yaml (root level)
```

## Benefits of Modular Structure

✅ **Separation of Concerns**
- Application logic separate from routing
- Infrastructure (Istio) separate from app
- GitOps config (Kargo) as optional layer

✅ **Reusability**
- Subcharts can be used independently
- Easy to extract and share subcharts
- Compose different combinations

✅ **Maintainability**
- Each chart has focused responsibility
- Easier to test individual components
- Clear upgrade paths per component

✅ **Flexibility**
- Enable/disable features via conditions
- Mix and match subcharts
- Add new subcharts without breaking existing

✅ **Version Control**
- Each subchart has independent version
- Main chart version tracks overall changes
- Clear dependency management

## Migration from v1.0.0

**Old structure (monolithic):**
```yaml
# Single values.yaml with everything
ingress:
  enabled: true
  path: /app

rollout:
  strategy:
    canary:
      trafficRouting:
        istio:
          enabled: true
```

**New structure (modular):**
```yaml
# Main chart handles app
rollout:
  enabled: true

# Subchart handles routing
istio-routing:
  enabled: true
  ingress:
    path: /app
  trafficRouting:
    enabled: true
```

**Breaking Changes:**
- `ingress.*` moved to `istio-routing.ingress.*`
- `rollout.strategy.canary.trafficRouting.istio.enabled` → `istio-routing.trafficRouting.enabled`
- `kargo.*` moved to `kargo-config.*`

**Migration Command:**
```bash
# Old deployment
helm upgrade myapp ./helm-charts/app-template \
  --set ingress.path=/myapp

# New deployment
helm upgrade myapp ./helm-charts/app-template \
  --set istio-routing.ingress.path=/myapp
```
