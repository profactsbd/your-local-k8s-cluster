# Deployment and HPA Enhancement Summary

## Overview

Enhanced the Helm chart with intelligent Deployment and HPA (Horizontal Pod Autoscaler) capabilities that automatically detect Kubernetes cluster version and API specifications.

## Changes Made

### 1. Deployment Template (Main Chart)

**Created**: [templates/deployment.yaml](helm-charts/app-template/templates/deployment.yaml)

- **Location**: Moved to main chart (from argo-rollouts subchart)
- **Condition**: Only renders when `argo-rollouts.enabled: false`
- **HPA Integration**: Omits `replicas` field when `autoscaling.enabled: true`
- **Features**:
  - Uses configuration from `argo-rollouts` values section
  - Supports Istio sidecar injection
  - Standard Kubernetes Deployment resource
  - Compatible with HPA autoscaling

### 2. HPA Template with API Detection

**Created**: [templates/hpa.yaml](helm-charts/app-template/templates/hpa.yaml)

**Smart API Version Detection**:
```yaml
# Automatically detects and uses:
- autoscaling/v2        (Kubernetes 1.23+)
- autoscaling/v2beta2   (Kubernetes 1.18-1.22)
- autoscaling/v2beta1   (Kubernetes <1.18)
```

**Features**:
- ✅ Automatic API version detection using `.Capabilities.APIVersions`
- ✅ CPU utilization metrics (all versions)
- ✅ Memory utilization metrics (v2 and v2beta2)
- ✅ Custom scaling behavior (v2 and v2beta2)
- ✅ Conditional rendering (only when autoscaling enabled)
- ✅ Works only with standard Deployment (not Argo Rollouts)

### 3. HPA Test

**Created**: [templates/tests/test-hpa.yaml](helm-charts/app-template/templates/tests/test-hpa.yaml)

**Validates**:
- HPA resource exists
- Min/Max replicas configuration is valid
- RBAC permissions for autoscaling API

### 4. Enhanced Values Configuration

**Updated**: [values.yaml](helm-charts/app-template/values.yaml)

```yaml
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80  # Optional
  behavior:  # Advanced scaling policies (v2/v2beta2 only)
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

## API Version Compatibility

### autoscaling/v2 (Kubernetes 1.23+)

**Supported Features**:
- CPU and Memory metrics
- Custom scaling behavior
- Multiple metric types
- Advanced target specifications

**Example HPA Output**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
```

### autoscaling/v2beta2 (Kubernetes 1.18-1.22)

**Supported Features**:
- CPU and Memory metrics
- Custom scaling behavior
- Same structure as v2

### autoscaling/v2beta1 (Kubernetes <1.18)

**Supported Features**:
- CPU metrics only (via `targetCPUUtilizationPercentage`)
- No custom behavior
- No memory metrics

**Example HPA Output**:
```yaml
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
spec:
  targetCPUUtilizationPercentage: 80
```

## Usage Examples

### 1. Standard Deployment (No Autoscaling)

```yaml
argo-rollouts:
  enabled: false
  replicas: 3

autoscaling:
  enabled: false
```

**Result**: 
- ✅ Deployment with 3 replicas
- ❌ No HPA

### 2. Deployment with CPU Autoscaling

```yaml
argo-rollouts:
  enabled: false
  replicas: 2  # Used as initial, HPA takes over

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

**Result**:
- ✅ Deployment without replicas field
- ✅ HPA with CPU metric
- ✅ Scales 2-10 replicas based on CPU

### 3. Deployment with CPU + Memory Autoscaling

```yaml
argo-rollouts:
  enabled: false

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 75
  targetMemoryUtilizationPercentage: 80
```

**Result** (on Kubernetes 1.23+):
- ✅ Deployment without replicas field
- ✅ HPA with CPU and Memory metrics
- ✅ Scales 3-20 replicas based on both metrics

### 4. Advanced Scaling Behavior

```yaml
argo-rollouts:
  enabled: false

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 15
  targetCPUUtilizationPercentage: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5min before scaling down
      policies:
        - type: Percent
          value: 50  # Scale down max 50% at a time
          periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
        - type: Percent
          value: 100  # Double pods if needed
          periodSeconds: 15
        - type: Pods
          value: 4  # Or add 4 pods
          periodSeconds: 60
      selectPolicy: Max  # Use the more aggressive policy
```

**Result** (on Kubernetes 1.23+ with autoscaling/v2):
- ✅ Conservative scale-down (5min stabilization)
- ✅ Aggressive scale-up (immediate)
- ✅ Custom scaling rates

### 5. Argo Rollouts (No HPA)

```yaml
argo-rollouts:
  enabled: true
  replicas: 3
  strategy:
    type: canary

autoscaling:
  enabled: false  # HPA disabled when using Argo Rollouts
