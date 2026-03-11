# Kubernetes Migration Documentation

This directory contains documentation and migration plans for transitioning Carian Observatory services from Docker Compose to Kubernetes.

## Migration Strategy

**Phased Approach:**
1. **Phase 1 (Proof of Concept):** Perplexica + SearXNG
2. **Phase 2 (Observability):** PGLA stack (Prometheus, Grafana, Loki, Alertmanager)
3. **Phase 3 (Critical Services):** Authelia + Redis (authentication stack)
4. **Phase 4 (Evaluation):** Nginx reverse proxy vs K8s Ingress Controller

**Services Remaining in Docker Compose:**
- Open-WebUI (personal workspace, no scaling needs)
- Homepage + Glance (lightweight single-instance dashboards)

## Available Documentation

### Migration Plans

- **[MIGRATION-PLAN-PERPLEXICA.md](MIGRATION-PLAN-PERPLEXICA.md)** - Phase 1: Perplexica + SearXNG migration
  - Complete step-by-step migration procedure
  - Kubernetes manifests (Deployment, StatefulSet, Service, Ingress, PVC)
  - Testing and validation procedures
  - Rollback procedures
  - Post-migration monitoring setup
  - ~800 lines of production-ready documentation

### Future Documentation (TBD)

- `MIGRATION-PLAN-PGLA.md` - Phase 2: Observability stack migration
- `MIGRATION-PLAN-AUTHELIA.md` - Phase 3: Authentication stack migration
- `K8S-ARCHITECTURE.md` - Overall K8s architecture and design decisions
- `K8S-OPERATIONS.md` - Day-to-day K8s operations guide
- `TROUBLESHOOTING.md` - Common K8s issues and solutions

## Kubernetes Cluster Options

### Local Development

**k3s** (Recommended)
- Lightweight, production-grade Kubernetes
- Low resource footprint (~500MB RAM)
- Includes local-path storage provisioner
- Installation: `curl -sfL https://get.k3s.io | sh -`

**microk8s**
- Ubuntu-friendly with easy addons
- Good for multi-node local clusters
- Installation: `snap install microk8s --classic`

**Docker Desktop K8s**
- Easiest for macOS users
- Higher resource usage
- Enable in Docker Desktop preferences

### Production Options

- **Cloud K8s:** EKS (AWS), GKE (Google Cloud), AKS (Azure)
- **Self-hosted:** Kubeadm, k3s (production mode), RKE2
- **Hybrid:** Rancher for multi-cluster management

## Migration Decision Tree

```
New Service or Migration?
  ↓
┌─────────────────────────────────┐
│ Does it need horizontal scaling?│
└────────┬────────────────────────┘
         │
    ┌────┴────┐
   Yes        No
    │          │
    ▼          ▼
Is it      Keep in
stateless? Docker Compose
    │          (simpler)
┌───┴───┐
Yes     No
│       │
▼       ▼
K8s   Evaluate:
Good  - Can state be extracted?
Fit   - StatefulSet appropriate?
      - Complexity justified?
```

## Prerequisites for All Migrations

### Required Knowledge

- Docker and containerization concepts
- Basic Kubernetes concepts (Pods, Deployments, Services)
- YAML syntax
- kubectl CLI usage
- Persistent storage in K8s (PVCs, PVs)

### Required Tooling

- `kubectl` - Kubernetes CLI
- `helm` (optional) - Package manager for K8s
- `k9s` (optional) - Terminal UI for K8s
- `kubectx`/`kubens` (optional) - Context/namespace switching

### Required Infrastructure

- Kubernetes cluster (local or cloud)
- Storage provisioner (local-path, NFS, cloud storage)
- Ingress controller (nginx, Traefik, Istio)
- Monitoring stack (Prometheus + Grafana recommended)

## Migration Checklist Template

Before starting any migration:

- [ ] **Backup existing data** - Critical! No going back without backups
- [ ] **Document current state** - Docker Compose config, resource usage, performance baselines
- [ ] **Test rollback procedure** - Ensure you can revert if issues arise
- [ ] **Parallel environment** - Run both Docker Compose and K8s simultaneously during testing
- [ ] **Monitoring ready** - Ensure you can observe K8s service health
- [ ] **Stakeholder communication** - If multi-user service, notify users of migration

## Success Criteria Template

For each migration, define success criteria:

- [ ] **Functional:** Service works identically to Docker Compose version
- [ ] **Performance:** Latency within 10% of Docker Compose baseline
- [ ] **Availability:** 99.9% uptime over 7-day test period
- [ ] **Data integrity:** No data loss, all persistence verified
- [ ] **Monitoring:** Metrics, logs, and alerts integrated
- [ ] **Documentation:** Runbooks and troubleshooting guides updated

## Learning Resources

### Official Kubernetes Documentation
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Concepts](https://kubernetes.io/docs/concepts/)
- [Tasks](https://kubernetes.io/docs/tasks/)

### Recommended Tutorials
- [Kubernetes by Example](http://kubernetesbyexample.com/)
- [Learn Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [k3s Documentation](https://docs.k3s.io/)

### Tools and Utilities
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Documentation](https://helm.sh/docs/)
- [k9s Terminal UI](https://k9scli.io/)

## Contributing to This Documentation

When completing a migration:

1. **Update migration plan** with actual timeline and issues encountered
2. **Fill in "Lessons Learned" section** with real-world insights
3. **Add troubleshooting entries** for any issues you solved
4. **Create next phase plan** based on lessons from current phase
5. **Update architecture diagrams** to reflect new K8s services

## Questions and Feedback

Migration questions or issues? Document them in:
- `/tasks/TASK-K8S-*.md` for tracking specific K8s work items
- `/todos/` for private planning notes

## Status Overview

| Service | Status | Migration Plan | K8s Manifests | Testing | Production |
|---------|--------|----------------|---------------|---------|------------|
| **Perplexica + SearXNG** | 📝 Planning | ✅ Complete | ✅ Ready | ⏳ Pending | ⏳ Pending |
| **PGLA Stack** | 📋 Backlog | ⏳ TBD | ⏳ TBD | ⏳ TBD | ⏳ TBD |
| **Authelia + Redis** | 📋 Backlog | ⏳ TBD | ⏳ TBD | ⏳ TBD | ⏳ TBD |
| **Nginx/Ingress** | 🤔 Evaluation | ⏳ TBD | ⏳ TBD | ⏳ TBD | ⏳ TBD |
| **Open-WebUI** | ❌ Staying Docker Compose | N/A | N/A | N/A | N/A |
| **Homepage/Glance** | ❌ Staying Docker Compose | N/A | N/A | N/A | N/A |

**Legend:**
- ✅ Complete
- ⏳ Pending/In Progress
- 📝 Planning
- 📋 Backlog
- 🤔 Under Evaluation
- ❌ Not Planned

---

**Created:** 2025-01-16
**Last Updated:** 2025-01-16
**Maintained By:** Carian Observatory Infrastructure Team
