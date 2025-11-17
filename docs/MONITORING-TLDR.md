# Monitoring Stack TL;DR

Quick reference for carian-observatory's PGLA (Prometheus + Grafana + Loki + Alertmanager) observability stack.

## 🎯 Quick Reference

| Component | Purpose | Port | URL | Status Check |
|-----------|---------|------|-----|--------------|
| **Prometheus** | Metrics collection & storage | 9090 | http://localhost:9090 | `curl http://localhost:9090/-/healthy` |
| **Grafana** | Visualization & dashboards | 3000 | https://monitoring.yourdomain.com | `curl http://localhost:3000/api/health` |
| **Loki** | Log aggregation & query | 3100 | http://localhost:3100 | `curl http://localhost:3100/ready` |
| **Alertmanager** | Alert routing & grouping | 9093 | http://localhost:9093 | `curl http://localhost:9093/-/healthy` |
| **Promtail** | Log shipping to Loki | 9080 | N/A (agent) | Logs to Loki |
| **cAdvisor** | Container metrics | 8080 | http://localhost:8080 | `curl http://localhost:8080/healthz` |
| **Node Exporter** | System metrics | 9100 | http://localhost:9100 | `curl http://localhost:9100/metrics` |

## 📊 For Applications: Sending Logs to Loki

### Python Example (Direct HTTP)

```python
import requests
import time
import socket

def send_log_to_loki(message: str, level: str = "INFO", service: str = "my-app"):
    """Send log entry to Loki"""
    timestamp_ns = str(int(time.time() * 1_000_000_000))

    payload = {
        "streams": [
            {
                "stream": {
                    "service": service,
                    "level": level,
                    "hostname": socket.gethostname(),
                },
                "values": [[timestamp_ns, message]]
            }
        ]
    }

    try:
        response = requests.post(
            "http://localhost:3100/loki/api/v1/push",
            json=payload,
            timeout=5
        )
        return response.status_code == 204  # Success
    except Exception as e:
        print(f"Failed to send log: {e}")
        return False

# Usage
send_log_to_loki("Application started", level="INFO", service="my-service")
send_log_to_loki("Database connection failed", level="ERROR", service="my-service")
```

### Python Example (Logging Handler)

See: `/path/to/ai-bedo/audio_monitor/monitoring.py` for complete `LokiHandler` implementation.

```python
from audio_monitor.monitoring import setup_monitoring

# Setup in your application
metrics = setup_monitoring(
    loki_url="http://localhost:3100",
    service_name="my-service"
)

# All ERROR and CRITICAL logs now go to Loki automatically
import logging
logger = logging.getLogger(__name__)
logger.error("This will appear in Loki")
logger.critical("This will alert in Grafana")
```

## 🔍 Querying Logs (LogQL)

### Common Queries

```logql
# All logs from a service
{service="audio-monitor"}

# Error logs only
{service="audio-monitor", level="ERROR"}

# Critical errors
{service="audio-monitor", level="CRITICAL"}

# Logs containing specific text
{service="audio-monitor"} |= "consecutive errors"

# Logs NOT containing text
{service="audio-monitor"} != "health check"

# Rate of errors (5 minute window)
rate({service="audio-monitor", level="ERROR"}[5m])

# Count logs by level
sum by (level) (count_over_time({service="audio-monitor"}[1h]))
```

### Query via API

```bash
# Query logs (range query required for log streams)
START=$(date -u -v-5M +%s)000000000  # 5 minutes ago
END=$(date -u +%s)000000000           # now

curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode "query={service=\"audio-monitor\"}" \
  --data-urlencode "start=$START" \
  --data-urlencode "end=$END" \
  --data-urlencode "limit=100"

# List available labels
curl "http://localhost:3100/loki/api/v1/labels"

# List values for a label
curl "http://localhost:3100/loki/api/v1/label/service/values"
```

## 📈 Sending Metrics to Prometheus

### Prometheus Scrape Targets

Add your service to `/services/monitoring/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:8000']
    scrape_interval: 15s
```

### Python Example (Prometheus Client)

```python
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time

# Define metrics
requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'status'])
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')
active_connections = Gauge('active_connections', 'Number of active connections')

# Use metrics
requests_total.labels(method='GET', status=200).inc()

with request_duration.time():
    # Your code here
    time.sleep(0.5)

active_connections.set(42)

# Expose metrics endpoint
start_http_server(8000)  # Metrics at http://localhost:8000/metrics
```

## 🚨 Alert Rules

### Creating Alerts in Prometheus

Edit `/services/monitoring/prometheus/alerts.yml`:

```yaml
groups:
  - name: my_service_alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate({service="my-service", level="ERROR"}[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate in my-service"
          description: "Error rate is {{ $value }} over last 5 minutes"

      - alert: ServiceDown
        expr: up{job="my-service"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "my-service is down"
          description: "Service has been down for 2+ minutes"
```

### Alert Routing (Alertmanager)

Configure notification channels in `/services/monitoring/alertmanager/config.yml`.

## 🎨 Grafana Dashboards

### Access

- **URL**: https://monitoring.yourdomain.com (or http://localhost:3000)
- **Username**: admin
- **Password**: Check `.env` file → `GRAFANA_PASSWORD`

