# ICAIR Multi-PA NSA Node

This setup implements a Network Service Agent (NSA) node with multiple Provider Agents (PA) for managing different network switches.

## Architecture

The system consists of:

1. **AG-RA (Aggregator/Requester Agent)**: Central coordination services
   - Document Distribution Service (DDS) - Port 8401
   - Path Calculation Engine (PCE) - Port 8090
   - Safnari Web GUI - Port 9080
   - NSI Requester - Port 9000

2. **Provider Agents (PA)**: Each managing a specific switch
   - **PA-AR400**: Manages AR400 Arista switch (192.168.50.17)
     - SuPA: Port 4321
     - PolyNSI: Port 8443
   - **PA-Z9432F**: Manages Z9432F Dell switch (192.168.50.31)
     - SuPA: Port 4322
     - PolyNSI: Port 8444
   - **PA-Z9664F**: Manages Z9664F Dell switch (192.168.50.49)
     - SuPA: Port 4323
     - PolyNSI: Port 8445

## Switch Information

| Switch  | Backend   | IP Address     | Credentials | Port Map |
|---------|-----------|----------------|-------------|----------|
| ar400   | aristaEOS4| 192.168.50.17  | supa/SuPA2025 | 4321/8443 |
| z9432f  | dellOS10  | 192.168.50.31  | supa/CYCU2025SuPA | 4322/8444 |
| z9664f  | dellOS10  | 192.168.50.49  | supa/CYCU2025SuPA | 4323/8445 |

## Quick Start

### Start All Services
```bash
# Start all components
docker compose up -d

# View logs
docker compose logs -f

# Stop all services
docker compose down
```

### Start Individual Components
```bash
# Start only AG-RA
docker compose up -d ag-ra

# Start specific PA
docker compose up -d pa-ar400

# Start multiple PAs
docker compose up -d pa-ar400 pa-z9432f
```

### Service Status
```bash
# Check running services
docker compose ps

# Check specific service logs
docker compose logs -f pa-ar400-nsi-supa
```

## Web Interfaces

After starting the services, you can access:

- **Safnari GUI**: http://localhost:9080 (Network topology and connection management)
- **NSI Requester**: http://localhost:9000 (Connection requests and monitoring)
- **SuPA Topology Documents**:
  - AR400: http://localhost:4321/topology
  - Z9432F: http://localhost:4322/topology  
  - Z9664F: http://localhost:4323/topology

## Configuration

### Directory Structure
```
icair_node_multi_supa/
├── docker-compose.yaml          # Master compose file
├── switch_info.txt              # Switch configuration reference
├── ag-ra/                       # Aggregator/Requester Agent
│   ├── docker-compose.yaml
│   └── config/
│       ├── dds/
│       ├── pce/
│       ├── safnari/
│       └── nsi-requester/
├── pa-ar400/                    # Provider Agent for AR400
│   ├── docker-compose.yaml
│   └── config/
│       ├── supa/
│       └── polynsi/
├── pa-z9432f/                   # Provider Agent for Z9432F
│   ├── docker-compose.yaml
│   └── config/
│       ├── supa/
│       └── polynsi/
└── pa-z9664f/                   # Provider Agent for Z9664F
    ├── docker-compose.yaml
    └── config/
        ├── supa/
        └── polynsi/
```

### Key Configuration Files

Each PA has its own configuration:

- `supa.env`: SuPA service configuration (domain, backend, ports)
- `backend_configs/*.env`: Switch-specific connection settings
- `backend_configs/stps_*.yml`: Service Termination Point definitions
- `polynsi/application.properties`: PolyNSI service configuration

## Troubleshooting

### Common Issues

1. **Port conflicts**: Make sure ports 4321-4323, 8401, 8090, 8443-8445, 9000, 9080 are available
2. **Switch connectivity**: Verify network access to switch management interfaces
3. **Database permissions**: Ensure database directories have proper write permissions

### Debugging

```bash
# Check container status
docker compose ps

# View specific service logs
docker compose logs pa-ar400-nsi-supa

# Access container shell
docker compose exec pa-ar400-nsi-supa bash

# Test switch connectivity
docker compose exec pa-ar400-nsi-supa ping 192.168.50.17
```

### Reset Database

```bash
# Stop services
docker compose down

# Remove database files
sudo rm -rf pa-*/config/supa/db/*

# Restart services
docker compose up -d
```

## Development

To modify configurations:

1. Edit the relevant configuration files in `*/config/` directories
2. Restart the affected service: `docker-compose restart <service-name>`
3. Check logs for any errors: `docker-compose logs <service-name>`

## NSI Protocol Endpoints

- **AG-RA DDS**: http://localhost:8401/dds
- **Provider Endpoints**:
  - AR400: http://localhost:8443/soap/connection/provider
  - Z9432F: http://localhost:8444/soap/connection/provider
  - Z9664F: http://localhost:8445/soap/connection/provider 