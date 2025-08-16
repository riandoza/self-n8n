#!/bin/bash
set -e

# n8n Docker Management Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Main management menu
main_menu() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                         n8n Docker Management                               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 Available Commands:"
    echo ""
    echo "🚀 Service Management:"
    echo "   1. Start services"
    echo "   2. Stop services"
    echo "   3. Restart services"
    echo "   4. View status"
    echo "   5. View logs"
    echo ""
    echo "🔧 Maintenance:"
    echo "   6. Update containers"
    echo "   7. Clean up Docker"
    echo ""
    echo "⚙️ Configuration:"
    echo "   8. Edit environment"
    echo "   9. Regenerate keys"
    echo "   10. Show access info"
    echo ""
    echo "   0. Exit"
    echo ""
    read -p "Select option (0-10): " choice
    
    case $choice in
        1) start_services ;;
        2) stop_services ;;
        3) restart_services ;;
        4) view_status ;;
        5) view_logs ;;
        6) update_containers ;;
        7) cleanup_docker ;;
        8) edit_environment ;;
        9) regenerate_keys ;;
        10) show_access_info ;;
        0) exit 0 ;;
        *) echo "Invalid option" && sleep 2 && main_menu ;;
    esac
}

# Service management functions
start_services() {
    echo "🚀 Starting n8n services..."
    docker-compose up -d
    echo "✅ Services started"
    read -p "Press Enter to continue..."
    main_menu
}

stop_services() {
    echo "⏹️ Stopping n8n services..."
    docker-compose down
    echo "✅ Services stopped"
    read -p "Press Enter to continue..."
    main_menu
}

restart_services() {
    echo "🔄 Restarting n8n services..."
    docker-compose restart
    echo "✅ Services restarted"
    read -p "Press Enter to continue..."
    main_menu
}

view_status() {
    echo "📊 Service Status:"
    docker-compose ps
    echo ""
    echo "🌐 Network Status:"
    docker network ls | grep n8n || echo "No n8n networks found"
    echo ""
    echo "💾 Volume Status:"
    docker volume ls | grep n8n || echo "No n8n volumes found"
    echo ""
    read -p "Press Enter to continue..."
    main_menu
}

view_logs() {
    echo "📋 Select service logs to view:"
    echo "1. n8n application"
    echo "2. PostgreSQL"
    echo "3. Nginx"
    echo "4. All services"
    echo "5. Return to main menu"
    read -p "Select option: " log_choice
    
    case $log_choice in
        1) docker-compose logs -f n8n ;;
        2) docker-compose logs -f postgres ;;
        3) docker-compose logs -f nginx ;;
        4) docker-compose logs -f ;;
        5) main_menu ;;
        *) echo "Invalid option" && view_logs ;;
    esac
}

# Maintenance functions
update_containers() {
    echo "📥 Updating container images..."
    docker-compose pull
    docker-compose up -d
    echo "✅ Containers updated"
    read -p "Press Enter to continue..."
    main_menu
}

cleanup_docker() {
    echo "🧹 Cleaning up Docker resources..."
    echo "This will remove unused containers, networks, and images."
    read -p "Continue? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        docker system prune -f
        echo "✅ Cleanup completed"
    fi
    read -p "Press Enter to continue..."
    main_menu
}

# Configuration functions
edit_environment() {
    if [[ -f ".env" ]]; then
        echo "⚙️ Editing environment configuration..."
        ${EDITOR:-nano} .env
        echo "✅ Configuration updated"
        echo "⚠️ Restart services to apply changes"
    else
        echo "❌ .env file not found"
    fi
    read -p "Press Enter to continue..."
    main_menu
}

regenerate_keys() {
    if [[ -f "scripts/generate-keys.sh" ]]; then
        echo "🔐 Regenerating security keys..."
        echo "⚠️ This will generate new passwords and encryption keys"
        read -p "Continue? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ./scripts/generate-keys.sh
            echo "✅ Keys regenerated"
            echo "⚠️ Restart services to apply changes"
        fi
    else
        echo "❌ Key generation script not found"
    fi
    read -p "Press Enter to continue..."
    main_menu
}

# Information functions
show_access_info() {
    echo "🌐 n8n Access Information:"
    echo "========================="
    if [[ -f ".env" ]]; then
        local host=$(grep N8N_HOST .env | cut -d= -f2)
        local protocol=$(grep N8N_PROTOCOL .env | cut -d= -f2)
        local port=$(grep N8N_PORT .env | cut -d= -f2)
        
        if [[ "$protocol" == "https" ]]; then
            echo "URL: https://$host"
        else
            echo "URL: http://$host:$port"
        fi
        echo ""
        echo "🔐 Credentials:"
        echo "Username: $(grep N8N_USER .env | cut -d= -f2)"
        echo "Password: $(grep N8N_PASSWORD .env | cut -d= -f2)"
    else
        echo "❌ .env file not found"
    fi
    read -p "Press Enter to continue..."
    main_menu
}

# Start the management interface
main_menu