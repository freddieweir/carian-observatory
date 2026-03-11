# Security Model

## Template-Based Configuration

Observatory uses a template system to prevent secrets from entering version control:

```
carian-observatory/
├── templates/                    # Safe for git (yourdomain.com placeholders)
│   ├── .env.template
│   └── services/{service}/
│       ├── configs/*.template
│       └── scripts/*.template
├── services/                     # Gitignored (real domains)
│   └── {service}/
│       ├── configs/*.yaml
│       └── scripts/*.sh
└── create-all-from-templates.sh  # Generates working files from templates
```

Templates use `yourdomain.com` placeholders. Running `create-all-from-templates.sh` generates working files with real domains. Generated files are automatically gitignored.

## Secret Management

### 1Password Connect

| Component | Role |
|-----------|------|
| `co-1p-connect-sync` | Maintains encrypted vault cache, syncs with 1Password.com |
| `co-1p-connect-api` | REST API for secret retrieval (localhost:8090 only) |

The sync container runs on an isolated internal network. The API container bridges to the main application network but binds only to localhost.

### CLI Injection

```bash
# Inject secrets from 1Password vault into .env
op inject -f -i .env -o .env.resolved
```

### Priority Order

1. 1Password Connect API (production)
2. 1Password CLI injection (deployment)
3. Environment variables (last resort, with warnings)

## Network Isolation

| Network | Purpose | Access |
|---------|---------|--------|
| `carian-shared` | Cross-stack communication | All three stacks |
| `onepassword-internal` | 1Password sync isolation | Sync + API containers only |
| `onepassword-external` | 1Password.com access | Sync container only |

All external traffic enters through `co-nginx-service` on ports 80/443. No service has direct internet exposure.

## Authentication

Authentication is handled by Manor's Authelia instance (`cm-authelia-service`). Observatory's nginx forwards auth checks to Authelia via the `carian-shared` network.

- Default policy: `deny` (explicit allow required)
- WebAuthn/FIDO2 support for hardware security keys
- TOTP for software-based 2FA
- Sessions stored in Manor's Redis instance

## SSL/TLS

- All external traffic terminates SSL at nginx
- Internal service communication is unencrypted (Docker network isolation)
- Certificates stored in `services/nginx/ssl/`
- HTTP automatically redirects to HTTPS
