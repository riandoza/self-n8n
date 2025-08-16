#!/bin/bash

# n8n Health Check and Monitoring Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/health-check.log"

# Create logs directory
mkdir -p "$PROJECT_DIR/logs"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Health check function
check_container_health() {
    local container_name=$1
    local service_name=$2
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-healthcheck")
        
        if [[ "$health_status" == "healthy" ]] || [[ "$health_status" == "no-healthcheck" ]]; then
            log "✅ $service_name ($container_name) is running"
            return 0
        else
            log "⚠️ $service_name ($container_name) is running but unhealthy: $health_status"
            return 1
        fi
    else
        log "❌ $service_name ($container_name) is not running"
        return 1
    fi
}

# Check HTTP endpoint
check_http_endpoint() {
    local url=$1
    local service_name=$2
    local expected_code=${3:-200}
    
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 10 || echo "000")
    
    if [[ "$response_code" == "$expected_code" ]]; then
        log "✅ $service_name HTTP check passed ($response_code)"
        return 0
    else
        log "❌ $service_name HTTP check failed (got $response_code, expected $expected_code)"
        return 1
    fi
}

# Check database connectivity
check_database() {
    if docker exec n8n_postgres psql -U n8n_user -d n8n -c "SELECT 1;" > /dev/null 2>&1; then
        log "✅ PostgreSQL database is accessible"
        return 0
    else
        log "❌ PostgreSQL database connection failed"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    local threshold=80
    local usage=$(df "$PROJECT_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ "$usage" -lt "$threshold" ]]; then
        log "✅ Disk space OK (${usage}% used)"
        return 0
    else
        log "⚠️ Disk space warning (${usage}% used, threshold: ${threshold}%)"
        return 1
    fi
}

# Generate system report
generate_system_report() {
    log "=== n8n System Health Report ==="
    log "Date: $(date)"
    log "Project Directory: $PROJECT_DIR"
    
    # Container status
    log "--- Container Status ---"
    check_container_health "n8n_app" "n8n Application"
    check_container_health "n8n_postgres" "PostgreSQL Database"
    
    # Service connectivity
    log "--- Service Connectivity ---"
    check_database
    check_http_endpoint "http://localhost:5678/healthz" "n8n Application"
    
    # System resources
    log "--- System Resources ---"
    check_disk_space
    
    log "=== Health Check Complete ==="
}

# Main execution
main() {
    case "${1:-check}" in
        "check")
            generate_system_report
            ;;
        "monitor")
            log "🔍 Starting continuous monitoring (Ctrl+C to stop)..."
            while true; do
                generate_system_report
                sleep 300  # Check every 5 minutes
            done
            ;;
        *)
            echo "Usage: $0 [check|monitor]"
            echo "  check   - Run health check once"
            echo "  monitor - Continuous monitoring"
            exit 1
            ;;
    esac
}

main "$@"