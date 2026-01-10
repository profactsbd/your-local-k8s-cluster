# Helm Chart Modular Structure - Summary

## ✅ Completed Refactoring

The `app-template` Helm chart has been successfully split into a modular architecture:

### Main Chart: app-template (v2.0.0)
**Location**: `helm-charts/app-template/`

**Core Components**:
- Argo Rollout or Deployment
- Kubernetes Service
- ServiceAccount

**Dependencies**: 2 optional subcharts

### Subchart 1: istio-routing (v1.0.0)
**Location**: `helm-charts/app-template/charts/istio-routing/`

**Components**:
- VirtualService (path-based routing)
- DestinationRule (canary subsets)

**Modes**:
- Basic: Simple routing to service
- Canary: Traffic splitting for progressive delivery

### Subchart 2: kargo-config (v1.0.0)
**Location**: `helm-charts/app-template/charts/kargo-config/`

**Components**:
- Kargo Stages (dev, staging, prod)
- Warehouse configuration
- ArgoCD integration

## Directory Structure

```
helm-charts/
├── ARCHITECTURE.md              # Detailed architecture diagrams
├── MIGRATION.md                 # Migration guide from v1 to v2
│
└── app-template/
    ├── Chart.yaml               # Main chart with dependencies
    ├── values.yaml              # Default values
    ├── values-examples.yaml     # 5 usage examples
    ├── README.md                # Complete documentation
    │
    ├── templates/               # Main chart templates
    │   ├── rollout.yaml
    │   ├── service.yaml
    │   ├── serviceaccount.yaml
    │   └── _helpers.tpl
    │
    └── charts/                  # Subcharts
        ├── istio-routing/
        │   ├── Chart.yaml
        │   ├── values.yaml
        │   └── templates/
        │       ├── virtualservice.yaml
        │       └── _helpers.tpl
        │
        └── kargo-config/
            ├── Chart.yaml
            ├── values.yaml
            └── templates/
                ├── stages.yaml
                └── _helpers.tpl
```

## Key Features

### 🎯 Separation of Concerns
- **Application logic** (main chart) separate from infrastructure
- **Istio routing** isolated in dedicated subchart
- **Kargo configuration** as optional GitOps layer

### 🔧 Flexibility
- Enable/disable features via subchart conditions
- Mix and match components as needed
- Independent version control per subchart

### 📦 Reusability
- Subcharts can be extracted and reused
- Clear interfaces between components
- Standard Helm dependency management

### 🚀 Easy to Extend
- Add new subcharts without breaking existing
- Clear pattern for additional modules
- Well-documented structure

## Usage Examples

### 1. Simple Web Application
```bash
helm install web-app ./helm-charts/app-template \
  --set image.repository=nginx \
  --set image.tag=alpine \
  --set istio-routing.ingress.path=/web \
  --set kargo-config.enabled=false
```

**Deploys**: App + Istio routing only

### 2. Canary Deployment
```bash
helm install api ./helm-charts/app-template \
  --set image.repository=myapi \
  --set image.tag=v2.0.0 \
  --set rollout.enabled=true \
  --set istio-routing.trafficRouting.enabled=true \
  --set istio-routing.ingress.path=/api
```

**Deploys**: App + Istio canary routing + Argo Rollouts

### 3. Full GitOps Stack
```bash
helm install production-app ./helm-charts/app-template \
  --set image.repository=myapp \
  --set istio-routing.ingress.path=/app \
  --set kargo-config.enabled=true \
  --set kargo-config.project.name=production
```

**Deploys**: App + Istio routing + Kargo stages

### 4. Minimal Deployment (No Subcharts)
```bash
helm install basic-app ./helm-charts/app-template \
  --set image.repository=nginx \
  --set istio-routing.enabled=false \
  --set kargo-config.enabled=false
```

**Deploys**: Core app only (vanilla Kubernetes)

## Value Configuration

### Enable/Disable Subcharts
```yaml
# values.yaml
istio-routing:
  enabled: true    # Set to false to skip Istio resources

kargo-config:
  enabled: false   # Set to true to enable Kargo stages
```

### Configure Istio Routing
```yaml
istio-routing:
  enabled: true
  ingress:
    path: /myapp
    pathType: Prefix
    gateway: istio-system/main-gateway
  trafficRouting:
    enabled: false  # true for canary deployments
```

