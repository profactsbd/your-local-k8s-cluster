# Argo Rollouts Subchart

Progressive delivery deployment strategies using Argo Rollouts.

## Overview

This subchart provides support for **Argo Rollouts**, enabling canary and blue-green deployment strategies for your applications. It can automatically integrate with Istio for advanced traffic management.

## Features

- ✅ **Canary Deployments**: Gradual rollout with configurable traffic weights
- ✅ **Blue-Green Deployments**: Zero-downtime deployments with instant rollback
- ✅ **Istio Integration**: Automatic traffic splitting using Istio VirtualServices
- ✅ **Standard Deployment Fallback**: Automatically uses Deployment when argo-rollouts is disabled
- ✅ **Helm Tests**: Automated validation of Rollout status

## Configuration

### Basic Usage

```yaml
argo-rollouts:
  enabled: true
  replicas: 2
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 20
        - pause: {duration: 30s}
        - setWeight: 50
        - pause: {duration: 30s}
        - setWeight: 80
        - pause: {duration: 30s}
```

### Blue-Green Strategy

```yaml
argo-rollouts:
  enabled: true
  replicas: 2
  strategy:
    type: blueGreen
    blueGreen:
      activeService: active
      previewService: preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
```

### Istio Traffic Routing

When using canary deployments with Istio routing enabled:

```yaml
argo-rollouts:
  enabled: true
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 25
        - pause: {duration: 60s}
        - setWeight: 75
        - pause: {duration: 60s}

istio-routing:
  enabled: true
  trafficRouting:
    enabled: true  # Required for Istio integration
```

The subchart will automatically configure Istio VirtualService traffic splitting.

## Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable Argo Rollouts (if false, uses standard Deployment) | `true` |
| `replicas` | Number of replicas | `2` |
| `strategy.type` | Deployment strategy: `canary` or `blueGreen` | `canary` |
| `strategy.canary.steps` | List of canary rollout steps | See values.yaml |
| `strategy.blueGreen.autoPromotionEnabled` | Auto-promote to active | `false` |
| `strategy.blueGreen.scaleDownDelaySeconds` | Delay before scaling down old version | `30` |
| `image.repository` | Container image repository | `nginx` |
| `image.tag` | Container image tag | `""` (uses appVersion) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `resources.limits.cpu` | CPU limit | `100m` |
| `resources.limits.memory` | Memory limit | `128Mi` |
| `resources.requests.cpu` | CPU request | `50m` |
| `resources.requests.memory` | Memory request | `64Mi` |
| `istio.inject` | Enable Istio sidecar injection | `true` |

## Deployment Strategies

### Canary Deployment

Gradually shifts traffic from the old version to the new version:

1. **SetWeight**: Define percentage of traffic to new version
2. **Pause**: Wait for specified duration or manual promotion
3. **Repeat**: Multiple steps for gradual rollout

Example:
```yaml
strategy:
  type: canary
  canary:
    steps:
      - setWeight: 10
      - pause: {duration: 2m}
      - setWeight: 30
      - pause: {duration: 2m}
      - setWeight: 60
      - pause: {duration: 2m}
      - setWeight: 90
      - pause: {duration: 1m}
```

### Blue-Green Deployment

Instantly switches traffic from old version (blue) to new version (green):

```yaml
strategy:
  type: blueGreen
  blueGreen:
    activeService: my-app
    previewService: my-app-preview
    autoPromotionEnabled: false  # Require manual promotion
    scaleDownDelaySeconds: 60    # Keep old version for 60s
```

## Helm Tests

The subchart includes a test that verifies the Rollout status:

```bash
helm test <release-name>
```

The test checks if the Rollout is in a `Healthy` or `Progressing` state.

## Fallback to Standard Deployment

If `argo-rollouts.enabled: false`, the subchart automatically creates a standard Kubernetes Deployment instead of a Rollout resource. This provides compatibility when Argo Rollouts controller is not available.

## Integration with Parent Chart

This subchart is designed to work with the `app-template` parent chart. It uses the following resources from the parent:

- **Service**: Created by parent chart for routing traffic
- **ServiceAccount**: Optionally uses parent's service account
- **Istio Routing**: Coordinates with `istio-routing` subchart for traffic management

## Examples

### Simple Canary Deployment

```yaml
argo-rollouts:
  enabled: true
  replicas: 3
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 33
        - pause: {duration: 1m}
        - setWeight: 66
        - pause: {duration: 1m}
```

### Advanced Canary with Istio

```yaml
argo-rollouts:
  enabled: true
  replicas: 4
  strategy:
    type: canary
    canary:
      steps:
        - setWeight: 25
        - pause: {duration: 30s}
        - setWeight: 50
        - pause: {}  # Manual promotion
        - setWeight: 75
        - pause: {duration: 30s}
  
istio-routing:
  enabled: true
  trafficRouting:
    enabled: true
```

### Blue-Green with Manual Promotion

```yaml
argo-rollouts:
  enabled: true
  replicas: 2
  strategy:
    type: blueGreen
    blueGreen:
      activeService: myapp
      previewService: myapp-preview
      autoPromotionEnabled: false  # Manual approval required
      scaleDownDelaySeconds: 300   # Keep old version for 5 minutes
```

## Troubleshooting

### Rollout Not Progressing

Check the rollout status:
```bash
kubectl argo rollouts get rollout <release-name>
kubectl argo rollouts status <release-name>
```

### Istio Traffic Routing Not Working

Ensure:
1. `istio-routing.trafficRouting.enabled` is `true`
2. `argo-rollouts.strategy.type` is `canary` (not blue-green)
3. Istio is properly configured in the cluster
4. VirtualService exists and is configured

### Manual Promotion

To manually promote a rollout:
```bash
kubectl argo rollouts promote <release-name>
```

To abort a rollout:
```bash
kubectl argo rollouts abort <release-name>
```

## Version

- **Chart Version**: 1.0.0
- **Argo Rollouts**: v1.7.2+ (controller must be installed separately)

## Dependencies

- **Argo Rollouts Controller**: Must be installed in the cluster
- **kubectl-argo-rollouts**: Plugin for CLI management (optional)
- **Istio**: Required only if using traffic routing features

## References

- [Argo Rollouts Documentation](https://argo-rollouts.readthedocs.io/)
- [Canary Strategy Reference](https://argo-rollouts.readthedocs.io/en/stable/features/canary/)
- [Blue-Green Strategy Reference](https://argo-rollouts.readthedocs.io/en/stable/features/bluegreen/)
- [Istio Integration Guide](https://argo-rollouts.readthedocs.io/en/stable/features/traffic-management/istio/)
