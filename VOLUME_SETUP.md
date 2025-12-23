# Volume Setup Quick Reference

## Quick Start

1. **Setup volumes:**
   ```bash
   # Windows
   scripts\setup-volumes.bat
   
   # Linux/macOS  
   chmod +x scripts/setup-volumes.sh
   ./scripts/setup-volumes.sh
   ```

2. **Validate setup:**
   ```bash
   # Windows
   scripts\validate-setup.bat
   
   # Linux/macOS
   chmod +x scripts/validate-setup.sh
   ./scripts/validate-setup.sh
   ```

3. **Start services:**
   ```bash
   docker-compose up -d
   ```

## Directory Structure

```
├── data/
│   ├── grafana/     # Grafana persistent data
│   └── loki/        # Loki persistent data  
├── scripts/
│   ├── setup-volumes.sh    # Unix setup
│   ├── setup-volumes.bat   # Windows setup
│   ├── validate-setup.sh   # Unix validation
│   └── validate-setup.bat  # Windows validation
└── docs/
    └── VOLUMES_AND_PERSISTENCE.md  # Detailed documentation
```

## Troubleshooting

- **Permission errors**: Run the setup script with appropriate privileges
- **Bind mount issues**: The system will fallback to named volumes automatically
- **Windows issues**: Ensure Docker Desktop is configured with proper drive sharing

For detailed information, see [docs/VOLUMES_AND_PERSISTENCE.md](docs/VOLUMES_AND_PERSISTENCE.md)