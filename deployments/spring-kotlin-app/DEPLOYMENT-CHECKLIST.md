# Pre-Deployment Checklist

## Prerequisites Verification

### ✅ Cluster Requirements
- [ ] Kubernetes cluster is running
  ```powershell
  kubectl cluster-info
  ```

### ✅ Istio Installation
- [ ] Istio is installed
  ```powershell
  kubectl get deployment -n istio-system
  # Should show: istiod, istio-ingressgateway
  ```
- [ ] Istio version 1.18+
  ```powershell
  istioctl version
  ```

### ✅ Argo Rollouts Installation
- [ ] Argo Rollouts controller is running
  ```powershell
  kubectl get deployment argo-rollouts -n argo-rollouts
  ```
- [ ] Argo Rollouts kubectl plugin is available
  ```powershell
  kubectl argo rollouts version
  # Or: .\tools\kubectl-plugins\kubectl-argo-rollouts.exe version
  ```

### ✅ Kargo Installation (Optional - for multi-environment)
- [ ] Kargo is installed
  ```powershell
  kubectl get deployment kargo-api -n kargo
  kubectl get deployment kargo-controller -n kargo
  ```

## Deployment Checklist

### Step 1: Prepare Namespace
- [ ] Create namespace
  ```powershell
  kubectl create namespace spring-kotlin-app
  ```
- [ ] Enable Istio sidecar injection
  ```powershell
  kubectl label namespace spring-kotlin-app istio-injection=enabled
  ```
- [ ] Verify label
  ```powershell
  kubectl get namespace spring-kotlin-app --show-labels
  # Should show: istio-injection=enabled
  ```

### Step 2: Review Configuration
- [ ] Review `values-spring-kotlin-app.yaml`
- [ ] Verify image tag: `nijogeorgep/spring-kotlin-app:2c5c983`
- [ ] Check resource requests/limits are appropriate
- [ ] Review canary step timings
- [ ] Verify Spring Boot actuator paths:
  - `/actuator/health/liveness`
  - `/actuator/health/readiness`

### Step 3: Deploy Application
- [ ] Navigate to chart directory
  ```powershell
  cd D:\Learnings\kubernetes\my-local-cluster\helm-charts\app-template
  ```
- [ ] Run Helm install
  ```powershell
  helm install spring-kotlin-app . -f values-spring-kotlin-app.yaml -n spring-kotlin-app
  ```
- [ ] Verify installation
  ```powershell
  helm list -n spring-kotlin-app
  ```

### Step 4: Verify Deployment
- [ ] Check Rollout status
  ```powershell
  kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app
  ```
- [ ] Verify all pods are running
  ```powershell
  kubectl get pods -n spring-kotlin-app
  # Should show 3 pods with 2/2 containers (app + istio-proxy)
  ```
- [ ] Check pod logs for startup errors
  ```powershell
  kubectl logs -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app -c spring-kotlin-app --tail=50
  ```
- [ ] Verify Istio sidecar injection
  ```powershell
  kubectl get pod -n spring-kotlin-app -o jsonpath='{.items[0].spec.containers[*].name}'
  # Should show: spring-kotlin-app istio-proxy
  ```

### Step 5: Verify Services
- [ ] Check Service is created
  ```powershell
  kubectl get svc spring-kotlin-app -n spring-kotlin-app
  ```
- [ ] Verify Istio resources
  ```powershell
  kubectl get virtualservice,destinationrule,peerauthentication -n spring-kotlin-app
  ```

### Step 6: Test Application
- [ ] Port forward to service
  ```powershell
  kubectl port-forward svc/spring-kotlin-app 8080:80 -n spring-kotlin-app
  ```
- [ ] Test health endpoint
  ```powershell
  # In another terminal:
  curl http://localhost:8080/actuator/health
  # Should return: {"status":"UP"}
  ```
- [ ] Test liveness endpoint
  ```powershell
  curl http://localhost:8080/actuator/health/liveness
  ```
- [ ] Test readiness endpoint
  ```powershell
  curl http://localhost:8080/actuator/health/readiness
  ```

### Step 7: Monitor Rollout
- [ ] Watch Rollout dashboard
  ```powershell
  .\tools\kubectl-plugins\kubectl-argo-rollouts.exe dashboard
  # Open: http://localhost:3100
  ```
- [ ] Monitor canary progression
  ```powershell
  kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch
  ```

## Post-Deployment Verification

### ✅ Application Health
- [ ] All pods are in Running state
- [ ] All containers show 2/2 READY
- [ ] Liveness probe is passing
- [ ] Readiness probe is passing
- [ ] No crash loops in pod logs

