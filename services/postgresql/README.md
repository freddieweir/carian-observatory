# PostgreSQL Service (In Development)

**Status**: 🚧 In Development - Not currently included in main deployment

PostgreSQL 18 with pgvector extension for vector similarity search and memory storage backend.

## Purpose

Planned as an alternative memory/storage backend for Open-WebUI and other services requiring:
- Persistent memory storage for AI conversations
- Vector similarity search (via pgvector extension)
- Better concurrency than SQLite
- Shared database for multiple services

## Current Status

**Not Active**: This service is defined but not included in the main `docker-compose.yml`.

To enable this service, uncomment it in `/docker-compose.yml`:

```yaml
include:
  # ... other services ...
  - path: services/postgresql/docker-compose.yml  # Uncomment this line
```

## Features

- **PostgreSQL 18**: Latest stable version
- **pgvector Extension**: Vector similarity search for AI embeddings
- **Persistent Storage**: Docker volume for data persistence
- **Health Checks**: Automated health monitoring
- **Initialization Scripts**: Auto-run SQL scripts on first start

## Configuration

### Environment Variables

Add to your `.env` file:

```bash
# PostgreSQL Configuration
POSTGRESQL_DB=carian_observatory
POSTGRESQL_USER=carian_user
POSTGRESQL_PASSWORD=generate_secure_password_here  # Use: openssl rand -base64 32
```

### Security Recommendations

1. **Strong Password**: Generate secure password:
   ```bash
   openssl rand -base64 32
   ```

2. **Network Isolation**: PostgreSQL is only accessible within Docker network
   - Port 5432 exposed for local development only
   - For production, remove port mapping entirely

3. **Secret Management**: Store credentials in 1Password:
   ```bash
   # Add to 1Password
   op item create \
     --category=database \
     --title="Carian Observatory PostgreSQL" \
     POSTGRESQL_PASSWORD="${POSTGRESQL_PASSWORD}"
   ```

## Directory Structure

```
services/postgresql/
├── docker-compose.yml.template  # Service definition
├── configs/
│   └── postgresql.conf.template # PostgreSQL configuration
├── init/
│   └── 01-init-pgvector.sql.template  # Initialize pgvector extension
├── scripts/
│   ├── import-memories.py.template    # Memory import utility
│   └── memory-manager.sh.template     # Memory management script
└── README.md                    # This file
```

## Initialization

On first start, PostgreSQL will:

1. Create database specified in `POSTGRESQL_DB`
2. Create user specified in `POSTGRESQL_USER`
3. Run scripts in `init/` directory:
   - `01-init-pgvector.sql`: Install and configure pgvector extension

## Usage

### Starting PostgreSQL

```bash
# Generate configs from templates
./scripts/create-all-from-templates.sh

# Start PostgreSQL service
docker compose up -d postgresql

# Check status
docker compose ps postgresql

# View logs
docker compose logs -f postgresql
```

### Connecting to PostgreSQL

#### From Docker Container

```bash
# Interactive psql session
docker exec -it co-postgresql-service psql -U carian_user -d carian_observatory

# Run single query
docker exec co-postgresql-service psql -U carian_user -d carian_observatory -c "SELECT version();"
```

#### From Host (if port exposed)

```bash
# Using psql client
psql -h localhost -p 5432 -U carian_user -d carian_observatory

# Using connection string
psql "postgresql://carian_user:password@localhost:5432/carian_observatory"
```

### Common Operations

#### Create Backup

```bash
# Backup to file
docker exec co-postgresql-service pg_dump -U carian_user carian_observatory > backup.sql

# Compressed backup
docker exec co-postgresql-service pg_dump -U carian_user carian_observatory | gzip > backup.sql.gz
```

#### Restore from Backup

```bash
# Stop services using the database
docker compose stop open-webui

# Restore from backup
docker exec -i co-postgresql-service psql -U carian_user carian_observatory < backup.sql

# Restart services
docker compose start open-webui
```

#### View Database Size

```bash
docker exec co-postgresql-service psql -U carian_user -d carian_observatory -c "
SELECT
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
"
```

## Integration with Open-WebUI

When enabled, configure Open-WebUI to use PostgreSQL:

### Environment Variables

```bash
# In .env or open-webui docker-compose.yml
DATABASE_URL=postgresql://carian_user:password@co-postgresql-service:5432/carian_observatory
```

### Migration from SQLite

```bash
# Export from SQLite (if exists)
docker exec co-open-webui-service python manage.py dumpdata > data.json

# Import to PostgreSQL
docker exec co-open-webui-service python manage.py loaddata data.json
```

## pgvector Extension

### What is pgvector?

PostgreSQL extension for vector similarity search, enabling:
- Embedding storage (AI model outputs)
- Similarity search (find similar conversations)
- Semantic search (meaning-based search)

