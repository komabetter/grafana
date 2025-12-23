# Service Access Guide

This document provides detailed information about accessing and using the Grafana logging stack services.

## Service URLs and Ports

### Grafana (Web Dashboard)
- **URL**: http://localhost:3000
- **Protocol**: HTTP
- **Purpose**: Log visualization and dashboard interface
- **Status**: http://localhost:3000/api/health

### Loki (Log Storage API)
- **URL**: http://localhost:3100
- **Protocol**: HTTP
- **Purpose**: Log aggregation and storage backend
- **Health Check**: http://localhost:3100/ready
- **Metrics**: http://localhost:3100/metrics

### Promtail (Log Collector)
- **Internal Service**: No external port exposed
- **Purpose**: Collects logs from Docker containers
- **Metrics**: Available via Loki metrics endpoint

## Default Credentials

### Grafana Access
- **Username**: `admin`
- **Password**: `admin` (default, configurable via .env)
- **First Login**: You'll be prompted to change the password

### Security Notes
- Change default credentials in production environments
- Configure authentication providers if needed
- Use environment variables for sensitive configuration

## API Access

### Loki Query API
```bash
# Query logs via HTTP API
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={container_name="api-auth"}' \
  --data-urlencode 'limit=100'

# Query log range
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="api-auth"}' \
  --data-urlencode 'start=2024-01-01T00:00:00Z' \
  --data-urlencode 'end=2024-01-01T23:59:59Z'
```

### Grafana API
```bash
# Get Grafana health status
curl http://localhost:3000/api/health

# List data sources (requires authentication)
curl -u admin:admin http://localhost:3000/api/datasources
```

## LogQL Query Examples

### Basic Queries
```logql
# All logs from api-auth service
{container_name="api-auth"}

# All logs from api-management service  
{container_name="api-management"}

# All API service logs
{container_name=~"api-.*"}
```

### Filtered Queries
```logql
# Error logs only
{container_name=~"api-.*"} |= "error"

# Logs containing specific text
{container_name="api-auth"} |= "authentication"

# Logs NOT containing text
{container_name="api-auth"} != "debug"
```

### Time-based Queries
```logql
# Last 5 minutes
{container_name="api-auth"}[5m]

# Last hour
{container_name=~"api-.*"}[1h]

# Specific time range (use in query_range)
{container_name="api-auth"}
```

### Advanced Queries
```logql
# Rate of error logs per minute
rate({container_name=~"api-.*"} |= "error"[1m])

# Count logs by service
count by (container_name) ({container_name=~"api-.*"})

# Parse JSON logs and filter
{container_name="api-auth"} | json | level="error"
```

## Dashboard Navigation

### Pre-configured Dashboards
1. **API Services Overview** - Main dashboard showing all service logs
2. **Service Health** - Health metrics and status indicators
3. **Error Analysis** - Focused view of error logs and patterns

### Dashboard Features
- **Time Range Picker**: Select custom time ranges for log analysis
- **Service Filter**: Filter logs by specific API service
- **Log Level Filter**: Show only specific log levels (info, warn, error, debug)
- **Search**: Full-text search across all log messages
- **Live Tail**: Real-time log streaming

### Creating Custom Dashboards
1. Navigate to "+" → "Dashboard" in Grafana
2. Add panels with Loki data source
3. Use LogQL queries for data
4. Save and organize in folders

## Monitoring and Alerts

### Service Health Monitoring
- Grafana health: http://localhost:3000/api/health
- Loki health: http://localhost:3100/ready
- Docker container status: `docker-compose ps`

### Log Volume Monitoring
```logql
# Monitor log ingestion rate
sum(rate({container_name=~"api-.*"}[5m])) by (container_name)

# Alert on high error rates
sum(rate({container_name=~"api-.*"} |= "error"[5m])) > 0.1
```

### Setting Up Alerts
1. Create alert rules in Grafana
2. Configure notification channels (email, Slack, etc.)
3. Set thresholds for log patterns or volumes
4. Test alert delivery

## Data Sources Configuration

### Loki Data Source Settings
- **URL**: http://loki:3100 (internal Docker network)
- **Access**: Server (default)
- **HTTP Method**: GET
- **Timeout**: 60s

### Verifying Data Source
1. Go to Configuration → Data Sources in Grafana
2. Click on Loki data source
3. Click "Test" button
4. Should show "Data source is working"

## Troubleshooting Access Issues

### Cannot Access Grafana
```bash
# Check if Grafana container is running
docker-compose ps grafana

# Check Grafana logs
docker-compose logs grafana

# Verify port binding
netstat -an | grep 3000
```

### Cannot Query Logs
```bash
# Check Loki health
curl http://localhost:3100/ready

# Check Promtail is sending logs
docker-compose logs promtail

# Verify log ingestion
curl -G -s "http://localhost:3100/loki/api/v1/label"
```

### Authentication Issues
```bash
# Reset Grafana admin password
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword

# Check Grafana configuration
docker-compose exec grafana cat /etc/grafana/grafana.ini
```

## Security Considerations

### Network Security
- Services communicate via internal Docker network
- Only Grafana port (3000) exposed externally
- Loki API (3100) accessible for debugging but can be restricted

### Data Security
- Logs stored locally in Docker volumes
- No external data transmission by default
- Configure TLS for production deployments

### Access Control
- Change default Grafana credentials
- Configure user roles and permissions
- Use authentication providers (LDAP, OAuth) for team access
- Implement network-level access controls if needed