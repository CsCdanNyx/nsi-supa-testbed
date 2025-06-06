# ICAIR Multi-PA NSA Node Setup Guide

This guide helps you set up a complete Network Service Agent (NSA) node with multiple Provider Agents (PA) for managing different network switches using Docker Compose.

## 🎯 What You'll Get

A fully functional NSI infrastructure with:
- **1 Aggregator/Requester Agent (AG-RA)** - Central coordination
- **3 Provider Agents (PA)** - Each managing a specific physical switch
- **Automatic service orchestration** - All services work together seamlessly

## 📋 Prerequisites

Before starting, ensure you have:
1. **Docker** and **Docker Compose V2** installed
2. **Network access** to the physical switches (192.168.50.17, 192.168.50.31, 192.168.50.49)
3. **Switch credentials** configured (see switch_info.txt)
4. **Available ports**: 4321-4323, 8090, 8401, 8443-8445, 9000, 9080

## 🌐 Public Access Information

**Server Public IP**: 165.124.33.153

All services will be accessible externally via this public IP address instead of localhost.

## 🏗️ Architecture Overview

```
                  ┌─────────────────────────────────────────────────────────┐
                  │              AG-RA (Aggregator/Requester Agent)         │
                  │                                                         │
                  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌───────────┐   │
                  │  │   DDS   │  │   PCE   │  │ Safnari │  │NSI-Request│   │
                  │  │  :8401  │  │         │  │  :9080  │  │   :9000   │   │
                  │  └─────────┘  └─────────┘  └─────────┘  └───────────┘   │
                  └─────────────────────────────┬───────────────────────────┘
                                                │
                          ┌─────────────────────┼─────────────────────┐
                          │                     │                     │
                          ▼                     ▼                     ▼
          ┌───────────────────────┐   ┌─────────────────┐   ┌─────────────────┐
          │       PA-AR400        │   │    PA-Z9432F    │   │    PA-Z9664F    │
          │                       │   │                 │   │                 │
          │   ┌─────────────────┐ │   │ ┌─────────────┐ │   │ ┌─────────────┐ │
          │   │  SuPA  :4321    │ │   │ │ SuPA  :4322 │ │   │ │ SuPA  :4323 │ │
          │   │ PolyNSI :8443   │ │   │ │PolyNSI :8444│ │   │ │PolyNSI :8445│ │
          │   └─────────────────┘ │   │ └─────────────┘ │   │ └─────────────┘ │
          └───────────┬───────────┘   └─────────┬───────┘   └─────────┬───────┘
                      │                         │                     │
                      ▼                         ▼                     ▼
          ┌───────────────────────┐   ┌─────────────────┐   ┌─────────────────┐
          │        AR400          │   │     Z9432F      │   │     Z9664F      │
          │   Arista Switch       │   │   Dell Switch   │   │   Dell Switch   │
          │   192.168.50.17:22    │   │ 192.168.50.31:22│   │ 192.168.50.49:22│
          └───────────────────────┘   └─────────────────┘   └─────────────────┘
```

## 🎛️ Service Components Details

### AG-RA Services
- **DDS (Document Distribution Service)**: Network topology discovery and distribution
- **PCE (Path Calculation Engine)**: Route calculation between network nodes  
- **Safnari**: Web-based GUI for network management and connection monitoring
- **NSI-Requester**: NSI client for initiating connection requests

### PA Services (per switch)
- **SuPA**: Switch control plane adapter, communicates directly with switches
- **PolyNSI**: NSI protocol handler, manages connection requests and reservations

## 🏗️ Docker Compose Project Design

This multi-PA NSA node uses a **modular Docker Compose architecture** designed for scalability and maintainability:

### Master Orchestration Pattern
- **Main `docker-compose.yaml`**: Uses Docker Compose `include` feature to orchestrate all components
- **Component isolation**: Each service group (AG-RA, PA-AR400, PA-Z9432F, PA-Z9664F) has its own docker-compose.yaml
- **Independent deployment**: Can start/stop individual PAs without affecting others
- **Shared configuration**: Common patterns across all PAs while maintaining switch-specific settings