### Example Usage

```sql
-- Create table with vector column
CREATE TABLE embeddings (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding VECTOR(1536)  -- OpenAI ada-002 dimensions
);

-- Insert embedding
INSERT INTO embeddings (content, embedding)
VALUES ('example text', '[0.1, 0.2, 0.3, ...]');

-- Find similar vectors (cosine similarity)
SELECT content
FROM embeddings
ORDER BY embedding <=> '[0.1, 0.2, 0.3, ...]'
LIMIT 5;
```

## Memory Management Scripts

### Import Memories

Import existing conversation memories:

```bash
./services/postgresql/scripts/import-memories.py \
    --source /path/to/memories.json \
    --db-url postgresql://user:pass@localhost:5432/dbname
```

### Memory Manager

Manage memory lifecycle:

```bash
# Show memory statistics
./services/postgresql/scripts/memory-manager.sh stats

# Clean old memories
./services/postgresql/scripts/memory-manager.sh clean --older-than 90d

# Export memories
./services/postgresql/scripts/memory-manager.sh export --output memories.json
```

## Performance Tuning

### Configuration (postgresql.conf)

Key settings for Carian Observatory workload:

```conf
# Memory
shared_buffers = 256MB          # 25% of RAM
effective_cache_size = 1GB      # 50-75% of RAM

# Connections
max_connections = 100

# Disk
random_page_cost = 1.1          # SSD optimized

# Logging
log_statement = 'mod'           # Log modifications
log_duration = on               # Log slow queries
```

### Vacuum and Analyze

```bash
# Manual vacuum (usually automatic)
docker exec co-postgresql-service psql -U carian_user -d carian_observatory -c "VACUUM ANALYZE;"

# Reindex database
docker exec co-postgresql-service psql -U carian_user -d carian_observatory -c "REINDEX DATABASE carian_observatory;"
```

## Monitoring

### Health Check

```bash
# Check if PostgreSQL is ready
docker exec co-postgresql-service pg_isready -U carian_user -d carian_observatory

# Check replication status (if applicable)
docker exec co-postgresql-service psql -U carian_user -c "SELECT * FROM pg_stat_replication;"
```

### Logs

```bash
# Follow logs
docker compose logs -f postgresql

# Last 100 lines
docker compose logs --tail=100 postgresql

# Search for errors
docker compose logs postgresql | grep ERROR
```

### Database Statistics

```bash
# Connection stats
docker exec co-postgresql-service psql -U carian_user -c "
SELECT datname, numbackends, xact_commit, xact_rollback
FROM pg_stat_database
WHERE datname = 'carian_observatory';
"

# Table sizes
docker exec co-postgresql-service psql -U carian_user -d carian_observatory -c "
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

## Troubleshooting

### Cannot Connect

**Issue**: Connection refused

**Solutions**:
1. Check service is running: `docker compose ps postgresql`
2. Check logs: `docker compose logs postgresql`
3. Verify credentials in `.env`
4. Ensure network connectivity: `docker network inspect carian-observatory_app-network`

### Permission Denied

**Issue**: Permission errors on data directory

**Solution**:
```bash
# Fix permissions
docker compose down postgresql
sudo chown -R 999:999 services/postgresql/data  # PostgreSQL runs as UID 999
docker compose up -d postgresql
```

### Disk Space

**Issue**: Database growing too large

**Solutions**:
```bash
# Check size
docker exec co-postgresql-service psql -U carian_user -c "\l+"

# Vacuum full (reclaim space)
docker exec co-postgresql-service psql -U carian_user -d carian_observatory -c "VACUUM FULL;"

# Clean old data (application-specific)
# Implement retention policy in application
```

## Production Considerations

Before enabling in production:

- [ ] Strong password generated and stored in 1Password
- [ ] Remove port 5432 exposure (internal network only)
- [ ] Configure automated backups (see backup scripts)
- [ ] Set up monitoring (Prometheus postgres_exporter)
- [ ] Configure log rotation
- [ ] Test restore procedure
- [ ] Document recovery time objective (RTO)
- [ ] Plan for database growth (disk space)

## Future Plans

- [ ] Integration with Open-WebUI for memory storage
- [ ] Prometheus postgres_exporter for monitoring
- [ ] Grafana dashboard for PostgreSQL metrics
- [ ] Automated backup to S3/B2
- [ ] Replication for high availability
- [ ] Connection pooling with PgBouncer

## Resources

- [PostgreSQL 18 Documentation](https://www.postgresql.org/docs/18/)
- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [Docker PostgreSQL Image](https://hub.docker.com/_/postgres)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

---

**Status**: In Development
**Last Updated**: 2025-11-09
**Maintainer**: See CODEOWNERS
