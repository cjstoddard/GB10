#!/bin/bash

# RAG Application Maintenance Script
# Provides common operations for managing the RAG application

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_menu() {
    echo ""
    echo "=========================================="
    echo "  RAG Application Maintenance Menu"
    echo "=========================================="
    echo "1.  View Status"
    echo "2.  View Logs (all services)"
    echo "3.  View Ollama Logs"
    echo "4.  View Open WebUI Logs"
    echo "5.  List Available Models"
    echo "6.  Pull New Model"
    echo "7.  Remove Model"
    echo "8.  Restart Services"
    echo "9.  Stop Services"
    echo "10. Start Services"
    echo "11. Update Images"
    echo "12. Backup Data"
    echo "13. Show Disk Usage"
    echo "14. Show GPU Usage"
    echo "15. Clean Up Unused Images"
    echo "0.  Exit"
    echo "=========================================="
    echo -n "Select option: "
}

view_status() {
    log_info "Service Status:"
    docker compose ps
}

view_logs_all() {
    log_info "Showing logs (Ctrl+C to exit)..."
    docker compose logs -f
}

view_logs_ollama() {
    log_info "Showing Ollama logs (Ctrl+C to exit)..."
    docker logs -f ollama
}

view_logs_webui() {
    log_info "Showing Open WebUI logs (Ctrl+C to exit)..."
    docker logs -f open-webui
}

list_models() {
    log_info "Available models:"
    docker exec ollama ollama list
}

pull_model() {
    echo -n "Enter model name (e.g., llama3.1:8b): "
    read model_name
    
    if [ -z "$model_name" ]; then
        log_error "Model name cannot be empty"
        return 1
    fi
    
    log_info "Pulling model: $model_name"
    docker exec ollama ollama pull "$model_name"
    log_info "Model pulled successfully!"
}

remove_model() {
    list_models
    echo ""
    echo -n "Enter model name to remove: "
    read model_name
    
    if [ -z "$model_name" ]; then
        log_error "Model name cannot be empty"
        return 1
    fi
    
    log_warn "Are you sure you want to remove $model_name?"
    echo -n "Type 'yes' to confirm: "
    read confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log_info "Cancelled"
        return 0
    fi
    
    log_info "Removing model: $model_name"
    docker exec ollama ollama rm "$model_name"
    log_info "Model removed successfully!"
}

restart_services() {
    log_info "Restarting services..."
    docker compose restart
    log_info "Services restarted!"
}

stop_services() {
    log_warn "Stopping services..."
    docker compose down
    log_info "Services stopped!"
}

start_services() {
    log_info "Starting services..."
    docker compose up -d
    log_info "Services started!"
}

update_images() {
    log_info "Pulling latest images..."
    docker compose pull
    
    log_info "Recreating containers with new images..."
    docker compose up -d
    
    log_info "Update complete!"
}

backup_data() {
    backup_dir="backups"
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    log_info "Backing up Ollama data..."
    docker run --rm \
        -v rag_ollama_data:/data \
        -v "$(pwd)/$backup_dir":/backup \
        ubuntu tar czf "/backup/ollama_backup_${timestamp}.tar.gz" /data
    
    log_info "Backing up Open WebUI data..."
    docker run --rm \
        -v rag_open_webui_data:/data \
        -v "$(pwd)/$backup_dir":/backup \
        ubuntu tar czf "/backup/webui_backup_${timestamp}.tar.gz" /data
    
    log_info "Backups saved to: $backup_dir/"
    ls -lh "$backup_dir/"
}

show_disk_usage() {
    log_info "Disk usage:"
    echo ""
    df -h | grep -E "Filesystem|/$"
    echo ""
    log_info "Docker volumes:"
    docker system df -v | grep -A 20 "VOLUME NAME"
}

show_gpu_usage() {
    log_info "GPU Status:"
    docker exec ollama nvidia-smi
}

cleanup_images() {
    log_info "Cleaning up unused Docker images..."
    docker image prune -a -f
    log_info "Cleanup complete!"
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1) view_status ;;
        2) view_logs_all ;;
        3) view_logs_ollama ;;
        4) view_logs_webui ;;
        5) list_models ;;
        6) pull_model ;;
        7) remove_model ;;
        8) restart_services ;;
        9) stop_services ;;
        10) start_services ;;
        11) update_images ;;
        12) backup_data ;;
        13) show_disk_usage ;;
        14) show_gpu_usage ;;
        15) cleanup_images ;;
        0) 
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac
    
    echo ""
    echo -n "Press Enter to continue..."
    read
done
