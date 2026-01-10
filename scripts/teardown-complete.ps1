#!/usr/bin/env pwsh
# Complete teardown: Delete all deployments, uninstall tools, delete cluster, clean files

param(
    [switch]$Force,
    [switch]$KeepCluster
)

$ErrorActionPreference = "Continue"

Write-Host @"
╔═══════════════════════════════════════════════╗
║       Complete Teardown                       ║
║  - Delete all deployments                     ║
║  - Uninstall all tools                        ║
║  - Delete kind cluster                        ║
║  - Clean local files                          ║
╚═══════════════════════════════════════════════╝
"@ -ForegroundColor Yellow

if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This will:" -ForegroundColor Red
    Write-Host "   • Delete all Helm deployments (spring-kotlin-app, etc.)" -ForegroundColor Yellow
    Write-Host "   • Uninstall all tools (Istio, ArgoCD, Kargo, Dashboard, etc.)" -ForegroundColor Yellow
    Write-Host "   • Delete the kind cluster 'my-local-cluster'" -ForegroundColor Yellow
    Write-Host "   • Remove tools/ and credentials/ directories" -ForegroundColor Yellow
    
    $confirm = Read-Host "`nType 'DELETE' to confirm"
    if ($confirm -ne "DELETE") {
        Write-Host "`n✓ Teardown cancelled." -ForegroundColor Cyan
        exit 0
    }
}

Write-Host "`n" -NoNewline

# Step 1: Delete all Helm deployments
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 1/5: Deleting Helm Deployments" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan

# Check if cluster is accessible
try {
    kubectl cluster-info | Out-Null
    $clusterAccessible = $true
} catch {
    Write-Host "⚠️  Cluster not accessible, skipping deployments cleanup" -ForegroundColor Yellow
    $clusterAccessible = $false
}

if ($clusterAccessible) {
    # Get all Helm releases
    $helmReleases = helm list --all-namespaces -o json 2>$null | ConvertFrom-Json
    
    if ($helmReleases -and $helmReleases.Count -gt 0) {
        Write-Host "`nFound $($helmReleases.Count) Helm release(s):" -ForegroundColor Yellow
        foreach ($release in $helmReleases) {
            Write-Host "  • $($release.name) (namespace: $($release.namespace))" -ForegroundColor White
        }
        
        Write-Host "`nDeleting Helm releases..." -ForegroundColor Yellow
        foreach ($release in $helmReleases) {
            Write-Host "  Deleting: $($release.name) from namespace $($release.namespace)..." -ForegroundColor Cyan
            helm uninstall $release.name -n $release.namespace 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✓ Deleted" -ForegroundColor Green
            } else {
                Write-Host "    ⚠️  Failed or already deleted" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "✓ No Helm releases found" -ForegroundColor Green
    }
    
    # Delete application namespaces
    Write-Host "`nDeleting application namespaces..." -ForegroundColor Yellow
    $appNamespaces = @("spring-kotlin-app", "spring-kotlin-app-project")
    foreach ($ns in $appNamespaces) {
        $exists = kubectl get namespace $ns --ignore-not-found=true 2>$null
        if ($exists) {
            Write-Host "  Deleting namespace: $ns..." -ForegroundColor Cyan
            kubectl delete namespace $ns --timeout=60s 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✓ Deleted" -ForegroundColor Green
            } else {
                Write-Host "    ⚠️  Failed or timed out" -ForegroundColor Yellow
            }
        }
    }
}

# Step 2: Uninstall all tools
Write-Host "`n════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 2/5: Uninstalling Tools" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan

if ($clusterAccessible) {
    & "$PSScriptRoot\uninstall-all.ps1" -Force
} else {
    Write-Host "⚠️  Skipping tool uninstallation (cluster not accessible)" -ForegroundColor Yellow
}

# Step 3: Delete cluster
if (-not $KeepCluster) {
    Write-Host "`n════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Step 3/5: Deleting Kind Cluster" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $clusterExists = kind get clusters 2>$null | Select-String -Pattern "my-local-cluster"
    if ($clusterExists) {
        Write-Host "Deleting kind cluster 'my-local-cluster'..." -ForegroundColor Yellow
        kind delete cluster --name my-local-cluster
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Cluster deleted" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Failed to delete cluster" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✓ Cluster 'my-local-cluster' not found" -ForegroundColor Green
    }
} else {
    Write-Host "`n════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Step 3/5: Keeping Cluster (--KeepCluster)" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan
}

# Step 4: Clean tools directory
Write-Host "`n════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 4/5: Cleaning Tools Directory" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan

$toolsDir = "$PSScriptRoot\..\tools"
if (Test-Path $toolsDir) {
    Write-Host "Removing tools directory..." -ForegroundColor Yellow
    try {
        Remove-Item $toolsDir -Recurse -Force -ErrorAction Stop
        Write-Host "✓ Removed tools/" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Failed to remove tools/: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Tools directory not found" -ForegroundColor Green
}

# Step 5: Clean credentials directory
Write-Host "`n════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 5/5: Cleaning Credentials Directory" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════" -ForegroundColor Cyan

$credsDir = "$PSScriptRoot\..\credentials"
if (Test-Path $credsDir) {
    Write-Host "Removing credentials directory..." -ForegroundColor Yellow
    try {
        Remove-Item $credsDir -Recurse -Force -ErrorAction Stop
        Write-Host "✓ Removed credentials/" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Failed to remove credentials/: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Credentials directory not found" -ForegroundColor Green
}

# Summary
Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     Teardown Complete!                     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n✓ Completed:" -ForegroundColor Green
Write-Host "  • Deleted all Helm deployments" -ForegroundColor White
Write-Host "  • Uninstalled all tools" -ForegroundColor White
if (-not $KeepCluster) {
    Write-Host "  • Deleted kind cluster" -ForegroundColor White
}
Write-Host "  • Cleaned tools/ directory" -ForegroundColor White
Write-Host "  • Cleaned credentials/ directory" -ForegroundColor White

Write-Host "`n📝 To recreate the cluster:" -ForegroundColor Cyan
Write-Host "  .\build.ps1 setup" -ForegroundColor White
Write-Host "  or" -ForegroundColor Yellow
Write-Host "  make setup" -ForegroundColor White
Write-Host ""