### Per-Component Structure
Each PA follows the same structure pattern:
```
pa-{switch}/
├── docker-compose.yaml          # Service definitions for this PA
└── config/                      # All configuration files
    ├── supa/                    # SuPA configuration
    └── polynsi/                 # PolyNSI configuration
```

## 🚀 Quick Start (Complete Setup)

### Step 1: Navigate to the Directory
```bash
cd new_demo/icair_node_multi_supa
```

### Step 2: Start All Services
```bash
# Start everything in background mode
docker compose up -d

# This command will:
# 1. Pull required Docker images (first time only)
# 2. Create and start all containers
# 3. Set up internal networks between services
# 4. Mount configuration files into containers
```

### Step 3: Verify Services Are Running
```bash
# Check all services status
docker compose ps

# Expected output should show all services as "running":
# - icair-ag-ra-nsi-dds-1
# - icair-ag-ra-nsi-pce-1  
# - icair-ag-ra-nsi-safnari-1
# - icair-ag-ra-nsi-requester-1
# - icair-pa-ar400-nsi-supa-1
# - icair-pa-ar400-polynsi-1
# - icair-pa-z9432f-nsi-supa-1
# - icair-pa-z9432f-polynsi-1
# - icair-pa-z9664f-nsi-supa-1
# - icair-pa-z9664f-polynsi-1
```

### Step 4: Access Web Interfaces
Once all services are running, open your browser to:

- **Safnari Network GUI**: http://165.124.33.153:9080
  - View network topology
  - Monitor active connections
  - Manage network resources

- **NSI Requester**: http://165.124.33.153:9000  
  - Create connection requests
  - Monitor connection status
  - Test end-to-end connectivity

## 🔧 Advanced Docker Compose Operations

### Starting Individual Components

#### Start Only AG-RA (without any PA)
```bash
docker compose up -d ag-ra
# Use this when you want to test the central services first
```

#### Start Specific Provider Agents
```bash
# Start only AR400 PA
docker compose up -d pa-ar400

# Start multiple PAs but not AG-RA
docker compose up -d pa-ar400 pa-z9432f

# Start all Dell switches (Z9432F + Z9664F)
docker compose up -d pa-z9432f pa-z9664f
```

### Service Management Commands

#### Viewing Logs
```bash
# View logs from all services (real-time)
docker compose logs -f

# View logs from specific service
docker compose logs -f pa-ar400-nsi-supa

# View historical logs (last 100 lines)
docker compose logs --tail=100 pa-z9432f-polynsi

# View logs from all PA services only
docker compose logs pa-ar400 pa-z9432f pa-z9664f
```

#### Restarting Services
```bash
# Restart specific service (after config changes)
docker compose restart pa-ar400-nsi-supa

# Restart all services in a PA
docker compose restart pa-ar400

# Restart everything
docker compose restart
```

#### Stopping Services
```bash
# Stop specific PA
docker compose stop pa-z9664f

# Stop all services but keep containers
docker compose stop

# Stop and remove containers (full cleanup)
docker compose down

# Stop and remove everything including volumes
docker compose down -v
```

#### Service Health Checks
```bash
# Check detailed container information
docker compose ps -a

# Access container shell for debugging
docker compose exec pa-ar400-nsi-supa bash

# Run commands inside containers
docker compose exec pa-ar400-nsi-supa ping 192.168.50.17
```

## 📁 Configuration File Structure

