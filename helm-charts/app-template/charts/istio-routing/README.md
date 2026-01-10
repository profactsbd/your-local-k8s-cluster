# Istio Traffic Management Capabilities - Complete Guide

## Overview

Enhanced the `istio-routing` subchart with comprehensive Istio traffic management features including security, resilience, observability, and advanced routing capabilities.

## New Capabilities Added

### 1. **Gateway** - Ingress Configuration
Manage ingress traffic with custom Gateway resources.

```yaml
istio-routing:
  gateway:
    enabled: true
    name: myapp-gateway
    servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
          - "*.example.com"
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: myapp-tls-cert
        hosts:
          - "app.example.com"
```

### 2. **ServiceEntry** - External Service Access
Define external services accessible from within the mesh.

```yaml
istio-routing:
  serviceEntry:
    enabled: true
    entries:
      - name: external-api
        hosts:
          - api.external.com
        ports:
          - number: 443
            name: https
            protocol: HTTPS
        location: MESH_EXTERNAL
        resolution: DNS
      - name: database
        hosts:
          - db.external.com
        ports:
          - number: 5432
            name: postgres
            protocol: TCP
        location: MESH_EXTERNAL
        resolution: DNS
        endpoints:
          - address: 10.0.1.50
```

### 3. **PeerAuthentication** - mTLS Configuration
Configure mutual TLS authentication for service-to-service communication.

```yaml
istio-routing:
  peerAuthentication:
    enabled: true
    mode: STRICT  # Enforce mTLS for all traffic
    portLevelMtls:
      8080:
        mode: DISABLE  # Disable mTLS for specific port
```

**Modes**:
- `STRICT`: Requires mTLS for all connections
- `PERMISSIVE`: Accepts both mTLS and plaintext
- `DISABLE`: Disables mTLS

### 4. **AuthorizationPolicy** - Access Control
Define fine-grained access control policies.

```yaml
istio-routing:
  authorizationPolicy:
    enabled: true
    action: ALLOW
    rules:
      - from:
        - source:
            principals:
              - "cluster.local/ns/frontend/sa/web"
        to:
        - operation:
            methods: ["GET", "POST"]
            paths: ["/api/v1/*"]
      - from:
        - source:
            namespaces: ["monitoring"]
        to:
        - operation:
            paths: ["/metrics"]
```

### 5. **Sidecar** - Resource Optimization
Optimize sidecar proxy configuration to reduce memory/CPU usage.

```yaml
istio-routing:
  sidecar:
    enabled: true
    egress:
      - hosts:
          - "./*"  # Same namespace
          - "istio-system/*"  # Istio system
          - "monitoring/*"  # Monitoring namespace
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY  # Only allow registered services
```

### 6. **Circuit Breaker** - Resilience
Protect services from cascading failures.

```yaml
istio-routing:
  circuitBreaker:
    enabled: true
    consecutiveErrors: 5
    interval: 30s
    baseEjectionTime: 30s
    maxEjectionPercent: 50
    connectionPool:
      tcp:
        maxConnections: 100
        connectTimeout: 30s
      http:
        http1MaxPendingRequests: 1024
        http2MaxRequests: 1024
        maxRequestsPerConnection: 0
        maxRetries: 3
```

### 7. **Retry Policy** - Automatic Retries
Automatically retry failed requests.

```yaml
istio-routing:
  retryPolicy:
    enabled: true
    attempts: 3
    perTryTimeout: 2s
    retryOn: "5xx,reset,connect-failure,refused-stream"
```

### 8. **Timeout Configuration** - Request Timeouts
Set timeouts for requests and idle connections.

```yaml
istio-routing:
  timeout:
    enabled: true
    request: 30s
    idle: 3600s
```

### 9. **Load Balancer** - Traffic Distribution
Configure load balancing algorithms.

```yaml
istio-routing:
  loadBalancer:
    simple: LEAST_REQUEST
    # Or use consistent hashing:
    # consistentHash:
    #   httpHeaderName: "x-user-id"
    #   minimumRingSize: 1024
```

**Algorithms**:
- `ROUND_ROBIN`: Default round-robin
- `LEAST_REQUEST`: Send to least loaded instance
- `RANDOM`: Random selection
- `PASSTHROUGH`: Forward without load balancing

### 10. **CORS Policy** - Cross-Origin Resource Sharing
Configure CORS for browser-based applications.

```yaml
istio-routing:
  cors:
    enabled: true
    allowOrigins:
      - exact: "https://app.example.com"
      - prefix: "https://*.example.com"
    allowMethods:
      - GET
      - POST
      - PUT
      - DELETE
      - OPTIONS
    allowHeaders:
      - "content-type"
      - "authorization"
      - "x-api-key"
    exposeHeaders:
      - "x-request-id"
    maxAge: 24h
    allowCredentials: true
```

### 11. **Header Manipulation** - Request/Response Headers
Add, modify, or remove headers.

