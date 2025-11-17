# Grafana Dashboards

Pre-configured dashboards for carian-observatory monitoring stack.

## Available Dashboards

### Audio Monitor Health (`audio-monitor-health.json`)

Real-time health monitoring dashboard for the audio-monitor service.

**Features**:
- **UP/DOWN Status** - Large status panel showing if service is alive
- **Heartbeat Activity** - Graph of heartbeat signals over time
- **Log Levels** - Breakdown of INFO, WARNING, ERROR, CRITICAL logs
- **Error Count** - Real-time error counter (1 hour window)
- **Critical Count** - Critical error counter (1 hour window)
- **Recent Errors** - Log viewer showing ERROR and CRITICAL logs
- **All Logs** - Complete log stream from audio-monitor

**Refresh Rate**: 30 seconds (auto-refresh)

**Time Range**: Last 6 hours (adjustable)

## Importing Dashboards

### Option 1: Via Grafana UI

1. **Open Grafana**: https://monitoring.yourdomain.com (or http://10.211.55.2:3000)
2. **Login**: Use admin credentials from `.env` file
3. **Navigate**: Dashboards → New → Import
4. **Upload**: Click "Upload JSON file"
5. **Select**: Choose `audio-monitor-health.json`
6. **Configure Data Source**:
   - **Loki**: Select your Loki data source (usually "loki" or "Loki")
7. **Click**: Import
8. **Done**: Dashboard will appear in your dashboards list

### Option 2: Via Grafana API

```bash
# Set Grafana credentials
GRAFANA_URL="http://10.211.55.2:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="your-password-from-env"

# Import dashboard
curl -X POST "$GRAFANA_URL/api/dashboards/db" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -H "Content-Type: application/json" \
  -d @audio-monitor-health.json
```

### Option 3: Auto-provisioning (Recommended for Production)

1. **Copy dashboard** to provisioning directory:
   ```bash
   cp audio-monitor-health.json /path/to/grafana/provisioning/dashboards/
   ```

2. **Create provisioning config** (`/path/to/grafana/provisioning/dashboards/default.yaml`):
   ```yaml
   apiVersion: 1

   providers:
     - name: 'Default'
       orgId: 1
       folder: ''
       type: file
       disableDeletion: false
       updateIntervalSeconds: 10
       allowUiUpdates: true
       options:
         path: /etc/grafana/provisioning/dashboards
   ```

3. **Restart Grafana**:
   ```bash
   docker compose restart grafana
   ```

## Data Source Configuration

The dashboard requires a Loki data source configured in Grafana.

### Verify Loki Data Source

1. Go to: Configuration (⚙️) → Data Sources
2. Check for "Loki" data source
3. If not exists, add new:
   - **Type**: Loki
   - **Name**: loki (lowercase recommended)
   - **URL**: `http://loki:3100` (internal docker network)
   - **Access**: Server (default)
4. Click "Save & Test"

## Dashboard Panels Explained

### 1. Audio Monitor Status (Stat Panel)

**Query**: `count_over_time({service="audio-monitor", type="heartbeat"}[2m]) > 0`

**Meaning**:
- Shows **UP** (green) if heartbeat detected in last 2 minutes
- Shows **DOWN** (red) if no heartbeat for 2+ minutes

**Alert Threshold**: Consider service down if no heartbeat for 2 minutes

### 2. Heartbeat Activity (Time Series)

**Query**: `count_over_time({service="audio-monitor", type="heartbeat"}[1m])`

**Meaning**:
- Plots heartbeat signals per minute
- Should show steady activity (1 heartbeat/minute)
- Gaps indicate service was down or restarting

### 3. Log Levels (Stacked Bars)

**Query**: `sum by (level) (count_over_time({service="audio-monitor"}[5m]))`

**Meaning**:
- Breaks down logs by severity (INFO, WARNING, ERROR, CRITICAL)
- 5-minute windows
- Colors: Blue (INFO), Yellow (WARNING), Red (ERROR), Dark Red (CRITICAL)

### 4. Error Count (Stat Panel)

**Query**: `count_over_time({service="audio-monitor", level="ERROR"}[1h])`

**Meaning**:
- Total ERROR logs in last hour
- Green if 0, Yellow if 1-4, Red if 5+

### 5. Critical Count (Stat Panel)

**Query**: `count_over_time({service="audio-monitor", level="CRITICAL"}[1h])`

**Meaning**:
- Total CRITICAL logs in last hour
- Green if 0, Red if any
- CRITICAL = service crash or fatal error

### 6. Recent Errors & Critical Logs (Log Panel)

