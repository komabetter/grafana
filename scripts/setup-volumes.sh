#!/bin/bash

# Setup script for Grafana logging stack volume and persistence configuration
# Optimized for Ubuntu 22.04 LTS
# This script creates the necessary directory structure and sets proper permissions

set -e

echo "Setting up Grafana logging stack volumes and directories..."
echo "Target OS: Ubuntu 22.04 LTS"
echo ""

# Get the absolute path of the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${PROJECT_DIR}/data"

echo "Project directory: ${PROJECT_DIR}"
echo "Data directory: ${DATA_DIR}"
echo ""

# Create data directories
echo "Creating data directories..."
mkdir -p "${DATA_DIR}/grafana"
mkdir -p "${DATA_DIR}/loki"

# Set proper ownership for Grafana (grafana user has UID 472, GID 472)
echo "Setting Grafana directory permissions (UID:472, GID:472)..."
if [ "$EUID" -eq 0 ]; then
    # Running as root
    chown -R 472:472 "${DATA_DIR}/grafana"
    chmod -R 755 "${DATA_DIR}/grafana"
    echo "✓ Grafana directory ownership set successfully"
else
    # Not running as root, need sudo
    if sudo -n true 2>/dev/null; then
        sudo chown -R 472:472 "${DATA_DIR}/grafana"
        sudo chmod -R 755 "${DATA_DIR}/grafana"
        echo "✓ Grafana directory ownership set successfully"
    else
        echo "⚠ Warning: Need sudo privileges to set ownership. Please run:"
        echo "  sudo chown -R 472:472 ${DATA_DIR}/grafana"
        echo "  sudo chmod -R 755 ${DATA_DIR}/grafana"
        echo ""
        echo "Alternatively, run this script with sudo:"
        echo "  sudo bash scripts/setup-volumes.sh"
        chmod -R 777 "${DATA_DIR}/grafana"
        echo "✓ Set fallback permissions (777) for Grafana directory"
    fi
fi

# Set proper ownership for Loki (loki user has UID 10001, GID 10001)
echo "Setting Loki directory permissions (UID:10001, GID:10001)..."
if [ "$EUID" -eq 0 ]; then
    # Running as root
    chown -R 10001:10001 "${DATA_DIR}/loki"
    chmod -R 755 "${DATA_DIR}/loki"
    echo "✓ Loki directory ownership set successfully"
else
    # Not running as root, need sudo
    if sudo -n true 2>/dev/null; then
        sudo chown -R 10001:10001 "${DATA_DIR}/loki"
        sudo chmod -R 755 "${DATA_DIR}/loki"
        echo "✓ Loki directory ownership set successfully"
    else
        echo "⚠ Warning: Need sudo privileges to set ownership. Please run:"
        echo "  sudo chown -R 10001:10001 ${DATA_DIR}/loki"
        echo "  sudo chmod -R 755 ${DATA_DIR}/loki"
        echo ""
        echo "Alternatively, run this script with sudo:"
        echo "  sudo bash scripts/setup-volumes.sh"
        chmod -R 777 "${DATA_DIR}/loki"
        echo "✓ Set fallback permissions (777) for Loki directory"
    fi
fi

# Ensure parent data directory has proper permissions
chmod 755 "${DATA_DIR}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✓ Volume setup complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Directory structure created:"
echo "  ${DATA_DIR}/"
echo "  ├── grafana/  (UID: 472, GID: 472)"
echo "  └── loki/     (UID: 10001, GID: 10001)"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env: cp .env.example .env"
echo "  2. Edit .env and update configuration values"
echo "  3. Start services: docker-compose up -d"
echo ""