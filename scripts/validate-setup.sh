#!/bin/bash

# Validation script for Grafana logging stack setup
# This script checks if the volume and persistence configuration is correct

set -e

echo "Validating Grafana logging stack setup..."

# Check if required directories exist
echo "Checking directory structure..."
if [ ! -d "data" ]; then
    echo "❌ Error: data/ directory not found"
    exit 1
fi

if [ ! -d "data/grafana" ]; then
    echo "❌ Error: data/grafana/ directory not found"
    exit 1
fi

if [ ! -d "data/loki" ]; then
    echo "❌ Error: data/loki/ directory not found"
    exit 1
fi

echo "✅ Directory structure is correct"

# Check if Docker Compose file exists and is valid
echo "Validating Docker Compose configuration..."
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found"
    exit 1
fi

# Validate Docker Compose syntax
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose config >/dev/null 2>&1; then
        echo "✅ Docker Compose configuration is valid"
    else
        echo "❌ Error: Docker Compose configuration is invalid"
        exit 1
    fi
else
    echo "⚠️  Warning: docker-compose not found, skipping syntax validation"
fi

# Check configuration files
echo "Checking configuration files..."
config_files=(
    "config/loki-config.yml"
    "config/promtail-config.yml"
    "config/grafana/grafana.ini"
    "config/grafana/provisioning/datasources/loki.yml"
)

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ Error: $file not found"
        exit 1
    fi
done

# Check directory permissions (if on Unix-like system)
if command -v stat >/dev/null 2>&1; then
    echo "Checking directory permissions..."
    
    grafana_owner=$(stat -c '%u:%g' data/grafana 2>/dev/null || echo "unknown")
    loki_owner=$(stat -c '%u:%g' data/loki 2>/dev/null || echo "unknown")
    
    echo "Grafana directory owner: $grafana_owner (should be 472:472)"
    echo "Loki directory owner: $loki_owner (should be 10001:10001)"
fi

echo ""
echo "🎉 Setup validation complete!"
echo ""
echo "Next steps:"
echo "1. Run 'docker-compose up -d' to start the services"
echo "2. Access Grafana at http://localhost:3000 (admin/admin)"
echo "3. Check service health with 'docker-compose ps'"