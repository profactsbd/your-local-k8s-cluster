# Helm Chart Migration Guide: v1.0.0 → v2.0.0

## Overview
Version 2.0.0 introduces a **modular architecture** with subcharts for better separation of concerns and flexibility.

## What Changed

### Chart Structure
- **Before**: Monolithic chart with all resources in templates/
- **After**: Main chart + 2 optional subcharts (istio-routing, kargo-config)

### Value Path Changes

| v1.0.0 Path | v2.0.0 Path | Component |
|-------------|-------------|-----------|
| `ingress.enabled` | `istio-routing.ingress.enabled` | Istio routing |
| `ingress.path` | `istio-routing.ingress.path` | Istio routing |
| `ingress.pathType` | `istio-routing.ingress.pathType` | Istio routing |
| `rollout.strategy.canary.trafficRouting.istio.enabled` | `istio-routing.trafficRouting.enabled` | Canary routing |
| `kargo.*` | `kargo-config.*` | Kargo stages |

## Migration Steps

### Step 1: Export Current Values
```powershell
# Export your current values
helm get values myapp -o yaml > myapp-old-values.yaml
```

### Step 2: Convert Values File
Create a new values file with updated paths:

**Old values (v1.0.0):**
```yaml
image:
  repository: nginx
  tag: "1.25"

ingress:
  enabled: true
  path: /myapp

rollout:
  enabled: true
  strategy:
    type: canary
    canary:
      trafficRouting:
        istio:
          enabled: true

kargo:
  enabled: true
  project: myproject
```

**New values (v2.0.0):**
```yaml
image:
  repository: nginx
  tag: "1.25"

rollout:
  enabled: true
  strategy:
    type: canary

# Istio subchart
istio-routing:
  enabled: true
  ingress:
    enabled: true
    path: /myapp
  trafficRouting:
    enabled: true

# Kargo subchart
kargo-config:
  enabled: true
  project:
    name: myproject
```

### Step 3: Update Dependencies
```powershell
cd helm-charts/app-template
helm dependency update
```

### Step 4: Test Upgrade (Dry Run)
```powershell
# Test the upgrade without applying
helm upgrade myapp ./helm-charts/app-template -f myapp-new-values.yaml --dry-run --debug
```

### Step 5: Perform Upgrade
```powershell
# Apply the upgrade
helm upgrade myapp ./helm-charts/app-template -f myapp-new-values.yaml
```

## Automated Migration Script

Save as `migrate-values.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$OldValuesFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

# Read old values
$oldValues = Get-Content $OldValuesFile -Raw | ConvertFrom-Yaml

# Create new structure
$newValues = @{
    image = $oldValues.image
    rollout = @{
        enabled = $oldValues.rollout.enabled
        replicas = $oldValues.rollout.replicas
        strategy = @{
            type = $oldValues.rollout.strategy.type
        }
    }
    service = $oldValues.service
    resources = $oldValues.resources
}

# Add canary steps if present
if ($oldValues.rollout.strategy.canary) {
    $newValues.rollout.strategy.canary = @{
        steps = $oldValues.rollout.strategy.canary.steps
    }
}

# Migrate ingress to istio-routing
$newValues["istio-routing"] = @{
    enabled = $true
    ingress = @{
        enabled = $oldValues.ingress.enabled
        path = $oldValues.ingress.path
        pathType = $oldValues.ingress.pathType
    }
    trafficRouting = @{
        enabled = $oldValues.rollout.strategy.canary.trafficRouting.istio.enabled
    }
    service = @{
        port = $oldValues.service.port
    }
}

# Migrate kargo
if ($oldValues.kargo.enabled) {
    $newValues["kargo-config"] = @{
        enabled = $true
        project = @{
            name = $oldValues.kargo.project
        }
        stages = $oldValues.kargo.stages
    }
}

# Write new values
$newValues | ConvertTo-Yaml | Out-File $OutputFile

Write-Host "✓ Migration complete: $OutputFile" -ForegroundColor Green
Write-Host "Review the file and test with: helm upgrade --dry-run" -ForegroundColor Yellow
```

