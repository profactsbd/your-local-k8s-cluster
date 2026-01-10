# Spring Kotlin App Deployment Guide

This guide walks you through deploying the Spring Kotlin application (`nijogeorgep/spring-kotlin-app:2c5c983`) using Argo Rollouts, Istio, and Kargo.

## Prerequisites

Ensure you have the following installed and running in your cluster:

- **Kubernetes cluster** (kind, minikube, or cloud cluster)
- **Istio** - Service mesh for traffic management
- **Argo Rollouts** - Progressive delivery controller
- **Kargo** - Multi-environment promotion
- **ArgoCD** (optional) - GitOps continuous delivery

### Quick Setup (Local Kind Cluster)

```powershell
# Create cluster and install all tools
make setup

# Or use individual scripts
.\scripts\install-istio.ps1
.\scripts\install-argo-rollouts.ps1
.\scripts\install-kargo.ps1
```

## Deployment Steps

### 1. Review Configuration

The values file `values-spring-kotlin-app.yaml` configures:

- **Application**: `nijogeorgep/spring-kotlin-app:2c5c983`
- **Port**: 8080 (Spring Boot default)
- **Replicas**: 3 pods
- **Strategy**: Canary deployment (10% → 25% → 50% → 75% → 100%)
- **Health Checks**: Spring Boot Actuator endpoints
- **Resources**: 500m-1000m CPU, 512Mi-1Gi memory
- **Security**: Non-root user, read-only filesystem, mTLS enabled

### 2. Create Namespace and Enable Istio Injection

```powershell
# Create namespace for the application
kubectl create namespace spring-kotlin-app

# Enable Istio sidecar injection
kubectl label namespace spring-kotlin-app istio-injection=enabled

# Verify label
kubectl get namespace spring-kotlin-app --show-labels
```

### 3. Deploy with Helm

```powershell
# Navigate to chart directory
cd helm-charts/app-template

# Install the application
helm install spring-kotlin-app . -f values-spring-kotlin-app.yaml -n spring-kotlin-app

# Or upgrade if already installed
helm upgrade --install spring-kotlin-app . -f values-spring-kotlin-app.yaml -n spring-kotlin-app
```

### 4. Verify Deployment

```powershell
# Check Rollout status
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app

# Watch Rollout progress
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch

# Check pods (should see istio-proxy sidecar)
kubectl get pods -n spring-kotlin-app

# Describe pod to verify sidecar injection
kubectl describe pod -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app

# Check Service
kubectl get svc spring-kotlin-app -n spring-kotlin-app

# Check Istio VirtualService and DestinationRule
kubectl get virtualservice,destinationrule -n spring-kotlin-app
```

### 5. Access the Application

#### Option A: Port Forward (Local Testing)

```powershell
# Port forward to the service
kubectl port-forward svc/spring-kotlin-app 8080:80 -n spring-kotlin-app

# Test the application
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/info
```

#### Option B: Istio Ingress Gateway

```powershell
# Get Istio ingress gateway external IP/port
kubectl get svc istio-ingressgateway -n istio-system

# For kind/local cluster, use port-forward
kubectl port-forward svc/istio-ingressgateway 8080:80 -n istio-system

# Add to hosts file (C:\Windows\System32\drivers\etc\hosts on Windows)
127.0.0.1  spring-kotlin-app.local

# Access via hostname
curl http://spring-kotlin-app.local:8080/actuator/health
```

### 6. Monitor Rollout Progress

```powershell
# Watch Rollout progression
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch

# View Rollout events
kubectl describe rollout spring-kotlin-app -n spring-kotlin-app

# Check traffic distribution (VirtualService weights)
kubectl get virtualservice spring-kotlin-app -n spring-kotlin-app -o yaml
```

### 7. Manual Promotion (Optional)

The canary deployment has automatic pauses. To manually promote:

```powershell
# Promote to next step
kubectl argo rollouts promote spring-kotlin-app -n spring-kotlin-app

# Skip all pauses and complete rollout
kubectl argo rollouts promote spring-kotlin-app -n spring-kotlin-app --full
```

### 8. Rollback (If Needed)

