# TICKET-005: Glance + Homepage Integration with OPML RSS Automation

## Overview
Integrate GlanceApp (external feeds) with Homepage (internal services) using iframe embedding approach. Implement automated RSS feed management using News Explorer OPML exports with 1Password secure storage.

## Architecture Plan

### Two-Page Glance Setup
```
co-glance-service (external feeds dashboard)
├── Page 1: External Feeds
│   ├── RSS feeds (tech news, releases)
│   ├── Reddit feeds (selfhosted, homelab)
│   ├── GitHub repositories monitoring
│   ├── Stock/crypto markets
│   └── Weather widget
│
└── Page 2: Internal Services
    └── iframe → co-homepage-service
        ├── Carian Observatory services
        ├── Perplexica search
        ├── Authelia auth status
        └── Container health monitoring
```

### Service Integration
- **Service Name**: `co-glance-service` (follows structured naming convention)
- **Domain**: `glance.corporateseas.com`
- **Network**: `carian-observatory_app-network`
- **Authentication**: Routes through Authelia (same as other services)
- **SSL**: Managed by `co-nginx-service`

## Technical Implementation

### Docker Configuration
```yaml
services:
  glance:
    container_name: co-glance-service
    image: glanceapp/glance
    networks:
      - app-network
    environment:
      - HOMEPAGE_INTERNAL_URL=http://co-homepage-service:3000
    volumes:
      - ./services/glance/configs/glance.yml:/app/config/glance.yml:ro
```

### Glance Configuration Template
```yaml
# glance.yml
server:
  port: 8080
  host: 0.0.0.0

pages:
  - name: "Feeds & Markets"
    columns:
      - size: small
        widgets:
          - type: rss
            title: "Tech News"
            feeds:
              - url: ${RSS_FEED_TECH_NEWS}
              - url: ${RSS_FEED_HOMELAB}
          - type: reddit
            subreddit: "selfhosted"
          - type: markets
            stocks: ["AAPL", "GOOGL", "MSFT"]
      - size: small
        widgets:
          - type: repository
            repositories:
              - "glanceapp/glance"
              - "gethomepage/homepage"

  - name: "Carian Observatory"
    columns:
      - size: full
        widgets:
          - type: iframe
            source: ${HOMEPAGE_INTERNAL_URL}
            height: 900
```

### Nginx Integration
Add to `services/nginx/configs/https.conf.template`:
```nginx
server {
    listen 443 ssl;
    server_name glance.yourdomain.com;

    ssl_certificate /app/ssl/yourdomain.com.crt;
    ssl_certificate_key /app/ssl/yourdomain.com.key;

    include /app/configs/authelia_authrequest.conf;

    location / {
        include /app/configs/authelia_proxy.conf;
        proxy_pass http://co-glance-service:8080;
    }
}
```

## RSS Feed Automation Strategy

### News Explorer OPML Integration
- **Source**: News Explorer on macOS with iCloud sync
- **Export**: OPML file containing all RSS feed URLs and metadata
- **Processing**: Automated script to parse OPML and generate 1Password variables
- **Storage**: RSS feed URLs securely stored as 1Password environment variables

### Implementation Approaches

#### Option 1: Local Carian Observatory Script
**Location**: `/scripts/glance/opml-to-1password.sh`
- Parse OPML file exported from News Explorer
- Extract RSS feed URLs and categories
- Generate 1Password items with structured naming
- Update `.env` template with new RSS variables

#### Option 2: Fifth Symphony Integration (Preferred Long-term)
**Location**: `/Users/fweir/git/internal/repos/fifth-symphony`
- Leverage Fifth Symphony's automation capabilities
- Cross-system RSS feed management
- Voice feedback for RSS feed operations
- ADHD-friendly interface for feed management

### OPML Processing Workflow
```bash
# 1. Export OPML from News Explorer
# 2. Process OPML file
./scripts/glance/opml-to-1password.sh ~/Downloads/NewsExplorer.opml

# 3. Generated 1Password items:
# RSS_FEED_TECH_NEWS_01=https://feeds.feedburner.com/oreilly/radar
# RSS_FEED_HOMELAB_01=https://www.reddit.com/r/homelab/.rss
# RSS_FEED_SELFHOSTED_01=https://www.reddit.com/r/selfhosted/.rss

# 4. Update Glance configuration with new variables
# 5. Restart co-glance-service to apply changes
```

