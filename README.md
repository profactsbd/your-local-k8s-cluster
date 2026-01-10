# My Local Kubernetes Cluster

A local Kubernetes learning environment using **kind** (Kubernetes in Docker) with automated installation of GitOps and service mesh tools.

## 🏗️ Architecture

- **Cluster Runtime**: kind (Kubernetes in Docker)
- **Service Mesh**: Istio
- **GitOps**: ArgoCD
- **Progressive Delivery**: Argo Rollouts
- **Multi-Stage Deployments**: Kargo
- **Cluster UI**: Kubernetes Dashboard

## 📋 Prerequisites

- Docker Desktop (with Kubernetes enabled)
- kubectl CLI
- kind CLI
- helm CLI (for Kargo installation)
- **Windows**: PowerShell 7+
- **Linux/macOS**: Bash, jq
- make (optional, for Makefile usage - Windows: `choco install make`)

## 🚀 Quick Start

### Platform-Specific Scripts

This project includes scripts for both Windows (PowerShell) and Linux/macOS (Bash):
- **Windows**: Use scripts in `scripts/` directory (`.ps1` files)
- **Linux/macOS**: Use scripts in `scripts/linux/` directory (`.sh` files)

See [scripts/linux/README.md](scripts/linux/README.md) for Linux/macOS specific instructions.

### Option A: Using Build Script (Windows)

```powershell
# Complete setup: create cluster + install all tools
.\build.ps1 setup

# Or step by step
.\build.ps1 create-cluster
.\build.ps1 install          # Interactive mode
.\build.ps1 verify           # Check everything is running
```

### Option B: Using Makefile (Cross-Platform)

```bash
make setup               # Complete setup
make verify              # Verify installation
```

### Option C: Using Scripts Directly

#### Windows PowerShell

##### 1. Create the kind Cluster

```powershell
kind create cluster --name my-local-cluster
```

##### 2. Install All Tools (Interactive)

```powershell
.\scripts\install-all.ps1
```

This will install all components one by one with prompts. To skip prompts:

```powershell
.\scripts\install-all.ps1 -NonInteractive
```

##### 3. Install Individual Tools

```powershell
# Install Istio
.\scripts\install-istio.ps1

# Install ArgoCD
.\scripts\install-argocd.ps1

# Install Argo Rollouts
.\scripts\install-argo-rollouts.ps1

# Install Kargo
.\scripts\install-kargo.ps1

# Install Kubernetes Dashboard
.\scripts\install-dashboard.ps1
```

#### Linux/macOS Bash

##### 1. Create the kind Cluster

```bash
kind create cluster --name my-local-cluster
```

##### 2. Make Scripts Executable

```bash
chmod +x scripts/linux/*.sh
```

##### 3. Install All Tools

```bash
# Interactive installation
./scripts/linux/install-all.sh

# Non-interactive (CI/CD friendly)
./scripts/linux/install-all.sh --non-interactive
```

##### 4. Install Individual Tools

```bash
# Install Istio
./scripts/linux/install-istio.sh

# Install ArgoCD
./scripts/linux/install-argocd.sh

# Install Argo Rollouts
./scripts/linux/install-argo-rollouts.sh

# Install Kargo
./scripts/linux/install-kargo.sh

# Install Kubernetes Dashboard
./scripts/linux/install-dashboard.sh
```

## 🔍 Verify Installation

```powershell
.\build.ps1 verify
# or
.\build.ps1 status
# or
.\scripts\verify-cluster.ps1
```

## 🌐 Access UIs

### Kubernetes Dashboard
```powershell
kubectl proxy
# Navigate to: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
# Token in: .\credentials\dashboard-token.txt

# Or use port-forward:
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443
# Navigate to: https://localhost:8443
```

### ArgoCD
```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Navigate to: https://localhost:8080
# Credentials in: .\credentials\argocd-credentials.txt
```

### Kargo
```powershell
kubectl port-forward svc/kargo-api -n kargo 8081:80
# Navigate to: http://localhost:8081
```

### Argo Rollouts Dashboard
```powershell
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe dashboard
```

## 📁 Project Structure

```
my-local-cluster/
├── scripts/                           # Installation automation
│   ├── install-all.ps1               # Master installation script
│   ├── install-istio.ps1             # Istio installation
│   ├── install-argocd.ps1            # ArgoCD installation
│   ├── install-argo-rollouts.ps1     # Argo Rollouts installation
│   ├── install-kargo.ps1             # Kargo installation
│   ├── install-dashboard.ps1         # Kubernetes Dashboard installation
│   ├── create-service-account.ps1    # Service account creator with RBAC
│   ├── generate-dashboard-token.ps1  # Dashboard token regenerator
│   ├── verify-cluster.ps1            # Check cluster status
│   └── uninstall-all.ps1             # Remove all components
├── manifests/                         # Kubernetes manifests (to be created)
├── tools/                             # Downloaded CLI tools (gitignored)
├── credentials/                       # Generated credentials (gitignored)
└── .github/
    └── copilot-instructions.md        # AI coding agent guidelines
```

## 🧹 Cleanup

### Using Build Script (Recommended)
```powershell
.\build.ps1 uninstall        # Remove all tools (keep cluster)
.\build.ps1 delete-cluster   # Delete the kind cluster
.\build.ps1 clean            # Remove tools/ and credentials/ directories
.\build.ps1 teardown         # Complete teardown (all of the above)
```

### Using Makefile
```bash
make uninstall           # Remove all tools (keep cluster)
make delete-cluster      # Delete the kind cluster
make clean               # Remove tools/ and credentials/ directories
make teardown            # Complete teardown (all of the above)
```

### Using Scripts Directly
```powershell
.\scripts\uninstall-all.ps1           # Remove all tools (keep cluster)
kind delete cluster --name my-local-cluster  # Delete the cluster
```

## 📚 Learning Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Argo Rollouts Documentation](https://argoproj.github.io/rollouts/)
- [Kargo Documentation](https://kargo.io/)

## 🔐 Service Account Management

### Create Custom Service Accounts
```powershell
# Create a service account with view permissions
.\scripts\create-service-account.ps1 -ServiceAccountName "my-viewer" -Role "view"

# Create a service account with admin permissions in specific namespace
.\scripts\create-service-account.ps1 -ServiceAccountName "my-admin" -Namespace "my-namespace" -Role "admin"

# Create a service account with cluster-admin (full access)
.\scripts\create-service-account.ps1 -ServiceAccountName "my-cluster-admin" -Role "cluster-admin"
```

### Regenerate Dashboard Token
```powershell
# Get a fresh token for the dashboard admin user
.\scripts\generate-dashboard-token.ps1

# Get token for a different service account
.\scripts\generate-dashboard-token.ps1 -ServiceAccount "custom-sa" -Namespace "default"
```

## 🎯 Next Steps

1. Access the Kubernetes Dashboard to visualize your cluster
2. Deploy sample applications to test Istio service mesh
3. Set up GitOps workflows with ArgoCD
4. Experiment with canary deployments using Argo Rollouts
5. Create multi-stage promotion pipelines with Kargo
