#!/bin/bash

# Service connectivity and health validation script
# This script validates that all services are running and can communicate properly

set -e

echo "🔍 Validating Grafana logging stack services..."

# Function to check if a service is responding
check_service_health() {
    local service_name=$1
    local health_url=$2
    local max_attempts=30
    local attempt=1

    echo "Checking $service_name health..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$health_url" >/dev/null 2>&1; then
            echo "✅ $service_name is healthy"
            return 0
        fi
        
        echo "⏳ Attempt $attempt/$max_attempts: $service_name not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "❌ $service_name failed to become healthy after $max_attempts attempts"
    return 1
}

# Function to check Docker Compose service status
check_compose_status() {
    echo "Checking Docker Compose service status..."
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "❌ Error: docker-compose not found"
        return 1
    fi
    
    # Check if services are running
    local services=("loki" "promtail" "grafana")
    
    for service in "${services[@]}"; do
        local status=$(docker-compose ps -q "$service" 2>/dev/null)
        if [ -z "$status" ]; then
            echo "❌ $service is not running"
            return 1
        fi
        
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "none")
        if [ "$health" = "healthy" ] || [ "$health" = "none" ]; then
            echo "✅ $service is running (health: $health)"
        else
            echo "⚠️  $service is running but health status is: $health"
        fi
    done
}

# Function to validate service connectivity
validate_connectivity() {
    echo "Validating service connectivity..."
    
    # Check Loki API
    if ! check_service_health "Loki" "http://localhost:3100/ready"; then
        return 1
    fi
    
    # Check Grafana API
    if ! check_service_health "Grafana" "http://localhost:3000/api/health"; then
        return 1
    fi
    
    # Test Loki query API
    echo "Testing Loki query capabilities..."
    if curl -f -s "http://localhost:3100/loki/api/v1/labels" >/dev/null 2>&1; then
        echo "✅ Loki query API is accessible"
    else
        echo "⚠️  Loki query API is not responding"
    fi
    
    # Test Grafana-Loki integration
    echo "Testing Grafana data source connectivity..."
    local grafana_auth="admin:admin"
    local datasource_test=$(curl -s -u "$grafana_auth" "http://localhost:3000/api/datasources" 2>/dev/null | grep -o "loki" || echo "")
    
    if [ -n "$datasource_test" ]; then
        echo "✅ Grafana has Loki data source configured"
    else
        echo "⚠️  Loki data source may not be configured in Grafana"
    fi
}

# Function to validate logging configuration
validate_logging_config() {
    echo "Validating logging configuration..."
    
    # Check if Promtail is collecting logs
    echo "Checking Promtail log collection..."
    
    # Generate a test log entry by creating a temporary container
    echo "Creating test log entry..."
    docker run --rm --name test-log-generator alpine:latest echo "Test log entry for validation" >/dev/null 2>&1 || true
    
    # Wait a moment for log processing
    sleep 5
    
    # Query Loki for recent logs
    local query_result=$(curl -s "http://localhost:3100/loki/api/v1/query_range?query={job=\"docker\"}&start=$(date -d '1 minute ago' -u +%s)000000000&end=$(date -u +%s)000000000" 2>/dev/null || echo "")
    
    if echo "$query_result" | grep -q "test-log-generator" 2>/dev/null; then
        echo "✅ Log collection is working - test logs found in Loki"
    else
        echo "⚠️  Log collection test inconclusive - may need more time or configuration check"
    fi
}

# Main validation flow
main() {
    echo "Starting comprehensive service validation..."
    echo "========================================"
    
    # Check if Docker Compose services are running
    if ! check_compose_status; then
        echo ""
        echo "❌ Some services are not running properly"
        echo "Try running: docker-compose up -d"
        exit 1
    fi
    
    echo ""
    
    # Validate service connectivity
    if ! validate_connectivity; then
        echo ""
        echo "❌ Service connectivity validation failed"
        exit 1
    fi
    
    echo ""
    
    # Validate logging configuration
    validate_logging_config
    
    echo ""
    echo "🎉 Service validation complete!"
    echo ""
    echo "Service URLs:"
    echo "- Grafana: http://localhost:3000 (admin/admin)"
    echo "- Loki API: http://localhost:3100"
    echo ""
    echo "To view logs in Grafana:"
    echo "1. Go to Explore section"
    echo "2. Select Loki data source"
    echo "3. Use query: {job=\"docker\"}"
}

# Run main function
main "$@"