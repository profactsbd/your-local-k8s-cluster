# Helm Chart Build and Verification Guide

## Overview

Helm chart verification is integrated into the build system through both PowerShell (`build.ps1`) and Makefile targets. This ensures charts are validated before deployment.

## Available Commands

### PowerShell (build.ps1)

```powershell
# Lint charts for syntax errors
.\build.ps1 helm-lint

# Test template rendering with different configurations
.\build.ps1 helm-template

# Run Helm tests on deployed release
.\build.ps1 helm-test

# Package charts into .tgz files
.\build.ps1 helm-package

# Run all verifications (lint + template)
.\build.ps1 helm-verify

# Complete build (deps + verify + package)
.\build.ps1 helm-build
```

### Make

```bash
# Lint charts
make helm-lint

# Test templates
make helm-template

# Run tests
make helm-test

# Package charts
make helm-package

# Verify charts
make helm-verify

# Full build
make helm-build
```

## Verification Steps

### 1. Helm Lint

**Command**: `.\build.ps1 helm-lint` or `make helm-lint`

**Purpose**: Validates chart structure and syntax

**Checks**:
- Chart.yaml validity
- Template syntax errors
- Required fields presence
- Value schema validation

**Output**:
```
=== Linting Helm Charts ===
Linting chart: app-template
==> Linting D:\Learnings\kubernetes\my-local-cluster\helm-charts\app-template
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

✓ Helm lint passed!
```

### 2. Template Testing

**Command**: `.\build.ps1 helm-template` or `make helm-template`

**Purpose**: Validates template rendering with different configurations

**Test Scenarios**:
1. **Basic rendering** - Default values
2. **Istio routing** - With custom path
3. **Canary enabled** - Traffic splitting configuration
4. **Kargo enabled** - Multi-stage deployment

**Output**:
```
=== Testing Chart Template Rendering ===
Testing basic rendering...
✓ Basic rendering passed

Testing with Istio routing...
✓ Istio routing passed

Testing with canary enabled...
✓ Canary routing passed

Testing with Kargo enabled...
✓ Kargo config passed

✓ All template tests passed!
```

### 3. Helm Tests

**Command**: `.\build.ps1 helm-test` or `make helm-test`

**Purpose**: Runs automated tests on deployed releases

**Prerequisites**: A Helm release must be deployed

**Process**:
1. Lists available Helm releases
2. Prompts for release name
3. Executes all test pods
4. Shows test results with logs

**Tests Run**:
- Service connectivity
- Rollout health
- Service endpoints
- VirtualService configuration (if enabled)
- DestinationRule subsets (if canary)
- Kargo stages (if enabled)

### 4. Chart Packaging

**Command**: `.\build.ps1 helm-package` or `make helm-package`

**Purpose**: Creates distributable .tgz chart packages

**Process**:
1. Updates chart dependencies
2. Packages main chart with subcharts
3. Saves to `helm-charts/packages/` directory

**Output**:
```
=== Packaging Helm Charts ===
Updating dependencies...
...
Packaging chart...
Successfully packaged chart and saved it to: helm-charts\packages\app-template-2.0.0.tgz

✓ Chart packaged successfully!
Package location: helm-charts\packages
  - app-template-2.0.0.tgz
```

### 5. Complete Verification

**Command**: `.\build.ps1 helm-verify` or `make helm-verify`

**Purpose**: Runs all verification steps

**Steps**:
1. Helm lint
2. Template testing (4 scenarios)

**Output**:
```
=== Running All Helm Verifications ===

[1/2] Running helm lint...
✓ Helm lint passed!

[2/2] Running template tests...
✓ All template tests passed!

═══════════════════════════════════════
✓ All Helm verifications passed!
═══════════════════════════════════════
```

### 6. Full Build

**Command**: `.\build.ps1 helm-build` or `make helm-build`

**Purpose**: Complete chart build pipeline

**Steps**:
1. Update dependencies
2. Lint charts
3. Test templates
4. Package charts

**Output**:
```
=== Building Helm Charts ===

[1/4] Updating dependencies...
✓ Dependencies updated

[2/4] Linting charts...
✓ Helm lint passed!

[3/4] Testing templates...
✓ All template tests passed!

[4/4] Packaging charts...
✓ Chart packaged successfully!

═══════════════════════════════════════
✓ Helm chart build complete!
═══════════════════════════════════════
```

