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
    
    # Start all PAs in parallel first
    for i in $(seq 1 $((${#COMPONENTS[@]} - 1))); do
        local component=${COMPONENTS[$i]}
        local dir=$(echo "$component" | cut -d: -f1)
        local name=$(echo "$component" | cut -d: -f2)
        start_component "$dir" "$name" &
    done
    
    # Wait for all PAs to complete startup
    wait
    
    # Give PAs time to fully initialize
    print_info "Waiting for PAs to fully initialize..."
    sleep 5
    
    # Start AG-RA after all PAs are running
    local ag_ra_dir=$(echo "${COMPONENTS[0]}" | cut -d: -f1)
    local ag_ra_name=$(echo "${COMPONENTS[0]}" | cut -d: -f2)
    start_component "$ag_ra_dir" "$ag_ra_name"
    
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

# Clean DDS cache and repository
clean_dds() {
    echo -e "${BLUE}Cleaning DDS cache and repository...${NC}\n"
    
    local ag_ra_dir=$(echo "${COMPONENTS[0]}" | cut -d: -f1)
    
    if [ -d "$ag_ra_dir" ]; then
        # Check if AG-RA is running
        cd "$ag_ra_dir"
        local running_containers=$(docker compose ps -q)
        cd - > /dev/null
        
        if [ -n "$running_containers" ]; then
            print_error "AG-RA services are still running"
            print_info "Please stop AG-RA first: cd $ag_ra_dir && docker compose down"
            return 1
        fi
        
        # Clean DDS data
        print_info "Cleaning DDS cache and repository..."
        rm -rf "$ag_ra_dir/config/dds/cache/"
        rm -rf "$ag_ra_dir/config/dds/repository/"
        
        print_success "DDS cleanup completed!"
    else
        print_error "AG-RA directory not found"
        return 1
    fi
}

# Clean all PA SuPA databases
clean_pa() {
    echo -e "${BLUE}Cleaning all PA SuPA databases...${NC}\n"
    
    # Check for sudo privileges
    if [ "$EUID" -ne 0 ]; then
        print_error "This command requires sudo privileges"
        print_info "Please run: sudo $0 clean-pa"
        return 1
    fi
    
    # Check if any PAs are running
    local running_pas=()
    for i in $(seq 1 $((${#COMPONENTS[@]} - 1))); do
        local component=${COMPONENTS[$i]}
        local dir=$(echo "$component" | cut -d: -f1)
        local name=$(echo "$component" | cut -d: -f2)
        
        if [ -d "$dir" ]; then
            cd "$dir"
            local running_containers=$(docker compose ps -q)
            cd - > /dev/null
            
            if [ -n "$running_containers" ]; then
                running_pas+=("$name ($dir)")
            fi
        fi
    done
    
    if [ ${#running_pas[@]} -gt 0 ]; then
        print_error "Some PA services are still running:"
        for pa in "${running_pas[@]}"; do
            echo "  - $pa"
        done
        print_info "Please stop all PAs first: ./nsi-manage.sh stop"
        return 1
    fi
    
    # Clean all PA databases
    print_info "Cleaning SuPA databases..."
    for i in $(seq 1 $((${#COMPONENTS[@]} - 1))); do
        local component=${COMPONENTS[$i]}
        local dir=$(echo "$component" | cut -d: -f1)
        local name=$(echo "$component" | cut -d: -f2)
        
        if [ -d "$dir/config/supa/db/" ]; then
            print_info "Cleaning $name database..."
            rm -rf "$dir/config/supa/db/"
        fi
    done
    
    print_success "PA databases cleanup completed!"
}

# Show help
show_help() {
    echo "ICAIR Multi-PA NSA Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start      Start all NSI components"
    echo "  stop       Stop all NSI components"
    echo "  clean-dds  Clean DDS cache and repository (topology issues)"
    echo "  clean-pa   Clean all PA SuPA databases (requires sudo)"
    echo "  help       Show this help message"
    echo
    echo "Components managed:"
    for component in "${COMPONENTS[@]}"; do
        local dir=$(echo "$component" | cut -d: -f1)
        local name=$(echo "$component" | cut -d: -f2)
        echo "  - $name (${dir}/)"
    done
    echo
    echo "Cleanup commands:"
    echo "  clean-dds: Removes DDS cache and repository (AG-RA must be stopped)"
    echo "  clean-pa:  Removes all PA databases (PAs must be stopped, needs sudo)"
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
    "clean-dds")
        clean_dds
        ;;
    "clean-pa")
        clean_pa
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
