#!/bin/bash

# Comprehensive startup script with validation
# This script sets up, starts, and validates the entire Grafana logging stack

set -e

echo "🚀 Starting Grafana Logging Stack with Full Validation"
echo "====================================================="

# Function to print section headers
print_section() {
    echo ""
    echo "📋 $1"
    echo "----------------------------------------"
}

# Step 1: Setup validation
print_section "Step 1: Validating Setup"
if ./scripts/validate-setup.sh; then
    echo "✅ Setup validation passed"
else
    echo "❌ Setup validation failed"
    exit 1
fi

# Step 2: Configuration validation
print_section "Step 2: Validating Configuration"
if ./scripts/validate-logging-config.sh; then
    echo "✅ Configuration validation passed"
else
    echo "❌ Configuration validation failed"
    exit 1
fi

# Step 3: Start services
print_section "Step 3: Starting Services"
echo "Starting Docker Compose services..."
if docker-compose up -d; then
    echo "✅ Services started successfully"
else
    echo "❌ Failed to start services"
    exit 1
fi

# Step 4: Wait for services to be ready
print_section "Step 4: Waiting for Services to be Ready"
echo "Waiting for services to start up..."
sleep 10

# Step 5: Service connectivity validation
print_section "Step 5: Validating Service Connectivity"
if ./scripts/validate-services.sh; then
    echo "✅ Service connectivity validation passed"
else
    echo "❌ Service connectivity validation failed"
    echo ""
    echo "Services may still be starting up. You can:"
    echo "1. Wait a few more minutes and run: ./scripts/validate-services.sh"
    echo "2. Check service logs: docker-compose logs"
    echo "3. Check service status: docker-compose ps"
fi

# Final summary
print_section "🎉 Startup Complete!"
echo "Grafana Logging Stack is ready!"
echo ""
echo "Service URLs:"
echo "- Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo "- Loki API: http://localhost:3100"
echo ""
echo "Next steps:"
echo "1. Open Grafana at http://localhost:3000"
echo "2. Go to Explore → Select Loki data source"
echo "3. Use query: {job=\"docker\"} to see logs"
echo ""
echo "To stop services: docker-compose down"
echo "To view logs: docker-compose logs [service-name]"