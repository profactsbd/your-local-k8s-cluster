# Istio Routing Templates - Inline Documentation Reference

This document provides an overview of all inline documentation added to the Istio routing templates.

## Purpose of Inline Documentation

Each template file now includes comprehensive inline comments that explain:
- **What the resource does** - High-level purpose and functionality
- **When it renders** - Conditions that control template rendering
- **Key configuration options** - Important fields and their meanings
- **Integration points** - How resources work together
- **Best practices** - Recommendations for usage

## Documented Template Files

### 1. Gateway (`gateway.yaml`)

**Purpose**: Configures how external traffic enters the service mesh at the edge

**Key Documentation Points**:
- Selector targets Istio ingress gateway pods
- Servers define port, protocol, and hosts configuration
- Works with VirtualServices to route traffic to internal services
- TLS configuration for HTTPS termination

**Rendering Condition**: `istio-routing.enabled && istio-routing.gateway.enabled`

### 2. ServiceEntry (`serviceentry.yaml`)

**Purpose**: Makes external services (outside the mesh) accessible from within the mesh

**Key Documentation Points**:
- Location types: MESH_EXTERNAL vs MESH_INTERNAL
- Resolution modes: DNS, STATIC, NONE
- Endpoints for explicit IP configuration
- subjectAltNames for mTLS certificate validation
- Enables traffic management features for external calls

**Rendering Condition**: `istio-routing.enabled && istio-routing.serviceEntry.enabled`

**Special Feature**: Iterates over `.Values.serviceEntry.entries` array - one ServiceEntry per entry

### 3. PeerAuthentication (`peerauthentication.yaml`)

**Purpose**: Configures mutual TLS (mTLS) for service-to-service communication within the mesh

**Key Documentation Points**:
- mTLS modes explained:
  - STRICT: Only encrypted mTLS traffic allowed (recommended for production)
  - PERMISSIVE: Accepts both mTLS and plaintext (useful during migration)
  - DISABLE: No mTLS enforcement (not recommended)
- Port-level mTLS overrides for gradual migration
- Identity verification between services using certificates

**Rendering Condition**: `istio-routing.enabled && istio-routing.peerAuthentication.enabled`

### 4. AuthorizationPolicy (`authorizationpolicy.yaml`)

**Purpose**: Fine-grained access control for service-to-service communication

**Key Documentation Points**:
- Controls WHO can access (service identity/principal)
- Controls WHAT operations are allowed (HTTP methods, paths, headers)
- Actions: ALLOW, DENY, AUDIT
- Rules structure: from (source), to (operation), when (conditions)
- Default behavior: No policy = all traffic allowed, empty policy = all denied

**Rendering Condition**: `istio-routing.enabled && istio-routing.authorizationPolicy.enabled`

### 5. Sidecar (`sidecar.yaml`)

**Purpose**: Optimizes Envoy proxy resource usage by limiting traffic scope

**Key Documentation Points**:
- egress.hosts whitelist format (namespace/service)
- outboundTrafficPolicy modes:
  - ALLOW_ANY: Unrestricted (default Istio behavior)
  - REGISTRY_ONLY: Block traffic not in egress.hosts (strict mode)
- Use case: Large service meshes where each workload only calls a few services
- Reduces memory/CPU usage and startup time

**Rendering Condition**: `istio-routing.enabled && istio-routing.sidecar.enabled`

### 6. VirtualService - Canary Mode (`virtualservice.yaml`)

**Purpose**: Routes traffic to multiple versions (stable/canary) for progressive delivery

**Key Documentation Points**:
- Distributes traffic using percentage weights
- Integration with DestinationRule subsets (stable, canary)
- Match conditions for request routing
- Advanced features documented:
  - **Fault Injection**: Delay and abort testing
  - **Retry Policy**: Automatic retry on failures
  - **Timeout**: Request timeout configuration
  - **CORS**: Cross-origin resource sharing
  - **Headers**: Request/response header manipulation
  - **Mirroring**: Shadow traffic to test services

