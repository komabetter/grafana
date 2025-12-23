# Grafana Logging Stack

A Docker Compose-based logging and monitoring solution using Grafana, Loki, and Promtail to collect, store, and visualize logs from API services.

## Overview

This setup provides:

- **Grafana**: Web-based visualization and dashboards
- **Loki**: Log aggregation and storage backend
- **Promtail**: Log collection agent for Docker containers

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Kong Gateway running (if using Kong integration)
- Ubuntu Server or compatible Linux distribution

### Setup for Ubuntu Server

1. **Clone and navigate to the project directory**

   ```bash
   cd grafana-logging-setup
   ```

2. **Configure environment variables**

   ```bash
   cp .env.template .env
   # Edit .env file with your preferred settings
   ```

3. **Make scripts executable**

   ```bash
   chmod +x scripts/*.sh
   ```

4. **Set up data directories**

   ```bash
   ./scripts/setup-volumes.sh
   ```

5. **Validate setup**

   ```bash
   ./scripts/validate-setup.sh
   ```

6. **Validate configuration**

   ```bash
   ./scripts/validate-logging-config.sh
   ```

7. **Start the logging stack**

   ```bash
   docker-compose up -d
   ```

   **Or use the comprehensive startup script (recommended):**

   ```bash
   ./scripts/startup-with-validation.sh
   ```

8. **Setup Kong Gateway routes** (if using Kong)
   ```bash
   ./scripts/setup-kong-routes.sh
   ```

### Quick Ubuntu Server Commands

For a quick setup, run these commands in sequence:

```bash
# Make scripts executable and run setup
chmod +x scripts/*.sh
./scripts/setup-volumes.sh
./scripts/validate-setup.sh
./scripts/validate-logging-config.sh
docker-compose up -d

# Optional: Setup Kong routes if Kong Gateway is running
./scripts/setup-kong-routes.sh
```

### Setup for Windows

1. **Clone and navigate to the project directory**

   ```cmd
   cd grafana-logging-setup
   ```

2. **Configure environment variables**

   ```cmd
   copy .env.template .env
   REM Edit .env file with your preferred settings
   ```

3. **Set up data directories**

   ```cmd
   scripts\setup-volumes.bat
   ```

4. **Start the logging stack**

   ```cmd
   docker-compose up -d
   ```

   **Or use the comprehensive startup script:**

   ```cmd
   scripts\startup-with-validation.bat
   ```

## Service Access

### Grafana Dashboard

- **URL**: http://localhost:3100 (admin/admin)
- **Username**: admin
- **Password**: admin (or value from .env file)

### Loki API

- **URL**: http://localhost:3101
- **Health Check**: http://localhost:3101/ready

### Kong Gateway Integration (Optional)

- **Grafana via Kong**: http://localhost:8000/grafana
- **Loki API via Kong**: http://localhost:8000/loki
- **Kong Admin API**: http://localhost:8001
- **Kong Manager GUI**: http://localhost:8002

## Configuration

### Environment Variables

Key settings in `.env` file:

| Variable                 | Default                 | Description                   |
| ------------------------ | ----------------------- | ----------------------------- |
| `GRAFANA_PORT`           | 3100                    | Grafana web interface port    |
| `LOKI_PORT`              | 3101                    | Loki API port                 |
| `GRAFANA_ADMIN_PASSWORD` | admin                   | Grafana admin password        |
| `LOKI_RETENTION_PERIOD`  | 7d                      | Log retention period          |
| `TARGET_API_SERVICES`    | api-auth,api-management | Services to collect logs from |

### Custom Configuration Files

- `config/grafana/grafana.ini` - Grafana server configuration
- `config/grafana/provisioning/` - Grafana data sources and dashboards
- `config/loki-config.yml` - Loki storage and ingestion settings
- `config/promtail-config.yml` - Log collection rules and targets

## Usage

### Viewing Logs

1. Open Grafana at http://localhost:3100
2. Navigate to "Explore" in the left sidebar
3. Select "Loki" as the data source
4. Use LogQL queries to filter logs:

```logql
# All logs from api-auth service
{container_name="api-auth"}

# Error logs from all services
{job=~"api-.*"} |= "error"

# Logs from last 1 hour
{container_name=~"api-.*"} [1h]
```

### Dashboard Features

The pre-configured dashboard includes:

- Real-time log streaming
- Service-based log filtering
- Log level filtering (info, warn, error, debug)
- Time range selection
- Full-text search capabilities

### Log Collection

Promtail automatically collects logs from:

- Docker containers matching the target services
- Container stdout/stderr streams
- Automatic service labeling and tagging

## Troubleshooting

### Validation Scripts

**Basic setup validation:**

```bash
# On Windows
scripts\validate-setup.bat

# On Linux/macOS
./scripts/validate-setup.sh
```

**Service connectivity validation:**

```bash
# On Windows
scripts\validate-services.bat

# On Linux/macOS
./scripts/validate-services.sh
```

**Configuration validation:**

```bash
# On Windows
scripts\validate-logging-config.bat

# On Linux/macOS
./scripts/validate-logging-config.sh
```

### Common Issues

**Services won't start:**

```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs grafana
docker-compose logs loki
docker-compose logs promtail
```

**Permission issues with volumes:**

```bash
# Reset volume permissions
docker-compose down
# On Windows
scripts\setup-volumes.bat

# On Linux/macOS
sudo ./scripts/setup-volumes.sh
docker-compose up -d
```

**Grafana can't connect to Loki:**

- Verify Loki is healthy: `curl http://localhost:3101/ready`
- Check network connectivity: `docker-compose logs loki`
- Restart services: `docker-compose restart`

**No logs appearing:**

- Verify target API services are running
- Check Promtail configuration: `docker-compose logs promtail`
- Ensure Docker socket is accessible

### Health Checks

All services include health checks:

```bash
# Check all service health
docker-compose ps

# Individual service health
curl http://localhost:3101/ready  # Loki
curl http://localhost:3100/api/health  # Grafana
```

## Data Persistence

### Volume Mounts

- **Grafana data**: `./data/grafana` - Dashboards, users, settings
- **Loki data**: `./data/loki` - Log storage and indexes

### Backup

```bash
# Stop services
docker-compose down

# Backup data directories
tar -czf grafana-backup-$(date +%Y%m%d).tar.gz data/

# Restore from backup
tar -xzf grafana-backup-YYYYMMDD.tar.gz
```

## Development

### Adding New Services

1. Update `TARGET_API_SERVICES` in `.env`
2. Modify `config/promtail-config.yml` if custom log parsing needed
3. Restart Promtail: `docker-compose restart promtail`

### Custom Dashboards

1. Create dashboards in Grafana UI
2. Export dashboard JSON
3. Place in `config/grafana/provisioning/dashboards/`
4. Restart Grafana: `docker-compose restart grafana`

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   api-auth      │    │ api-management  │
│   (port 3001)   │    │   (port 3002)   │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────┬───────────┘
                     │ (Docker logs)
                     ▼
              ┌─────────────┐
              │  Promtail   │
              │ (collector) │
              └─────┬───────┘
                    │ (HTTP)
                    ▼
              ┌─────────────┐
              │    Loki     │
              │  (storage)  │
              └─────┬───────┘
                    │ (HTTP API)
                    ▼
              ┌─────────────┐
              │   Grafana   │
              │ (dashboard) │
              └─────────────┘
```

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review Docker Compose logs: `docker-compose logs`
3. Verify configuration files in `config/` directory
4. Ensure all prerequisites are met