### Configure Kargo Stages
```yaml
kargo-config:
  enabled: true
  project:
    name: myproject
  stages:
    - name: dev
      namespace: dev
    - name: staging
      namespace: staging
    - name: prod
      namespace: prod
```

## Documentation Files

| File | Purpose |
|------|---------|
| [README.md](app-template/README.md) | Complete usage guide |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture diagrams and patterns |
| [MIGRATION.md](MIGRATION.md) | Migration from v1.0.0 to v2.0.0 |
| [TESTING.md](TESTING.md) | Helm test guide and troubleshooting |
| [HELM-BUILD.md](HELM-BUILD.md) | Build and verification workflow |
| [values-examples.yaml](app-template/values-examples.yaml) | 5 real-world examples |

## Building and Verifying Charts

Before deploying, verify your charts:

```bash
# Quick verification (lint + template test)
make helm-verify
# or
.\build.ps1 helm-verify

# Full build (deps + verify + package)
make helm-build
# or
.\build.ps1 helm-build
```

**CI/CD Integration**: Automated verification runs on every push via GitHub Actions.

See [HELM-BUILD.md](HELM-BUILD.md) for complete build documentation.

## Testing

### Verify Chart Structure
```powershell
# Show chart structure
tree /F helm-charts\app-template

# List dependencies
helm dependency list helm-charts/app-template
```

### Template Rendering
```powershell
# Test basic rendering
helm template test ./helm-charts/app-template

# Test with custom values
helm template test ./helm-charts/app-template \
  --set image.repository=nginx \
  --set istio-routing.ingress.path=/test

# Debug mode
helm template test ./helm-charts/app-template --debug
```

### Dry Run Deployment
```powershell
# Simulate deployment
helm install test ./helm-charts/app-template --dry-run --debug

# Check what will be created
helm install test ./helm-charts/app-template --dry-run | \
  Select-String "^kind:"
```

## Dependencies Management

### Update Dependencies
```powershell
cd helm-charts/app-template
helm dependency update
```

**Creates**:
- `Chart.lock` - Locked dependency versions
- `charts/*.tgz` - Packaged subcharts

### Build Subcharts
```powershell
# Package individual subchart
helm package charts/istio-routing
helm package charts/kargo-config

# Package main chart with dependencies
helm package helm-charts/app-template
```

## Integration Points

### With Argo Rollouts
The main chart's Rollout template automatically references Istio routing when enabled:
```yaml
# In rollout.yaml
trafficRouting:
  istio:
    virtualService:
      name: {{ include "app-template.fullname" . }}
```

### With ArgoCD
Create an Application resource:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
spec:
  source:
    path: helm-charts/app-template
    helm:
      values: |
        istio-routing:
          ingress:
            path: /myapp
```

### With Kargo
Stages automatically configure ArgoCD app updates:
```yaml
# In kargo-config stages
promotionMechanisms:
  argoCDAppUpdates:
    - appName: myapp-dev
      appNamespace: argocd
```

## Benefits Summary

✅ **Modularity**: Each component is self-contained
✅ **Flexibility**: Enable only what you need
✅ **Maintainability**: Clear separation of concerns
✅ **Scalability**: Easy to add new subcharts
✅ **Testability**: Test components independently
✅ **Documentation**: Comprehensive guides and examples
✅ **Standards**: Follows Helm best practices

## Next Steps

1. **Review** [ARCHITECTURE.md](ARCHITECTURE.md) for detailed diagrams
2. **Check** [values-examples.yaml](app-template/values-examples.yaml) for configuration patterns
3. **Test** with your application using the examples above
4. **Migrate** existing deployments using [MIGRATION.md](MIGRATION.md)
5. **Extend** by adding custom subcharts as needed

## Support Files Created

- ✅ Chart.yaml with dependencies
- ✅ Updated values.yaml with subchart sections
- ✅ README.md with complete documentation
- ✅ ARCHITECTURE.md with diagrams
- ✅ MIGRATION.md for v1→v2 migration
- ✅ values-examples.yaml with 5 patterns
- ✅ Subchart templates and helpers
- ✅ Chart.lock with locked versions

All charts tested and working! 🚀