### 1Password Integration Pattern
```bash
# Store RSS feeds as 1Password environment variables
op item create \
  --category="API Credential" \
  --title="Glance RSS Feeds" \
  --field="RSS_FEED_TECH_NEWS=https://example.com/rss" \
  --field="RSS_FEED_HOMELAB=https://homelab.com/rss"

# Retrieve in scripts
RSS_FEEDS=$(op item get "Glance RSS Feeds" --fields RSS_FEED_TECH_NEWS)
```

## Security Considerations

### Authentication Flow
1. User accesses `https://glance.corporateseas.com`
2. Nginx routes through Authelia authentication
3. Authenticated users see Glance dashboard
4. Page 2 iframe loads Homepage via internal Docker network (no auth required)

### Data Protection
- RSS feed URLs stored in 1Password (not in git)
- OPML files processed locally, not committed
- Environment variables injected at runtime
- Internal iframe communication over Docker network

### Template System
- **Scripts**: Use `.template` files with `yourdomain.com` placeholders
- **Generated**: Real scripts with `corporateseas.com` domains (gitignored)
- **Configuration**: Environment variable substitution for RSS URLs

## Implementation Tasks

### Phase 1: Basic Integration
- [ ] Add Glance service to docker-compose.yml
- [ ] Create Glance configuration template
- [ ] Update nginx routing for glance.corporateseas.com
- [ ] Configure iframe embedding of Homepage
- [ ] Test two-page navigation and iframe functionality

### Phase 2: RSS Automation
- [ ] Create OPML processing script in `/scripts/glance/`
- [ ] Implement 1Password RSS feed storage pattern
- [ ] Test News Explorer OPML export workflow
- [ ] Automate environment variable generation
- [ ] Document RSS feed management procedures

### Phase 3: Fifth Symphony Integration (Future)
- [ ] Design Fifth Symphony RSS management module
- [ ] Implement cross-system feed synchronization
- [ ] Add voice feedback for RSS operations
- [ ] Create ADHD-friendly feed management interface

## Success Criteria

### Functional Requirements
- [ ] Glance accessible at `https://glance.corporateseas.com`
- [ ] Two-page navigation working (External Feeds + Internal Services)
- [ ] Homepage embedded correctly in iframe
- [ ] RSS feeds display external content
- [ ] Reddit and GitHub widgets showing data

### Automation Requirements
- [ ] News Explorer OPML export processed successfully
- [ ] RSS URLs stored securely in 1Password
- [ ] Environment variables generated automatically
- [ ] Glance configuration updated without manual editing

### Security Requirements
- [ ] All access authenticated through Authelia
- [ ] No RSS URLs committed to git
- [ ] OPML processing script uses template system
- [ ] Internal iframe communication secure

## Benefits

### User Experience
- **Unified Dashboard**: Single interface for external feeds and internal services
- **Familiar Navigation**: Two-page structure separates concerns clearly
- **Automated RSS Management**: News Explorer integration reduces manual configuration
- **Secure Storage**: 1Password integration maintains security best practices

### Technical Benefits
- **Proven Approach**: Based on successful Reddit community example
- **Structured Architecture**: Follows Carian Observatory naming conventions
- **Scalable Automation**: Fifth Symphony integration path for advanced workflows
- **Maintainable Security**: Template system prevents domain exposure

## Related Documentation
- Reddit Inspiration: https://www.reddit.com/r/selfhosted/comments/1gpsmnj/glance_and_homepage_in_iframe/
- Glance Documentation: `/Users/fweir/git/external/repos/monitoring-tools/glance/docs`
- Fifth Symphony: `/Users/fweir/git/internal/repos/fifth-symphony/CLAUDE.md`

## Priority
**High** - Provides unified external/internal dashboard integration

## Status
**Planning** - Ready for morning implementation

## Created
January 18, 2025

## Notes
- OPML automation can start local, migrate to Fifth Symphony later
- iframe approach proven by Reddit community
- Maintains Carian Observatory structured service patterns
- 1Password integration follows existing security practices