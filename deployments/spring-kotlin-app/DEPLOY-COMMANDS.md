# Quick Deployment Commands for Spring Kotlin App
# Copy and paste these commands to deploy the application

# =============================================================================
# STEP 1: CREATE NAMESPACE
# =============================================================================
kubectl create namespace spring-kotlin-app

# Enable Istio sidecar injection
kubectl label namespace spring-kotlin-app istio-injection=enabled

# Verify namespace
kubectl get namespace spring-kotlin-app --show-labels

# =============================================================================
# STEP 2: DEPLOY APPLICATION
# =============================================================================
# Navigate to chart directory (if not already there)
cd D:\Learnings\kubernetes\my-local-cluster\helm-charts\app-template

# Install the application with Argo Rollouts, Istio, and Kargo
helm install spring-kotlin-app . -f values-spring-kotlin-app.yaml -n spring-kotlin-app

# =============================================================================
# STEP 3: VERIFY DEPLOYMENT
# =============================================================================
# Check Rollout status
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app

# Watch Rollout progress (use Ctrl+C to exit)
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch

# Check pods (should see 2 containers: app + istio-proxy)
kubectl get pods -n spring-kotlin-app

# Check all resources
kubectl get all,virtualservice,destinationrule,peerauthentication -n spring-kotlin-app

# =============================================================================
# STEP 4: ACCESS APPLICATION
# =============================================================================
# Port forward to service (local testing)
kubectl port-forward svc/spring-kotlin-app 8080:80 -n spring-kotlin-app

# In another terminal, test the application:
# curl http://localhost:8080/actuator/health
# curl http://localhost:8080/actuator/info

# =============================================================================
# STEP 5: MONITOR CANARY DEPLOYMENT
# =============================================================================
# Watch the canary rollout progress
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch

# Launch Argo Rollouts dashboard
.\tools\kubectl-plugins\kubectl-argo-rollouts.exe dashboard
# Open browser: http://localhost:3100

# =============================================================================
# OPTIONAL: MANUAL PROMOTION
# =============================================================================
# Promote to next canary step
kubectl argo rollouts promote spring-kotlin-app -n spring-kotlin-app

# Complete rollout (skip all pauses)
kubectl argo rollouts promote spring-kotlin-app -n spring-kotlin-app --full

# =============================================================================
# OPTIONAL: ROLLBACK
# =============================================================================
# Abort and rollback to stable version
kubectl argo rollouts abort spring-kotlin-app -n spring-kotlin-app

# =============================================================================
# OPTIONAL: KARGO MULTI-ENVIRONMENT SETUP
# =============================================================================
# Create namespaces for dev, staging, prod
kubectl create namespace spring-kotlin-app-dev
kubectl create namespace spring-kotlin-app-staging
kubectl create namespace spring-kotlin-app-prod
kubectl create namespace kargo-project-spring-kotlin-app

# Enable Istio injection for all environments
kubectl label namespace spring-kotlin-app-dev istio-injection=enabled
kubectl label namespace spring-kotlin-app-staging istio-injection=enabled
kubectl label namespace spring-kotlin-app-prod istio-injection=enabled

# Access Kargo UI
kubectl port-forward svc/kargo-api 8081:80 -n kargo
# Open browser: http://localhost:8081

# =============================================================================
# OPTIONAL: ISTIO MONITORING
# =============================================================================
# Install Istio observability addons (if not already installed)
kubectl apply -f D:\Learnings\kubernetes\my-local-cluster\tools\istio-1.24.0\samples\addons\

# Access Kiali (Service Mesh Dashboard)
kubectl port-forward svc/kiali 20001:20001 -n istio-system
# Open browser: http://localhost:20001

# Access Grafana (Metrics Dashboard)
kubectl port-forward svc/grafana 3000:3000 -n istio-system
# Open browser: http://localhost:3000

# Access Prometheus (Metrics)
kubectl port-forward svc/prometheus 9090:9090 -n istio-system
# Open browser: http://localhost:9090

# =============================================================================
# UPDATE APPLICATION
# =============================================================================
# Deploy new version (example: tag abc123)
helm upgrade spring-kotlin-app . -f values-spring-kotlin-app.yaml --set argo-rollouts.image.tag=abc123 -n spring-kotlin-app

# Watch the canary rollout
kubectl argo rollouts get rollout spring-kotlin-app -n spring-kotlin-app --watch

# =============================================================================
# CLEANUP
# =============================================================================
# Uninstall application
helm uninstall spring-kotlin-app -n spring-kotlin-app

# Delete namespace
kubectl delete namespace spring-kotlin-app

# Delete Kargo namespaces (if created)
kubectl delete namespace spring-kotlin-app-dev spring-kotlin-app-staging spring-kotlin-app-prod kargo-project-spring-kotlin-app

# =============================================================================
# USEFUL TROUBLESHOOTING COMMANDS
# =============================================================================
# View Rollout events
kubectl describe rollout spring-kotlin-app -n spring-kotlin-app

# View pod logs (application)
kubectl logs -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app -c spring-kotlin-app

# View pod logs (Istio sidecar)
kubectl logs -l app.kubernetes.io/name=spring-kotlin-app -n spring-kotlin-app -c istio-proxy

# Check VirtualService traffic weights
kubectl get virtualservice spring-kotlin-app -n spring-kotlin-app -o jsonpath='{.spec.http[0].route}' | ConvertFrom-Json | ConvertTo-Json

# Check Istio configuration
istioctl analyze -n spring-kotlin-app

# Check proxy status
istioctl proxy-status

# View all events
kubectl get events -n spring-kotlin-app --sort-by='.lastTimestamp'