```
icair_node_multi_supa/
├── docker-compose.yaml              # Master orchestration file
├── switch_info.txt                  # Switch reference information
├── README.md                        # This guide
│
├── ag-ra/                           # Aggregator/Requester Agent
│   ├── docker-compose.yaml          # AG-RA services definition
│   └── config/
│       ├── dds/                     # DDS configuration
│       ├── pce/                     # PCE configuration  
│       ├── safnari/                 # Safnari config
│       └── nsi-requester/           # NSI-Requester config
│
├── pa-ar400/                        # Provider Agent for AR400 Arista switch
│   ├── docker-compose.yaml          # PA-AR400 services definition
│   └── config/
│       ├── supa/
│       │   ├── supa.env             # SuPA main configuration
│       │   ├── db/                  # SuPA database (auto-created)
│       │   └── backend_configs/
│       │       ├── aristaEOS4.env   # Arista switch connection settings
│       │       └── stps_ar400.yml   # Service Termination Points definition
│       └── polynsi/
│           ├── application.properties # PolyNSI configuration  
│           ├── polynsi-keystore.jks  # SSL certificates
│           ├── polynsi-truststore.jks
│           └── logback-spring.xml    # Logging configuration
│
├── pa-z9432f/                       # Provider Agent for Z9432F Dell switch
│   ├── docker-compose.yaml          # PA-Z9432F services definition
│   └── config/
│       ├── supa/
│       │   ├── supa.env             # SuPA main configuration  
│       │   ├── db/                  # SuPA database (auto-created)
│       │   └── backend_configs/
│       │       ├── dellOS10.env     # Dell switch connection settings
│       │       └── stps_z9432f.yml  # Service Termination Points definition
│       └── polynsi/
│           ├── application.properties # PolyNSI configuration
│           ├── polynsi-keystore.jks  # SSL certificates  
│           ├── polynsi-truststore.jks
│           └── logback-spring.xml    # Logging configuration
│
└── pa-z9664f/                       # Provider Agent for Z9664F Dell switch
    ├── docker-compose.yaml          # PA-Z9664F services definition
    └── config/
        ├── supa/
        │   ├── supa.env             # SuPA main configuration
        │   ├── db/                  # SuPA database (auto-created)  
        │   └── backend_configs/
        │       ├── dellOS10.env     # Dell switch connection settings
        │       └── stps_z9664f.yml  # Service Termination Points definition
        └── polynsi/
            ├── application.properties # PolyNSI configuration
            ├── polynsi-keystore.jks  # SSL certificates
            ├── polynsi-truststore.jks  
            └── logback-spring.xml    # Logging configuration
```

## ⚙️ Key Configuration Files Explained

### 1. SuPA Configuration (`supa.env`)

Each PA has its own `config/supa/supa.env` file:

```bash
# Example: pa-ar400/config/supa/supa.env
domain=icairtest.org:2025           # NSI domain identifier
topology=ar400topology              # Network topology name  
backend=aristaEOS4                  # Switch backend type
document_server_port=4321           # SuPA HTTP port
nsa_provider_port=8443              # PolyNSI SOAP port
nsa_name="icairtest.org uPA AR400"  # Human readable name
```

**Key settings per PA:**
- **PA-AR400**: `backend=aristaEOS4`, `topology=ar400topology`, ports `4321/8443`
- **PA-Z9432F**: `backend=dellOS10`, `topology=z9432ftopology`, ports `4322/8444`  
- **PA-Z9664F**: `backend=dellOS10`, `topology=z9664ftopology`, ports `4323/8445`

### 2. Switch Connection Settings (`backend_configs/*.env`)

Contains actual switch connection parameters with **environment variable override support**:

```bash
# Example: pa-ar400/config/supa/backend_configs/aristaEOS4.env
ssh_hostname=${SW_IP_ADDRESS:-192.168.50.17}    # Switch IP
ssh_username=${SW_SSH_USER:-supa}               # SSH username
ssh_password=${SW_SSH_PASS:-SuPA2025}           # SSH password
cli_prompt=${SW_CLI_PROMPT:-Ar400CR3}           # Switch CLI prompt
stps_config=${SW_STPS_CONFIG:-stps_ar400.yml}   # STP definitions file
```

**Environment Variable Override**: You can override these settings via Docker Compose environment variables without modifying config files:

```yaml
# In docker-compose.yaml
environment:
  - SW_IP_ADDRESS=192.168.50.17      # Override switch IP
  - SW_SSH_PORT=22                   # Override SSH port
  - SW_SSH_USER=supa                 # Override username
  - SW_SSH_PASS=SuPA2025             # Override password
  - SW_CLI_PROMPT=Ar400CR3           # Override CLI prompt
  - SW_CLI_NEEDS_ENABLE=False        # Override enable requirement
  - SW_STPS_CONFIG=stps_ar400.yml    # Override STP config file
```

