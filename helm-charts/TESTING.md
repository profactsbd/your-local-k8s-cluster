# Helm Chart Testing Guide

## Overview

All charts include automated tests that can be run using `helm test` command. These tests verify that deployed resources are configured correctly and functioning as expected.

## Test Structure

### Main Chart (app-template)
- **test-connection.yaml** - Verifies service connectivity using wget
- **test-rollout.yaml** - Checks Argo Rollout health status
- **test-service.yaml** - Validates Service existence and endpoints

### Istio Routing Subchart
- **test-virtualservice.yaml** - Verifies VirtualService configuration
- **test-destinationrule.yaml** - Validates canary subsets (when enabled)

### Kargo Config Subchart
- **test-stages.yaml** - Checks Kargo Stage resources per environment

## Running Tests

### Basic Usage

```bash
# Deploy the chart
helm install myapp ./helm-charts/app-template

# Run all tests
helm test myapp

# View test pod logs
kubectl logs myapp-app-template-test-connection
kubectl logs myapp-app-template-test-rollout
kubectl logs myapp-app-template-test-service
```

### Test with Verbose Output

```bash
# Run tests with detailed output
helm test myapp --logs

# Run tests and keep test pods for debugging
helm test myapp --logs --timeout 5m
```

### Test Individual Components

```bash
# Test only main chart (exclude subcharts)
helm test myapp

# Check specific test pod
kubectl get pod -l "helm.sh/hook=test"
kubectl describe pod myapp-app-template-test-connection
```

## Test Scenarios

### Scenario 1: Basic Deployment Test
```bash
# Deploy simple web app
helm install webapp ./helm-charts/app-template \
  --set image.repository=nginx \
  --set image.tag=alpine \
  --set istio-routing.ingress.path=/webapp

# Wait for deployment
kubectl rollout status rollout webapp-app-template

# Run tests
helm test webapp --logs
```

**Expected Tests**:
- ✅ Service connection test
- ✅ Rollout health test
- ✅ Service endpoints test
- ✅ VirtualService configuration test

### Scenario 2: Canary Deployment Test
```bash
# Deploy with canary enabled
helm install api ./helm-charts/app-template \
  --set image.repository=nginx \
  --set rollout.enabled=true \
  --set istio-routing.trafficRouting.enabled=true

# Run tests
helm test api --logs
```

**Expected Tests**:
- ✅ Service connection test
- ✅ Rollout health test
- ✅ Service endpoints test
- ✅ VirtualService configuration test
- ✅ DestinationRule subsets test (stable + canary)

### Scenario 3: Kargo Multi-Stage Test
```bash
# Deploy with Kargo enabled
helm install myapp ./helm-charts/app-template \
  --set kargo-config.enabled=true \
  --set kargo-config.project.name=myproject

# Run tests
helm test myapp --logs
```

**Expected Tests**:
- ✅ All main chart tests
- ✅ Kargo Stage 'dev' existence test
- ✅ Kargo Stage 'staging' existence test
- ✅ Kargo Stage 'prod' existence test

## Test Details

### Main Chart Tests

#### test-connection.yaml
**Purpose**: Verify the application service is reachable

**How it works**:
- Creates a test pod with busybox
- Attempts to wget the service endpoint
- Succeeds if connection is established

**Example output**:
```
Connecting to myapp-app-template:80
saving to 'index.html'
index.html 100% |********************************| 615 0:00:00 ETA
'index.html' saved
```

#### test-rollout.yaml
**Purpose**: Validate Argo Rollout status

**How it works**:
- Creates test pod with kubectl
- Queries rollout status via Kubernetes API
- Checks if status is "Healthy" or "Progressing"
- Creates temporary ServiceAccount with RBAC permissions

**Example output**:
```
Testing Rollout status...
Healthy
✓ Rollout is healthy
```

#### test-service.yaml
**Purpose**: Ensure Service has active endpoints

**How it works**:
- Checks if Service resource exists
- Queries Service endpoints
- Reports endpoint IP addresses

**Example output**:
```
Testing Service existence...
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
myapp-app-template   ClusterIP   10.96.152.123   <none>        80/TCP    2m
✓ Service exists
Testing Service endpoints...
✓ Service has endpoints: 10.244.0.5 10.244.0.6
```

### Istio Routing Tests

#### test-virtualservice.yaml
**Purpose**: Verify VirtualService configuration

**How it works**:
- Checks VirtualService resource exists
- Validates path matching configuration
- Confirms gateway reference

**Example output**:
```
Testing VirtualService existence...
NAME                   GATEWAYS                       HOSTS   AGE
myapp-istio-routing   [istio-system/main-gateway]   [*]     3m
✓ VirtualService exists
Checking VirtualService configuration...
✓ VirtualService path configured correctly: /myapp
✓ VirtualService gateway: istio-system/main-gateway
```

#### test-destinationrule.yaml
**Purpose**: Validate canary deployment subsets

**How it works**:
- Only runs when `istio-routing.trafficRouting.enabled: true`
- Checks DestinationRule exists
- Validates 'stable' and 'canary' subsets are defined

**Example output**:
```
Testing DestinationRule existence...
NAME                  HOST                   AGE
myapp-istio-routing  myapp-istio-routing    4m
✓ DestinationRule exists
Checking DestinationRule subsets...
Found subsets: stable canary
✓ 'stable' subset configured
✓ 'canary' subset configured
✓ DestinationRule configured correctly for canary deployment
```

