# Deployment & Autoscaling Quick Reference

## Decision Matrix

### When to Use What?

| Use Case | Configuration | Result |
|----------|---------------|--------|
| **Standard deployment, fixed replicas** | `argo-rollouts.enabled: false`<br>`autoscaling.enabled: false` | Deployment with fixed replicas |
| **Auto-scaling deployment** | `argo-rollouts.enabled: false`<br>`autoscaling.enabled: true` | Deployment + HPA |
| **Progressive delivery (canary)** | `argo-rollouts.enabled: true`<br>`strategy.type: canary` | Argo Rollout (no HPA) |
| **Progressive delivery (blue-green)** | `argo-rollouts.enabled: true`<br>`strategy.type: blueGreen` | Argo Rollout (no HPA) |

## Quick Examples

### 1. Fixed Replicas (Simplest)

```yaml
argo-rollouts:
  enabled: false
  replicas: 3

autoscaling:
  enabled: false
```

**Creates**: Deployment with 3 replicas

---

### 2. CPU-Based Autoscaling

```yaml
argo-rollouts:
  enabled: false
  replicas: 2  # Initial count, HPA manages actual

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

**Creates**: Deployment + HPA (scales 2-10 pods based on 80% CPU)

---

### 3. CPU + Memory Autoscaling

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

**Creates**: Deployment + HPA (scales 3-20 pods, CPU @ 75% OR Memory @ 80%)

---

### 4. Advanced HPA with Custom Behavior

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
          value: 50  # Max 50% reduction per cycle
          periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
        - type: Percent
          value: 100  # Can double pods
          periodSeconds: 15
        - type: Pods
          value: 4  # Or add 4 pods
          periodSeconds: 60
      selectPolicy: Max
```

**Creates**: Deployment + HPA with conservative scale-down, aggressive scale-up

---

### 5. Canary Deployment (No HPA)

```yaml
argo-rollouts:
  enabled: true
  replicas: 3
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 25
        - pause: {duration: 1m}
        - setWeight: 50
        - pause: {duration: 2m}
        - setWeight: 75
        - pause: {duration: 1m}

istio-routing:
  enabled: true
  trafficRouting:
    enabled: true

autoscaling:
  enabled: false  # Cannot use HPA with Argo Rollouts
```

**Creates**: Argo Rollout with canary strategy + Istio traffic routing

---

### 6. Blue-Green Deployment (No HPA)

```yaml
argo-rollouts:
  enabled: true
  replicas: 4
  strategy:
    type: blueGreen
    blueGreen:
      activeService: myapp
      previewService: myapp-preview
      autoPromotionEnabled: false

autoscaling:
  enabled: false  # Cannot use HPA with Argo Rollouts
```

**Creates**: Argo Rollout with blue-green strategy

## HPA API Version Compatibility

The chart **automatically detects** the best HPA API version:

| Kubernetes Version | API Version Used | Metrics Support |
|-------------------|------------------|-----------------|
| 1.23+ | `autoscaling/v2` | CPU + Memory + Behavior |
| 1.18-1.22 | `autoscaling/v2beta2` | CPU + Memory + Behavior |
| <1.18 | `autoscaling/v2beta1` | CPU only |

**No configuration needed** - it just works! 🎉

## Common Commands

### Check HPA Status
```bash
kubectl get hpa
kubectl describe hpa <release-name>
kubectl get hpa <release-name> --watch
```

### Check Current Replicas
```bash
# For Deployment
kubectl get deployment <release-name> -o jsonpath='{.spec.replicas}'

# For Argo Rollout
kubectl argo rollouts get rollout <release-name>
```

### Manual HPA Testing
```bash
# Generate load to trigger scaling
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://<service-name>; done"
```

### View HPA Events
```bash
kubectl get events --field-selector involvedObject.name=<release-name> --sort-by='.lastTimestamp'
```

## Troubleshooting

### HPA Not Scaling

**Check metrics availability**:
```bash
kubectl top pods
kubectl top nodes
```

If metrics not available, install metrics-server:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### HPA Shows "Unknown" Metrics

**Verify resource requests are set**:
```yaml
argo-rollouts:
  resources:
    requests:
      cpu: 100m      # Required for CPU-based HPA
      memory: 128Mi  # Required for memory-based HPA
```

### Deployment Has No Replicas

**This is expected when HPA is enabled!** The HPA manages the replica count.

### Both Rollout and Deployment Created

**Check configuration**:
- If `argo-rollouts.enabled: true` → Only Rollout
- If `argo-rollouts.enabled: false` → Only Deployment

## Best Practices

### ✅ DO

- Set resource requests when using HPA
- Use minReplicas ≥ 2 for high availability
- Add stabilization windows to prevent flapping
- Monitor HPA metrics regularly
- Test scaling behavior under load

### ❌ DON'T

- Use HPA with Argo Rollouts (incompatible)
- Set maxReplicas too low (can cause outages)
- Forget to install metrics-server
- Use very aggressive scaling policies in production
- Scale stateful applications with HPA

## Testing Your Configuration

```bash
# Dry-run to see what will be created
helm template myapp ./helm-charts/app-template --set argo-rollouts.enabled=false --set autoscaling.enabled=true

# Install and test
helm install myapp ./helm-charts/app-template --set argo-rollouts.enabled=false --set autoscaling.enabled=true

# Run Helm tests
helm test myapp

# Check what was created
kubectl get deployment,hpa,svc
```

## Migration Path

**From fixed replicas to HPA**:
1. Start with fixed replicas
2. Monitor CPU/Memory usage
3. Enable HPA with conservative settings
4. Adjust min/max based on observed patterns
5. Fine-tune target percentages
6. Add custom behavior policies

**From Deployment to Argo Rollouts**:
1. Disable autoscaling: `autoscaling.enabled: false`
2. Enable Argo Rollouts: `argo-rollouts.enabled: true`
3. Choose strategy: `canary` or `blueGreen`
4. Configure rollout steps
5. Enable Istio if needed: `istio-routing.trafficRouting.enabled: true`

## Resources Required

### For Standard Deployment
- ✅ Kubernetes 1.16+
- ✅ kubectl

### For HPA
- ✅ Kubernetes 1.16+
- ✅ metrics-server installed
- ✅ Resource requests configured

### For Argo Rollouts
- ✅ Kubernetes 1.16+
- ✅ Argo Rollouts controller installed
- ✅ kubectl-argo-rollouts plugin (optional)

### For Istio Traffic Routing
- ✅ Kubernetes 1.16+
- ✅ Argo Rollouts controller
- ✅ Istio installed (1.14+)
- ✅ Istio Gateway configured

---

**Quick Tip**: Start simple (fixed replicas), then add HPA, then consider Argo Rollouts for advanced use cases!
