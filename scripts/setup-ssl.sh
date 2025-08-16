#!/bin/bash
set -e

echo "🔐 SSL Certificate Setup for n8n"

SSL_DIR="./ssl"
DOMAIN=${1:-localhost}

if [[ "$DOMAIN" == "localhost" ]]; then
    echo "🔧 Creating self-signed certificate for local development..."
    
    # Create SSL directory
    mkdir -p $SSL_DIR
    
    # Generate private key
    openssl genrsa -out $SSL_DIR/privkey.pem 2048
    
    # Generate certificate signing request
    openssl req -new -key $SSL_DIR/privkey.pem -out $SSL_DIR/cert.csr -subj "/C=US/ST=Local/L=Local/O=n8n Development/CN=localhost"
    
    # Generate self-signed certificate
    openssl x509 -req -in $SSL_DIR/cert.csr -signkey $SSL_DIR/privkey.pem -out $SSL_DIR/fullchain.pem -days 365
    
    # Set proper permissions
    chmod 600 $SSL_DIR/privkey.pem
    chmod 644 $SSL_DIR/fullchain.pem
    
    echo "✅ Self-signed certificate created for localhost"
    echo "⚠️ This certificate will show security warnings in browsers"
    
else
    echo "🌐 Setting up Let's Encrypt for domain: $DOMAIN"
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        if [[ -f /etc/debian_version ]]; then
            apt-get update && apt-get install -y certbot
        elif [[ -f /etc/redhat-release ]]; then
            yum install -y certbot
        else
            echo "❌ Please install certbot manually"
            exit 1
        fi
    fi
    
    # Stop nginx if running to free port 80
    docker-compose stop nginx 2>/dev/null || true
    
    # Get certificate
    certbot certonly --standalone -d $DOMAIN --email admin@$DOMAIN --agree-tos --non-interactive
    
    # Copy certificates to ssl directory
    mkdir -p $SSL_DIR
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $SSL_DIR/
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $SSL_DIR/
    
    # Set proper permissions
    chmod 644 $SSL_DIR/fullchain.pem
    chmod 600 $SSL_DIR/privkey.pem
    
    echo "✅ Let's Encrypt certificate obtained for $DOMAIN"
    
    # Setup certificate renewal
    cat > /etc/cron.d/certbot-n8n << EOF
# Renew n8n certificates twice daily
0 12,0 * * * root certbot renew --quiet --deploy-hook "docker-compose -f $(pwd)/docker-compose.yml restart nginx"
EOF
    
    echo "✅ Certificate auto-renewal configured"
fi

echo ""
echo "📋 SSL Configuration:"
echo "   - Certificate: $SSL_DIR/fullchain.pem"
echo "   - Private Key: $SSL_DIR/privkey.pem"
echo "   - Domain: $DOMAIN"