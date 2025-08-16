#!/bin/bash
set -e

# n8n Comprehensive Backup Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_BASE_DIR="${PROJECT_DIR}/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/${TIMESTAMP}"

# Load environment variables
if [[ -f "${PROJECT_DIR}/.env" ]]; then
    source "${PROJECT_DIR}/.env"
fi

# Configuration
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
POSTGRES_USER=${POSTGRES_USER:-n8n_user}
POSTGRES_DB=${POSTGRES_DB:-n8n}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${BACKUP_BASE_DIR}/backup.log"
}

# Create backup directory structure
create_backup_structure() {
    log "📁 Creating backup directory structure..."
    mkdir -p "${BACKUP_DIR}"/{database,n8n_data,configuration}
}

# Backup PostgreSQL database
backup_database() {
    log "🗃️ Backing up PostgreSQL database..."
    
    if docker ps | grep -q "n8n_postgres"; then
        # Create SQL dump
        docker exec n8n_postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --verbose > "${BACKUP_DIR}/database/n8n_dump.sql"
        
        # Create compressed binary dump for faster restore
        docker exec n8n_postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "${BACKUP_DIR}/database/n8n_dump.backup"
        
        log "✅ Database backup completed"
    else
        log "❌ PostgreSQL container not running - skipping database backup"
        return 1
    fi
}

# Backup n8n application data
backup_n8n_data() {
    log "📦 Backing up n8n application data..."
    
    if docker ps | grep -q "n8n_app"; then
        # Create application data backup
        docker exec n8n_app tar czf - /home/node/.n8n > "${BACKUP_DIR}/n8n_data/n8n_application_data.tar.gz"
        
        log "✅ n8n data backup completed"
    else
        log "❌ n8n container not running - skipping application data backup"
        return 1
    fi
}

# Backup configuration files
backup_configuration() {
    log "⚙️ Backing up configuration files..."
    
    # Copy Docker Compose files
    cp "${PROJECT_DIR}/docker-compose.yml" "${BACKUP_DIR}/configuration/" 2>/dev/null || true
    
    # Copy environment file (without sensitive data)
    if [[ -f "${PROJECT_DIR}/.env" ]]; then
        # Create sanitized env file
        grep -v -E "(PASSWORD|KEY|SECRET)" "${PROJECT_DIR}/.env" > "${BACKUP_DIR}/configuration/env.template" || true
        echo "# Sensitive variables removed for security" >> "${BACKUP_DIR}/configuration/env.template"
    fi
    
    # Copy Nginx configuration
    if [[ -d "${PROJECT_DIR}/nginx" ]]; then
        cp -r "${PROJECT_DIR}/nginx" "${BACKUP_DIR}/configuration/"
    fi
    
    log "✅ Configuration backup completed"
}

# Create backup manifest
create_backup_manifest() {
    log "📄 Creating backup manifest..."
    
    cat > "${BACKUP_DIR}/MANIFEST.txt" << EOF
n8n Docker Backup Manifest
==========================
Backup Date: $(date)
Backup Directory: ${BACKUP_DIR}
n8n Version: $(docker exec n8n_app n8n --version 2>/dev/null || echo "Unknown")
PostgreSQL Version: $(docker exec n8n_postgres psql --version 2>/dev/null || echo "Unknown")

Backup Contents:
- database/: PostgreSQL database dumps
- n8n_data/: Application data
- configuration/: System configuration

Backup Size: $(du -sh "${BACKUP_DIR}" | cut -f1)
EOF

    log "✅ Backup manifest created"
}

# Compress and finalize backup
finalize_backup() {
    log "🗜️ Compressing backup..."
    
    cd "${BACKUP_BASE_DIR}"
    tar czf "${TIMESTAMP}_n8n_backup.tar.gz" "${TIMESTAMP}/"
    
    # Calculate checksums
    sha256sum "${TIMESTAMP}_n8n_backup.tar.gz" > "${TIMESTAMP}_n8n_backup.tar.gz.sha256"
    
    # Remove uncompressed directory
    rm -rf "${TIMESTAMP}"
    
    log "✅ Backup compressed: ${TIMESTAMP}_n8n_backup.tar.gz"
}

# Cleanup old backups
cleanup_old_backups() {
    log "🧹 Cleaning up old backups (keeping ${RETENTION_DAYS} days)..."
    
    find "${BACKUP_BASE_DIR}" -name "*_n8n_backup.tar.gz" -mtime +${RETENTION_DAYS} -delete
    find "${BACKUP_BASE_DIR}" -name "*_n8n_backup.tar.gz.sha256" -mtime +${RETENTION_DAYS} -delete
    
    # Count remaining backups
    local backup_count=$(find "${BACKUP_BASE_DIR}" -name "*_n8n_backup.tar.gz" | wc -l)
    log "📊 Backup retention: ${backup_count} backups remaining"
}

# Main backup execution
main() {
    case "${1:-full}" in
        "full")
            log "🚀 Starting full n8n backup..."
            create_backup_structure
            backup_database
            backup_n8n_data
            backup_configuration
            create_backup_manifest
            finalize_backup
            cleanup_old_backups
            log "✅ Full backup completed successfully"
            ;;
        "database")
            log "🚀 Starting database-only backup..."
            create_backup_structure
            backup_database
            create_backup_manifest
            finalize_backup
            log "✅ Database backup completed successfully"
            ;;
        *)
            echo "Usage: $0 [full|database]"
            echo ""
            echo "Backup Types:"
            echo "  full     - Complete backup (default)"
            echo "  database - Database only"
            exit 1
            ;;
    esac
}

# Ensure backup directory exists
mkdir -p "${BACKUP_BASE_DIR}"

# Execute main function
main "$@"