@echo off
REM Comprehensive startup script with validation
REM This script sets up, starts, and validates the entire Grafana logging stack

echo 🚀 Starting Grafana Logging Stack with Full Validation
echo =====================================================

REM Step 1: Setup validation
echo.
echo 📋 Step 1: Validating Setup
echo ----------------------------------------
call scripts\validate-setup.bat
if %errorlevel% neq 0 (
    echo ❌ Setup validation failed
    exit /b 1
)
echo ✅ Setup validation passed

REM Step 2: Configuration validation
echo.
echo 📋 Step 2: Validating Configuration
echo ----------------------------------------
call scripts\validate-logging-config.bat
if %errorlevel% neq 0 (
    echo ❌ Configuration validation failed
    exit /b 1
)
echo ✅ Configuration validation passed

REM Step 3: Start services
echo.
echo 📋 Step 3: Starting Services
echo ----------------------------------------
echo Starting Docker Compose services...
docker-compose up -d
if %errorlevel% neq 0 (
    echo ❌ Failed to start services
    exit /b 1
)
echo ✅ Services started successfully

REM Step 4: Wait for services to be ready
echo.
echo 📋 Step 4: Waiting for Services to be Ready
echo ----------------------------------------
echo Waiting for services to start up...
timeout /t 10 >nul

REM Step 5: Service connectivity validation
echo.
echo 📋 Step 5: Validating Service Connectivity
echo ----------------------------------------
call scripts\validate-services.bat
if %errorlevel% neq 0 (
    echo ❌ Service connectivity validation failed
    echo.
    echo Services may still be starting up. You can:
    echo 1. Wait a few more minutes and run: scripts\validate-services.bat
    echo 2. Check service logs: docker-compose logs
    echo 3. Check service status: docker-compose ps
    goto kong_setup
)
echo ✅ Service connectivity validation passed

:kong_setup
REM Step 6: Kong Gateway routes setup (Kong assumed to be running)
echo.
echo 📋 Step 6: Setting up Kong Gateway Routes
echo ----------------------------------------
echo Setting up routes for existing Kong Gateway...
call scripts\setup-kong-routes.bat
if %errorlevel% neq 0 (
    echo ⚠️  Kong Gateway route setup had issues
    echo Make sure Kong Gateway is running and accessible at http://localhost:8001
) else (
    echo ✅ Kong Gateway routes configured successfully
)

:summary
REM Final summary
echo.
echo 📋 🎉 Startup Complete!
echo ----------------------------------------
echo Grafana Logging Stack is ready!
echo.
echo Service URLs:
echo - Grafana Dashboard: http://localhost:3100 (admin/admin)
echo - Loki API: http://localhost:3101
echo.
echo Kong Gateway URLs:
echo - Grafana via Kong: http://localhost:8000/grafana
echo - Loki API via Kong: http://localhost:8000/loki
echo - Kong Admin API: http://localhost:8001
echo - Kong Manager GUI: http://localhost:8002
echo.
echo Next steps:
echo 1. Open Grafana at http://localhost:3100
echo 2. Go to Explore → Select Loki data source
echo 3. Use query: {job="docker"} to see logs
echo.
echo To stop services: docker-compose down
echo To view logs: docker-compose logs [service-name]