### Creating Dashboard

1. Go to Dashboards → New Dashboard
2. Add Panel
3. Select Data Source:
   - **Prometheus** for metrics
   - **Loki** for logs
4. Enter query (PromQL or LogQL)
5. Customize visualization
6. Save dashboard

### Pre-built Dashboards

Import community dashboards from [Grafana Dashboard Gallery](https://grafana.com/grafana/dashboards/):

- **Node Exporter Full**: Dashboard ID 1860
- **Docker Container & Host**: Dashboard ID 179
- **Loki Log Dashboard**: Dashboard ID 13639

## 🔧 Common Tasks

### Check Service Health

```bash
# All services
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3000/api/health # Grafana
curl http://localhost:3100/ready      # Loki
curl http://localhost:9093/-/healthy  # Alertmanager

# Container status
docker ps | grep co-monitoring
```

### View Logs

```bash
# Service logs
docker logs co-monitoring-prometheus
docker logs co-monitoring-grafana
docker logs co-monitoring-loki
docker logs co-monitoring-promtail

# Follow logs
docker logs -f co-monitoring-loki
```

### Restart Services

```bash
cd /path/to/carian-observatory/services/monitoring
docker compose restart prometheus
docker compose restart grafana
docker compose restart loki
```

### Backup Data

```bash
# Prometheus data
docker run --rm -v co-prometheus-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/prometheus-backup-$(date +%Y%m%d).tar.gz /data

# Grafana data
docker run --rm -v co-grafana-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/grafana-backup-$(date +%Y%m%d).tar.gz /data

# Loki data
docker run --rm -v co-loki-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/loki-backup-$(date +%Y%m%d).tar.gz /data
```

## 📚 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Applications                         │
│  (audio-monitor, open-webui, custom services)               │
└───────────┬─────────────────────────────┬───────────────────┘
            │                             │
            │ Logs (Loki API)            │ Metrics (Prometheus scrape)
            │                             │
            ▼                             ▼
    ┌───────────────┐           ┌──────────────────┐
    │ Promtail      │           │ Prometheus       │
    │ (Log Shipper) │───────────│ (Metrics Store)  │
    └───────┬───────┘           └────────┬─────────┘
            │                            │
            │                            │ Alerts
            ▼                            ▼
    ┌───────────────┐           ┌──────────────────┐
    │ Loki          │           │ Alertmanager     │
    │ (Log Store)   │           │ (Alert Routing)  │
    └───────┬───────┘           └──────────────────┘
            │
            │
            ▼
    ┌────────────────────────────────────────────────┐
    │            Grafana (Visualization)             │
    │  - Dashboards                                  │
    │  - Alerts                                      │
    │  - Query UI                                    │
    └────────────────────────────────────────────────┘
```

## 🏷️ Label Best Practices

### Recommended Labels for All Services

```json
{
  "service": "my-service-name",      // Required - unique service identifier
  "level": "INFO|WARNING|ERROR|CRITICAL",  // Log level
  "environment": "production|staging|development",
  "hostname": "machine-hostname",    // Auto-detected
  "component": "api|worker|scheduler",  // Service component
  "version": "1.0.0"                 // Application version
}
```

### Avoid High Cardinality

❌ **Bad**: `{request_id="unique-per-request"}` (millions of unique values)
✅ **Good**: `{service="api", method="GET", status="200"}` (limited combinations)

## 🐛 Troubleshooting

### Logs Not Appearing in Loki

```bash
# Check Promtail is shipping logs
docker logs co-monitoring-promtail | grep -i error

# Check Loki ingestion
curl http://localhost:3100/metrics | grep loki_ingester_chunks_created_total

# Verify timestamp is recent (not too old)
date +%s000000000  # Current timestamp in nanoseconds

# Test direct push
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d "{\"streams\":[{\"stream\":{\"service\":\"test\"},\"values\":[[\"$(date +%s000000000)\",\"Test message\"]]}]}"
```

### Grafana Can't Query Loki

1. Check Data Source configuration in Grafana Settings
2. Verify URL is `http://loki:3100` (internal docker network)
3. Test connection in Data Source settings
4. Check Loki logs for query errors

### Prometheus Not Scraping

```bash
# Check Prometheus targets page
open http://localhost:9090/targets

# Verify service is exposing /metrics endpoint
curl http://my-service:8000/metrics

# Check Prometheus config
docker exec co-monitoring-prometheus cat /etc/prometheus/prometheus.yml
```

## 📖 Related Documentation

- **Main Repository**: `/path/to/carian-observatory/README.md`
- **Audio Monitor Integration**: `/path/to/ai-bedo/docs/AUDIO-MONITOR-ERROR-HANDLING.md`
- **Docker Compose**: `/path/to/carian-observatory/services/monitoring/docker-compose.yml`
- **Prometheus Config**: `/path/to/carian-observatory/services/monitoring/prometheus/prometheus.yml`
- **Loki Config**: `/path/to/carian-observatory/services/monitoring/loki/config.yml`

## 🔗 External Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)

---

**Created**: 2025-10-17
**Last Updated**: 2025-10-17
**Maintainer**: Main Machine Albedo (Orchestrator)
**Status**: Production Ready
