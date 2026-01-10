# Kubernetes Dashboard Quick Reference

## Installation
```powershell
.\scripts\install-dashboard.ps1
```

This creates:
- Dashboard UI in `kubernetes-dashboard` namespace
- Admin service account: `admin-user`
- Token saved to: `.\credentials\dashboard-token.txt`

## Accessing the Dashboard

### Method 1: kubectl proxy (Recommended)
```powershell
# Start the proxy
kubectl proxy

# Open in browser:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Method 2: Port Forward
```powershell
# Forward port 8443
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443

# Open in browser:
# https://localhost:8443
```

## Authentication

1. Select **Token** authentication method
2. Copy token from `.\credentials\dashboard-token.txt`
3. Paste and sign in

### Regenerate Token
```powershell
.\scripts\generate-dashboard-token.ps1
```

## Custom Service Accounts

### Read-Only Access
```powershell
.\scripts\create-service-account.ps1 -ServiceAccountName "dashboard-viewer" -Role "view"
```

### Namespace-Specific Admin
```powershell
.\scripts\create-service-account.ps1 -ServiceAccountName "app-admin" -Namespace "my-app" -Role "admin"
```

### Full Cluster Access
```powershell
.\scripts\create-service-account.ps1 -ServiceAccountName "cluster-admin-user" -Role "cluster-admin"
```

## Dashboard Features

- **Overview**: Cluster resource usage, pods, deployments
- **Workloads**: Deployments, ReplicaSets, StatefulSets, DaemonSets
- **Services**: Services, Ingresses, Network Policies
- **Config**: ConfigMaps, Secrets, PVCs
- **Cluster**: Nodes, Namespaces, Roles
- **Logs**: View pod logs directly in browser
- **Shell**: Execute commands in running pods

## Troubleshooting

### Token Expired
```powershell
# Generate a new token
.\scripts\generate-dashboard-token.ps1
```

### Port Already in Use
```powershell
# Use a different port
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 9443:443
```

### Dashboard Pods Not Running
```powershell
# Check pod status
kubectl get pods -n kubernetes-dashboard

# View logs
kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard

# Restart dashboard
kubectl rollout restart deployment kubernetes-dashboard -n kubernetes-dashboard
```

## Security Notes

- The default `admin-user` service account has **cluster-admin** privileges
- For production, create service accounts with minimal required permissions
- Tokens are long-lived (10 years by default) - store securely
- Consider using OIDC authentication for production clusters
- Never commit tokens to version control (credentials/ is gitignored)

## Uninstall

```powershell
# Remove dashboard
kubectl delete namespace kubernetes-dashboard

# Remove cluster role binding
kubectl delete clusterrolebinding admin-user
```
