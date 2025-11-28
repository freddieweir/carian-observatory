# Perplexica + SearXNG Migration to Kubernetes

**Status:** Planning
**Priority:** Medium
**Complexity:** 🟢 Easy-Medium
**Estimated Time:** 4-8 hours (including testing)

## Executive Summary

This document outlines the migration of the Perplexica AI search stack (Perplexica + SearXNG) from Docker Compose to Kubernetes as a proof of concept for broader K8s adoption in Carian Observatory.

**Why Perplexica First?**
- ✅ Stateless workload (good for K8s learning curve)
- ✅ Independent service (no tight coupling to other services)
- ✅ Resource-intensive (benefits from K8s resource management)
- ✅ Horizontal scaling potential (AI search can benefit from multiple replicas)
- ✅ Low migration risk (can run both environments in parallel)

**Success Criteria:**
1. Perplexica accessible via same domain (`perplexica.yourdomain.com`)
2. Search functionality identical to Docker Compose version
3. Data persistence (search history, uploads) preserved
4. Health checks passing, monitoring integrated
5. Rollback procedure tested and documented

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Comparison](#architecture-comparison)
3. [Migration Procedure](#migration-procedure)
4. [Kubernetes Manifests](#kubernetes-manifests)
5. [Testing & Validation](#testing--validation)
6. [Rollback Procedure](#rollback-procedure)
7. [Post-Migration Monitoring](#post-migration-monitoring)
8. [Lessons Learned](#lessons-learned)

---

## Prerequisites

### 1. Kubernetes Cluster

**Recommended for Local Development:**
- **k3s** (lightweight, production-grade)
- **microk8s** (Ubuntu-friendly, easy addons)
- **Docker Desktop K8s** (if already using Docker Desktop)

**Installation (k3s example):**
```bash
# Install k3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -

# Verify installation
sudo k3s kubectl get nodes

# Copy kubeconfig for standard kubectl access
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
chmod 600 ~/.kube/config

# Verify kubectl access
kubectl get nodes
```

### 2. Storage Provisioner

**k3s includes local-path-provisioner by default.**

Verify storage class:
```bash
kubectl get storageclass

# Expected output:
# NAME                   PROVISIONER             RECLAIMPOLICY
# local-path (default)   rancher.io/local-path   Delete
```

**For other K8s distributions:**
```bash
# Install local-path-provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### 3. Ingress Controller

**Install nginx-ingress:**
```bash
# For k3s (Traefik is default, but we'll use nginx for consistency)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Verify ingress controller is running
kubectl get pods -n ingress-nginx
```

**For microk8s:**
```bash
microk8s enable ingress
```

### 4. cert-manager (Optional - SSL/TLS)

If you want automated SSL certificate management:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Verify cert-manager
kubectl get pods -n cert-manager
```

### 5. External Secrets Operator (Optional - 1Password Integration)

For secure secrets management with 1Password Connect:
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# Configure 1Password Connect SecretStore (requires 1Password Connect in K8s)
```

**Note:** For Phase 1, we'll use K8s Secrets directly. ESO can be added in Phase 2.

---

## Architecture Comparison

### Current Docker Compose Architecture

```yaml
# services/perplexica/docker-compose.yml
services:
  perplexica:
    image: itzcrazykns1337/perplexica:main
    container_name: co-perplexica-service
    volumes:
      - perplexica-data:/home/perplexica/data
      - perplexica-uploads:/home/perplexica/uploads
      - ./configs/perplexica.toml:/home/perplexica/config.toml:ro
    environment:
      - SEARXNG_API_URL=http://searxng:8080
    networks:
      - app-network
    depends_on:
      - searxng

  searxng:
    image: docker.io/searxng/searxng:latest
    container_name: co-perplexica-searxng
    volumes:
      - ./configs/searxng:/etc/searxng:rw
    networks:
      - app-network
```

**Key Points:**
- Service-to-service communication via Docker network (`app-network`)
- Configuration via bind mounts (`.toml`, searxng configs)
- Data persistence via named volumes
- nginx reverse proxy routes `perplexica.yourdomain.com` to container

### Target Kubernetes Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Ingress Controller                    │
│          (perplexica.yourdomain.com → Service)        │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│               Perplexica Service (ClusterIP)            │
│                     (port 3000)                          │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Perplexica Deployment (1-3 replicas)       │
│  - Env: SEARXNG_API_URL=http://searxng-service:8080    │
│  - ConfigMap: perplexica.toml                           │
│  - PVC: perplexica-data, perplexica-uploads             │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              SearXNG Service (ClusterIP)                │
│                     (port 8080)                          │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│           SearXNG StatefulSet (1 replica)               │
│  - ConfigMap: searxng configs                           │
│  - PVC: searxng-data (for cache, optional)              │
└─────────────────────────────────────────────────────────┘
```

**Key Changes:**
- Service-to-service communication via K8s DNS (`searxng-service.perplexica.svc.cluster.local`)
- Configuration via ConfigMaps
- Data persistence via PersistentVolumeClaims
- Ingress resource routes external traffic
- StatefulSet for SearXNG (ensures stable network identity)
- Deployment for Perplexica (enables horizontal scaling)

---

## Migration Procedure

### Phase 1: Preparation (1 hour)

#### 1.1 Backup Existing Data

```bash
# Navigate to carian-observatory
cd /path/to/carian-observatory

# Backup Docker volumes
docker run --rm \
  -v carian-observatory_perplexica-data:/source:ro \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/perplexica-data-$(date +%Y%m%d-%H%M%S).tar.gz -C /source .

docker run --rm \
  -v carian-observatory_perplexica-uploads:/source:ro \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/perplexica-uploads-$(date +%Y%m%d-%H%M%S).tar.gz -C /source .

# Verify backups
ls -lh backups/perplexica-*
```

#### 1.2 Create Kubernetes Namespace

```bash
# Create dedicated namespace for perplexica
kubectl create namespace perplexica

# Set as default namespace for convenience
kubectl config set-context --current --namespace=perplexica

# Verify
kubectl get namespace perplexica
```

#### 1.3 Copy Configuration Files

```bash
# Copy configs to kubernetes manifest directory
mkdir -p kubernetes/perplexica/configs
cp services/perplexica/configs/perplexica.toml kubernetes/perplexica/configs/
cp -r services/perplexica/configs/searxng kubernetes/perplexica/configs/
```

### Phase 2: Storage Migration (1-2 hours)

#### 2.1 Create PersistentVolumeClaims

Apply the PVC manifests (see [Kubernetes Manifests](#kubernetes-manifests) section):

```bash
kubectl apply -f kubernetes/perplexica/01-pvcs.yaml

# Verify PVCs are bound
kubectl get pvc -n perplexica
```

#### 2.2 Migrate Data to Kubernetes Volumes

**Option A: Using a temporary pod to copy data**

```bash
# Create temporary data migration pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: data-migration
  namespace: perplexica
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: perplexica-data
      mountPath: /mnt/perplexica-data
    - name: perplexica-uploads
      mountPath: /mnt/perplexica-uploads
  volumes:
  - name: perplexica-data
    persistentVolumeClaim:
      claimName: perplexica-data-pvc
  - name: perplexica-uploads
    persistentVolumeClaim:
      claimName: perplexica-uploads-pvc
EOF

# Wait for pod to be ready
kubectl wait --for=condition=ready pod/data-migration -n perplexica --timeout=60s

# Copy data from backups to K8s volumes
kubectl cp backups/perplexica-data-*.tar.gz perplexica/data-migration:/tmp/data.tar.gz
kubectl exec -n perplexica data-migration -- sh -c "cd /mnt/perplexica-data && tar xzf /tmp/data.tar.gz"

kubectl cp backups/perplexica-uploads-*.tar.gz perplexica/data-migration:/tmp/uploads.tar.gz
kubectl exec -n perplexica data-migration -- sh -c "cd /mnt/perplexica-uploads && tar xzf /tmp/uploads.tar.gz"

# Verify data copied
kubectl exec -n perplexica data-migration -- ls -lah /mnt/perplexica-data
kubectl exec -n perplexica data-migration -- ls -lah /mnt/perplexica-uploads

# Clean up migration pod
kubectl delete pod data-migration -n perplexica
```

**Option B: Start fresh (if no critical data)**

Skip data migration, let Perplexica create new data directories.

### Phase 3: Deploy Kubernetes Resources (1 hour)

#### 3.1 Create ConfigMaps

```bash
# Create ConfigMap for perplexica.toml
kubectl create configmap perplexica-config \
  --from-file=perplexica.toml=kubernetes/perplexica/configs/perplexica.toml \
  -n perplexica

# Create ConfigMap for SearXNG configs
kubectl create configmap searxng-config \
  --from-file=kubernetes/perplexica/configs/searxng/ \
  -n perplexica

# Verify ConfigMaps
kubectl get configmap -n perplexica
kubectl describe configmap perplexica-config -n perplexica
```

#### 3.2 Deploy SearXNG StatefulSet

```bash
kubectl apply -f kubernetes/perplexica/02-searxng-statefulset.yaml

# Watch deployment
kubectl get pods -n perplexica -w

# Verify SearXNG is healthy
kubectl logs -n perplexica searxng-0 --tail=50
```

#### 3.3 Deploy Perplexica Deployment

```bash
kubectl apply -f kubernetes/perplexica/03-perplexica-deployment.yaml

# Watch deployment
kubectl get pods -n perplexica -w

# Verify Perplexica is healthy
kubectl logs -n perplexica -l app=perplexica --tail=50
```

#### 3.4 Create Services

```bash
kubectl apply -f kubernetes/perplexica/04-services.yaml

# Verify services
kubectl get svc -n perplexica
```

#### 3.5 Configure Ingress

**Note:** Update `kubernetes/perplexica/05-ingress.yaml` with your actual domain before applying.

```bash
# Apply Ingress resource
kubectl apply -f kubernetes/perplexica/05-ingress.yaml

# Verify Ingress
kubectl get ingress -n perplexica
kubectl describe ingress perplexica-ingress -n perplexica
```

**If using existing nginx in Docker Compose:**

You'll need to configure nginx to route to K8s Ingress Controller's NodePort or LoadBalancer IP:

```bash
# Get Ingress Controller LoadBalancer/NodePort
kubectl get svc -n ingress-nginx

# Update nginx config to proxy_pass to K8s Ingress
# Example: proxy_pass http://localhost:30080;  # NodePort example
```

### Phase 4: DNS and Routing (30 minutes)

#### 4.1 Update /etc/hosts (for local testing)

```bash
# Get Ingress Controller external IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# If no LoadBalancer (local cluster), use localhost with NodePort
# Get NodePort
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# Add to /etc/hosts (requires sudo)
echo "127.0.0.1 perplexica-k8s.yourdomain.com" | sudo tee -a /etc/hosts
```

**Note:** For production, update actual DNS records to point to Ingress Controller IP.

#### 4.2 Test Connectivity

```bash
# Test SearXNG service
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n perplexica -- \
  curl -s http://searxng-service:8080/healthz

# Test Perplexica service
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n perplexica -- \
  curl -s http://perplexica-service:3000/health

# Test external access (via Ingress)
curl -H "Host: perplexica-k8s.yourdomain.com" http://localhost/health
```

### Phase 5: Parallel Testing (1-2 hours)

#### 5.1 Run Both Environments

**Docker Compose** (existing): `perplexica.yourdomain.com`
**Kubernetes** (new): `perplexica-k8s.yourdomain.com`

```bash
# Verify Docker Compose still running
docker ps --filter "name=co-perplexica"

# Verify Kubernetes pods running
kubectl get pods -n perplexica
```

#### 5.2 Functional Testing Checklist

- [ ] **Search Functionality**
  - [ ] Basic web search returns results
  - [ ] Search history persists across pod restarts
  - [ ] Upload functionality works (if applicable)
  - [ ] Search filters/options work correctly

- [ ] **Performance**
  - [ ] Search latency comparable to Docker Compose
  - [ ] Resource usage within expected limits
  - [ ] No memory leaks over 24-hour period

- [ ] **Persistence**
  - [ ] Restart Perplexica pod: `kubectl rollout restart deployment perplexica -n perplexica`
  - [ ] Verify data persists (uploads, search history)
  - [ ] Restart SearXNG pod: `kubectl delete pod searxng-0 -n perplexica`
  - [ ] Verify SearXNG recreates successfully

- [ ] **High Availability (if multiple replicas)**
  - [ ] Scale Perplexica to 3 replicas: `kubectl scale deployment perplexica --replicas=3 -n perplexica`
  - [ ] Verify load balancing works across replicas
  - [ ] Delete one pod, verify service continues

#### 5.3 Monitoring Integration

**Add ServiceMonitor for Prometheus (if using Prometheus Operator):**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: perplexica-monitor
  namespace: perplexica
spec:
  selector:
    matchLabels:
      app: perplexica
  endpoints:
  - port: http
    interval: 30s
```

**Verify metrics in Prometheus:**
```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Open browser: http://localhost:9090
# Query: up{namespace="perplexica"}
```

### Phase 6: Cutover (30 minutes)

Once K8s version is validated:

#### 6.1 Update nginx Reverse Proxy

Update `services/nginx/configs/https.conf` to route `perplexica.yourdomain.com` to K8s Ingress:

```nginx
# Option A: Route directly to K8s Ingress Controller
server {
    listen 443 ssl http2;
    server_name perplexica.yourdomain.com;

    # SSL config (existing)
    ssl_certificate /etc/nginx/ssl/yourdomain.com.crt;
    ssl_certificate_key /etc/nginx/ssl/yourdomain.com.key;

    location / {
        proxy_pass http://localhost:30080;  # K8s Ingress NodePort
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Option B: Use K8s Ingress directly (remove nginx proxy)**

Remove nginx proxy entirely, let K8s Ingress handle SSL/TLS via cert-manager.

#### 6.2 Stop Docker Compose Perplexica

```bash
# Stop Perplexica containers (keep others running)
docker stop co-perplexica-service co-perplexica-searxng

# Or comment out in docker-compose.yml and restart
# - path: services/perplexica/docker-compose.yml  # Commented out
docker compose up -d
```

#### 6.3 Verify Production Traffic

```bash
# Test production domain
curl -I https://perplexica.yourdomain.com/health

# Monitor K8s logs for incoming requests
kubectl logs -n perplexica -l app=perplexica -f
```

---

## Kubernetes Manifests

All manifests should be stored in `kubernetes/perplexica/` directory.

### 01-pvcs.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: perplexica-data-pvc
  namespace: perplexica
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path  # Use your cluster's default storage class
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: perplexica-uploads-pvc
  namespace: perplexica
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
```

### 02-searxng-statefulset.yaml

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: searxng
  namespace: perplexica
  labels:
    app: searxng
spec:
  serviceName: searxng-headless
  replicas: 1
  selector:
    matchLabels:
      app: searxng
  template:
    metadata:
      labels:
        app: searxng
    spec:
      containers:
      - name: searxng
        image: docker.io/searxng/searxng:latest
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: SEARXNG_BASE_URL
          value: "http://searxng-service:8080/"
        volumeMounts:
        - name: searxng-config
          mountPath: /etc/searxng
          readOnly: false  # SearXNG may write to config directory
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
      volumes:
      - name: searxng-config
        configMap:
          name: searxng-config
---
# Headless service for StatefulSet
apiVersion: v1
kind: Service
metadata:
  name: searxng-headless
  namespace: perplexica
spec:
  clusterIP: None
  selector:
    app: searxng
  ports:
  - port: 8080
    name: http
---
# Regular service for external access
apiVersion: v1
kind: Service
metadata:
  name: searxng-service
  namespace: perplexica
  labels:
    app: searxng
spec:
  selector:
    app: searxng
  ports:
  - port: 8080
    targetPort: 8080
    name: http
  type: ClusterIP
```

### 03-perplexica-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: perplexica
  namespace: perplexica
  labels:
    app: perplexica
spec:
  replicas: 1  # Start with 1, scale to 2-3 after validation
  selector:
    matchLabels:
      app: perplexica
  template:
    metadata:
      labels:
        app: perplexica
    spec:
      containers:
      - name: perplexica
        image: itzcrazykns1337/perplexica:main
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: SEARXNG_API_URL
          value: "http://searxng-service:8080"
        - name: DATA_DIR
          value: "/home/perplexica"
        volumeMounts:
        - name: perplexica-data
          mountPath: /home/perplexica/data
        - name: perplexica-uploads
          mountPath: /home/perplexica/uploads
        - name: perplexica-config
          mountPath: /home/perplexica/config.toml
          subPath: perplexica.toml
          readOnly: true
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 40
          periodSeconds: 30
          timeoutSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 2Gi
      volumes:
      - name: perplexica-data
        persistentVolumeClaim:
          claimName: perplexica-data-pvc
      - name: perplexica-uploads
        persistentVolumeClaim:
          claimName: perplexica-uploads-pvc
      - name: perplexica-config
        configMap:
          name: perplexica-config
```

### 04-services.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: perplexica-service
  namespace: perplexica
  labels:
    app: perplexica
spec:
  selector:
    app: perplexica
  ports:
  - port: 3000
    targetPort: 3000
    name: http
  type: ClusterIP  # Use LoadBalancer if you want external IP directly
```

### 05-ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: perplexica-ingress
  namespace: perplexica
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    # Optional: SSL redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # Optional: cert-manager for automated SSL
    # cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  rules:
  - host: perplexica.yourdomain.com  # Update with your actual domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: perplexica-service
            port:
              number: 3000
  # Optional: TLS configuration
  # tls:
  # - hosts:
  #   - perplexica.yourdomain.com
  #   secretName: perplexica-tls  # cert-manager will create this
```

### 06-networkpolicy.yaml (Optional - Security Hardening)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: perplexica-netpol
  namespace: perplexica
spec:
  podSelector:
    matchLabels:
      app: perplexica
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx  # Allow ingress controller
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: searxng  # Allow connection to SearXNG
    ports:
    - protocol: TCP
      port: 8080
  - to:  # Allow DNS
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
  - to:  # Allow external internet (for AI API calls if needed)
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: searxng-netpol
  namespace: perplexica
spec:
  podSelector:
    matchLabels:
      app: searxng
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: perplexica  # Only allow Perplexica
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:  # Allow DNS
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
  - to:  # Allow external internet for search engines
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
```

---

## Testing & Validation

### Functional Tests

```bash
# Test Suite 1: Basic Connectivity
echo "=== Test 1: SearXNG Health Check ==="
kubectl exec -n perplexica -it deployment/perplexica -- \
  curl -s http://searxng-service:8080/healthz
# Expected: HTTP 200 OK

echo "=== Test 2: Perplexica Health Check ==="
kubectl exec -n perplexica -it deployment/perplexica -- \
  curl -s http://localhost:3000/health
# Expected: {"status":"ok"} or similar

echo "=== Test 3: External Access (via Ingress) ==="
curl -H "Host: perplexica.yourdomain.com" http://localhost/health
# Expected: HTTP 200 OK

# Test Suite 2: Data Persistence
echo "=== Test 4: Data Persistence ==="
# Create a test search (manual browser test)
# Then restart pod
kubectl rollout restart deployment perplexica -n perplexica
kubectl wait --for=condition=ready pod -l app=perplexica -n perplexica --timeout=60s
# Verify search history persists

# Test Suite 3: High Availability (if scaled)
echo "=== Test 5: Horizontal Scaling ==="
kubectl scale deployment perplexica --replicas=3 -n perplexica
kubectl wait --for=condition=ready pod -l app=perplexica -n perplexica --timeout=120s
kubectl get pods -n perplexica -l app=perplexica
# Verify all 3 replicas are ready

# Test load balancing (make multiple requests, check different pod logs)
for i in {1..10}; do
  curl -s -H "Host: perplexica.yourdomain.com" http://localhost/health > /dev/null
  sleep 0.5
done
kubectl logs -n perplexica -l app=perplexica --tail=20
# Verify requests distributed across replicas
```

### Performance Comparison

```bash
# Docker Compose baseline
echo "=== Docker Compose Performance ==="
ab -n 100 -c 10 https://perplexica.yourdomain.com/health
# Record: Requests per second, Time per request

# Kubernetes performance
echo "=== Kubernetes Performance ==="
ab -n 100 -c 10 -H "Host: perplexica-k8s.yourdomain.com" http://localhost/health
# Compare metrics

# Resource usage
echo "=== Docker Compose Resource Usage ==="
docker stats co-perplexica-service --no-stream

echo "=== Kubernetes Resource Usage ==="
kubectl top pods -n perplexica
```

### Load Testing (Optional)

```bash
# Install k6 (load testing tool)
brew install k6

# Create load test script
cat > load-test.js <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 10 },  // Ramp up to 10 users
    { duration: '3m', target: 10 },  // Stay at 10 users
    { duration: '1m', target: 0 },   // Ramp down
  ],
};

export default function () {
  let res = http.get('http://perplexica.yourdomain.com/health', {
    headers: { 'Host': 'perplexica.yourdomain.com' },
  });
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
EOF

# Run load test
k6 run load-test.js

# Monitor K8s during load test
kubectl top pods -n perplexica --watch
```

---

## Rollback Procedure

If issues arise, rollback to Docker Compose:

### Immediate Rollback (During Parallel Testing)

```bash
# 1. Stop routing traffic to K8s
# Update nginx to route back to Docker Compose Perplexica
docker restart co-nginx-service

# 2. Verify Docker Compose Perplexica is running
docker ps --filter "name=co-perplexica"

# If stopped, restart
docker start co-perplexica-service co-perplexica-searxng

# 3. Test Docker Compose version
curl https://perplexica.yourdomain.com/health

# 4. (Optional) Scale down K8s deployment
kubectl scale deployment perplexica --replicas=0 -n perplexica
```

### Full Rollback (After Cutover)

```bash
# 1. Re-enable Docker Compose Perplexica in docker-compose.yml
# Uncomment: - path: services/perplexica/docker-compose.yml

# 2. Start Docker Compose services
cd /path/to/carian-observatory
docker compose up -d

# 3. Verify containers running
docker ps --filter "name=co-perplexica"

# 4. Update nginx routing back to Docker Compose
# Revert nginx config changes

# 5. Restart nginx
docker restart co-nginx-service

# 6. Test production domain
curl https://perplexica.yourdomain.com/health

# 7. (Optional) Delete K8s namespace
kubectl delete namespace perplexica --wait=false
# Data will be deleted after grace period unless you backup PVCs first
```

### Data Recovery from Kubernetes

If you need to recover data from K8s PVCs:

```bash
# 1. Create temporary pod with PVC mounts
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: data-recovery
  namespace: perplexica
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: perplexica-data
      mountPath: /mnt/perplexica-data
    - name: perplexica-uploads
      mountPath: /mnt/perplexica-uploads
  volumes:
  - name: perplexica-data
    persistentVolumeClaim:
      claimName: perplexica-data-pvc
  - name: perplexica-uploads
    persistentVolumeClaim:
      claimName: perplexica-uploads-pvc
EOF

# 2. Wait for pod
kubectl wait --for=condition=ready pod/data-recovery -n perplexica --timeout=60s

# 3. Create backup archives
kubectl exec -n perplexica data-recovery -- \
  tar czf /tmp/perplexica-data-recovery.tar.gz -C /mnt/perplexica-data .

kubectl exec -n perplexica data-recovery -- \
  tar czf /tmp/perplexica-uploads-recovery.tar.gz -C /mnt/perplexica-uploads .

# 4. Copy archives to local machine
kubectl cp perplexica/data-recovery:/tmp/perplexica-data-recovery.tar.gz \
  ./backups/perplexica-data-recovery-$(date +%Y%m%d-%H%M%S).tar.gz

kubectl cp perplexica/data-recovery:/tmp/perplexica-uploads-recovery.tar.gz \
  ./backups/perplexica-uploads-recovery-$(date +%Y%m%d-%H%M%S).tar.gz

# 5. Restore to Docker volumes
docker run --rm \
  -v carian-observatory_perplexica-data:/target \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd /target && tar xzf /backup/perplexica-data-recovery-*.tar.gz"

docker run --rm \
  -v carian-observatory_perplexica-uploads:/target \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd /target && tar xzf /backup/perplexica-uploads-recovery-*.tar.gz"

# 6. Clean up recovery pod
kubectl delete pod data-recovery -n perplexica
```

---

## Post-Migration Monitoring

### Metrics to Track

#### Application Metrics
- **Request Rate:** Requests per second to Perplexica
- **Latency:** p50, p95, p99 response times
- **Error Rate:** HTTP 5xx errors per minute
- **Search Success Rate:** Successful searches vs failed

#### Infrastructure Metrics
- **Pod Restarts:** Should remain at 0 after stabilization
- **CPU Usage:** Track against resource requests/limits
- **Memory Usage:** Watch for memory leaks over time
- **Disk Usage:** PVC usage growth rate

#### Business Metrics
- **Uptime:** Track availability percentage
- **Data Persistence:** Verify uploads/search history retention

### Grafana Dashboard

If using PGLA stack, create Perplexica dashboard:

```yaml
# Example Prometheus queries for Grafana dashboard

# Request rate
rate(http_requests_total{namespace="perplexica"}[5m])

# Error rate
rate(http_requests_total{namespace="perplexica",status=~"5.."}[5m])

# Pod restarts
kube_pod_container_status_restarts_total{namespace="perplexica"}

# CPU usage
rate(container_cpu_usage_seconds_total{namespace="perplexica"}[5m])

# Memory usage
container_memory_usage_bytes{namespace="perplexica"}

# PVC usage
kubelet_volume_stats_used_bytes{namespace="perplexica"}
  / kubelet_volume_stats_capacity_bytes{namespace="perplexica"}
```

### Alerting Rules

Create Prometheus alert rules (example):

```yaml
groups:
- name: perplexica_alerts
  interval: 30s
  rules:
  - alert: PerplexicaDown
    expr: up{namespace="perplexica", app="perplexica"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Perplexica service is down"
      description: "Perplexica has been down for more than 2 minutes"

  - alert: PerplexicaHighErrorRate
    expr: rate(http_requests_total{namespace="perplexica",status=~"5.."}[5m]) > 0.05
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High error rate in Perplexica"
      description: "Error rate is {{ $value }} over last 5 minutes"

  - alert: PerplexicaHighMemory
    expr: container_memory_usage_bytes{namespace="perplexica"}
         / container_spec_memory_limit_bytes{namespace="perplexica"} > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Perplexica high memory usage"
      description: "Memory usage is {{ $value | humanizePercentage }}"

  - alert: PerplexicaPodRestarts
    expr: rate(kube_pod_container_status_restarts_total{namespace="perplexica"}[15m]) > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Perplexica pod is restarting"
      description: "Pod {{ $labels.pod }} has restarted {{ $value }} times"
```

---

## Lessons Learned

**Template for post-migration review:**

### What Worked Well

- [ ] **Item 1:**
  _Description:_
  _Why it worked:_
  _Recommendation for future migrations:_

- [ ] **Item 2:**

### Challenges Encountered

- [ ] **Challenge 1:**
  _Description:_
  _Root cause:_
  _Resolution:_
  _Prevention for next migration:_

- [ ] **Challenge 2:**

### Performance Comparison

| Metric | Docker Compose | Kubernetes | Difference |
|--------|----------------|------------|------------|
| **Avg Response Time** | | | |
| **p95 Response Time** | | | |
| **Requests per Second** | | | |
| **CPU Usage (avg)** | | | |
| **Memory Usage (avg)** | | | |
| **Uptime (30 days)** | | | |

### Configuration Changes Required

- [ ] **nginx routing:** _Details of changes made_
- [ ] **DNS updates:** _Details of changes made_
- [ ] **Monitoring integration:** _Details of changes made_
- [ ] **Secrets management:** _Details of changes made_

### Recommendations for Phase 2 (PGLA Migration)

Based on Perplexica migration experience:

- [ ] **Storage strategy:**
- [ ] **Networking approach:**
- [ ] **Migration procedure improvements:**
- [ ] **Monitoring/alerting enhancements:**
- [ ] **Rollback strategy refinements:**

### Decision: Production Readiness

After completing migration and testing:

- [ ] **Promote to production:** Perplexica K8s is stable, migrate PGLA next
- [ ] **Iterate on current setup:** Need more testing/optimization before Phase 2
- [ ] **Rollback to Docker Compose:** K8s not suitable for carian-observatory (document why)

**Next Steps:**
1.
2.
3.

---

## Appendix A: Troubleshooting Guide

### Issue: Pods stuck in Pending state

**Symptoms:**
```bash
kubectl get pods -n perplexica
# NAME                          READY   STATUS    RESTARTS   AGE
# perplexica-xxx-xxx            0/1     Pending   0          5m
```

**Diagnosis:**
```bash
kubectl describe pod perplexica-xxx-xxx -n perplexica
# Look for "Events" section
```

**Common Causes:**
1. **Insufficient resources:** Node doesn't have enough CPU/memory
   - **Fix:** Reduce resource requests in deployment YAML
2. **PVC not bound:** PersistentVolumeClaim stuck in Pending
   - **Fix:** Check storage class exists: `kubectl get storageclass`
3. **Node selector mismatch:** Pod requires node labels that don't exist
   - **Fix:** Remove node selector or label nodes appropriately

### Issue: Service returns 503 errors

**Symptoms:**
```bash
curl https://perplexica.yourdomain.com/health
# HTTP 503 Service Unavailable
```

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n perplexica -l app=perplexica

# Check pod logs
kubectl logs -n perplexica -l app=perplexica --tail=50

# Check service endpoints
kubectl get endpoints -n perplexica perplexica-service
```

**Common Causes:**
1. **No ready pods:** Pods are crashing or failing health checks
   - **Fix:** Check logs for errors, verify health check endpoints
2. **Service selector mismatch:** Service not routing to pods
   - **Fix:** Verify labels match between service and deployment
3. **Ingress misconfiguration:** Ingress controller can't reach service
   - **Fix:** Check Ingress status: `kubectl describe ingress perplexica-ingress -n perplexica`

### Issue: Data not persisting across pod restarts

**Symptoms:**
- Uploads disappear after pod restart
- Search history lost

**Diagnosis:**
```bash
# Check PVC status
kubectl get pvc -n perplexica

# Check volume mounts in pod
kubectl describe pod -n perplexica -l app=perplexica | grep -A 5 "Mounts"

# Verify data exists in PVC
kubectl exec -n perplexica deployment/perplexica -- ls -lah /home/perplexica/data
```

**Common Causes:**
1. **PVC not mounted:** Volume mount missing in deployment
   - **Fix:** Verify volumeMounts in deployment YAML
2. **Wrong mount path:** Application writing to different directory
   - **Fix:** Check application logs for actual data directory
3. **PVC deleted/recreated:** PVC was deleted, causing data loss
   - **Fix:** Restore from backups

### Issue: SearXNG not reachable from Perplexica

**Symptoms:**
- Perplexica logs show connection errors to SearXNG
- Searches fail with "Backend error"

**Diagnosis:**
```bash
# Test connectivity from Perplexica pod
kubectl exec -n perplexica deployment/perplexica -- \
  curl -s http://searxng-service:8080/healthz

# Check SearXNG pod status
kubectl get pods -n perplexica -l app=searxng

# Check SearXNG logs
kubectl logs -n perplexica searxng-0
```

**Common Causes:**
1. **DNS resolution failure:** K8s DNS not working
   - **Fix:** Check CoreDNS pods: `kubectl get pods -n kube-system -l k8s-app=kube-dns`
2. **Network policy blocking:** NetworkPolicy preventing communication
   - **Fix:** Review NetworkPolicy rules, temporarily delete to test
3. **Wrong service name:** Environment variable has incorrect service URL
   - **Fix:** Verify `SEARXNG_API_URL=http://searxng-service:8080`

---

## Appendix B: Scaling Strategies

### Horizontal Pod Autoscaling (HPA)

Once baseline resource usage is established:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: perplexica-hpa
  namespace: perplexica
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: perplexica
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

**Apply HPA:**
```bash
kubectl apply -f kubernetes/perplexica/07-hpa.yaml

# Monitor autoscaling
kubectl get hpa -n perplexica --watch
```

### Vertical Pod Autoscaling (VPA)

For automatic resource request/limit tuning:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: perplexica-vpa
  namespace: perplexica
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: perplexica
  updatePolicy:
    updateMode: "Auto"  # or "Initial" for new pods only
```

**Note:** VPA requires metrics-server and VPA admission controller installed.

---

## Appendix C: Security Hardening

### Pod Security Standards

Apply Pod Security Standards to namespace:

```bash
kubectl label namespace perplexica \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### Security Context

Add security context to pods:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: perplexica
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true  # Requires writable emptyDir for /tmp
```

### Secret Management with External Secrets Operator

Replace K8s Secrets with 1Password integration:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: onepassword-store
  namespace: perplexica
spec:
  provider:
    onepassword:
      connectHost: http://onepassword-connect:8080
      vaults:
        API: 1
      auth:
        secretRef:
          connectTokenSecretRef:
            name: onepassword-token
            key: token
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: perplexica-secrets
  namespace: perplexica
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: onepassword-store
    kind: SecretStore
  target:
    name: perplexica-app-secrets
    creationPolicy: Owner
  data:
  - secretKey: api-key
    remoteRef:
      key: perplexica-api-key
      property: credential
```

---

## Appendix D: Cost Analysis

### Resource Requirements

**Current Docker Compose:**
- Perplexica: ~512MB RAM, 0.2 CPU cores
- SearXNG: ~256MB RAM, 0.1 CPU cores
- Total: ~768MB RAM, 0.3 CPU cores

**Kubernetes Overhead:**
- K3s control plane: ~500MB RAM, 0.2 CPU cores
- Ingress controller: ~256MB RAM, 0.1 CPU cores
- Per-pod overhead: ~20MB RAM, 0.01 CPU cores per pod

**Total K8s Footprint (single replica):**
- ~1.5GB RAM, 0.6 CPU cores (including K8s overhead)

**Total K8s Footprint (3 replicas for HA):**
- ~2.3GB RAM, 1.0 CPU cores

### ROI Analysis

**Benefits:**
- Horizontal scaling for peak load handling
- Automated pod restarts (self-healing)
- Zero-downtime rolling updates
- Resource isolation and limits
- Foundation for future service migrations

**Costs:**
- ~2x memory overhead (K8s control plane + ingress)
- Increased complexity (YAML manifests, kubectl commands)
- Learning curve for K8s operations

**Verdict:**
- **Worth it if:** Planning to migrate more services, need HA/scaling
- **Not worth it if:** Perplexica is only K8s workload (overhead too high)

---

## Document History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-01-16 | 1.0 | Claude | Initial migration plan created |

---

**Status:** Ready for implementation
**Next Review:** After Phase 1 completion (update Lessons Learned)