```yaml
istio-routing:
  headers:
    request:
      add:
        x-forwarded-for: "%DOWNSTREAM_REMOTE_ADDRESS%"
        x-request-id: "%REQ(X-REQUEST-ID)%"
      set:
        x-app-version: "v1.0.0"
      remove:
        - "x-legacy-header"
    response:
      add:
        x-served-by: "istio-gateway"
        cache-control: "no-cache, no-store"
      remove:
        - "server"
```

### 12. **Traffic Mirroring** - Shadow Testing
Mirror traffic to test new versions without impacting users.

```yaml
istio-routing:
  mirroring:
    enabled: true
    host: myapp-v2.default.svc.cluster.local
    subset: canary
    percentage: 100  # Mirror 100% of traffic
```

### 13. **Fault Injection** - Chaos Testing
Inject faults for testing resilience.

```yaml
istio-routing:
  faultInjection:
    enabled: true
    delay:
      percentage: 10
      fixedDelay: 5s
    abort:
      percentage: 1
      httpStatus: 503
```

### 14. **TLS for Egress** - Secure External Connections
Configure TLS for outbound traffic.

```yaml
istio-routing:
  tls:
    enabled: true
    mode: SIMPLE
    # For mutual TLS:
    # mode: MUTUAL
    # clientCertificate: /etc/certs/client.pem
    # privateKey: /etc/certs/key.pem
    # caCertificates: /etc/certs/ca.pem
```

## Complete Example Configurations

### Production Web Application

```yaml
istio-routing:
  enabled: true
  
  # Ingress with HTTPS
  gateway:
    enabled: true
    servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: app-tls-secret
        hosts:
          - "app.example.com"
  
  ingress:
    enabled: true
    path: /
    pathType: Prefix
    gateway: myapp-gateway
    hosts:
      - "app.example.com"
  
  # Security
  peerAuthentication:
    enabled: true
    mode: STRICT
  
  authorizationPolicy:
    enabled: true
    action: ALLOW
    rules:
      - to:
        - operation:
            methods: ["GET", "POST"]
  
  # Resilience
  circuitBreaker:
    enabled: true
    consecutiveErrors: 5
    interval: 30s
    baseEjectionTime: 30s
  
  retryPolicy:
    enabled: true
    attempts: 3
    perTryTimeout: 2s
  
  timeout:
    enabled: true
    request: 30s
  
  # CORS for browser apps
  cors:
    enabled: true
    allowOrigins:
      - exact: "https://app.example.com"
    allowMethods: [GET, POST, PUT, DELETE]
    allowCredentials: true
  
  # Headers
  headers:
    response:
      add:
        strict-transport-security: "max-age=31536000; includeSubDomains"
        x-content-type-options: "nosniff"
        x-frame-options: "DENY"
```

### Microservices with External API

```yaml
istio-routing:
  enabled: true
  
  # Allow specific egress traffic
  serviceEntry:
    enabled: true
    entries:
      - name: payment-api
        hosts:
          - api.stripe.com
        ports:
          - number: 443
            name: https
            protocol: HTTPS
        location: MESH_EXTERNAL
        resolution: DNS
      - name: email-service
        hosts:
          - smtp.sendgrid.net
        ports:
          - number: 587
            name: smtp
            protocol: TCP
        location: MESH_EXTERNAL
        resolution: DNS
  
  # Optimize sidecar
  sidecar:
    enabled: true
    egress:
      - hosts:
          - "./*"
          - "istio-system/*"
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
  
  # mTLS
  peerAuthentication:
    enabled: true
    mode: STRICT
  
  # TLS for external services
  tls:
    enabled: true
    mode: SIMPLE
```

### Canary Deployment with Traffic Management

```yaml
istio-routing:
  enabled: true
  
  # Canary routing
  trafficRouting:
    enabled: true
    stable:
      weight: 90
    canary:
      weight: 10
  
  # Circuit breaker
  circuitBreaker:
    enabled: true
    consecutiveErrors: 3
    interval: 10s
    baseEjectionTime: 30s
  
  # Retry for resilience
  retryPolicy:
    enabled: true
    attempts: 3
    perTryTimeout: 2s
    retryOn: "5xx,reset,connect-failure"
  
  # Timeout
  timeout:
    enabled: true
    request: 10s
  
  # Mirror traffic to canary for testing
  mirroring:
    enabled: true
    host: myapp.default.svc.cluster.local
    subset: canary
    percentage: 100
```

### Testing/Staging Environment with Fault Injection

```yaml
istio-routing:
  enabled: true
  
  # Inject delays and errors for testing
  faultInjection:
    enabled: true
    delay:
      percentage: 20
      fixedDelay: 3s
    abort:
      percentage: 5
      httpStatus: 503
  
  # Short timeouts for faster feedback
  timeout:
    enabled: true
    request: 5s
  
  # Retry quickly
  retryPolicy:
    enabled: true
    attempts: 2
    perTryTimeout: 1s
```

