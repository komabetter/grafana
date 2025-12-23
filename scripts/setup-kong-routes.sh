#!/bin/bash

# Kong Gateway Route Setup Script
# This script configures Kong routes for Grafana and Loki services

set -e

echo "🔧 Setting up Kong Gateway routes for Grafana Logging Stack..."

# Kong Admin API URL
KONG_ADMIN_URL="http://localhost:8001"

# Function to check if Kong is ready
wait_for_kong() {
    echo "Waiting for Kong Gateway to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$KONG_ADMIN_URL" >/dev/null 2>&1; then
            echo "✅ Kong Gateway is ready"
            return 0
        fi
        
        echo "⏳ Attempt $attempt/$max_attempts: Kong not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "❌ Kong Gateway failed to become ready after $max_attempts attempts"
    return 1
}

# Function to create a service in Kong
create_service() {
    local service_name=$1
    local service_url=$2
    
    echo "Creating Kong service: $service_name"
    
    curl -i -X POST "$KONG_ADMIN_URL/services/" \
        --data "name=$service_name" \
        --data "url=$service_url" \
        --data "protocol=http" \
        --data "connect_timeout=60000" \
        --data "write_timeout=60000" \
        --data "read_timeout=60000" \
        2>/dev/null || echo "Service $service_name may already exist"
}

# Function to create a route in Kong
create_route() {
    local service_name=$1
    local route_path=$2
    local route_name=$3
    
    echo "Creating Kong route: $route_name for service: $service_name"
    
    curl -i -X POST "$KONG_ADMIN_URL/services/$service_name/routes" \
        --data "name=$route_name" \
        --data "paths[]=$route_path" \
        --data "strip_path=true" \
        2>/dev/null || echo "Route $route_name may already exist"
}

# Function to enable CORS plugin
enable_cors() {
    local service_name=$1
    
    echo "Enabling CORS for service: $service_name"
    
    curl -i -X POST "$KONG_ADMIN_URL/services/$service_name/plugins" \
        --data "name=cors" \
        --data "config.origins=*" \
        --data "config.methods=GET,POST,PUT,DELETE,OPTIONS" \
        --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token,Authorization" \
        --data "config.exposed_headers=X-Auth-Token" \
        --data "config.credentials=true" \
        --data "config.max_age=3600" \
        2>/dev/null || echo "CORS plugin may already be enabled for $service_name"
}

# Main setup function
main() {
    echo "Starting Kong Gateway route setup..."
    echo "===================================="
    
    # Wait for Kong to be ready
    if ! wait_for_kong; then
        echo "❌ Kong Gateway setup failed - Kong not ready"
        exit 1
    fi
    
    echo ""
    echo "📋 Creating Kong Services..."
    echo "----------------------------"
    
    # Create Grafana service
    create_service "grafana" "http://grafana:3000"
    
    # Create Loki service
    create_service "loki" "http://loki:3100"
    
    echo ""
    echo "📋 Creating Kong Routes..."
    echo "-------------------------"
    
    # Create Grafana route
    create_route "grafana" "/grafana" "grafana-route"
    
    # Create Loki route
    create_route "loki" "/loki" "loki-route"
    
    echo ""
    echo "📋 Enabling CORS..."
    echo "------------------"
    
    # Enable CORS for services
    enable_cors "grafana"
    enable_cors "loki"
    
    echo ""
    echo "🎉 Kong Gateway setup complete!"
    echo ""
    echo "Service URLs through Kong Gateway:"
    echo "- Grafana: http://localhost:8000/grafana"
    echo "- Loki API: http://localhost:8000/loki"
    echo ""
    echo "Direct service URLs:"
    echo "- Grafana: http://localhost:3100"
    echo "- Loki API: http://localhost:3101"
    echo ""
    echo "Kong Management:"
    echo "- Kong Admin API: http://localhost:8001"
    echo "- Kong Manager GUI: http://localhost:8002"
    echo ""
    echo "To view Kong configuration:"
    echo "curl http://localhost:8001/services"
    echo "curl http://localhost:8001/routes"
}

# Run main function
main "$@"