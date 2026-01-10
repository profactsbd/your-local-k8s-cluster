# Copilot Instructions - My Local Cluster

## Project Overview
Local Kubernetes learning environment using **kind** with automated installation of GitOps and service mesh tools: Istio, ArgoCD, Argo Rollouts, Kargo, and Kubernetes Dashboard.

## Architecture
- **Cluster**: kind (Kubernetes in Docker Desktop)
- **Service Mesh**: Istio (demo profile, sidecar injection enabled)
- **GitOps**: ArgoCD
- **Progressive Delivery**: Argo Rollouts
- **Multi-Stage Deployments**: Kargo
- **Cluster UI**: Kubernetes Dashboard

## Critical Workflows

### Using Makefile (Preferred Method)
```bash
make help             # Show all available targets
make setup            # Complete setup: create cluster + install all tools + verify
make verify           # Verify cluster status and components
make install          # Interactive installation of all components
make install-quiet    # Non-interactive installation
make teardown         # Complete cleanup: uninstall + delete cluster + clean files
```

### Installation Automation (PowerShell Scripts)
All installation scripts are in `scripts/` using PowerShell:

```powershell
# Install everything interactively (recommended for first-time setup)
.\scripts\install-all.ps1

# Non-interactive installation (CI/CD friendly)
.\scripts\install-all.ps1 -NonInteractive

# Install individual components
.\scripts\install-istio.ps1          # Downloads istioctl, installs Istio demo profile
.\scripts\install-argocd.ps1         # Saves admin password to credentials/
.\scripts\install-argo-rollouts.ps1  # Downloads kubectl plugin to tools/
.\scripts\install-kargo.ps1          # Uses Helm
.\scripts\install-dashboard.ps1      # Creates admin service account, saves token

# Service account management
.\scripts\create-service-account.ps1 -ServiceAccountName "my-sa" -Role "view"
.\scripts\generate-dashboard-token.ps1  # Regenerate dashboard token

# Verify what's installed
.\scripts\verify-cluster.ps1

# Clean up (keeps cluster)
.\scripts\uninstall-all.ps1
```

### Tool Access Patterns

**Kubernetes Dashboard**: kubectl proxy or port-forward
```powershell
kubectl proxy
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
# Token: credentials/dashboard-token.txt
```

**ArgoCD UI**: Port-forward required
```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
# Credentials: credentials/argocd-credentials.txt
```

**Kargo UI**: Port-forward required
```powershell
kubectl port-forward svc/kargo-api -n kargo 8081:80
# http://localhost:8081
```

**Argo Rollouts Dashboard**: Uses local plugin
```powershell
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe dashboard
```

## Project Conventions

### Directory Structure
- `scripts/` - PowerShell automation for tool installation/management
- `manifests/` - Kubernetes resource definitions (create as needed)
- `tools/` - Auto-downloaded CLIs (istioctl, kubectl plugins) - gitignored
- `kubernetes-dashboard` - Dashboard UI and metrics scraper
- `credentials/` - Generated secrets (ArgoCD passwords) - gitignored

### Namespace Organization
- `istio-system` - Istio control plane and gateways
- `argocd` - ArgoCD components
- `argo-rollouts` - Rollouts controller
- `kargo` - Kargo API and controllers
- `default` - Labeled with `istio-injection=enabled` for automatic sidecar injection

### Installation Script Pattern
Each `install-*.ps1` script follows a consistent pattern:
1. **Check if already installed** - Detect existing installations, show status, exit early if found
2. **Download tools** - Download required CLIs to `tools/` directory (Istio, Argo Rollouts plugins)
3. **Create namespace** - Use `--dry-run=client -o yaml | kubectl apply -f -` for idempotency
4. **Install components** - Apply manifests or use Helm (Kargo uses Helm, others use kubectl)
5. **Wait for readiness** - `kubectl wait --for=condition=Ready pods --all -n <namespace> --timeout=300s`
6. **Extract/save credentials** - Save passwords/tokens to `credentials/` directory
7. **Output access instructions** - Show port-forward commands and access URLs

Example idempotency check from [install-istio.ps1](scripts/install-istio.ps1#L14-L33):
```powershell
$istioNamespace = kubectl get namespace istio-system --ignore-not-found=true 2>$null
if ($istioNamespace) {
    Write-Host "✓ Istio is already installed" -ForegroundColor Green
    # Check running status and exit
    exit 0
}
```

### Service Account Scripts
- [create-service-account.ps1](scripts/create-service-account.ps1) - Creates service accounts with configurable RBAC roles (view, edit, admin, cluster-admin)
- [generate-dashboard-token.ps1](scripts/generate-dashboard-token.ps1) - Retrieves or creates tokens for dashboard access
- All tokens saved to `credentials/` directory (gitignored)
- Can be run independently or via [install-all.ps1](scripts/install-all.ps1)

### Makefile Targets
The [Makefile](Makefile) provides convenient shortcuts for common workflows:
- `make setup` - Complete end-to-end setup (create cluster → install → verify)
- `make verify` / `make status` - Run verification script
- `make install-{istio,argocd,rollouts,kargo,dashboard}` - Install individual components
- `make {dashboard,argocd-ui,kargo-ui,rollouts-ui}` - Launch UI access helpers
- `make teardown` - Complete cleanup (uninstall → delete cluster → clean files)

## Key Integration Points

### Istio + Applications
The default namespace has sidecar injection enabled. Any pod deployed to `default` automatically gets an Envoy proxy.

### ArgoCD + Git
- ArgoCD watches Git repositories for manifest changes
- Initial admin password auto-generated and saved
- Use `argocd` CLI or UI for repository/application management

### Argo Rollouts + Istio
Argo Rollouts can use Istio VirtualServices for traffic splitting in canary deployments. Reference pattern:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      trafficRouting:
        istio:
          virtualService:
            name: <service-name>
```

### Kargo Stages
Kargo orchestrates promotions across environments. Typical flow: dev → staging → prod stages defined in Kargo resources.

## Common Troubleshooting

### Tool Not Ready
All install scripts use `kubectl wait` with 300s timeout. If pods aren't ready:
```powershell
kubectl get pods -n <namespace> -w  # Watch pod status
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Already Installed Detection
Scripts detect existing installations and exit gracefully. To force reinstall:
```powershell
# Uninstall first, then reinstall
.\scripts\uninstall-all.ps1
.\scripts\install-all.ps1 -Interactive:$false
```

### Port-Forward Connection Issues
kind cluster uses localhost. If port-forwards fail:
```powershell
kubectl cluster-info  # Verify cluster connectivity
kubectl get svc -n <namespace>  # Verify service exists
netstat -ano | findstr :<port>  # Check if port is already in use
```

### Helm Not Found (Kargo)
Kargo installation requires Helm. Install from: https://helm.sh/docs/intro/install/

### Credentials Location
All auto-generated credentials are saved to `credentials/` directory:
- `argocd-credentials.txt` - ArgoCD username/password and port-forward command
- `dashboard-token.txt` - Kubernetes Dashboard bearer token
- `service-accounts/` - Custom service account tokens by name and namespace

## Learning Resources
- Istio demo profile includes istio-ingressgateway for external traffic
- ArgoCD Application CRDs define sync policies
- Argo Rollouts supports BlueGreen and Canary strategies
- Kargo Freight represents promotable artifacts across stages
