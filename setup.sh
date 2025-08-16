#!/bin/bash
set -e

# n8n Docker Setup - Master Installation Script
echo "🚀 n8n Docker Self-Hosting Setup"
echo "================================="

# Check system requirements
check_requirements() {
    echo "🔍 Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check disk space (minimum 5GB)
    available_space=$(df . | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 5000000 ]]; then
        echo "⚠️ Warning: Less than 5GB disk space available"
    fi
    
    echo "✅ System requirements satisfied"
}

# Main setup menu
main_menu() {
    echo ""
    echo "📋 Setup Options:"
    echo "1. Quick Start (Local Development)"
    echo "2. Production Setup"
    echo "3. Custom Setup"
    echo "4. Exit"
    echo ""
    read -p "Select option (1-4): " choice
    
    case $choice in
        1) quick_start ;;
        2) production_setup ;;
        3) custom_setup ;;
        4) exit 0 ;;
        *) echo "Invalid option"; main_menu ;;
    esac
}

# Quick start for local development
quick_start() {
    echo ""
    echo "🏃 Quick Start Setup for Local Development"
    echo "=========================================="
    
    # Generate secure keys
    echo "🔐 Generating secure configuration..."
    chmod +x scripts/generate-keys.sh
    ./scripts/generate-keys.sh
    
    # Setup volumes
    echo "📁 Setting up data volumes..."
    chmod +x scripts/setup-volumes.sh
    ./scripts/setup-volumes.sh
    
    # Start services
    echo "🚀 Starting n8n services..."
    docker-compose up -d
    
    # Wait for services
    echo "⏳ Waiting for services to start..."
    sleep 30
    
    # Display access information
    show_access_info
}

# Production setup
production_setup() {
    echo ""
    echo "🏭 Production Setup"
    echo "=================="
    
    # Domain input
    read -p "Enter your domain name (e.g., n8n.yourdomain.com): " domain
    if [[ -z "$domain" ]]; then
        echo "❌ Domain name is required for production setup"
        return 1
    fi
    
    # Generate configuration
    echo "🔐 Generating secure configuration..."
    chmod +x scripts/generate-keys.sh
    ./scripts/generate-keys.sh
    
    # Update domain in .env
    sed -i.bak "s/N8N_HOST=localhost/N8N_HOST=$domain/" .env
    sed -i.bak "s/N8N_PROTOCOL=http/N8N_PROTOCOL=https/" .env
    
    # Setup volumes
    echo "📁 Setting up data volumes..."
    chmod +x scripts/setup-volumes.sh
    ./scripts/setup-volumes.sh
    
    # Start production services
    echo "🚀 Starting production services..."
    docker-compose --profile production up -d
    
    # Wait for services
    echo "⏳ Waiting for services to start..."
    sleep 45
    
    # Display production access info
    show_production_info "$domain"
}

# Custom setup
custom_setup() {
    echo ""
    echo "🛠️ Custom Setup"
    echo "==============="
    
    echo "Available setup components:"
    echo "1. Generate secure keys"
    echo "2. Setup data volumes"
    echo "3. Start services"
    echo "4. Return to main menu"
    echo ""
    read -p "Select component to setup: " component
    
    case $component in
        1) chmod +x scripts/generate-keys.sh && ./scripts/generate-keys.sh ;;
        2) chmod +x scripts/setup-volumes.sh && ./scripts/setup-volumes.sh ;;
        3) docker-compose up -d ;;
        4) main_menu ;;
        *) echo "Invalid option"; custom_setup ;;
    esac
    
    custom_setup
}

# Show access information
show_access_info() {
    echo ""
    echo "✅ n8n Setup Complete!"
    echo "======================"
    echo ""
    echo "🌐 Access your n8n instance:"
    echo "   URL: http://localhost:5678"
    echo ""
    echo "🔐 Login credentials:"
    if [[ -f .env ]]; then
        echo "   Username: $(grep N8N_USER .env | cut -d= -f2)"
        echo "   Password: $(grep N8N_PASSWORD .env | cut -d= -f2)"
    fi
    echo ""
    echo "📋 Useful commands:"
    echo "   View logs: docker-compose logs -f"
    echo "   Stop services: docker-compose down"
    echo "   Restart services: docker-compose restart"
    echo "   Management interface: ./manage.sh"
    echo ""
    echo "📚 Next steps:"
    echo "   1. Access n8n and complete the initial setup"
    echo "   2. Create your first workflow"
    echo "   3. Configure any needed integrations"
    echo "   4. Review security settings for production use"
}

# Show production access information
show_production_info() {
    local domain=$1
    echo ""
    echo "✅ n8n Production Setup Complete!"
    echo "================================="
    echo ""
    echo "🌐 Access your n8n instance:"
    echo "   URL: https://$domain"
    echo ""
    echo "🔐 Login credentials:"
    if [[ -f .env ]]; then
        echo "   Username: $(grep N8N_USER .env | cut -d= -f2)"
        echo "   Password: $(grep N8N_PASSWORD .env | cut -d= -f2)"
    fi
    echo ""
    echo "📊 Management:"
    echo "   Management interface: ./manage.sh"
    echo ""
    echo "⚠️ Security Reminders:"
    echo "   - Configure SSL certificates for HTTPS"
    echo "   - Set up firewall rules"
    echo "   - Monitor access logs regularly"
    echo "   - Update passwords periodically"
}

# Main execution
echo "Starting n8n Docker setup..."
check_requirements
main_menu