## Resource Matrix

| Resource | Purpose | Use Case |
|----------|---------|----------|
| **Gateway** | Ingress traffic | External access to services |
| **VirtualService** | Traffic routing | Path-based routing, traffic splitting |
| **DestinationRule** | Load balancing & policies | Circuit breakers, connection pools |
| **ServiceEntry** | External services | Access APIs, databases outside mesh |
| **PeerAuthentication** | mTLS | Secure service-to-service communication |
| **AuthorizationPolicy** | Access control | Fine-grained permissions |
| **Sidecar** | Resource optimization | Reduce sidecar memory/CPU |

## Testing Your Configuration

### Test Gateway
```bash
kubectl get gateway
kubectl describe gateway <name>
```

### Test ServiceEntry
```bash
kubectl get serviceentry
# Test external connectivity
kubectl run test --rm -it --image=curlimages/curl -- curl https://api.external.com
```

### Test mTLS
```bash
kubectl get peerauthentication
# Check if mTLS is enforced
istioctl authn tls-check <pod> <service>
```

### Test Authorization
```bash
kubectl get authorizationpolicy
# Try unauthorized access (should fail)
curl -v http://service/api
```

### Test Circuit Breaker
```bash
# Generate load to trigger circuit breaker
kubectl run load-gen --rm -it --image=busybox -- /bin/sh -c "while true; do wget -q -O- http://service; done"
# Check ejected hosts
kubectl get destinationrule <name> -o yaml | grep -A 10 outlierDetection
```

## Troubleshooting

### Gateway Not Working
```bash
# Check gateway status
kubectl get gateway
kubectl describe gateway <name>

# Check if gateway pod is running
kubectl get pods -n istio-system -l istio=ingressgateway

# Check logs
kubectl logs -n istio-system -l istio=ingressgateway
```

### ServiceEntry Not Accessible
```bash
# Verify ServiceEntry
kubectl get serviceentry
kubectl describe serviceentry <name>

# Check if sidecar allows egress
kubectl get sidecar
# Ensure outboundTrafficPolicy allows it
```

### mTLS Issues
```bash
# Check PeerAuthentication
kubectl get peerauthentication

# Verify mTLS status
istioctl proxy-config secret <pod>

# Check if both sides support mTLS
istioctl authn tls-check <source-pod> <destination-service>
```

### Circuit Breaker Not Triggering
```bash
# Check DestinationRule
kubectl get destinationrule <name> -o yaml

# View Envoy stats
kubectl exec <pod> -c istio-proxy -- pilot-agent request GET stats | grep outlier
```

## Best Practices

### Security
1. ✅ Enable STRICT mTLS in production
2. ✅ Use AuthorizationPolicy for access control
3. ✅ Disable unused ports in PeerAuthentication
4. ✅ Use ServiceEntry with REGISTRY_ONLY for egress control

### Resilience
1. ✅ Always configure circuit breakers
2. ✅ Set appropriate timeouts (not too long)
3. ✅ Use retry policies wisely (avoid retry storms)
4. ✅ Test fault injection in staging

### Performance
1. ✅ Use Sidecar resources to limit egress hosts
2. ✅ Configure connection pools appropriately
3. ✅ Use LEAST_REQUEST for uneven workloads
4. ✅ Set reasonable timeout values

### Observability
1. ✅ Add custom headers for tracing
2. ✅ Use traffic mirroring before deploying
3. ✅ Enable access logs for troubleshooting
4. ✅ Monitor circuit breaker metrics

## Migration from Basic to Advanced

**Step 1: Start with basics**
```yaml
istio-routing:
  enabled: true
  ingress:
    enabled: true
```

**Step 2: Add resilience**
```yaml
istio-routing:
  retryPolicy:
    enabled: true
  timeout:
    enabled: true
  circuitBreaker:
    enabled: true
```

**Step 3: Add security**
```yaml
istio-routing:
  peerAuthentication:
    enabled: true
    mode: PERMISSIVE  # Start permissive
  authorizationPolicy:
    enabled: true
```

**Step 4: Enable STRICT mTLS**
```yaml
istio-routing:
  peerAuthentication:
    mode: STRICT
```

**Step 5: Optimize**
```yaml
istio-routing:
  sidecar:
    enabled: true
  loadBalancer:
    simple: LEAST_REQUEST
```

## Summary

The enhanced `istio-routing` subchart now provides:

- ✅ **14 advanced traffic management capabilities**
- ✅ **Complete security with mTLS and AuthZ**
- ✅ **Resilience with circuit breakers, retries, timeouts**
- ✅ **Observability with mirroring and headers**
- ✅ **Performance with sidecars and load balancing**
- ✅ **Testing with fault injection**
- ✅ **All configurable via values.yaml**
- ✅ **Production-ready defaults**
- ✅ **Backward compatible**

All features are **optional and independently configurable**.
