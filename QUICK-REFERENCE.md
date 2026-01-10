# 🎯 Quick Reference Card

## Infrastructure Commands
```powershell
.\build.ps1 setup                    # Complete setup (cluster + tools + infrastructure)
.\build.ps1 setup-infrastructure     # Setup SSL certificates and Istio gateway
.\build.ps1 verify                   # Check all components status
.\build.ps1 expose-gateway           # Expose Istio gateway on https://localhost:8443
```

## Helm Chart Build & Verification
```powershell
.\build.ps1 helm-verify              # Quick verification (lint + template)
.\build.ps1 helm-build               # Full build (deps + verify + package)
.\build.ps1 helm-test                # Run Helm tests on deployed release
.\build.ps1 helm-lint                # Lint charts for syntax errors
.\build.ps1 helm-template            # Test template rendering
.\build.ps1 helm-package             # Package charts to .tgz
```

## Access URLs (via Gateway)
| Tool | URL | Credentials |
|------|-----|-------------|
| ArgoCD | https://localhost:8443/argocd | `credentials/argocd-credentials.txt` |
| Kargo | https://localhost:8443/kargo | `credentials/kargo-credentials.txt` |
| Kubernetes Dashboard | https://localhost:8443/dashboard | `credentials/dashboard-token.txt` |
| Argo Rollouts | https://localhost:8443/rollouts | N/A |

## Deploy Application
```powershell
# Using Helm Chart
helm install myapp ./helm-charts/app-template \
  --set image.repository=nginx \
  --set image.tag=1.25-alpine \
  --set ingress.path=/myapp

# Access: https://localhost:8443/myapp
```

## Manage Rollouts
```powershell
# Get rollout status
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe get rollout myapp

# Watch rollout progress
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe get rollout myapp --watch

# Promote canary
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe promote myapp

# Abort rollout
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe abort myapp
```

## Check Certificates
```powershell
kubectl get certificates -n istio-system
kubectl describe certificate local-cluster-tls -n istio-system
```

## Troubleshooting
```powershell
# Check gateway
kubectl get gateway -n istio-system

# Check routing
kubectl get virtualservices -A

# Check cert-manager
kubectl logs -n cert-manager -l app=cert-manager

# Check Istio ingress
kubectl logs -n istio-system -l app=istio-ingressgateway
```

## File Locations
- **Helm Chart**: `helm-charts/app-template/`
- **Infrastructure**: `manifests/infrastructure/`
- **Examples**: `manifests/examples/`
- **Credentials**: `credentials/`
- **Scripts**: `scripts/`

## Documentation
- **Complete Guide**: [README-DEPLOYMENT-STACK.md](README-DEPLOYMENT-STACK.md)
- **Deployment Details**: [docs/deployment-guide.md](docs/deployment-guide.md)
- **Dashboard Guide**: [docs/dashboard-guide.md](docs/dashboard-guide.md)