```

**Result**:
- ✅ Argo Rollout resource with 3 replicas
- ❌ No Deployment
- ❌ No HPA (incompatible with Rollouts)

## Architecture Decision

### Why Move Deployment to Main Chart?

1. **Separation of Concerns**:
   - **argo-rollouts subchart**: Progressive delivery strategies (Rollout resource)
   - **Main chart**: Standard deployment mechanisms (Deployment + HPA)

2. **Feature Independence**:
   - HPA is a core Kubernetes feature, not specific to Argo Rollouts
   - Standard deployments should be managed by main chart
   - Subcharts should focus on their specific domain

3. **Better User Experience**:
   - Users can enable/disable Argo Rollouts without affecting HPA
   - Clear separation between progressive delivery and autoscaling
   - Simpler mental model: main chart = standard K8s, subcharts = optional enhancements

## Compatibility Matrix

| Kubernetes Version | HPA API Version | CPU Metrics | Memory Metrics | Behavior Policies |
|-------------------|-----------------|-------------|----------------|-------------------|
| 1.25+             | autoscaling/v2  | ✅          | ✅             | ✅                |
| 1.23-1.24         | autoscaling/v2  | ✅          | ✅             | ✅                |
| 1.18-1.22         | autoscaling/v2beta2 | ✅      | ✅             | ✅                |
| 1.16-1.17         | autoscaling/v2beta1 | ✅      | ❌             | ❌                |
| <1.16             | autoscaling/v2beta1 | ✅      | ❌             | ❌                |

## Testing Validation

### Template Rendering Tests

```bash
# Test 1: Deployment without HPA
helm template test .\helm-charts\app-template\ \
  --set argo-rollouts.enabled=false \
  --set autoscaling.enabled=false

# Result: ✅ Deployment with replicas field

# Test 2: Deployment with HPA (CPU only)
helm template test .\helm-charts\app-template\ \
  --set argo-rollouts.enabled=false \
  --set autoscaling.enabled=true

# Result: ✅ Deployment without replicas + HPA with CPU metric

# Test 3: Deployment with HPA (CPU + Memory)
helm template test .\helm-charts\app-template\ \
  --set argo-rollouts.enabled=false \
  --set autoscaling.enabled=true \
  --set autoscaling.targetMemoryUtilizationPercentage=70

# Result: ✅ Deployment + HPA with CPU and Memory metrics

# Test 4: Argo Rollouts (no Deployment or HPA)
helm template test .\helm-charts\app-template\ \
  --set argo-rollouts.enabled=true

# Result: ✅ Rollout resource only, no Deployment, no HPA
```

### Helm Tests

```bash
helm install myapp ./helm-charts/app-template \
  --set argo-rollouts.enabled=false \
  --set autoscaling.enabled=true

helm test myapp

# Expected tests:
# ✅ test-connection: Service connectivity
# ✅ test-service: Service validation
# ✅ test-hpa: HPA configuration validation
```

## Migration Impact

### For Users with Argo Rollouts Enabled

**No changes required** - behavior is identical:
- Argo Rollout resource still used
- No Deployment created
- No HPA created

### For Users with Argo Rollouts Disabled

**Before** (v2.0.0):
- Deployment created by argo-rollouts subchart
- No HPA support

**After** (v2.1.0):
- Deployment created by main chart
- HPA support available
- API version auto-detection

### Breaking Changes

⚠️ **None** - This is a backward-compatible enhancement.

## File Changes Summary

### Created Files
1. `templates/deployment.yaml` - Standard Deployment resource
2. `templates/hpa.yaml` - HPA with API version detection
3. `templates/tests/test-hpa.yaml` - HPA validation test

### Modified Files
1. `values.yaml` - Enhanced autoscaling section with comments
2. `charts/argo-rollouts/` - Removed deployment.yaml (no longer needed)

### Removed Files
1. `charts/argo-rollouts/templates/deployment.yaml` - Moved to main chart

## Best Practices

### When to Use HPA

✅ **Good Use Cases**:
- Applications with variable load patterns
- Web services with traffic fluctuations
- API backends with unpredictable demand
- Batch processing with queue-based workloads

❌ **Not Recommended**:
- Stateful applications (databases, message queues)
- Applications using Argo Rollouts progressive delivery
- Very low latency requirements (HPA has 15-30s reaction time)

### HPA Configuration Tips

1. **Set Appropriate Resource Requests**:
   ```yaml
   resources:
     requests:
       cpu: 100m      # HPA needs this to calculate percentage
       memory: 128Mi
   ```

2. **Use Conservative Min Replicas**:
   ```yaml
   autoscaling:
     minReplicas: 2  # Always have at least 2 for availability
   ```

3. **Add Stabilization Windows**:
   ```yaml
   autoscaling:
     behavior:
       scaleDown:
         stabilizationWindowSeconds: 300  # Prevent flapping
   ```

4. **Monitor HPA Status**:
   ```bash
   kubectl get hpa
   kubectl describe hpa <name>
   ```

## References

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA v2 API Reference](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/)
- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)

---

**Status**: ✅ Complete and tested
- Helm lint: Passed
- Template rendering: All scenarios validated
- API version detection: Verified with `.Capabilities`
- Backward compatibility: Maintained