## Integration with Workflows

### Pre-Commit Hook

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/sh
echo "Running Helm verification..."
make helm-verify || exit 1
```

### CI/CD Pipeline

**GitHub Actions**: See [.github/workflows/helm-ci.yml](.github/workflows/helm-ci.yml)

**GitLab CI**:
```yaml
helm-verify:
  stage: verify
  script:
    - make helm-verify
  only:
    - merge_requests
    - main
```

### Development Workflow

**Recommended sequence**:
```powershell
# 1. Make changes to charts
code helm-charts/app-template/

# 2. Verify changes
.\build.ps1 helm-verify

# 3. Build if verification passes
.\build.ps1 helm-build

# 4. Deploy to test environment
helm upgrade --install test-app ./helm-charts/app-template --wait

# 5. Run integration tests
.\build.ps1 helm-test
```

## Troubleshooting

### Lint Failures

**Error**: `yaml: line X: mapping values are not allowed in this context`

**Solution**: Check YAML indentation and syntax

**Error**: `chart requires kubeVersion: >=1.20.0 which is incompatible`

**Solution**: Update Chart.yaml kubeVersion or upgrade cluster

### Template Rendering Failures

**Error**: `Error: template: ... undefined variable`

**Solution**: Check values.yaml has all required fields

**Error**: `Error: unable to build kubernetes objects from release manifest`

**Solution**: Verify CRDs are installed (Argo Rollouts, Istio, Kargo)

### Test Failures

**Error**: `Error: timed out waiting for the condition`

**Solution**: 
- Increase timeout: `helm test myapp --timeout 10m`
- Check pod status: `kubectl get pods`
- View test logs: `kubectl logs <test-pod-name>`

### Packaging Failures

**Error**: `Error: found in Chart.yaml, but missing in charts/ directory`

**Solution**: Run `helm dependency update` in chart directory

## Best Practices

✅ **Run verifications before commits**
```powershell
.\build.ps1 helm-verify
git commit -m "Update chart"
```

✅ **Use helm-build for releases**
```powershell
# Build and package
.\build.ps1 helm-build

# Tag release
git tag -a v2.0.0 -m "Release v2.0.0"

# Package is in helm-charts/packages/
```

✅ **Test in CI/CD pipeline**
- Lint on every PR
- Template test with multiple configs
- Integration test on merge to main

✅ **Version charts properly**
- Update Chart.yaml version
- Follow semantic versioning
- Document changes in CHANGELOG

✅ **Validate before deployment**
```powershell
# Development
.\build.ps1 helm-verify
helm upgrade --install dev-app ./helm-charts/app-template -n dev

# Staging
.\build.ps1 helm-build
helm upgrade --install staging-app ./helm-charts/packages/app-template-2.0.0.tgz -n staging
.\build.ps1 helm-test

# Production (after staging tests pass)
helm upgrade --install prod-app ./helm-charts/packages/app-template-2.0.0.tgz -n production
.\build.ps1 helm-test
```

## Automated Verification in CI

The GitHub Actions workflow (`.github/workflows/helm-ci.yml`) automatically:

1. **On every push/PR**:
   - Lints all charts
   - Tests template rendering
   - Packages charts
   - Uploads artifacts

2. **Integration tests**:
   - Creates kind cluster
   - Installs prerequisites (Istio, Argo Rollouts)
   - Deploys test application
   - Runs Helm tests
   - Validates all resources

3. **Security scanning**:
   - Runs Trivy vulnerability scan
   - Reports to GitHub Security

## Quick Reference

| Command | Purpose | Time | Exit on Fail |
|---------|---------|------|--------------|
| `helm-lint` | Syntax check | <5s | Yes |
| `helm-template` | Rendering test | <10s | Yes |
| `helm-test` | Integration test | 1-5min | Yes |
| `helm-package` | Create .tgz | <5s | Yes |
| `helm-verify` | Lint + Template | <15s | Yes |
| `helm-build` | Full pipeline | <30s | Yes |

## Next Steps

- Integrate into your CI/CD pipeline
- Set up pre-commit hooks
- Add custom validation logic
- Create release automation

For more details, see:
- [TESTING.md](TESTING.md) - Helm test documentation
- [TEST-REFERENCE.md](TEST-REFERENCE.md) - Quick test reference
- [.github/workflows/helm-ci.yml](.github/workflows/helm-ci.yml) - CI configuration
