# 1Password Connect Secure Management Scripts

These scripts provide secure management of 1Password Connect services using Touch ID authentication instead of storing credentials on disk.

## Security Features

- ✅ **Touch ID Authentication**: Credentials fetched on-demand using biometric auth
- ✅ **No Persistent Storage**: Credentials exist only in tmpfs (RAM) during runtime
- ✅ **Automatic Cleanup**: Credentials are securely shredded when services stop
- ✅ **Session-based Access**: Each restart requires fresh Touch ID authentication

## Scripts Overview

### `manage-with-auto-restart.sh` ⭐ **RECOMMENDED**
Enhanced service manager with auto-restart capabilities:
```bash
# Start with optional auto-restart setup
./manage-with-auto-restart.sh start

# Stop with cleanup options
./manage-with-auto-restart.sh stop

# Install auto-restart monitoring
./manage-with-auto-restart.sh auto-install

# Check auto-restart status
./manage-with-auto-restart.sh auto-status

# Remove auto-restart monitoring
./manage-with-auto-restart.sh auto-remove
```

### `manage-1password-connect.sh`
Basic service manager with systemd-style commands:
```bash
# Start services with Touch ID
./manage-1password-connect.sh start

# Stop and clean up credentials
./manage-1password-connect.sh stop

# Restart with fresh authentication
./manage-1password-connect.sh restart

# Check service status
./manage-1password-connect.sh status

# View logs
./manage-1password-connect.sh logs

# Check health endpoint
./manage-1password-connect.sh health
```

### `start-with-touchid.sh`
Dedicated startup script that:
1. Prompts for Touch ID
2. Fetches credentials from 1Password vault
3. Creates temporary docker-compose override
4. Starts services with credentials mounted from tmpfs
5. Cleans up override file

### `auto-restart-monitor.sh`
Background monitor that watches container health:
```bash
# Start monitoring in background
./auto-restart-monitor.sh start

# Check monitor status
./auto-restart-monitor.sh status

# Stop monitoring
./auto-restart-monitor.sh stop

# View monitor logs
./auto-restart-monitor.sh logs
```

### `fetch-connect-credentials.sh`
Low-level credential fetcher that:
1. Uses `op` CLI with Touch ID
2. Retrieves service account token from vault
3. Saves to `/tmp/1password-credentials.json`
4. Sets restrictive permissions (600)

### `touchid-prompt.sh`
Native macOS notifications and prompts:
```bash
# Show dialog and prompt for Touch ID
./touchid-prompt.sh prompt

# Attempt automatic restart
./touchid-prompt.sh auto

# Test notifications
./touchid-prompt.sh test
```

## Prerequisites

1. **1Password CLI installed**:
   ```bash
   brew install --cask 1password-cli
   ```

2. **1Password account configured**:
   ```bash
   op signin
   ```

3. **Service account token in 1Password**:
   - Item name: "Service Account Auth Token: admin_sister_service"
   - Contains the 1Password Connect credentials JSON

## Initial Setup

1. Ensure your service account token is saved in 1Password
2. Test the credential fetch:
   ```bash
   ./fetch-connect-credentials.sh
   ```
3. Start services with auto-restart:
   ```bash
   ./manage-with-auto-restart.sh start
   ```

## Auto-Restart Features

The auto-restart system provides automatic Touch ID authentication when containers fail:

### Installation
```bash
# Install auto-restart monitoring
./manage-with-auto-restart.sh auto-install
```

This creates a macOS Launch Agent that:
- ✅ Monitors container health continuously
- ✅ Automatically prompts for Touch ID when containers fail
- ✅ Shows native macOS notifications
- ✅ Survives system reboots and user logouts
- ✅ Runs in background without terminal

### How It Works
1. **Monitor**: Background process watches container health every 30 seconds
2. **Detect**: When containers become unhealthy or credentials are missing
3. **Notify**: macOS notification appears requesting Touch ID
4. **Prompt**: Native dialog asks for user confirmation
5. **Authenticate**: Touch ID prompt appears for 1Password CLI
6. **Restart**: Containers restart with fresh credentials
7. **Cleanup**: Temporary credentials are securely removed

### Management
```bash
# Check auto-restart status
./manage-with-auto-restart.sh auto-status

# Remove auto-restart monitoring
./manage-with-auto-restart.sh auto-remove

# View logs
tail -f /tmp/1password-connect-agent.log
```

## Security Notes

- Credentials are NEVER written to persistent storage
- `/tmp` on macOS is backed by RAM (tmpfs)
- Files are shredded (overwritten) before deletion
- Each service restart requires re-authentication
- No credentials in git repository
- No credentials in Docker volumes

## Troubleshooting

### "Item not found" error
- Check the exact item name in 1Password
- Update `ITEM_NAME` in `fetch-connect-credentials.sh`

### Touch ID not working
- Ensure Terminal has Touch ID permissions in System Settings
- Try `op signin` manually first

### Services won't start
- Check credentials are valid JSON: `jq . /tmp/1password-credentials.json`
- Verify Docker networks exist: `docker network ls`
- Check logs: `./manage-1password-connect.sh logs`