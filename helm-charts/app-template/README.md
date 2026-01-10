# App Template - Modular Helm Chart

A modular Helm chart for deploying applications on Kubernetes with GitOps, progressive delivery, and service mesh capabilities.

## Architecture

The chart is split into multiple modules:

### Main Chart: `app-template`
Core application resources including:
- **Rollout/Deployment**: Argo Rollouts or standard Kubernetes Deployment
- **Service**: ClusterIP service for pod access
- **ServiceAccount**: Optional service account with configurable RBAC

### Subchart: `istio-routing`
Istio service mesh routing components:
- **VirtualService**: Path-based routing and traffic splitting
- **DestinationRule**: Traffic subsets for canary deployments
- Supports both standard routing and canary traffic management

### Subchart: `kargo-config`
Kargo multi-stage deployment configuration:
- **Stages**: dev → staging → prod promotion pipeline
- **Warehouse**: Optional freight source configuration
- Integrates with ArgoCD for automated promotions

## Usage

### Basic Deployment
```bash
helm install myapp ./helm-charts/app-template \
  --set image.repository=nginx \
  --set image.tag=1.25-alpine \
  --set istio-routing.ingress.path=/myapp
```

Access: `https://localhost:8443/myapp`

### Enable Canary Deployments
```bash
helm install myapp ./helm-charts/app-template \
  --set image.repository=myapp \
  --set image.tag=v1.0.0 \
  --set rollout.enabled=true \
  --set rollout.strategy.type=canary \
  --set istio-routing.trafficRouting.enabled=true \
  --set istio-routing.ingress.path=/myapp
```

### Enable Kargo Multi-Stage Deployments
```bash
helm install myapp ./helm-charts/app-template \
  --set image.repository=myapp \
  --set image.tag=v1.0.0 \
  --set kargo-config.enabled=true \
  --set kargo-config.project.name=myapp
```

### Disable Subcharts
```bash
# Deploy only core application without Istio or Kargo
helm install myapp ./helm-charts/app-template \
  --set istio-routing.enabled=false \
  --set kargo-config.enabled=false
```

## Configuration

### Main Chart Values
| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `nginx` |
| `image.tag` | Container image tag | `1.25-alpine` |
| `rollout.enabled` | Use Argo Rollouts instead of Deployment | `true` |
| `rollout.replicas` | Number of pod replicas | `2` |
| `rollout.strategy.type` | Deployment strategy (canary/blueGreen) | `canary` |
| `service.port` | Service port | `80` |
| `resources.limits.cpu` | CPU limit | `100m` |
| `resources.limits.memory` | Memory limit | `128Mi` |

### Istio Routing Subchart
| Parameter | Description | Default |
|-----------|-------------|---------|
| `istio-routing.enabled` | Enable Istio routing subchart | `true` |
| `istio-routing.ingress.enabled` | Create VirtualService | `true` |
| `istio-routing.ingress.path` | URL path for routing | `/myapp` |
| `istio-routing.ingress.gateway` | Istio Gateway reference | `istio-system/main-gateway` |
| `istio-routing.trafficRouting.enabled` | Enable canary traffic splitting | `false` |

### Kargo Config Subchart
| Parameter | Description | Default |
|-----------|-------------|---------|
| `kargo-config.enabled` | Enable Kargo stages | `false` |
| `kargo-config.project.name` | Kargo project name | `default` |
| `kargo-config.stages` | List of deployment stages | See values.yaml |

## Directory Structure
```
app-template/
├── Chart.yaml              # Main chart metadata with dependencies
├── values.yaml             # Default values for all charts
├── templates/              # Main chart templates
│   ├── rollout.yaml       # Argo Rollout or Deployment
│   ├── service.yaml       # Kubernetes Service
│   ├── serviceaccount.yaml
│   └── _helpers.tpl
└── charts/                 # Subcharts
    ├── istio-routing/      # Istio subchart
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   └── templates/
    │       ├── virtualservice.yaml
    │       └── _helpers.tpl
    └── kargo-config/       # Kargo subchart
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── stages.yaml
            └── _helpers.tpl
```

## Chart Dependencies

Dependencies are defined in `Chart.yaml`:
```yaml
dependencies:
  - name: istio-routing
    version: 1.0.0
    repository: "file://./charts/istio-routing"
    condition: istio-routing.enabled
  - name: kargo-config
    version: 1.0.0
    repository: "file://./charts/kargo-config"
    condition: kargo-config.enabled
```

To update dependencies:
```bash
cd helm-charts/app-template
helm dependency update
```

## Examples

### Example 1: Simple Web Application
```bash
helm install web-app ./helm-charts/app-template \
  --set image.repository=nginx \
  --set image.tag=alpine \
  --set istio-routing.ingress.path=/web \
  --set kargo-config.enabled=false
```

### Example 2: Canary Deployment with Istio
```bash
helm install api-service ./helm-charts/app-template \
  --set image.repository=myapi \
  --set image.tag=v2.0.0 \
  --set rollout.enabled=true \
  --set istio-routing.trafficRouting.enabled=true \
  --set istio-routing.ingress.path=/api
```

### Example 3: Full GitOps with Kargo
```bash
helm install production-app ./helm-charts/app-template \
  --set image.repository=myapp \
  --set kargo-config.enabled=true \
  --set kargo-config.project.name=production \
  --set istio-routing.ingress.path=/app
```

## Upgrading

### Update Main Chart
```bash
helm upgrade myapp ./helm-charts/app-template \
  --set image.tag=v2.0.0
```

### Enable/Disable Subcharts
```bash
# Enable Kargo after initial deployment
helm upgrade myapp ./helm-charts/app-template \
  --reuse-values \
  --set kargo-config.enabled=true
```

## Testing

Automated tests verify your deployment is working correctly:

```bash
# Deploy and run tests
helm install myapp ./helm-charts/app-template --wait
helm test myapp --logs
```

**Available Tests**:
- **test-connection** - Verifies service is reachable
- **test-rollout** - Checks Argo Rollout health
- **test-service** - Validates service endpoints
- **test-virtualservice** - Verifies Istio routing (if enabled)
- **test-destinationrule** - Validates canary subsets (if enabled)
- **test-stages** - Checks Kargo stages (if enabled)

For detailed testing guide, see [../TESTING.md](../TESTING.md).

## Troubleshooting

### Check Installed Charts
```bash
helm list
helm get values myapp
```

### Verify Subchart Resources
```bash
# Check Istio resources
kubectl get virtualservices
kubectl get destinationrules

# Check Kargo resources
kubectl get stages -n kargo
```

### Run Tests
```bash
# Validate deployment
helm test myapp --logs

# Check individual test
kubectl logs myapp-app-template-test-connection
```

### Template Debugging
```bash
# Render templates without installing
helm template myapp ./helm-charts/app-template \
  --set image.repository=nginx

# Debug with verbose output
helm install myapp ./helm-charts/app-template --debug --dry-run
```

## Integration with ArgoCD

Create an ArgoCD Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/yourrepo
    targetRevision: main
    path: helm-charts/app-template
    helm:
      values: |
        image:
          repository: myapp
          tag: v1.0.0
        istio-routing:
          ingress:
            path: /myapp
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Version History

- **v2.0.0**: Modular architecture with subcharts
- **v1.0.0**: Monolithic chart with all components

## Contributing

To add new subcharts:
1. Create directory: `charts/<subchart-name>/`
2. Add Chart.yaml, values.yaml, templates/
3. Update main Chart.yaml dependencies
4. Run `helm dependency update`