This allows **runtime configuration** without modifying configuration files, useful for different environments or testing.

### 3. Service Termination Points (`stps_*.yml`)

Defines network interfaces and VLANs available for connections:

```yaml
# Example: pa-ar400/config/supa/backend_configs/stps_ar400.yml
stps:
  - stp_id: ar400_stp1                    # Unique STP identifier
    port_id: ethernet1/1                  # Physical switch port
    vlans: "1700-1728"                    # Available VLAN range
    description: "AR400 STP to external network"
    bandwidth: 1000                       # Port capacity (Mbps)
    enabled: True                         # STP is active
    remote_stp:                           # Remote connected STP (isAlias)
      prefix_urn: "urn:ogf:network:external.network:2025:topology"
      id: "external_stp1"                # Remote STP identifier
```

**Remote STP Configuration**: The `remote_stp` section defines the **isAlias connection** to remote STPs:
- **prefix_urn**: URN of the remote network topology
- **id**: Identifier of the remote STP this local STP connects to
- This creates the **inter-domain topology mapping** for NSI path calculation
- PCE uses this information to build **end-to-end paths** across multiple domains

### 4. PolyNSI Configuration (`application.properties`)

Controls NSI protocol behavior:

```properties
# Each PA has different server.port:
# PA-AR400: server.port=8443
# PA-Z9432F: server.port=8444  
# PA-Z9664F: server.port=8445

grpc.client.connection_provider.address=dns:///nsi-supa:50051
# This connects PolyNSI to SuPA within same PA
```

## 🔍 Monitoring and Troubleshooting

### Check Service Health

#### View Service Status
```bash
# Quick status overview
docker compose ps

# Detailed container information  
docker compose ps -a --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

#### Monitor Resource Usage
```bash
# View CPU/Memory usage
docker stats

# Monitor specific services
docker stats icair-pa-ar400-nsi-supa-1 icair-pa-ar400-polynsi-1
```

### Debug Connection Issues

#### Test Switch Connectivity
```bash
# Test from SuPA container to switch
docker compose exec pa-ar400-nsi-supa ping 192.168.50.17
docker compose exec pa-z9432f-nsi-supa ping 192.168.50.31  
docker compose exec pa-z9664f-nsi-supa ping 192.168.50.49

# Test SSH connectivity
docker compose exec pa-ar400-nsi-supa ssh -o ConnectTimeout=5 supa@192.168.50.17 'show version'
```

## 🌐 NSI Protocol Endpoints Reference

### AG-RA Endpoints
- **DDS**: http://165.124.33.153:8401/dds (Document Distribution)
- **Safnari**: http://165.124.33.153:9080 (Web GUI)
- **NSI-Requester**: http://165.124.33.153:9000 (Client Interface)

  ### Provider Agent Endpoints
  - **AR400 PA**:
    - SuPA: 
      - http://165.124.33.153:4321/discovery
      - http://165.124.33.153:4321/topology
    - PolyNSI: http://165.124.33.153:8443/soap/connection/provider
    
  - **Z9432F PA**:
    - SuPA:
      - http://165.124.33.153:4322/discovery
      - http://165.124.33.153:4322/topology
    - PolyNSI: http://165.124.33.153:8444/soap/connection/provider
    
  - **Z9664F PA**:
    - SuPA:
      - http://165.124.33.153:4323/discovery
      - http://165.124.33.153:4323/topology
    - PolyNSI: http://165.124.33.153:8445/soap/connection/provider

### Switch Management Information

| Switch | IP Address | Username | Password | Backend | CLI Prompt |
|--------|------------|----------|----------|---------|------------|
| AR400 | 192.168.50.17 | supa | SuPA2025 | aristaEOS4 | Ar400CR3 |
| Z9432F | 192.168.50.31 | supa | CYCU2025SuPA | dellOS10 | (empty) |
| Z9664F | 192.168.50.49 | supa | CYCU2025SuPA | dellOS10 | (empty) |

Remember: All configuration files are stored locally in the `config/` directories, so you can always inspect and modify them directly with your preferred text editor! 