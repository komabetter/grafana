# Volume and Persistence Configuration

This document explains the volume and persistence configuration for the Grafana logging stack.

## Overview

The logging stack uses persistent volumes to ensure data survives container restarts and updates. Two main services require persistent storage:

- **Grafana**: Stores dashboards, user settings, and configuration
- **Loki**: Stores log data and indexes

## Directory Structure

```
project-root/
├── data/
│   ├── grafana/          # Grafana persistent data (UID: 472)
│   └── loki/             # Loki persistent data (UID: 10001)
├── config/
│   ├── grafana/          # Grafana configuration files
│   ├── loki-config.yml   # Loki configuration
│   └── promtail-config.yml # Promtail configuration
└── scripts/
    ├── setup-volumes.sh  # Unix/Linux setup script
    └── setup-volumes.bat # Windows setup script
```

## Setup Instructions

### Automatic Setup

Run the appropriate setup script for your operating system:

**Linux/macOS:**
```bash
chmod +x scripts/setup-volumes.sh
./scripts/setup-volumes.sh
```

**Windows:**
```cmd
scripts\setup-volumes.bat
```

### Manual Setup

If the automatic setup fails, create directories manually:

```bash
# Create directories
mkdir -p data/grafana data/loki

# Set permissions (Linux/macOS)
sudo chown -R 472:472 data/grafana
sudo chown -R 10001:10001 data/loki
chmod -R 755 data/
```

## Volume Configuration

### Bind Mounts (Default)

The default configuration uses bind mounts for direct access to data:

```yaml
volumes:
  loki-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/loki
  grafana-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/grafana
```

### Named Volumes (Fallback)

If bind mounts cause permission issues, the system falls back to named volumes via `docker-compose.override.yml`.

## User and Permission Configuration

### Grafana
- **User ID**: 472
- **Group ID**: 472
- **Data Path**: `/var/lib/grafana`
- **Host Mount**: `./data/grafana`

### Loki
- **User ID**: 10001
- **Group ID**: 10001
- **Data Path**: `/loki`
- **Host Mount**: `./data/loki`

## Troubleshooting

### Permission Denied Errors

If you encounter permission errors:

1. **Check directory ownership:**
   ```bash
   ls -la data/
   ```

2. **Fix Grafana permissions:**
   ```bash
   sudo chown -R 472:472 data/grafana
   ```

3. **Fix Loki permissions:**
   ```bash
   sudo chown -R 10001:10001 data/loki
   ```

### Windows-Specific Issues

On Windows with Docker Desktop:
- Ensure the project directory is in a shared drive
- Docker Desktop handles most permission mapping automatically
- Use the Windows setup script for proper directory creation

### SELinux Issues (RHEL/CentOS/Fedora)

If using SELinux, you may need to set appropriate contexts:

```bash
sudo setsebool -P container_manage_cgroup true
sudo chcon -Rt svirt_sandbox_file_t data/
```

## Data Backup and Recovery

### Backup

To backup persistent data:

```bash
# Create backup directory
mkdir -p backups/$(date +%Y%m%d)

# Backup Grafana data
tar -czf backups/$(date +%Y%m%d)/grafana-backup.tar.gz -C data grafana/

# Backup Loki data
tar -czf backups/$(date +%Y%m%d)/loki-backup.tar.gz -C data loki/
```

### Recovery

To restore from backup:

```bash
# Stop services
docker-compose down

# Restore data (replace YYYYMMDD with backup date)
tar -xzf backups/YYYYMMDD/grafana-backup.tar.gz -C data/
tar -xzf backups/YYYYMMDD/loki-backup.tar.gz -C data/

# Fix permissions
./scripts/setup-volumes.sh

# Start services
docker-compose up -d
```

## Environment Variables

The following environment variables can be used to customize paths:

- `GRAFANA_DATA_PATH`: Override Grafana data directory (default: `./data/grafana`)
- `LOKI_DATA_PATH`: Override Loki data directory (default: `./data/loki`)

Example usage:
```bash
export GRAFANA_DATA_PATH=/custom/grafana/path
export LOKI_DATA_PATH=/custom/loki/path
docker-compose up -d
```