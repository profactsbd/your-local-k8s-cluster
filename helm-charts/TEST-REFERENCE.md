# 🧪 Helm Test Quick Reference

## Quick Start

```bash
# 1. Deploy
helm install myapp ./helm-charts/app-template --wait

# 2. Test
helm test myapp --logs

# 3. Cleanup
helm delete myapp
```

## Test Files Overview

### Main Chart (app-template)
| Test | File | Purpose |
|------|------|---------|
| Connection | `test-connection.yaml` | wget service endpoint |
| Rollout | `test-rollout.yaml` | Check rollout health |
| Service | `test-service.yaml` | Verify endpoints exist |

### Istio Routing Subchart
| Test | File | Purpose |
|------|------|---------|
| VirtualService | `test-virtualservice.yaml` | Validate path routing |
| DestinationRule | `test-destinationrule.yaml` | Check canary subsets |

### Kargo Config Subchart
| Test | File | Purpose |
|------|------|---------|
| Stages | `test-stages.yaml` | Verify stage resources |

## Common Commands

```bash
# Run all tests with output
helm test myapp --logs

# Keep test pods for debugging
helm test myapp --logs --timeout 10m

# List test pods
kubectl get pods -l "helm.sh/hook=test"

# Check specific test
kubectl logs myapp-app-template-test-connection

# Delete test pods manually
kubectl delete pods -l "helm.sh/hook=test"

# Re-run tests
kubectl delete pods -l "helm.sh/hook=test"
helm test myapp --logs
```

## Test Scenarios

### Basic Web App
```bash
helm install webapp ./helm-charts/app-template \
  --set image.repository=nginx \
  --wait

helm test webapp --logs
```
**Tests**: 4 (connection, rollout, service, virtualservice)

### Canary Deployment
```bash
helm install api ./helm-charts/app-template \
  --set istio-routing.trafficRouting.enabled=true \
  --wait

helm test api --logs
```
**Tests**: 5 (adds destinationrule test)

### With Kargo
```bash
helm install myapp ./helm-charts/app-template \
  --set kargo-config.enabled=true \
  --wait

helm test myapp --logs
```
**Tests**: 7+ (adds stage tests per environment)

## Expected Output

### ✅ Success
```
NAME: myapp
LAST DEPLOYED: [timestamp]
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE:     myapp-app-template-test-connection
Last Started:   [timestamp]
Last Completed: [timestamp]
Phase:          Succeeded

TEST SUITE:     myapp-app-template-test-rollout
Last Started:   [timestamp]
Last Completed: [timestamp]
Phase:          Succeeded

TEST SUITE:     myapp-app-template-test-service
Last Started:   [timestamp]
Last Completed: [timestamp]
Phase:          Succeeded
```

### ❌ Failure
```
Phase: Failed

POD LOGS: myapp-app-template-test-connection
Error: wget: can't connect to remote host (10.96.1.1:80): Connection refused
```

**Action**: Check pod status and logs
```bash
kubectl get pods
kubectl logs -l app.kubernetes.io/instance=myapp
```

## Debugging Tests

### View Test Manifest
```bash
helm template myapp ./helm-charts/app-template | grep -A 30 "helm.sh/hook.*test"
```

### Manual Test Pod
```bash
kubectl run manual-test \
  --image=busybox \
  --restart=Never \
  --command -- wget myapp-app-template:80

kubectl logs manual-test
kubectl delete pod manual-test
```

### Check RBAC
```bash
# Test pods create ServiceAccounts
kubectl get sa -l "helm.sh/hook=test"
kubectl get role,rolebinding -l "helm.sh/hook=test"
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Test deployment
  run: |
    helm install test-app ./helm-charts/app-template --wait
    helm test test-app --logs
```

### GitLab CI
```yaml
test:
  script:
    - helm install myapp ./helm-charts/app-template --wait
    - helm test myapp --logs
```

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| Connection refused | Pods not ready | Wait longer, check pod status |
| Rollout not healthy | Deployment issue | Check rollout events |
| VirtualService not found | Istio not enabled | Set `istio-routing.enabled=true` |
| Permission denied | RBAC issue | Tests create own ServiceAccounts |
| Stage not found | Wrong namespace | Check Kargo namespace config |

## Test Coverage

✅ **Main Chart**: 3 tests  
✅ **Istio Routing**: 2 tests  
✅ **Kargo Config**: 1 test per stage  

**Total**: 5-8 tests depending on configuration

## Best Practices

✅ Always use `--wait` flag when installing  
✅ Run tests after every deployment  
✅ Use `--logs` to see detailed output  
✅ Clean up test pods between runs  
✅ Integrate into CI/CD pipeline  

## Documentation

📖 Full guide: [TESTING.md](TESTING.md)  
📖 Chart docs: [app-template/README.md](app-template/README.md)  
📖 Examples: [app-template/values-examples.yaml](app-template/values-examples.yaml)