**Query**: `{service="audio-monitor", level=~"ERROR|CRITICAL"}`

**Meaning**:
- Shows recent ERROR and CRITICAL log entries
- Expandable for full stack traces
- Useful for debugging active issues

### 7. All Audio Monitor Logs (Log Panel)

**Query**: `{service="audio-monitor"}`

**Meaning**:
- Complete log stream (all levels)
- Includes INFO, DEBUG, WARNING, ERROR, CRITICAL
- Searchable and filterable

## Setting Up Alerts

### Alert Rule Example (Prometheus)

Create in `/services/monitoring/prometheus/alerts.yml`:

```yaml
groups:
  - name: audio_monitor_alerts
    interval: 30s
    rules:
      - alert: AudioMonitorDown
        expr: count_over_time({service="audio-monitor", type="heartbeat"}[3m]) == 0
        for: 3m
        labels:
          severity: critical
          service: audio-monitor
        annotations:
          summary: "Audio Monitor service is down"
          description: "No heartbeat received from audio-monitor for 3+ minutes"

      - alert: AudioMonitorHighErrorRate
        expr: rate({service="audio-monitor", level="ERROR"}[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
          service: audio-monitor
        annotations:
          summary: "Audio Monitor experiencing high error rate"
          description: "Error rate is {{ $value }} errors/second over 5 minutes"

      - alert: AudioMonitorCriticalError
        expr: count_over_time({service="audio-monitor", level="CRITICAL"}[1m]) > 0
        for: 1m
        labels:
          severity: critical
          service: audio-monitor
        annotations:
          summary: "Audio Monitor CRITICAL error detected"
          description: "Service logged a CRITICAL error - may be crashing"
```

### Grafana Alert Example

1. Open "Audio Monitor Status" panel
2. Click panel title → Edit
3. Go to Alert tab
4. Click "Create Alert"
5. Configure:
   - **Name**: Audio Monitor Down
   - **Condition**: When `count_over_time({service="audio-monitor", type="heartbeat"}[2m])` is below `1`
   - **For**: 2m
   - **Send to**: Your notification channel
6. Save

## Troubleshooting

### Dashboard Shows "No Data"

**Check**:
1. Is Loki data source configured correctly?
   ```bash
   curl http://10.211.55.2:3100/ready
   ```

2. Are heartbeats being sent?
   ```bash
   curl -G "http://10.211.55.2:3100/loki/api/v1/query" \
     --data-urlencode 'query={service="audio-monitor", type="heartbeat"}' \
     --data-urlencode 'limit=1'
   ```

3. Is audio-monitor service running?
   ```bash
   launchctl list | grep audio-monitor
   ```

### Dashboard Shows "DOWN" Status

**Investigate**:
```bash
# Check if service is actually down
launchctl list | grep audio-monitor

# Check for errors in logs
tail -50 ~/.claude/logs/audio-monitor-launchd-stderr.log

# Manually restart service
launchctl stop com.albedo.audio-monitor
launchctl start com.albedo.audio-monitor

# Run health check
/path/to/ai-bedo/scripts/audio-monitor-healthcheck.sh
```

### Heartbeat Not Appearing

**Verify heartbeat thread started**:
```bash
grep -i "heartbeat" ~/.claude/logs/audio-monitor-launchd-stderr.log
```

Should see: `Started heartbeat monitor (60s interval)`

**Wait 60 seconds** for first heartbeat, then check Loki:
```bash
curl -G "http://10.211.55.2:3100/loki/api/v1/labels" | grep -i service
```

Should see `"service"` in the labels list.

## Dashboard Customization

### Change Refresh Rate

1. Click time picker (top right)
2. Set refresh interval: 10s, 30s, 1m, 5m, etc.
3. Save dashboard

### Modify Time Range

1. Click time picker
2. Select preset (Last 1h, 3h, 6h, 12h, 24h)
3. Or set custom range

### Add New Panels

1. Click "+ Add panel"
2. Select visualization type (Time series, Stat, Logs, etc.)
3. Configure query (LogQL or PromQL)
4. Customize appearance
5. Save

## Related Documentation

- **Monitoring Stack TL;DR**: `/path/to/carian-observatory/docs/MONITORING-TLDR.md`
- **Audio Monitor Error Handling**: `/path/to/ai-bedo/docs/AUDIO-MONITOR-ERROR-HANDLING.md`
- **Loki Documentation**: https://grafana.com/docs/loki/latest/
- **LogQL Query Language**: https://grafana.com/docs/loki/latest/logql/

---

**Created**: 2025-10-17
**Last Updated**: 2025-10-17
**Maintainer**: Main Machine Albedo
