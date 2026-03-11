# Perplexica Kubernetes Manifests

This directory contains Kubernetes manifests for deploying Perplexica + SearXNG to a Kubernetes cluster.

## Directory Structure

```
perplexica/
├── README.md                          # This file
├── configs/                           # Configuration files (copied from services/perplexica/configs/)
│   ├── perplexica.toml               # Perplexica config (to be copied)
│   └── searxng/                      # SearXNG configs (to be copied)
├── 01-pvcs.yaml                      # PersistentVolumeClaims (to be created)
├── 02-searxng-statefulset.yaml       # SearXNG StatefulSet + Services (to be created)
├── 03-perplexica-deployment.yaml     # Perplexica Deployment (to be created)
├── 04-services.yaml                  # Perplexica Service (to be created)
├── 05-ingress.yaml                   # Ingress resource (to be created)
├── 06-networkpolicy.yaml             # Network policies (optional, to be created)
└── 07-hpa.yaml                       # Horizontal Pod Autoscaler (optional, to be created)
```

## Usage

### Prerequisites

1. **Kubernetes cluster** running (k3s, microk8s, Docker Desktop K8s, or cloud)
2. **kubectl** configured to access cluster
3. **Storage provisioner** installed (k3s includes local-path by default)
4. **Ingress controller** installed (nginx-ingress recommended)

### Preparation

Before applying manifests, copy configuration files:

```bash
# From carian-observatory root
cp services/perplexica/configs/perplexica.toml kubernetes/perplexica/configs/
cp -r services/perplexica/configs/searxng kubernetes/perplexica/configs/
```

### Deployment

**Step 1: Create namespace**
```bash
kubectl create namespace perplexica
kubectl config set-context --current --namespace=perplexica
```

**Step 2: Create ConfigMaps**
```bash
kubectl create configmap perplexica-config \
  --from-file=perplexica.toml=configs/perplexica.toml \
  -n perplexica

kubectl create configmap searxng-config \
  --from-file=configs/searxng/ \
  -n perplexica
```

**Step 3: Apply manifests in order**
```bash
kubectl apply -f 01-pvcs.yaml
kubectl apply -f 02-searxng-statefulset.yaml
kubectl apply -f 03-perplexica-deployment.yaml
kubectl apply -f 04-services.yaml
kubectl apply -f 05-ingress.yaml

# Optional: Network policies for security hardening
kubectl apply -f 06-networkpolicy.yaml

# Optional: Horizontal Pod Autoscaler for auto-scaling
kubectl apply -f 07-hpa.yaml
```

**Step 4: Verify deployment**
```bash
kubectl get pods -n perplexica
kubectl get svc -n perplexica
kubectl get ingress -n perplexica
```

### Quick Commands

```bash
# View all resources
kubectl get all -n perplexica

# Check pod logs
kubectl logs -n perplexica -l app=perplexica --tail=50
kubectl logs -n perplexica searxng-0 --tail=50

# Test service connectivity
kubectl exec -n perplexica deployment/perplexica -- \
  curl -s http://searxng-service:8080/healthz

# Port-forward for local testing (bypassing Ingress)
kubectl port-forward -n perplexica svc/perplexica-service 3000:3000
# Access: http://localhost:3000

# Scale deployment
kubectl scale deployment perplexica --replicas=3 -n perplexica

# Restart deployment
kubectl rollout restart deployment perplexica -n perplexica
```

## Creating Manifests

The YAML manifest files listed above need to be created based on the templates in:
**[/docs/kubernetes/MIGRATION-PLAN-PERPLEXICA.md](../../docs/kubernetes/MIGRATION-PLAN-PERPLEXICA.md)**

Copy the manifest examples from the migration plan into the corresponding files:

- `01-pvcs.yaml` → Section "01-pvcs.yaml" in migration plan
- `02-searxng-statefulset.yaml` → Section "02-searxng-statefulset.yaml" in migration plan
- `03-perplexica-deployment.yaml` → Section "03-perplexica-deployment.yaml" in migration plan
- `04-services.yaml` → Section "04-services.yaml" in migration plan
- `05-ingress.yaml` → Section "05-ingress.yaml" in migration plan
- `06-networkpolicy.yaml` → Section "06-networkpolicy.yaml" in migration plan
- `07-hpa.yaml` → Section "Appendix B: Scaling Strategies" in migration plan

**⚠️ Important:** Update domain names in `05-ingress.yaml` before applying:
```yaml
# Replace with your actual domain
host: perplexica.yourdomain.com
```

## Rollback to Docker Compose

If you need to rollback:

```bash
# Scale down K8s deployment
kubectl scale deployment perplexica --replicas=0 -n perplexica

# Start Docker Compose version
cd ../..
docker compose up -d

# Or delete namespace entirely (data will be lost unless backed up)
kubectl delete namespace perplexica
```

## Data Migration

### From Docker Compose to Kubernetes

See migration plan for detailed procedures:
**[Migration Procedure → Phase 2: Storage Migration](../../docs/kubernetes/MIGRATION-PLAN-PERPLEXICA.md#phase-2-storage-migration-1-2-hours)**

### From Kubernetes to Docker Compose

See migration plan for detailed recovery procedures:
**[Rollback Procedure → Data Recovery from Kubernetes](../../docs/kubernetes/MIGRATION-PLAN-PERPLEXICA.md#data-recovery-from-kubernetes)**

## Troubleshooting

Common issues and solutions documented in:
**[Appendix A: Troubleshooting Guide](../../docs/kubernetes/MIGRATION-PLAN-PERPLEXICA.md#appendix-a-troubleshooting-guide)**

Quick diagnostics:

```bash
# Check pod status
kubectl get pods -n perplexica
kubectl describe pod -n perplexica <pod-name>

# Check events
kubectl get events -n perplexica --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n perplexica <pod-name>

# Check service endpoints
kubectl get endpoints -n perplexica

# Check PVC status
kubectl get pvc -n perplexica
```

## Monitoring

Once deployed, monitor via:

- **kubectl:** `kubectl top pods -n perplexica`
- **Prometheus:** Metrics scraped from pods (if ServiceMonitor configured)
- **Grafana:** Create dashboard with Perplexica metrics
- **Logs:** Aggregated via Loki (if promtail configured)

## Status

**Current Status:** 📝 Ready for implementation

**Checklist:**
- [ ] Configuration files copied to `configs/`
- [ ] Manifest files created from migration plan templates
- [ ] Domain name updated in `05-ingress.yaml`
- [ ] Namespace created
- [ ] ConfigMaps created
- [ ] Manifests applied
- [ ] Pods running and healthy
- [ ] Ingress accessible
- [ ] Data migrated (if needed)
- [ ] Monitoring configured
- [ ] Rollback procedure tested

---

**See also:**
- [Migration Plan](../../docs/kubernetes/MIGRATION-PLAN-PERPLEXICA.md) - Complete step-by-step guide
- [K8s Documentation Overview](../../docs/kubernetes/README.md) - Migration strategy and resources
