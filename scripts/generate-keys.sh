#!/bin/bash
set -e

echo "🔐 Generating secure keys for n8n setup..."

# Generate random passwords and keys
N8N_PASSWORD=$(openssl rand -base64 24)
POSTGRES_PASSWORD=$(openssl rand -base64 24)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Create secure .env file
cat > .env << EOF
# n8n Docker Setup - Generated $(date)
# WARNING: Keep this file secure and never commit to version control

# Host Configuration
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http

# Authentication & Security
N8N_USER=admin
N8N_PASSWORD=${N8N_PASSWORD}
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}

# Database Configuration
POSTGRES_DB=n8n
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# System Configuration
GENERIC_TIMEZONE=UTC
NODE_ENV=production

# Optional SMTP (configure manually if needed)
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=

# Backup Configuration
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION_DAYS=30
EOF

echo "✅ Secure .env file created"
echo "📋 Your n8n admin credentials:"
echo "   Username: admin"
echo "   Password: ${N8N_PASSWORD}"
echo ""
echo "🔒 Save these credentials securely!"
echo "📄 All configuration saved to .env file"

# Set secure permissions
chmod 600 .env
echo "🛡️ Environment file permissions secured (600)"