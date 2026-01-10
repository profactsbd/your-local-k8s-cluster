# Linux/macOS Scripts

Bash versions of all PowerShell scripts for Linux and macOS users.

## Prerequisites

- `kubectl` installed and in PATH
- `helm` installed (required for Kargo)
- `jq` installed (for verify-cluster.sh)
- Active Kubernetes cluster (kind, minikube, etc.)

## Making Scripts Executable

```bash
chmod +x *.sh
```

## Usage

### Complete Setup

```bash
# Interactive installation of all components
./install-all.sh

# Non-interactive installation (CI/CD friendly)
./install-all.sh --non-interactive

# Skip specific components
./install-all.sh --skip-istio --skip-kargo
```

### Individual Component Installation

```bash
./install-cert-manager.sh    # Install cert-manager
./install-istio.sh           # Install Istio service mesh
./install-argocd.sh          # Install ArgoCD
./install-argo-rollouts.sh   # Install Argo Rollouts
./install-kargo.sh           # Install Kargo (requires Helm)
./install-dashboard.sh       # Install Kubernetes Dashboard
```

### Infrastructure Setup

```bash
./setup-infrastructure.sh    # Apply cert-issuers, gateways, etc.
```

### Verification

```bash
./verify-cluster.sh          # Check cluster status and components
```

### Service Account Management

```bash
# Create service account with view role
./create-service-account.sh --name my-sa --role view

# Create with admin role in specific namespace
./create-service-account.sh --name admin-sa --namespace my-app --role admin

# Create with custom cluster role
./create-service-account.sh --name custom-sa --role custom --custom-role my-custom-role

# Generate/regenerate dashboard token
./generate-dashboard-token.sh
```

### Cleanup

```bash
# Uninstall all components (prompts for confirmation)
./uninstall-all.sh

# Force uninstall without confirmation
./uninstall-all.sh --force
```

## Accessing UIs

### Kubernetes Dashboard
```bash
kubectl proxy
# Open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
# Token: ./credentials/service-accounts/admin-user-kubernetes-dashboard.txt
```

### ArgoCD
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
# Credentials: ./credentials/argocd-credentials.txt
```

### Kargo
```bash
kubectl port-forward svc/kargo-api -n kargo 8081:443
# Open: http://localhost:8081
# Credentials: ./credentials/kargo-credentials.txt
```

### Argo Rollouts Dashboard
```bash
./tools/kubectl-plugins/kubectl-argo-rollouts dashboard
```

## Script Features

All scripts include:
- ✅ Idempotency checks (safe to re-run)
- ✅ Colored output for better readability
- ✅ Automatic credential saving to `./credentials/`
- ✅ Wait for pod readiness before completion
- ✅ Error handling and status reporting

## Platform-Specific Notes

### Linux
- Uses `curl` for downloads
- Uses `xclip` for clipboard (optional, install with `apt-get install xclip` or `yum install xclip`)
- Detects architecture: amd64, arm64

### macOS
- Uses `curl` for downloads
- Uses `pbcopy` for clipboard (built-in)
- Detects architecture: amd64 (Intel), arm64 (Apple Silicon)

## Differences from PowerShell Scripts

- Uses `bash` instead of `pwsh`
- Uses ANSI escape codes for colors instead of PowerShell color parameters
- Uses `base64 -d` instead of PowerShell Base64 conversion
- Uses `jq` for JSON parsing instead of PowerShell ConvertFrom-Json
- Uses `xclip`/`pbcopy` for clipboard instead of Set-Clipboard

## Troubleshooting

### Permission Denied
```bash
chmod +x <script-name>.sh
```

### Command Not Found: jq
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# RHEL/CentOS
sudo yum install jq
```

### Command Not Found: helm
Install from: https://helm.sh/docs/intro/install/

## Integration with Makefile

These scripts can be called from the root Makefile if desired:

```makefile
install-istio:
	@bash scripts/linux/install-istio.sh

install-argocd:
	@bash scripts/linux/install-argocd.sh
```

## Script Compatibility

All scripts are compatible with:
- ✅ Linux (amd64, arm64)
- ✅ macOS (Intel, Apple Silicon)
- ✅ WSL2 (Windows Subsystem for Linux)
- ✅ CI/CD environments (GitHub Actions, GitLab CI, etc.)