### Kargo Config Tests

#### test-stages.yaml
**Purpose**: Verify Kargo Stages are created

**How it works**:
- Creates one test pod per configured stage
- Checks each Stage resource exists
- Validates promotion mechanisms are configured
- Uses ClusterRole for cross-namespace access

**Example output** (per stage):
```
Testing Kargo Stage: dev...
NAME   AGE
dev    5m
✓ Stage 'dev' exists
Checking Stage configuration...
✓ Stage name: dev
✓ Promotion mechanisms configured
```

## Troubleshooting

### Test Pod Failures

#### Check Test Pod Status
```bash
# List all test pods
kubectl get pods -l "helm.sh/hook=test"

# Check pod status
kubectl describe pod myapp-app-template-test-connection

# View pod logs
kubectl logs myapp-app-template-test-connection
```

#### Common Issues

**1. Service Connection Test Fails**
```
Error: wget: can't connect to remote host: Connection refused
```

**Solution**:
- Check if pods are running: `kubectl get pods`
- Verify service exists: `kubectl get svc`
- Check endpoints: `kubectl get endpoints`
- Wait longer for pods to start

**2. Rollout Test Fails**
```
Error: Rollout is not healthy
```

**Solution**:
- Check rollout status: `kubectl argo rollouts get rollout myapp-app-template`
- View rollout events: `kubectl describe rollout myapp-app-template`
- Check pod logs: `kubectl logs -l app.kubernetes.io/name=app-template`

**3. VirtualService Test Fails**
```
Error: VirtualService not found
```

**Solution**:
- Verify Istio is installed: `kubectl get ns istio-system`
- Check if istio-routing is enabled: `helm get values myapp`
- Verify CRDs: `kubectl get crd virtualservices.networking.istio.io`

**4. RBAC Permission Denied**
```
Error: forbidden: User "system:serviceaccount:default:myapp-test" cannot get resource "rollouts"
```

**Solution**:
- Tests create their own ServiceAccounts and RBAC
- Ensure the test hooks have time to create resources
- Check if Role/RoleBinding exists: `kubectl get role,rolebinding -l helm.sh/hook=test`

### Debugging Tests

#### Manual Test Execution
```bash
# Extract test manifest
helm template myapp ./helm-charts/app-template > /tmp/manifests.yaml
grep -A 50 "helm.sh/hook.*test" /tmp/manifests.yaml

# Apply test pod manually
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: manual-test
spec:
  containers:
  - name: wget
    image: busybox:latest
    command: ['wget', 'myapp-app-template:80']
  restartPolicy: Never
EOF

# Check results
kubectl logs manual-test
```

#### Keep Test Pods for Inspection
```bash
# Prevent automatic cleanup
kubectl annotate pod myapp-app-template-test-connection \
  "helm.sh/hook-delete-policy=hook-succeeded" --overwrite=false

# Or edit the test YAML to remove hook-delete-policy annotation
```

## Test Automation in CI/CD

### GitHub Actions Example
```yaml
name: Helm Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup kind cluster
        run: |
          kind create cluster
          
      - name: Install Istio
        run: ./scripts/install-istio.ps1
        
      - name: Deploy with Helm
        run: |
          helm install test-app ./helm-charts/app-template \
            --set image.repository=nginx \
            --wait
      
      - name: Run Helm tests
        run: helm test test-app --logs
      
      - name: Cleanup
        if: always()
        run: kind delete cluster
```

### GitLab CI Example
```yaml
helm-test:
  stage: test
  script:
    - helm install myapp ./helm-charts/app-template --wait
    - helm test myapp --logs
    - helm delete myapp
  after_script:
    - kubectl logs -l "helm.sh/hook=test" || true
```

## Best Practices

✅ **Always run tests after deployment**
```bash
helm install myapp ./helm-charts/app-template --wait
helm test myapp --logs
```

✅ **Use --wait flag to ensure pods are ready**
```bash
helm install myapp ./helm-charts/app-template --wait --timeout 5m
```

✅ **Check test logs for detailed output**
```bash
helm test myapp --logs > test-results.txt
```

✅ **Clean up test pods between runs**
```bash
kubectl delete pods -l "helm.sh/hook=test"
helm test myapp --logs
```

✅ **Test in staging before production**
```bash
# Staging
helm install myapp-staging ./helm-charts/app-template -n staging
helm test myapp-staging -n staging

# If tests pass, deploy to production
helm install myapp-prod ./helm-charts/app-template -n production
helm test myapp-prod -n production
```

## Test Coverage Summary

| Chart | Tests | Coverage |
|-------|-------|----------|
| **app-template** | 3 | Service connectivity, Rollout health, Service endpoints |
| **istio-routing** | 2 | VirtualService config, DestinationRule subsets |
| **kargo-config** | 1 per stage | Stage existence and configuration |

**Total**: 6+ test pods per deployment (varies by enabled subcharts)

## Next Steps

- Run tests after every deployment
- Integrate tests into CI/CD pipeline
- Monitor test results for deployment validation
- Extend tests for custom application health checks

For more examples, see [values-examples.yaml](../app-template/values-examples.yaml).