**Rendering Condition**: `istio-routing.enabled && istio-routing.trafficRouting.enabled`

### 7. VirtualService - Standard Mode (`virtualservice.yaml`)

**Purpose**: Routes all traffic to a single version (no canary/traffic splitting)

**Key Documentation Points**:
- Simpler configuration without subsets
- All the same advanced features as canary mode
- Difference from canary mode clearly explained
- Use case: Standard deployments without progressive delivery

**Rendering Condition**: `istio-routing.enabled && istio-routing.ingress.enabled && !istio-routing.trafficRouting.enabled`

### 8. DestinationRule - Canary Mode (`virtualservice.yaml`)

**Purpose**: Defines subsets (versions) and traffic policies for the service

**Key Documentation Points**:
- Subsets for traffic splitting (stable, canary)
- Traffic policies documented:
  - **Load Balancer**: ROUND_ROBIN, LEAST_CONN, RANDOM, consistent hashing
  - **Connection Pool**: TCP/HTTP connection limits
  - **Circuit Breaker**: Outlier detection parameters explained
    - consecutiveErrors: Threshold for ejection
    - interval: Time between analysis sweeps
    - baseEjectionTime: Minimum ejection duration
    - maxEjectionPercent: Maximum instances that can be ejected
    - minHealthPercent: Minimum healthy instances required
  - **TLS**: Upstream connection encryption modes

**Rendering Condition**: Automatically rendered with VirtualService in canary mode

## Documentation Format

All inline documentation follows a consistent format:

```yaml
#
# RESOURCE TYPE
# Purpose: Brief description of what it does
# Renders: Conditions that control when this template renders
#
# What it does:
# - Bullet point list of functionality
# - Integration with other resources
# - Use cases and scenarios
#
# Key concepts:
# - Important fields with explanations
# - Configuration options and their meanings
# - Best practices and recommendations
#
apiVersion: ...
kind: ...
# Inline comments throughout the spec explaining each field
```

## Benefits of Inline Documentation

1. **Self-Documenting Templates**: New developers can understand templates without external docs
2. **Context-Aware**: Comments appear right where configuration happens
3. **Rendered Output**: Comments appear in `helm template` output for debugging
4. **Learning Tool**: Helps users understand Istio concepts while configuring
5. **Maintenance**: Makes it easier to maintain and update templates over time

## Using the Documentation

### Reading Templates
When editing template files, read the block comments at the top to understand:
- What the resource does
- When it will be rendered
- What configuration options are available

### Debugging with Helm Template
Run `helm template` to see rendered YAML with inline comments:

```powershell
cd helm-charts/app-template
helm template test . --set istio-routing.enabled=true,istio-routing.gateway.enabled=true,...
```

The output will include all documentation comments, making it easy to understand what each section does.

### Understanding Relationships
The documentation explains how resources work together:
- **Gateway + VirtualService**: Gateway accepts traffic, VirtualService routes it
- **VirtualService + DestinationRule**: VirtualService defines routes, DestinationRule defines destinations
- **PeerAuthentication + AuthorizationPolicy**: Authentication verifies identity, Authorization controls access
- **ServiceEntry + DestinationRule**: ServiceEntry registers external service, DestinationRule adds policies

## Additional Resources

For more detailed examples and configuration patterns, see:
- [README.md](README.md) - Comprehensive guide with full examples
- [ISTIO-QUICK-REFERENCE.md](../../ISTIO-QUICK-REFERENCE.md) - Quick reference for common patterns
- [values.yaml](values.yaml) - All configuration options with descriptions

## Contributing

When adding new templates or updating existing ones:
1. Add block comment at the top explaining the resource
2. Add inline comments for complex logic or important fields
3. Explain conditional rendering with {{- if }} blocks
4. Document integration points with other resources
5. Include examples in comments when helpful
