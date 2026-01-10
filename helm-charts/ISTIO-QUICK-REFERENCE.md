# Istio Traffic Management - Quick Reference

## Feature Matrix

| Feature | Values Key | Use Case | Example |
|---------|-----------|----------|---------|
| **Gateway** | `gateway.enabled` | Custom ingress gateway | HTTPS, multi-domain |
| **ServiceEntry** | `serviceEntry.enabled` | External service access | APIs, databases |
| **PeerAuth** | `peerAuthentication.enabled` | mTLS enforcement | Service security |
| **AuthZ** | `authorizationPolicy.enabled` | Access control | Role-based access |
| **Sidecar** | `sidecar.enabled` | Resource optimization | Reduce memory/CPU |
| **Circuit Breaker** | `circuitBreaker.enabled` | Fault isolation | Prevent cascading failures |
| **Retry** | `retryPolicy.enabled` | Auto retry failed requests | 5xx errors |
| **Timeout** | `timeout.enabled` | Request timeout | Prevent hanging requests |
| **CORS** | `cors.enabled` | Browser apps | Cross-origin requests |
| **Headers** | `headers.*` | Header manipulation | Add/remove headers |
| **Mirroring** | `mirroring.enabled` | Shadow testing | Test new versions |
| **Fault Injection** | `faultInjection.enabled` | Chaos testing | Inject delays/errors |
| **Load Balancer** | `loadBalancer.simple` | Traffic distribution | Round-robin, least-request |
| **TLS** | `tls.enabled` | Egress encryption | Secure external calls |

## Common Patterns

### 🔒 Production Security Stack

```yaml
istio-routing:
  peerAuthentication:
    enabled: true
    mode: STRICT
  authorizationPolicy:
    enabled: true
    action: ALLOW
    rules:
      - from:
        - source:
            principals: ["cluster.local/ns/*/sa/allowed-service"]
```

### 🛡️ Resilience Stack

```yaml
istio-routing:
  circuitBreaker:
    enabled: true
    consecutiveErrors: 5
  retryPolicy:
    enabled: true
    attempts: 3
  timeout:
    enabled: true
    request: 30s
```

### 🌐 External API Access

```yaml
istio-routing:
  serviceEntry:
    enabled: true
    entries:
      - name: payment-api
        hosts: ["api.stripe.com"]
        ports: [{number: 443, name: https, protocol: HTTPS}]
        location: MESH_EXTERNAL
        resolution: DNS
  sidecar:
    enabled: true
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
```

### 🚦 Canary with Safety

```yaml
istio-routing:
  trafficRouting:
    enabled: true
    stable: {weight: 90}
    canary: {weight: 10}
  circuitBreaker:
    enabled: true
  mirroring:
    enabled: true
    host: myapp.default.svc.cluster.local
    subset: canary
```

### 🧪 Testing Configuration

```yaml
istio-routing:
  faultInjection:
    enabled: true
    delay: {percentage: 20, fixedDelay: 3s}
    abort: {percentage: 5, httpStatus: 503}
  retryPolicy:
    enabled: true
  timeout:
    enabled: true
    request: 5s
```

## Quick Commands

### Deploy with Istio Features
```bash
# Gateway + mTLS
helm install myapp ./helm-charts/app-template \
  --set istio-routing.gateway.enabled=true \
  --set istio-routing.peerAuthentication.enabled=true

# Circuit breaker + retries
helm install myapp ./helm-charts/app-template \
  --set istio-routing.circuitBreaker.enabled=true \
  --set istio-routing.retryPolicy.enabled=true

# External API access
helm install myapp ./helm-charts/app-template \
  --set istio-routing.serviceEntry.enabled=true \
  --set-json 'istio-routing.serviceEntry.entries=[{"name":"api","hosts":["api.example.com"],"ports":[{"number":443,"name":"https","protocol":"HTTPS"}],"location":"MESH_EXTERNAL","resolution":"DNS"}]'
```

### Check Resources
```bash
kubectl get gateway,virtualservice,destinationrule
kubectl get serviceentry,peerauthentication,authorizationpolicy
kubectl get sidecar
```

### Test Features
```bash
# Test circuit breaker
kubectl run load --image=busybox --restart=Never --rm -it -- sh -c "while true; do wget -q -O- http://myapp; done"

# Test mTLS
istioctl authn tls-check <pod> <service>

# Test external access
kubectl run test --image=curlimages/curl --rm -it -- curl https://api.example.com
```

## Decision Tree

```
Need external service access?
├─ Yes → serviceEntry.enabled: true
└─ No
    ├─ Need security?
    │  ├─ Yes → peerAuthentication + authorizationPolicy
    │  └─ No
    │      ├─ Need resilience?
    │      │  ├─ Yes → circuitBreaker + retry + timeout
    │      │  └─ No
    │      │      ├─ Testing?
    │      │      │  ├─ Yes → faultInjection + mirroring
    │      │      │  └─ No → Basic ingress
    │      │      └─ Done
    │      └─ Done
    └─ Done
```

## Values Template

```yaml
istio-routing:
  enabled: true
  
  # Basic ingress (always needed)
  ingress:
    enabled: true
    path: /myapp
    gateway: istio-system/main-gateway
  
  # Security (recommended for production)
  # peerAuthentication: {enabled: true, mode: STRICT}
  # authorizationPolicy: {enabled: true, action: ALLOW}
  
  # Resilience (recommended)
  # circuitBreaker: {enabled: true}
  # retryPolicy: {enabled: true}
  # timeout: {enabled: true, request: 30s}
  
  # External access (as needed)
  # serviceEntry: {enabled: true, entries: [...]}
  
  # Optimization (large clusters)
  # sidecar: {enabled: true}
  
  # Advanced (specific use cases)
  # cors: {enabled: true}
  # mirroring: {enabled: true}
  # faultInjection: {enabled: true}
```

## Troubleshooting

| Issue | Check | Fix |
|-------|-------|-----|
| Gateway not working | `kubectl get gateway` | Verify gateway pod running |
| Can't reach external API | `kubectl get serviceentry` | Add ServiceEntry |
| mTLS errors | `istioctl authn tls-check` | Set mode to PERMISSIVE |
| High latency | Check circuit breaker stats | Adjust timeout/retry |
| 403 errors | `kubectl get authorizationpolicy` | Update rules |
| High memory | Check sidecar config | Enable egress optimization |

## Example Configurations by Environment

### Development
```yaml
istio-routing:
  ingress: {enabled: true}
  faultInjection: {enabled: true}  # Test resilience
  timeout: {enabled: true, request: 5s}  # Fast feedback
```

### Staging
```yaml
istio-routing:
  ingress: {enabled: true}
  peerAuthentication: {enabled: true, mode: PERMISSIVE}
  circuitBreaker: {enabled: true}
  retryPolicy: {enabled: true}
  mirroring: {enabled: true}  # Shadow production
```

### Production
```yaml
istio-routing:
  ingress: {enabled: true}
  peerAuthentication: {enabled: true, mode: STRICT}
  authorizationPolicy: {enabled: true}
  circuitBreaker: {enabled: true}
  retryPolicy: {enabled: true}
  timeout: {enabled: true}
  sidecar: {enabled: true}
```

---

**Tip**: Start simple, add features incrementally, test thoroughly!
