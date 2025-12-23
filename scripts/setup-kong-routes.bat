@echo off
REM Kong Gateway Route Setup Script
REM This script configures Kong routes for Grafana and Loki services

echo 🔧 Setting up Kong Gateway routes for Grafana Logging Stack...

REM Kong Admin API URL
set "KONG_ADMIN_URL=http://localhost:8001"

REM Wait for Kong to be ready
echo Waiting for Kong Gateway to be ready...
set /a attempts=0
:check_kong
set /a attempts+=1
curl -f -s %KONG_ADMIN_URL% >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Kong Gateway is ready
    goto setup_services
)
if %attempts% lss 30 (
    echo ⏳ Attempt %attempts%/30: Kong not ready yet...
    timeout /t 2 >nul
    goto check_kong
)
echo ❌ Kong Gateway failed to become ready
exit /b 1

:setup_services
echo.
echo 📋 Creating Kong Services...
echo ----------------------------

REM Create Grafana service
echo Creating Kong service: grafana
curl -i -X POST "%KONG_ADMIN_URL%/services/" --data "name=grafana" --data "url=http://grafana:3000" --data "protocol=http" --data "connect_timeout=60000" --data "write_timeout=60000" --data "read_timeout=60000" 2>nul

REM Create Loki service
echo Creating Kong service: loki
curl -i -X POST "%KONG_ADMIN_URL%/services/" --data "name=loki" --data "url=http://loki:3100" --data "protocol=http" --data "connect_timeout=60000" --data "write_timeout=60000" --data "read_timeout=60000" 2>nul

echo.
echo 📋 Creating Kong Routes...
echo -------------------------

REM Create Grafana route
echo Creating Kong route: grafana-route
curl -i -X POST "%KONG_ADMIN_URL%/services/grafana/routes" --data "name=grafana-route" --data "paths[]=/grafana" --data "strip_path=true" 2>nul

REM Create Loki route
echo Creating Kong route: loki-route
curl -i -X POST "%KONG_ADMIN_URL%/services/loki/routes" --data "name=loki-route" --data "paths[]=/loki" --data "strip_path=true" 2>nul

echo.
echo 📋 Enabling CORS...
echo ------------------

REM Enable CORS for Grafana
echo Enabling CORS for service: grafana
curl -i -X POST "%KONG_ADMIN_URL%/services/grafana/plugins" --data "name=cors" --data "config.origins=*" --data "config.methods=GET,POST,PUT,DELETE,OPTIONS" --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token,Authorization" --data "config.exposed_headers=X-Auth-Token" --data "config.credentials=true" --data "config.max_age=3600" 2>nul

REM Enable CORS for Loki
echo Enabling CORS for service: loki
curl -i -X POST "%KONG_ADMIN_URL%/services/loki/plugins" --data "name=cors" --data "config.origins=*" --data "config.methods=GET,POST,PUT,DELETE,OPTIONS" --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token,Authorization" --data "config.exposed_headers=X-Auth-Token" --data "config.credentials=true" --data "config.max_age=3600" 2>nul

echo.
echo 🎉 Kong Gateway setup complete!
echo.
echo Service URLs through Kong Gateway:
echo - Grafana: http://localhost:8000/grafana
echo - Loki API: http://localhost:8000/loki
echo.
echo Direct service URLs:
echo - Grafana: http://localhost:3100
echo - Loki API: http://localhost:3101
echo.
echo Kong Management:
echo - Kong Admin API: http://localhost:8001
echo - Kong Manager GUI: http://localhost:8002
echo.
echo To view Kong configuration:
echo curl http://localhost:8001/services
echo curl http://localhost:8001/routes