```powershell
# Abort current rollout and rollback to stable
kubectl argo rollouts abort spring-kotlin-app -n spring-kotlin-app

# Check revision history
kubectl argo rollouts history rollout spring-kotlin-app -n spring-kotlin-app

# Rollback to specific revision
kubectl argo rollouts undo spring-kotlin-app -n spring-kotlin-app --to-revision=2
```

## Updating the Application

### Deploy New Version

To deploy a new image version:

```powershell
# Update image tag in values file or use --set
helm upgrade spring-kotlin-app . \
  -f values-spring-kotlin-app.yaml \
  --set argo-rollouts.image.tag=new-tag \
  -n spring-kotlin-app

# Watch the canary rollout
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch
```

### Canary Deployment Flow

1. **10% traffic** → New version gets 10% of traffic, observe for 2 minutes
2. **25% traffic** → Increase to 25%, observe for 3 minutes
3. **50% traffic** → Increase to 50%, observe for 5 minutes
4. **75% traffic** → Increase to 75%, observe for 5 minutes
5. **100% traffic** → Full rollout completed

At any step, you can:
- **Promote**: `kubectl argo rollouts promote spring-kotlin-app -n spring-kotlin-app`
- **Abort**: `kubectl argo rollouts abort spring-kotlin-app -n spring-kotlin-app`

## Multi-Environment Deployment with Kargo

### Setup Kargo Stages

If Kargo is enabled in the values file, it creates three stages:

1. **dev** - Auto-promotes from warehouse
2. **staging** - Manual promotion from dev
3. **prod** - Manual promotion from staging

### Create Namespaces for Each Stage

```powershell
# Create namespaces
kubectl create namespace spring-kotlin-app-dev
kubectl create namespace spring-kotlin-app-staging
kubectl create namespace spring-kotlin-app-prod

# Enable Istio injection
kubectl label namespace spring-kotlin-app-dev istio-injection=enabled
kubectl label namespace spring-kotlin-app-staging istio-injection=enabled
kubectl label namespace spring-kotlin-app-prod istio-injection=enabled

# Create Kargo project namespace
kubectl create namespace kargo-project-spring-kotlin-app
```

### Deploy Kargo Resources

```powershell
# Deploy with Kargo enabled
helm upgrade --install spring-kotlin-app . \
  -f values-spring-kotlin-app.yaml \
  --set kargo-config.enabled=true \
  -n spring-kotlin-app
```

### Promote Across Environments

```powershell
# View Kargo UI
kubectl port-forward svc/kargo-api 8081:80 -n kargo
# Open: http://localhost:8081

# Check Kargo stages
kubectl get stages -n kargo-project-spring-kotlin-app

# Promote from dev to staging (manual)
# Use Kargo UI or CLI to approve promotion

# Promote from staging to prod (manual)
# Use Kargo UI or CLI to approve promotion
```

## Monitoring and Observability

### Application Metrics

The deployment includes Prometheus annotations for metrics scraping:

```powershell
# Check Prometheus annotations
kubectl get pod -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app -o yaml | grep prometheus

# Access metrics endpoint (via port-forward)
kubectl port-forward svc/spring-kotlin-app 8080:80 -n spring-kotlin-app
curl http://localhost:8080/actuator/prometheus
```

### Istio Metrics

```powershell
# Install Istio addons (Prometheus, Grafana, Kiali)
kubectl apply -f tools/istio-1.24.0/samples/addons/

# Access Kiali dashboard
kubectl port-forward svc/kiali 20001:20001 -n istio-system
# Open: http://localhost:20001

# Access Grafana dashboards
kubectl port-forward svc/grafana 3000:3000 -n istio-system
# Open: http://localhost:3000

# Access Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n istio-system
# Open: http://localhost:9090
```

### Argo Rollouts Dashboard

```powershell
# Launch Argo Rollouts dashboard
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe dashboard

# Open: http://localhost:3100
```

## Troubleshooting

### Rollout Not Progressing

