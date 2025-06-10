#!/bin/bash

# ICAIR Multi-PA NSA Management Script
# Simple script to start/stop all NSI components

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Component configuration
# To add a new PA, simply add it to this array
COMPONENTS=(
    "ag-ra:Aggregator/Requester Agent"
    "pa-ar400:PA-AR400 (Arista Switch)"
    "pa-z9432f:PA-Z9432F (Dell Switch)"
    "pa-z9664f:PA-Z9664F (Dell Switch)"
)

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to start a component
start_component() {
    local dir=$1
    local name=$2
    
    if [ -d "$dir" ]; then
        print_info "Starting $name..."
        cd "$dir"
        docker compose up -d
        cd - > /dev/null
        print_success "$name started"
    else
        print_error "Directory $dir not found"
        return 1
    fi
}

# Function to stop a component
stop_component() {
    local dir=$1
    local name=$2
    
    if [ -d "$dir" ]; then
        print_info "Stopping $name..."
        cd "$dir"
        docker compose down
        cd - > /dev/null
        print_success "$name stopped"
    else
        print_error "Directory $dir not found"
    fi
}

# Start all components
start_all() {
    echo -e "${GREEN}Starting ICAIR Multi-PA NSA Node...${NC}\n"
    
    # Start AG-RA first
    local ag_ra_dir=$(echo "${COMPONENTS[0]}" | cut -d: -f1)
    local ag_ra_name=$(echo "${COMPONENTS[0]}" | cut -d: -f2)
    start_component "$ag_ra_dir" "$ag_ra_name"
    
    # Give AG-RA time to start
    print_info "Waiting for AG-RA to initialize..."
    sleep 5
    
    # Start all PAs in parallel
    for i in $(seq 1 $((${#COMPONENTS[@]} - 1))); do
        local component=${COMPONENTS[$i]}
        local dir=$(echo "$component" | cut -d: -f1)
        local name=$(echo "$component" | cut -d: -f2)
        start_component "$dir" "$name" &
    done
    
    # Wait for all background jobs to complete
    wait
    
    echo
    print_success "All components started!"
    echo
    print_info "Started components:"
    for component in "${COMPONENTS[@]}"; do
        local name=$(echo "$component" | cut -d: -f2)
        echo "  ✓ $name"
    done
}

# Stop all components
stop_all() {
    echo -e "${RED}Stopping ICAIR Multi-PA NSA Node...${NC}\n"
    
    # Stop all PAs in parallel (skip AG-RA which is first)
    for i in $(seq 1 $((${#COMPONENTS[@]} - 1))); do
        local component=${COMPONENTS[$i]}
        local dir=$(echo "$component" | cut -d: -f1)
        local name=$(echo "$component" | cut -d: -f2)
        stop_component "$dir" "$name" &
    done
    
    # Wait for all PA stops to complete
    wait
    
    # Stop AG-RA last
    local ag_ra_dir=$(echo "${COMPONENTS[0]}" | cut -d: -f1)
    local ag_ra_name=$(echo "${COMPONENTS[0]}" | cut -d: -f2)
    stop_component "$ag_ra_dir" "$ag_ra_name"
    
    echo
    print_success "All components stopped!"
}

# Show help
show_help() {
    echo "ICAIR Multi-PA NSA Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start    Start all NSI components"
    echo "  stop     Stop all NSI components"
    echo "  help     Show this help message"
    echo
    echo "Components managed:"
    for component in "${COMPONENTS[@]}"; do
        local dir=$(echo "$component" | cut -d: -f1)
        local name=$(echo "$component" | cut -d: -f2)
        echo "  - $name (${dir}/)"
    done
    echo
    echo "To add a new PA:"
    echo "  1. Create new PA directory with docker-compose.yaml"
    echo "  2. Add entry to COMPONENTS array in this script"
}

# Main script logic
case "$1" in
    "start")
        start_all
        ;;
    "stop")
        stop_all
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac 