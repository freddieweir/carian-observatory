# Homepage Configuration Structure

## Modular Configuration

Homepage automatically loads ALL `.yaml` files in this directory and merges them. This allows for a modular configuration approach.

### File Organization

- **`services.yaml`** - Main platform services (AI Platform, Infrastructure, Whatbox, Documentation)
- **`personal-tldr.yaml`** - Personal TL;DR section with quick access links (gitignored)
- **`personal-dev.yaml`** - Development tools and personal favorites (gitignored)
- **`bookmarks.yaml`** - Browser bookmarks integration
- **`widgets.yaml`** - Dashboard widgets configuration
- **`settings.yaml`** - Homepage settings and appearance
- **`docker.yaml`** - Docker integration settings

### Personal Files

Files prefixed with `personal-` are automatically gitignored and won't be committed to the repository. This allows you to maintain personal customizations without affecting the main configuration.

To create your own personal sections:
1. Create a new file with `personal-` prefix (e.g., `personal-links.yaml`)
2. Follow the YAML structure used in other service files
3. Restart Homepage: `docker restart co-homepage-service`

### Adding New Service Groups

You can create additional service groups in any YAML file:

```yaml
---
- My Custom Group:
    - Service Name:
        href: https://service.yourdomain.com
        description: Service description
        icon: si-iconname
```

### Template System

For production use, configuration templates (`.yaml.template` files) should use generic domains (`yourdomain.com`). The `create-configs.sh` script generates the actual configuration files with real domains from environment variables.

### Load Order

Homepage loads configuration files alphabetically. If you need specific ordering:
- Prefix files with numbers: `01-critical.yaml`, `02-services.yaml`
- Or use semantic names that naturally sort: `aaa-first.yaml`, `zzz-last.yaml`

Note: The order typically doesn't matter as Homepage merges all configurations intelligently.