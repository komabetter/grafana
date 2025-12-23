#!/bin/bash

# Logging configuration validation script
# This script validates the configuration files for proper syntax and settings

set -e

echo "🔧 Validating logging configuration files..."

# Function to validate YAML syntax
validate_yaml() {
    local file=$1
    local service=$2
    
    echo "Validating $service configuration: $file"
    
    if [ ! -f "$file" ]; then
        echo "❌ Configuration file not found: $file"
        return 1
    fi
    
    # Check if python or yq is available for YAML validation
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo "✅ $file has valid YAML syntax"
        else
            echo "❌ $file has invalid YAML syntax"
            return 1
        fi
    elif command -v yq >/dev/null 2>&1; then
        if yq eval '.' "$file" >/dev/null 2>&1; then
            echo "✅ $file has valid YAML syntax"
        else
            echo "❌ $file has invalid YAML syntax"
            return 1
        fi
    else
        echo "⚠️  Cannot validate YAML syntax (python3 or yq not available)"
    fi
}

# Function to validate Loki configuration
validate_loki_config() {
    local config_file="config/loki-config.yml"
    
    echo "Validating Loki configuration..."
    validate_yaml "$config_file" "Loki"
    
    # Check for required Loki configuration sections
    if grep -q "auth_enabled:" "$config_file" && \
       grep -q "server:" "$config_file" && \
       grep -q "ingester:" "$config_file" && \
       grep -q "schema_config:" "$config_file" && \
       grep -q "storage_config:" "$config_file"; then
        echo "✅ Loki configuration has required sections"
    else
        echo "❌ Loki configuration missing required sections"
        return 1
    fi
    
    # Check storage configuration
    if grep -q "filesystem:" "$config_file"; then
        echo "✅ Loki configured for filesystem storage"
    else
        echo "⚠️  Loki storage configuration may need review"
    fi
}

# Function to validate Promtail configuration
validate_promtail_config() {
    local config_file="config/promtail-config.yml"
    
    echo "Validating Promtail configuration..."
    validate_yaml "$config_file" "Promtail"
    
    # Check for required Promtail configuration sections
    if grep -q "server:" "$config_file" && \
       grep -q "positions:" "$config_file" && \
       grep -q "clients:" "$config_file" && \
       grep -q "scrape_configs:" "$config_file"; then
        echo "✅ Promtail configuration has required sections"
    else
        echo "❌ Promtail configuration missing required sections"
        return 1
    fi
    
    # Check if Loki client is configured
    if grep -q "http://loki:3100/loki/api/v1/push" "$config_file"; then
        echo "✅ Promtail configured to send logs to Loki"
    else
        echo "❌ Promtail Loki client configuration missing or incorrect"
        return 1
    fi
    
    # Check Docker log collection configuration
    if grep -q "docker:" "$config_file" || grep -q "/var/lib/docker/containers" "$config_file"; then
        echo "✅ Promtail configured for Docker log collection"
    else
        echo "⚠️  Docker log collection may not be configured"
    fi
}

# Function to validate Grafana configuration
validate_grafana_config() {
    local grafana_ini="config/grafana/grafana.ini"
    local datasource_config="config/grafana/provisioning/datasources/loki.yml"
    
    echo "Validating Grafana configuration..."
    
    # Check grafana.ini
    if [ -f "$grafana_ini" ]; then
        echo "✅ Grafana configuration file exists"
        
        # Check for security settings
        if grep -q "admin_password" "$grafana_ini" || grep -q "GF_SECURITY_ADMIN_PASSWORD" docker-compose.yml; then
            echo "✅ Grafana admin password is configured"
        else
            echo "⚠️  Grafana admin password should be configured"
        fi
    else
        echo "⚠️  Grafana configuration file not found (using defaults)"
    fi
    
    # Check Loki data source provisioning
    if [ -f "$datasource_config" ]; then
        validate_yaml "$datasource_config" "Grafana Loki datasource"
        
        if grep -q "loki" "$datasource_config" && grep -q "http://loki:3100" "$datasource_config"; then
            echo "✅ Loki data source properly configured in Grafana"
        else
            echo "❌ Loki data source configuration incorrect"
            return 1
        fi
    else
        echo "❌ Grafana Loki data source configuration not found"
        return 1
    fi
}

# Function to validate Docker Compose health checks
validate_health_checks() {
    echo "Validating Docker Compose health check configuration..."
    
    local compose_file="docker-compose.yml"
    
    # Check if health checks are defined for all services
    local services=("loki" "grafana" "promtail")
    
    for service in "${services[@]}"; do
        if grep -A 10 "^  $service:" "$compose_file" | grep -q "healthcheck:"; then
            echo "✅ $service has health check configured"
        else
            echo "⚠️  $service missing health check configuration"
        fi
    done
    
    # Check service dependencies
    if grep -A 5 "promtail:" "$compose_file" | grep -q "condition: service_healthy"; then
        echo "✅ Promtail properly depends on Loki health"
    else
        echo "⚠️  Promtail dependency configuration may need review"
    fi
}

# Main validation function
main() {
    echo "Starting logging configuration validation..."
    echo "========================================="
    
    local validation_failed=0
    
    # Validate each component
    if ! validate_loki_config; then
        validation_failed=1
    fi
    
    echo ""
    
    if ! validate_promtail_config; then
        validation_failed=1
    fi
    
    echo ""
    
    if ! validate_grafana_config; then
        validation_failed=1
    fi
    
    echo ""
    
    validate_health_checks
    
    echo ""
    
    if [ $validation_failed -eq 0 ]; then
        echo "🎉 All logging configuration validation passed!"
        echo ""
        echo "Configuration is ready for deployment."
        echo "Run 'docker-compose up -d' to start the services."
    else
        echo "❌ Some configuration validation failed!"
        echo ""
        echo "Please review and fix the configuration issues above."
        exit 1
    fi
}

# Run main function
main "$@"