#!/bin/bash
set -e

echo "🗂️ Setting up n8n data volumes..."

# Create data directories with proper structure
mkdir -p data/n8n/{workflows,credentials,logs,custom,backups}
mkdir -p data/postgres
mkdir -p nginx/logs
mkdir -p ssl
mkdir -p backup/{n8n,postgres}

# Set ownership and permissions
if [[ "$OSTYPE" != "darwin"* ]]; then
    # Linux permissions
    sudo chown -R 1000:1000 data/n8n
    sudo chown -R 999:999 data/postgres
    sudo chown -R 101:101 nginx/logs
else
    # macOS permissions
    chown -R $(id -u):$(id -g) data/
    chown -R $(id -u):$(id -g) nginx/logs
fi

# Set directory permissions
chmod -R 755 data/n8n
chmod -R 700 data/postgres
chmod -R 755 nginx/logs
chmod -R 700 ssl

echo "✅ Volume structure created successfully"
echo "📁 Data directories:"
echo "   - data/n8n/ (n8n application data)"
echo "   - data/postgres/ (database files)"
echo "   - nginx/logs/ (web server logs)"
echo "   - ssl/ (SSL certificates)"
echo "   - backup/ (automated backups)"