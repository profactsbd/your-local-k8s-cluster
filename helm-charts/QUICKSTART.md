# 🚀 Quick Start - Modular Helm Chart

## What's New in v2.0.0

The Helm chart is now **modular** with 3 components:

```
app-template (main)
├── istio-routing (optional) - VirtualService & DestinationRule
└── kargo-config (optional) - Multi-stage deployments
```

## 📦 Installation Patterns

### Pattern 1: Web Application
```bash
helm install webapp ./helm-charts/app-template \
  --set image.repository=nginx \
  --set image.tag=alpine \
  --set istio-routing.ingress.path=/webapp
```
✅ App + Istio routing  
🌐 Access: https://localhost:8443/webapp

### Pattern 2: Canary Deployment
```bash
helm install api ./helm-charts/app-template \
  --set image.repository=myapi \
  --set image.tag=v1.0.0 \
  --set rollout.enabled=true \
  --set istio-routing.trafficRouting.enabled=true \
  --set istio-routing.ingress.path=/api
```
✅ App + Canary routing + Argo Rollouts  
🔄 Progressive traffic shifting

### Pattern 3: Full GitOps
```bash
helm install myapp ./helm-charts/app-template \
  --set image.repository=myapp \
  --set istio-routing.ingress.path=/myapp \
  --set kargo-config.enabled=true
```
✅ App + Istio + Kargo multi-stage  
🚢 dev → staging → prod pipeline

### Pattern 4: Minimal (No Service Mesh)
```bash
helm install basic ./helm-charts/app-template \
  --set image.repository=nginx \
  --set istio-routing.enabled=false
```
✅ Core app only  
📦 Vanilla Kubernetes

## 🎛️ Enable/Disable Components

```yaml
# values.yaml
istio-routing:
  enabled: true    # false = no Istio resources

kargo-config:
  enabled: false   # true = enable multi-stage
```

## 📊 What Gets Deployed

### Always Deployed (Main Chart)
- ✅ Rollout or Deployment
- ✅ Service (ClusterIP)
- ✅ ServiceAccount

### When `istio-routing.enabled: true`
- ✅ VirtualService (path routing)
- ✅ DestinationRule (if canary enabled)

### When `kargo-config.enabled: true`
- ✅ Kargo Stages (dev, staging, prod)
- ✅ ArgoCD integration

## 🔧 Common Configurations

### Change Path
```bash
--set istio-routing.ingress.path=/custom-path
```

### Change Image
```bash
--set image.repository=myregistry/myapp \
--set image.tag=v2.0.0
```

### Enable Canary
```bash
--set rollout.enabled=true \
--set istio-routing.trafficRouting.enabled=true
```

### Set Replicas
```bash
--set rollout.replicas=5
```

## 📚 Documentation

| File | What's Inside |
|------|---------------|
| [README.md](helm-charts/README.md) | Overview & summary |
| [app-template/README.md](helm-charts/app-template/README.md) | Complete usage guide |
| [ARCHITECTURE.md](helm-charts/ARCHITECTURE.md) | Diagrams & patterns |
| [MIGRATION.md](helm-charts/MIGRATION.md) | Upgrade from v1 to v2 |
| [values-examples.yaml](helm-charts/app-template/values-examples.yaml) | 5 real examples |

## 🧪 Testing

```bash
# Render templates without deploying
helm template test ./helm-charts/app-template

# Dry run
helm install test ./helm-charts/app-template --dry-run --debug

# Check what resources will be created
helm template test ./helm-charts/app-template | grep "^kind:"
```

## 🔄 Upgrade Existing Deployment

```bash
# From v1.0.0 to v2.0.0
helm upgrade myapp ./helm-charts/app-template \
  --set istio-routing.ingress.path=/myapp \
  --set istio-routing.trafficRouting.enabled=false
```

See [MIGRATION.md](helm-charts/MIGRATION.md) for details.

## 📂 Chart Structure

```
helm-charts/app-template/
├── Chart.yaml              # Dependencies defined here
├── values.yaml             # All default values
├── templates/              # Main app resources
│   ├── rollout.yaml
│   ├── service.yaml
│   └── serviceaccount.yaml
└── charts/                 # Subcharts
    ├── istio-routing/      # Istio components
    └── kargo-config/       # Kargo stages
```

## ⚡ Quick Commands

```bash
# Update dependencies
cd helm-charts/app-template && helm dependency update

# List subcharts
helm dependency list ./helm-charts/app-template

# Show values
helm show values ./helm-charts/app-template

# Get deployed values
helm get values myapp

# Uninstall
helm uninstall myapp
```

## 💡 Tips

✅ Start with `istio-routing.enabled: true` for web apps  
✅ Enable `trafficRouting` only for canary deployments  
✅ Use `kargo-config` for multi-environment workflows  
✅ Disable all subcharts for vanilla Kubernetes  
✅ Test with `--dry-run` before real deployment

## 🆘 Need Help?

1. Check [app-template/README.md](helm-charts/app-template/README.md) for detailed docs
2. Review [values-examples.yaml](helm-charts/app-template/values-examples.yaml) for patterns
3. See [ARCHITECTURE.md](helm-charts/ARCHITECTURE.md) for how it works
4. Use `helm template --debug` to troubleshoot

---

**Ready to deploy?** Pick a pattern above and run it! 🚀