```powershell
# Check Rollout status
kubectl argo rollouts status spring-kotlin-app -n spring-kotlin-app

# View events
kubectl describe rollout spring-kotlin-app -n spring-kotlin-app

# Check pod logs
kubectl logs -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app -c spring-kotlin-app

# Check Istio sidecar logs
kubectl logs -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app -c istio-proxy
```

### Pods Not Starting

```powershell
# Check pod status
kubectl get pods -n spring-kotlin-app

# Describe pod
kubectl describe pod <pod-name> -n spring-kotlin-app

# Check events
kubectl get events -n spring-kotlin-app --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n spring-kotlin-app --all-containers
```

### Health Check Failures

```powershell
# Check if Spring Boot Actuator is responding
kubectl port-forward <pod-name> 8080:8080 -n spring-kotlin-app
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/health/liveness
curl http://localhost:8080/actuator/health/readiness

# If endpoints are different, update values file:
# argo-rollouts.livenessProbe.httpGet.path
# argo-rollouts.readinessProbe.httpGet.path
```

### Istio Sidecar Not Injected

```powershell
# Verify namespace has injection label
kubectl get namespace spring-kotlin-app --show-labels

# If missing, add label
kubectl label namespace spring-kotlin-app istio-injection=enabled

# Restart pods to inject sidecar
kubectl rollout restart rollout spring-kotlin-app -n spring-kotlin-app
```

### Traffic Not Routing Through Istio

```powershell
# Check VirtualService
kubectl get virtualservice spring-kotlin-app -n spring-kotlin-app -o yaml

# Check DestinationRule
kubectl get destinationrule spring-kotlin-app -n spring-kotlin-app -o yaml

# Check Istio configuration
istioctl analyze -n spring-kotlin-app

# Check Istio proxy status
istioctl proxy-status
```

## Cleanup

### Remove Application

```powershell
# Uninstall Helm release
helm uninstall spring-kotlin-app -n spring-kotlin-app

# Delete namespace
kubectl delete namespace spring-kotlin-app
```

### Remove Kargo Resources

```powershell
# Delete Kargo namespaces
kubectl delete namespace spring-kotlin-app-dev
kubectl delete namespace spring-kotlin-app-staging
kubectl delete namespace spring-kotlin-app-prod
kubectl delete namespace kargo-project-spring-kotlin-app
```

## Configuration Customization

### Change Canary Steps

Edit `values-spring-kotlin-app.yaml`:

```yaml
argo-rollouts:
  strategy:
    canary:
      steps:
        - setWeight: 20    # Changed from 10
        - pause: {duration: 1m}  # Shorter pause
        - setWeight: 100   # Skip intermediate steps
```

### Adjust Resource Limits

```yaml
argo-rollouts:
  resources:
    requests:
      cpu: 1000m        # Increased from 500m
      memory: 1Gi       # Increased from 512Mi
    limits:
      cpu: 2000m
      memory: 2Gi
```

### Change Port

```yaml
service:
  targetPort: 9090    # If Spring Boot runs on different port

argo-rollouts:
  livenessProbe:
    httpGet:
      port: 9090      # Update probe port
  readinessProbe:
    httpGet:
      port: 9090      # Update probe port
```

### Add Environment Variables

```yaml
argo-rollouts:
  env:
    - name: DATABASE_URL
      value: "jdbc:postgresql://postgres:5432/mydb"
    - name: SPRING_DATASOURCE_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
```

## Next Steps

1. **Configure Monitoring**: Set up Prometheus and Grafana for metrics
2. **Set up Logging**: Configure centralized logging (ELK, Loki)
3. **Add Analysis**: Configure Argo Rollouts analysis for automated rollback
4. **Configure Alerts**: Set up alerting for rollout failures
5. **Implement GitOps**: Connect Kargo to your Git repository
6. **Security Hardening**: Add NetworkPolicies, PodSecurityPolicies
7. **Performance Testing**: Load test during canary deployments

## Additional Resources

- **Argo Rollouts**: https://argoproj.github.io/argo-rollouts/
- **Kargo**: https://kargo.akuity.io/
- **Istio**: https://istio.io/
- **Spring Boot on Kubernetes**: https://spring.io/guides/gs/spring-boot-kubernetes/
