#!/bin/bash

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yaml"
REQUIRED_MODEL="llama3.1:70b"
EMBEDDING_MODEL="nomic-embed-text"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root. This is okay but not recommended for production."
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        log_info "Visit: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    
    # Check if NVIDIA Docker runtime is available
    if ! docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
        log_error "NVIDIA Docker runtime is not properly configured."
        log_info "Please install nvidia-container-toolkit:"
        log_info "  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
        exit 1
    fi
    
    log_info "All requirements met!"
}

# Check available disk space
check_disk_space() {
    log_info "Checking available disk space..."
    
    available_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    required_space=100  # GB
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_warn "Low disk space detected: ${available_space}GB available"
        log_warn "Recommended: at least ${required_space}GB for 70B model and data"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_info "Sufficient disk space available: ${available_space}GB"
    fi
}

# Stop and remove existing containers
cleanup_existing() {
    log_info "Cleaning up existing containers..."
    
    if docker compose -f "$COMPOSE_FILE" ps -q &> /dev/null; then
        docker compose -f "$COMPOSE_FILE" down
    fi
    
    log_info "Cleanup complete."
}

# Pull Docker images
pull_images() {
    log_info "Pulling Docker images..."
    docker compose -f "$COMPOSE_FILE" pull
    log_info "Images pulled successfully."
}

# Start services
start_services() {
    log_info "Starting services..."
    docker compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to initialize..."
    sleep 10
    
    # Check if services are running
    if ! docker compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        log_error "Services failed to start. Check logs with: docker compose logs"
        exit 1
    fi
    
    log_info "Services started successfully!"
}

# Wait for Ollama to be ready
wait_for_ollama() {
    log_info "Waiting for Ollama service to be ready..."
    
    max_attempts=30
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec ollama ollama list &> /dev/null; then
            log_info "Ollama is ready!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    log_error "Ollama failed to start within expected time."
    log_info "Check logs with: docker logs ollama"
    exit 1
}

# Pull the main LLM model
pull_llm_model() {
    log_info "Pulling $REQUIRED_MODEL model (this will take a while - ~40GB download)..."
    
    # Check if model already exists
    if docker exec ollama ollama list | grep -q "$REQUIRED_MODEL"; then
        log_info "Model $REQUIRED_MODEL already exists. Skipping download."
        return 0
    fi
    
    log_warn "Downloading 70B model will take significant time and bandwidth."
    log_info "You can monitor progress in another terminal with: docker logs -f ollama"
    
    if docker exec ollama ollama pull "$REQUIRED_MODEL"; then
        log_info "Model $REQUIRED_MODEL pulled successfully!"
    else
        log_error "Failed to pull model $REQUIRED_MODEL"
        log_info "You can manually pull it later with: docker exec ollama ollama pull $REQUIRED_MODEL"
    fi
}

# Pull the embedding model for RAG
pull_embedding_model() {
    log_info "Pulling embedding model: $EMBEDDING_MODEL..."
    
    if docker exec ollama ollama list | grep -q "$EMBEDDING_MODEL"; then
        log_info "Embedding model $EMBEDDING_MODEL already exists. Skipping download."
        return 0
    fi
    
    if docker exec ollama ollama pull "$EMBEDDING_MODEL"; then
        log_info "Embedding model $EMBEDDING_MODEL pulled successfully!"
    else
        log_error "Failed to pull embedding model $EMBEDDING_MODEL"
    fi
}

# Display status and access information
display_info() {
    echo ""
    echo "=========================================="
    log_info "RAG Application Setup Complete!"
    echo "=========================================="
    echo ""
    log_info "Access Open WebUI at: http://localhost:8080"
    log_info "Ollama API endpoint: http://localhost:11434"
    echo ""
    log_info "Available commands:"
    echo "  - View logs:           docker compose logs -f"
    echo "  - Stop services:       docker compose down"
    echo "  - Restart services:    docker compose restart"
    echo "  - Check status:        docker compose ps"
    echo "  - Pull more models:    docker exec ollama ollama pull <model-name>"
    echo "  - List models:         docker exec ollama ollama list"
    echo ""
    log_info "RAG Features enabled:"
    echo "  - Document upload and processing (PDF, TXT, DOC, etc.)"
    echo "  - Web search integration"
    echo "  - Embedding model: $EMBEDDING_MODEL"
    echo "  - Main LLM: $REQUIRED_MODEL"
    echo ""
    log_warn "Note: First queries may be slow as the model loads into memory."
    echo "=========================================="
}

# Main execution
main() {
    log_info "Starting RAG Application Setup for Dell Pro Max GB10"
    echo ""
    
    check_privileges
    check_requirements
    check_disk_space
    cleanup_existing
    pull_images
    start_services
    wait_for_ollama
    pull_embedding_model
    pull_llm_model
    display_info
    
    log_info "Setup complete! Happy RAG-ing!"
}

# Run main function
main
