# 🚀 Application Deployment Stack - Complete Setup

Your local Kubernetes cluster now has a full GitOps and progressive delivery stack ready for deploying applications!

## ✅ What's Installed

### Core Tools
- ✅ **cert-manager** v1.14.0 - Certificate management
- ✅ **Istio** v1.23.2 - Service mesh with ingress gateway
- ✅ **ArgoCD** - GitOps continuous deployment
- ✅ **Argo Rollouts** v1.7.2 - Progressive delivery (canary/blue-green)
- ✅ **Kargo** v1.8.4 - Multi-stage deployment promotions
- ✅ **Kubernetes Dashboard** - Cluster management UI

### Infrastructure Components
- ✅ **SSL Certificates** - Self-signed (local) or Let's Encrypt support
- ✅ **Istio Gateway** - HTTPS ingress with automatic HTTP redirect
- ✅ **Path-based Routing** - All tools accessible via single gateway
- ✅ **Auto Certificate Rotation** - cert-manager renews certs automatically

## 🌐 Access Your Tools

### Method 1: Individual Port-Forwards (Traditional)
```powershell
.\build.ps1 dashboard        # Kubernetes Dashboard
.\build.ps1 argocd-ui        # ArgoCD
.\build.ps1 kargo-ui         # Kargo
.\build.ps1 rollouts-ui      # Argo Rollouts
```

### Method 2: Unified Gateway Access (Recommended)
```powershell
# Expose the Istio gateway
.\build.ps1 expose-gateway

# Then access all tools through one gateway:
# - ArgoCD:    https://localhost:8443/argocd
# - Kargo:     https://localhost:8443/kargo
# - Dashboard: https://localhost:8443/dashboard
# - Rollouts:  https://localhost:8443/rollouts
```

**Note**: You'll see a certificate warning (self-signed cert). This is expected for local development.

## 📦 Deploy Applications

### Quick Deploy with Helm Chart

The [helm-charts/app-template](helm-charts/app-template/) provides:
- ✅ Argo Rollouts integration (canary/blue-green)
- ✅ Istio VirtualService and DestinationRule
- ✅ Automatic sidecar injection
- ✅ Configurable resources, probes, scaling
- ✅ Environment variables and secrets

**Example deployment:**
```powershell
# Deploy nginx with canary rollout
helm install myapp ./helm-charts/app-template --set image.repository=nginx --set image.tag=1.25-alpine --set ingress.path=/myapp

# Access at: https://localhost:8443/myapp
```

### GitOps with ArgoCD

See [manifests/examples/argocd-application.yaml](manifests/examples/argocd-application.yaml) for:
- Automatic sync from Git
- Progressive rollouts
- Self-healing
- Pruning old resources

### Multi-Stage with Kargo

See [manifests/examples/kargo-project.yaml](manifests/examples/kargo-project.yaml) for:
- Dev → Staging → Prod promotion pipeline
- Image and Git tracking
- Manual or auto-promotion
- ArgoCD integration

## 📖 Documentation

- **[Deployment Guide](docs/deployment-guide.md)** - Complete application deployment walkthrough
- **[Dashboard Guide](docs/dashboard-guide.md)** - Kubernetes Dashboard usage
- **[Copilot Instructions](.github/copilot-instructions.md)** - AI agent guidelines

## 🔐 SSL Certificates

### Current Setup: Self-Signed (Local Development)
- Certificate: `local-cluster-tls` in `istio-system` namespace
- Valid for: `*.local-cluster.local`, `localhost`
- Auto-renews: 15 days before expiry (75 days into 90-day validity)

### For Production: Let's Encrypt

1. **Edit** [manifests/infrastructure/cert-issuers.yaml](manifests/infrastructure/cert-issuers.yaml):
   - Update email address

2. **Edit** [manifests/infrastructure/cluster-certificate.yaml](manifests/infrastructure/cluster-certificate.yaml):
   - Change issuer to `letsencrypt-staging` (testing) or `letsencrypt-prod`
   - Update DNS names to your domain

3. **Reapply**:
   ```powershell
   kubectl apply -f .\manifests\infrastructure\cluster-certificate.yaml
   ```

4. **Monitor**:
   ```powershell
   kubectl get certificate -n istio-system -w
   kubectl describe certificate local-cluster-tls -n istio-system
   ```

## 🎯 Progressive Delivery Workflows

### Canary Deployment
1. Deploy v1 of your app
2. Update to v2 (new image tag)
3. Argo Rollouts automatically:
   - Creates canary pods
   - Routes 25% → 50% → 75% → 100% of traffic
   - Pauses between steps
   - Monitors metrics
   - Rolls back on failure

### Blue-Green Deployment
1. Deploy "blue" version (active)
2. Deploy "green" version (preview)
3. Test green version
4. Manually promote green to active
5. Blue becomes preview

### Multi-Stage Promotion (Kargo)
1. Commit code to Git
2. Image built and pushed
3. Kargo detects new freight
4. Auto-promotes to dev
5. Manual promotion to staging (after testing)
6. Manual promotion to prod (after approval)

## 🛠️ Quick Commands

```powershell
# Setup complete cluster
.\build.ps1 setup                    # Create + install + verify

# Setup infrastructure
.\build.ps1 setup-infrastructure     # SSL + Gateway + Routing

# Verify installation
.\build.ps1 verify                   # Check all components

# Access tools
.\build.ps1 expose-gateway           # All tools via https://localhost:8443/*

# Deploy app
helm install myapp ./helm-charts/app-template -f my-values.yaml

# Manage rollouts
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe get rollout myapp
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe promote myapp
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe abort myapp

# Check certificates
kubectl get certificates -A
kubectl get clusterissuers
```

## 🔍 Troubleshooting

### Certificate Not Ready
```powershell
kubectl describe certificate local-cluster-tls -n istio-system
kubectl logs -n cert-manager -l app=cert-manager
```

### Gateway Not Accessible
```powershell
kubectl get gateway -n istio-system
kubectl get virtualservices -A
kubectl logs -n istio-system -l app=istio-ingressgateway
```

### Application Not Routing
```powershell
# Check VirtualService
kubectl get virtualservice myapp -o yaml

# Check DestinationRule
kubectl get destinationrule myapp -o yaml

# Check Rollout status
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe get rollout myapp
```

## 📚 Next Steps

1. **Deploy a sample app** using the Helm chart
2. **Configure ArgoCD** to watch your Git repo
3. **Setup Kargo project** for multi-stage promotions
4. **Experiment with canary** deployments
5. **Switch to Let's Encrypt** when ready for real domains

Happy deploying! 🎉
