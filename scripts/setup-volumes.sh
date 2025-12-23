#!/bin/bash

# Setup script for Grafana logging stack volume and persistence configuration
# This script creates the necessary directory structure and sets proper permissions

set -e

echo "Setting up Grafana logging stack volumes and directories..."

# Create data directories
echo "Creating data directories..."
mkdir -p data/grafana
mkdir -p data/loki

# Set proper ownership for Grafana (grafana user has UID 472)
echo "Setting Grafana directory permissions..."
if command -v chown >/dev/null 2>&1; then
    # On systems where chown is available
    sudo chown -R 472:472 data/grafana 2>/dev/null || {
        echo "Warning: Could not set ownership for Grafana directory. You may need to run:"
        echo "  sudo chown -R 472:472 data/grafana"
    }
else
    echo "chown not available, setting directory permissions to 777 for compatibility"
    chmod -R 777 data/grafana
fi

# Set proper ownership for Loki (loki user has UID 10001)
echo "Setting Loki directory permissions..."
if command -v chown >/dev/null 2>&1; then
    # On systems where chown is available
    sudo chown -R 10001:10001 data/loki 2>/dev/null || {
        echo "Warning: Could not set ownership for Loki directory. You may need to run:"
        echo "  sudo chown -R 10001:10001 data/loki"
    }
else
    echo "chown not available, setting directory permissions to 777 for compatibility"
    chmod -R 777 data/loki
fi

# Ensure directories are writable
chmod -R 755 data/

echo "Volume setup complete!"
echo ""
echo "Directory structure created:"
echo "  data/"
echo "  ├── grafana/  (UID: 472, GID: 472)"
echo "  └── loki/     (UID: 10001, GID: 10001)"
echo ""
echo "You can now run 'docker-compose up -d' to start the services."