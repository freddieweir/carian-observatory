# 1Password Connect Secure Management Scripts

These scripts provide secure management of 1Password Connect services using Touch ID authentication instead of storing credentials on disk.

## Security Features

- ✅ **Touch ID Authentication**: Credentials fetched on-demand using biometric auth
- ✅ **No Persistent Storage**: Credentials exist only in tmpfs (RAM) during runtime
- ✅ **Automatic Cleanup**: Credentials are securely shredded when services stop
- ✅ **Session-based Access**: Each restart requires fresh Touch ID authentication

## Scripts Overview

### `manage-1password-connect.sh`
Main service manager with systemd-style commands:
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

### `fetch-connect-credentials.sh`
Low-level credential fetcher that:
1. Uses `op` CLI with Touch ID
2. Retrieves service account token from vault
3. Saves to `/tmp/1password-credentials.json`
4. Sets restrictive permissions (600)

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
3. Start services:
   ```bash
   ./manage-1password-connect.sh start
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