### ✅ Istio Configuration
- [ ] VirtualService is created
- [ ] DestinationRule is created with stable/canary subsets
- [ ] PeerAuthentication is enforcing mTLS
- [ ] No Istio configuration errors
  ```powershell
  istioctl analyze -n spring-kotlin-app
  ```

### ✅ Traffic Management
- [ ] Traffic is flowing through Istio ingress gateway
- [ ] Canary weights are being applied correctly
- [ ] Circuit breaker is configured
- [ ] Retry policy is active
- [ ] CORS headers are present (if testing from browser)

### ✅ Monitoring
- [ ] Prometheus metrics are being scraped
  ```powershell
  kubectl port-forward svc/spring-kotlin-app 8080:80 -n spring-kotlin-app
  curl http://localhost:8080/actuator/prometheus
  # Should return metrics in Prometheus format
  ```
- [ ] Istio metrics are available in Prometheus
- [ ] Application appears in Kiali dashboard

## Troubleshooting Checklist

### If Pods Don't Start
- [ ] Check image pull policy and registry access
  ```powershell
  kubectl describe pod <pod-name> -n spring-kotlin-app
  ```
- [ ] Verify resource requests can be satisfied
  ```powershell
  kubectl describe nodes
  ```
- [ ] Check pod events
  ```powershell
  kubectl get events -n spring-kotlin-app --sort-by='.lastTimestamp'
  ```

### If Health Checks Fail
- [ ] Verify actuator endpoints are correct
- [ ] Check if Spring Boot is running on port 8080
- [ ] Review application logs for startup errors
- [ ] Increase initialDelaySeconds if app takes longer to start

### If Istio Sidecar Not Injected
- [ ] Verify namespace has `istio-injection=enabled` label
- [ ] Delete and recreate pods
  ```powershell
  kubectl delete pods -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app
  ```
- [ ] Check Istio version compatibility

### If Rollout Stuck
- [ ] Check Rollout events
  ```powershell
  kubectl describe rollout spring-kotlin-app -n spring-kotlin-app
  ```
- [ ] Manually promote if paused
  ```powershell
  kubectl argo rollouts promote spring-kotlin-app -n spring-kotlin-app
  ```
- [ ] Check if VirtualService exists (required for Istio traffic routing)

## Optional: Multi-Environment Setup

### Kargo Multi-Environment
- [ ] Create environment namespaces
  ```powershell
  kubectl create namespace spring-kotlin-app-dev
  kubectl create namespace spring-kotlin-app-staging
  kubectl create namespace spring-kotlin-app-prod
  kubectl create namespace kargo-project-spring-kotlin-app
  ```
- [ ] Enable Istio injection for all environments
  ```powershell
  kubectl label namespace spring-kotlin-app-dev istio-injection=enabled
  kubectl label namespace spring-kotlin-app-staging istio-injection=enabled
  kubectl label namespace spring-kotlin-app-prod istio-injection=enabled
  ```
- [ ] Verify Kargo stages are created
  ```powershell
  kubectl get stages -n kargo-project-spring-kotlin-app
  ```
- [ ] Access Kargo UI
  ```powershell
  kubectl port-forward svc/kargo-api 8081:80 -n kargo
  # Open: http://localhost:8081
  ```

## Success Criteria

✅ **Deployment is successful when:**
- All 3 pods are running with 2/2 containers ready
- Health endpoints return HTTP 200
- VirtualService and DestinationRule are configured
- mTLS is enforced (PeerAuthentication)
- Canary rollout progresses through all steps
- Application is accessible via Service
- No errors in pod logs
- Istio configuration analysis shows no issues

## Next Steps After Successful Deployment

1. **Test Canary Deployment**: Deploy a new version to see canary in action
2. **Configure Monitoring**: Set up Grafana dashboards
3. **Set up Alerts**: Configure alerts for deployment failures
4. **Load Testing**: Test application under load during canary
5. **Documentation**: Document any environment-specific configurations
6. **Backup**: Take etcd snapshots for disaster recovery

## Quick Reference Commands

```powershell
# Check everything
kubectl get all,vs,dr,pa -n spring-kotlin-app

# Watch rollout
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch

# Access application
kubectl port-forward svc/spring-kotlin-app 8080:80 -n spring-kotlin-app

# View logs
kubectl logs -f -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app -c spring-kotlin-app

# Promote canary
kubectl argo rollouts promote spring-kotlin-app -n spring-kotlin-app

# Rollback
kubectl argo rollouts abort spring-kotlin-app -n spring-kotlin-app

# Uninstall
helm uninstall spring-kotlin-app -n spring-kotlin-app
```