**Usage:**
```powershell
# Requires PowerShell-yaml module
Install-Module powershell-yaml -Scope CurrentUser

# Run migration
.\migrate-values.ps1 -OldValuesFile myapp-old-values.yaml -OutputFile myapp-new-values.yaml
```

## Breaking Changes

### 1. Ingress Configuration
```yaml
# OLD - No longer works
ingress:
  path: /myapp

# NEW - Required format
istio-routing:
  ingress:
    path: /myapp
```

### 2. Traffic Routing
```yaml
# OLD - Nested under rollout
rollout:
  strategy:
    canary:
      trafficRouting:
        istio:
          enabled: true

# NEW - Separate subchart
istio-routing:
  trafficRouting:
    enabled: true
```

### 3. Kargo Configuration
```yaml
# OLD - Top level
kargo:
  enabled: true

# NEW - Subchart
kargo-config:
  enabled: true
```

## Rollback Plan

If migration fails, rollback to v1.0.0:

```powershell
# List releases
helm history myapp

# Rollback to previous version
helm rollback myapp 1

# Or reinstall v1.0.0
git checkout tags/v1.0.0
helm upgrade myapp ./helm-charts/app-template -f myapp-old-values.yaml
```

## Verification Checklist

After migration, verify:

- [ ] Application pods are running
  ```powershell
  kubectl get rollouts
  kubectl get pods -l app.kubernetes.io/instance=myapp
  ```

- [ ] Service is accessible
  ```powershell
  kubectl get svc -l app.kubernetes.io/instance=myapp
  ```

- [ ] Istio routing works
  ```powershell
  kubectl get virtualservices
  kubectl get destinationrules
  ```

- [ ] Kargo stages created (if enabled)
  ```powershell
  kubectl get stages -n kargo
  ```

- [ ] Application is accessible via gateway
  ```powershell
  curl -k https://localhost:8443/myapp
  ```

## Command Quick Reference

### Export current deployment
```powershell
helm get values myapp -o yaml > current-values.yaml
helm get manifest myapp > current-manifest.yaml
```

### Compare old vs new templates
```powershell
# Old version template
git checkout v1.0.0
helm template myapp ./helm-charts/app-template -f values.yaml > old-template.yaml

# New version template
git checkout v2.0.0
helm template myapp ./helm-charts/app-template -f values.yaml > new-template.yaml

# Compare
code --diff old-template.yaml new-template.yaml
```

### Upgrade with confirmation
```powershell
# 1. Dry run first
helm upgrade myapp ./helm-charts/app-template -f new-values.yaml --dry-run

# 2. Apply if looks good
helm upgrade myapp ./helm-charts/app-template -f new-values.yaml

# 3. Monitor rollout
kubectl get rollouts -w
```

## Troubleshooting

### Error: "subchart not found"
```powershell
# Update dependencies
cd helm-charts/app-template
helm dependency update
```

### Error: "unknown field"
Check for old value paths in your values file. Use the mapping table above.

### Pods not starting
```powershell
# Check rollout status
kubectl describe rollout myapp-app-template

# Check pod events
kubectl get events --sort-by='.lastTimestamp'
```

### VirtualService not created
```powershell
# Verify subchart is enabled
helm get values myapp | grep -A5 "istio-routing"

# Should show:
istio-routing:
  enabled: true
```

## Support

For issues during migration:
1. Check [ARCHITECTURE.md](ARCHITECTURE.md) for understanding the new structure
2. Review [values-examples.yaml](values-examples.yaml) for configuration examples
3. Test with `--dry-run` before applying changes
4. Keep old values file as backup

## New Features in v2.0.0

Beyond modular structure, v2.0.0 adds:

✨ **Subchart Isolation** - Enable/disable Istio or Kargo independently
✨ **Better Defaults** - Sensible defaults per subchart
✨ **Clearer Ownership** - Each subchart manages its own resources
✨ **Future-Proof** - Easy to add new subcharts (monitoring, logging, etc.)

## Next Steps

After migration:
- Review [README.md](README.md) for new usage patterns
- Check [values-examples.yaml](values-examples.yaml) for advanced configurations
- Consider enabling additional subcharts as needed
