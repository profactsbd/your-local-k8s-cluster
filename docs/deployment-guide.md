# Application Deployment Guide

Complete guide for deploying applications to the local Kubernetes cluster using ArgoCD, Argo Rollouts, Kargo, and Istio.

## 🏗️ Architecture Overview

- **Helm Chart**: Generic template for any application ([helm-charts/app-template](../helm-charts/app-template/))
- **ArgoCD**: GitOps continuous deployment
- **Argo Rollouts**: Progressive delivery (canary/blue-green)
- **Kargo**: Multi-stage promotions (dev → staging → prod)
- **Istio**: Service mesh with path-based routing
- **cert-manager**: SSL certificate management with Let's Encrypt
- **Automatic certificate rotation**: cert-manager handles renewal before expiry

## 🚀 Quick Start

### 1. Setup Infrastructure

```powershell
# Apply all infrastructure components
.\scripts\setup-infrastructure.ps1

# Or apply individually
kubectl apply -f .\manifests\infrastructure\cert-issuers.yaml
kubectl apply -f .\manifests\infrastructure\cluster-certificate.yaml
kubectl apply -f .\manifests\infrastructure\istio-gateway.yaml
kubectl apply -f .\manifests\infrastructure\tools-routing.yaml
```

### 2. Expose the Istio Gateway

```powershell
# Port-forward the Istio ingress gateway
kubectl port-forward -n istio-system svc/istio-ingressgateway 8443:443 8080:80
```

### 3. Access Tools via HTTPS

All tools are now accessible through path-based routing:

- **ArgoCD**: https://localhost:8443/argocd
- **Kargo**: https://localhost:8443/kargo
- **Kubernetes Dashboard**: https://localhost:8443/dashboard
- **Argo Rollouts**: https://localhost:8443/rollouts

Credentials are in `./credentials/` directory.

## 📦 Deploy Your First Application

### Using the Helm Chart Template

1. **Create a values file** for your application:

```yaml
# my-app-values.yaml
image:
  repository: myregistry/myapp
  tag: "v1.0.0"

ingress:
  enabled: true
  path: /myapp

rollout:
  enabled: true
  replicas: 3
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 25
        - pause: {duration: 1m}
        - setWeight: 50
        - pause: {duration: 1m}
        - setWeight: 75
        - pause: {duration: 1m}
      trafficRouting:
        istio:
          enabled: true

service:
  port: 80
  targetPort: 8080

env:
  - name: ENV_NAME
    value: "production"
```

2. **Deploy using Helm**:

```powershell
helm install myapp ./helm-charts/app-template -f my-app-values.yaml
```

3. **Access your app**:
   - URL: https://localhost:8443/myapp

### Using ArgoCD (GitOps)

1. **Create an ArgoCD Application**:

```yaml
# my-argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: HEAD
    path: helm-charts/app-template
    helm:
      values: |
        image:
          repository: myregistry/myapp
          tag: "v1.0.0"
        ingress:
          path: /myapp
        rollout:
          enabled: true
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

2. **Apply the Application**:

```powershell
kubectl apply -f my-argocd-app.yaml
```

3. **Monitor in ArgoCD UI**: https://localhost:8443/argocd

## 🎯 Multi-Stage Deployments with Kargo

### Setup Kargo Project

1. **Create a Kargo namespace**:

```powershell
kubectl create namespace myapp
```

2. **Apply Kargo manifests** (see [manifests/examples/kargo-project.yaml](../manifests/examples/kargo-project.yaml)):

```powershell
kubectl apply -f .\manifests\examples\kargo-project.yaml
```

3. **Promote through stages**:
   - **Dev**: Auto-promotes from warehouse
   - **Staging**: Manual promotion from dev
   - **Prod**: Manual promotion from staging

4. **Monitor in Kargo UI**: https://localhost:8443/kargo

## 🔐 SSL Certificate Management

### Self-Signed Certificates (Local Development)

Default configuration uses self-signed certificates:

```yaml
issuerRef:
  name: selfsigned-issuer
  kind: ClusterIssuer
```

### Let's Encrypt Staging (Testing)

For testing with real Let's Encrypt:

1. **Update email** in [cert-issuers.yaml](../manifests/infrastructure/cert-issuers.yaml)
2. **Change issuer** in [cluster-certificate.yaml](../manifests/infrastructure/cluster-certificate.yaml):

```yaml
issuerRef:
  name: letsencrypt-staging
  kind: ClusterIssuer
```

3. **Update DNS names** to your actual domain:

```yaml
dnsNames:
  - "your-domain.com"
  - "*.your-domain.com"
```

### Let's Encrypt Production

After testing with staging:

```yaml
issuerRef:
  name: letsencrypt-prod
  kind: ClusterIssuer
```

### Automatic Certificate Rotation

cert-manager automatically renews certificates:

```yaml
duration: 2160h # 90 days
renewBefore: 360h # Renews 15 days before expiry
```

Monitor certificate status:

```powershell
kubectl get certificates -n istio-system
kubectl describe certificate local-cluster-tls -n istio-system
```

## 🔄 Canary Deployments with Argo Rollouts

The Helm chart supports canary deployments with Istio traffic routing:

1. **Update your application** (new image tag)
2. **Argo Rollouts automatically**:
   - Creates canary pods
   - Gradually shifts traffic (25% → 50% → 75% → 100%)
   - Pauses between steps
   - Rolls back on failure

3. **Monitor rollout**:

```powershell
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe get rollout myapp
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe dashboard
```

Or via UI: https://localhost:8443/rollouts

### Manual Promotion

```powershell
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe promote myapp
```

### Abort Rollout

```powershell
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe abort myapp
```

## 📊 Monitoring Deployments

### ArgoCD
```powershell
# List all applications
kubectl get applications -n argocd

# Check sync status
kubectl get application myapp -n argocd -o yaml
```

### Argo Rollouts
```powershell
# Get rollout status
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe status myapp

# Watch rollout progress
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe get rollout myapp --watch
```

### Kargo
```powershell
# List stages
kubectl get stages -n myapp

# List freight
kubectl get freight -n myapp
```

## 🛠️ Helm Chart Customization

The [app-template](../helm-charts/app-template/) chart supports:

- **Deployment types**: Rollout (canary/blue-green) or standard Deployment
- **Istio integration**: Automatic VirtualService and DestinationRule
- **ConfigMaps and Secrets**: Application configuration
- **Resource limits**: CPU and memory
- **Health checks**: Liveness and readiness probes
- **Autoscaling**: Horizontal Pod Autoscaler
- **Service Account**: RBAC configuration

See [values.yaml](../helm-charts/app-template/values.yaml) for all options.

## 🔍 Troubleshooting

### Certificate Issues

```powershell
# Check certificate status
kubectl get certificate -n istio-system
kubectl describe certificate local-cluster-tls -n istio-system

# Check certificate secret
kubectl get secret local-cluster-tls -n istio-system

# View cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Istio Gateway Issues

```powershell
# Check gateway status
kubectl get gateway -n istio-system

# Check VirtualServices
kubectl get virtualservices -A

# View ingress gateway logs
kubectl logs -n istio-system -l app=istio-ingressgateway
```

### Rollout Issues

```powershell
# Get rollout details
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe get rollout myapp

# View rollout events
kubectl describe rollout myapp
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Argo Rollouts Documentation](https://argoproj.github.io/rollouts/)
- [Kargo Documentation](https://docs.kargo.io/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
