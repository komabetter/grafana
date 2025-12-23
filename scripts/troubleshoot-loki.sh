#!/bin/bash

# Loki troubleshooting script
# This script helps diagnose Loki health check issues

set -e

echo "🔍 Troubleshooting Loki Health Issues..."
echo "======================================"

# Function to check directory permissions
check_permissions() {
    local dir=$1
    echo "Checking permissions for: $dir"
    
    if [ -d "$dir" ]; then
        ls -la "$dir"
        echo "Owner: $(stat -c '%U:%G' "$dir" 2>/dev/null || echo "unknown")"
        echo "Permissions: $(stat -c '%A' "$dir" 2>/dev/null || echo "unknown")"
    else
        echo "❌ Directory does not exist: $dir"
        return 1
    fi
}

# Check data directories
echo "📁 Checking Data Directories..."
echo "------------------------------"
check_permissions "data"
check_permissions "data/loki"

# Check if Loki user can write to directories
echo ""
echo "🔐 Checking Loki User Permissions..."
echo "-----------------------------------"
LOKI_UID=10001
LOKI_GID=10001

echo "Expected Loki UID:GID = $LOKI_UID:$LOKI_GID"

# Check if directories are writable by Loki user
if [ -d "data/loki" ]; then
    echo "Testing write permissions..."
    sudo -u "#$LOKI_UID" touch data/loki/test-write 2>/dev/null && {
        echo "✅ Loki user can write to data/loki"
        rm -f data/loki/test-write
    } || {
        echo "❌ Loki user cannot write to data/loki"
        echo "Fixing permissions..."
        sudo chown -R $LOKI_UID:$LOKI_GID data/loki
        sudo chmod -R 755 data/loki
    }
fi

# Check Loki container status
echo ""
echo "🐳 Checking Loki Container Status..."
echo "-----------------------------------"
if docker-compose ps loki | grep -q "Up"; then
    echo "✅ Loki container is running"
    
    # Check Loki logs
    echo ""
    echo "📋 Recent Loki Logs:"
    echo "-------------------"
    docker-compose logs --tail=20 loki
    
    # Test health endpoint
    echo ""
    echo "🏥 Testing Health Endpoint..."
    echo "----------------------------"
    
    # Wait a moment for Loki to start
    sleep 5
    
    # Test health endpoint from host
    if curl -f -s "http://localhost:3101/ready" >/dev/null 2>&1; then
        echo "✅ Loki health endpoint accessible from host"
    else
        echo "❌ Loki health endpoint not accessible from host"
        
        # Test from inside container
        echo "Testing from inside container..."
        if docker-compose exec loki wget -q --spider http://localhost:3100/ready 2>/dev/null; then
            echo "✅ Loki health endpoint accessible from inside container"
            echo "Issue might be with port mapping"
        else
            echo "❌ Loki health endpoint not accessible from inside container"
            echo "Loki service is not responding properly"
        fi
    fi
    
else
    echo "❌ Loki container is not running"
    echo ""
    echo "📋 Loki Container Logs:"
    echo "----------------------"
    docker-compose logs loki
fi

# Check configuration
echo ""
echo "⚙️  Checking Loki Configuration..."
echo "---------------------------------"
if [ -f "config/loki-config.yml" ]; then
    echo "✅ Loki configuration file exists"
    
    # Check for common configuration issues
    if grep -q "http_listen_address: 0.0.0.0" config/loki-config.yml; then
        echo "✅ Loki configured to listen on all interfaces"
    else
        echo "⚠️  Loki might not be configured to listen on all interfaces"
    fi
    
    if grep -q "http_listen_port: 3100" config/loki-config.yml; then
        echo "✅ Loki configured for port 3100"
    else
        echo "⚠️  Loki port configuration might be incorrect"
    fi
else
    echo "❌ Loki configuration file not found"
fi

echo ""
echo "🔧 Suggested Solutions:"
echo "----------------------"
echo "1. Restart Loki container: docker-compose restart loki"
echo "2. Check data directory permissions: sudo chown -R 10001:10001 data/loki"
echo "3. Recreate containers: docker-compose down && docker-compose up -d"
echo "4. Check Docker logs: docker-compose logs loki"
echo "5. Verify configuration: ./scripts/validate-logging-config.sh"