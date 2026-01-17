#!/bin/bash
# StarTraining - Google Drive Raw Folder Watcher
# Starts all services and triggers n8n workflow when new/modified files are detected
# Supports: .docx, .odt, .csv, .xlsx, and any other file types
#
# Usage: ./watch_raw_folder.sh
# Stop: Ctrl+C
#
# Requirements: fswatch (install with: brew install fswatch)

set -e

# Configuration
WEBHOOK_URL="http://localhost:5001/run-single"
RAW_FOLDER_NAME="Raw"
DEBOUNCE_SECONDS=5
N8N_PROJECT_DIR="$HOME/GitHub/startraining-n8n"
PIPELINE_PROJECT_DIR="$HOME/GitHub/startraining-ai-pipeline"
WEBHOOK_PORT=5001
WEBHOOK_PID_FILE="/tmp/startraining_webhook.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Cleanup on exit
cleanup() {
    echo ""
    log_info "Shutting down..."

    # Kill webhook server if we started it
    if [ -f "$WEBHOOK_PID_FILE" ]; then
        local pid=$(cat "$WEBHOOK_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Stopping webhook server (PID: $pid)..."
            kill "$pid" 2>/dev/null
        fi
        rm -f "$WEBHOOK_PID_FILE"
    fi

    log_success "Goodbye!"
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Start Docker Desktop if not running
start_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_info "Starting Docker Desktop..."
        open -a Docker

        # Wait for Docker to be ready (max 60 seconds)
        local count=0
        while ! docker info > /dev/null 2>&1; do
            if [ $count -ge 60 ]; then
                log_error "Docker failed to start within 60 seconds"
                exit 1
            fi
            sleep 1
            count=$((count + 1))
            if [ $((count % 10)) -eq 0 ]; then
                log_info "Waiting for Docker... ($count seconds)"
            fi
        done
        log_success "Docker Desktop started"
    else
        log_success "Docker is running"
    fi
}

# Start n8n container if not running
start_n8n() {
    local container_status=$(docker ps --filter "name=n8n" --format "{{.Status}}" 2>/dev/null)

    if [ -z "$container_status" ]; then
        log_info "Starting n8n container..."
        cd "$N8N_PROJECT_DIR"
        docker compose up -d

        # Wait for n8n to be ready (max 30 seconds)
        local count=0
        while ! curl -s --connect-timeout 2 "http://127.0.0.1:5678" > /dev/null 2>&1; do
            if [ $count -ge 30 ]; then
                log_warn "n8n may still be starting up..."
                break
            fi
            sleep 1
            count=$((count + 1))
        done
        log_success "n8n container started"
    else
        log_success "n8n container is running ($container_status)"
    fi
}

# Start webhook server if not running
start_webhook_server() {
    if curl -s --connect-timeout 2 "http://localhost:$WEBHOOK_PORT/health" > /dev/null 2>&1; then
        log_success "Webhook server is running"
        return 0
    fi

    log_info "Starting webhook server..."

    # Check if pipeline directory exists
    if [ ! -d "$PIPELINE_PROJECT_DIR" ]; then
        log_error "Pipeline directory not found: $PIPELINE_PROJECT_DIR"
        exit 1
    fi

    # Start webhook server in background
    cd "$PIPELINE_PROJECT_DIR"

    # Activate venv and start server
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        PORT=$WEBHOOK_PORT nohup python webhook_server.py > /tmp/webhook_server.log 2>&1 &
        echo $! > "$WEBHOOK_PID_FILE"
    else
        log_error "Python venv not found at $PIPELINE_PROJECT_DIR/.venv"
        exit 1
    fi

    # Wait for webhook server to be ready (max 15 seconds)
    local count=0
    while ! curl -s --connect-timeout 2 "http://localhost:$WEBHOOK_PORT/health" > /dev/null 2>&1; do
        if [ $count -ge 15 ]; then
            log_error "Webhook server failed to start. Check /tmp/webhook_server.log"
            exit 1
        fi
        sleep 1
        count=$((count + 1))
    done
    log_success "Webhook server started (logs: /tmp/webhook_server.log)"
}

# Find Google Drive folder
find_google_drive_folder() {
    local cloud_storage="$HOME/Library/CloudStorage"

    # Check CloudStorage for Google Drive (newer location)
    if [ -d "$cloud_storage" ]; then
        local gd_folder=$(find "$cloud_storage" -maxdepth 1 -type d -name "GoogleDrive-*" 2>/dev/null | head -1)
        if [ -n "$gd_folder" ]; then
            # Check for "My Drive" subfolder
            if [ -d "$gd_folder/My Drive" ]; then
                echo "$gd_folder/My Drive"
                return 0
            fi
        fi
    fi

    # Check legacy location
    if [ -d "$HOME/Google Drive" ]; then
        echo "$HOME/Google Drive"
        return 0
    fi

    # Check alternative location
    if [ -d "$HOME/Google Drive/My Drive" ]; then
        echo "$HOME/Google Drive/My Drive"
        return 0
    fi

    return 1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check fswatch
    if ! command -v fswatch &> /dev/null; then
        log_error "fswatch is not installed."
        echo "Install it with: brew install fswatch"
        exit 1
    fi
    log_success "fswatch found"

    # Check docker command exists
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed."
        echo "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    log_success "Docker command found"
}

# Start all services
start_services() {
    echo ""
    log_info "Starting services..."
    echo ""

    start_docker
    start_n8n
    start_webhook_server

    echo ""
    log_success "All services are running!"
    echo "  - n8n UI: http://127.0.0.1:5678"
    echo "  - Webhook: http://localhost:$WEBHOOK_PORT"
    echo ""
}

# Process a single file
process_file() {
    local filepath="$1"
    local filename=$(basename "$filepath")

    # Skip hidden files and temporary files (Google Drive creates these during sync)
    if [[ "$filename" =~ ^\. ]] || [[ "$filename" =~ ^~ ]] || [[ "$filename" =~ \.tmp$ ]] || [[ "$filename" =~ \.crdownload$ ]]; then
        log_info "Skipping temporary/hidden file: $filename"
        return 0
    fi

    # Skip directories
    if [ -d "$filepath" ]; then
        return 0
    fi

    log_info "Detected file: $filename"
    log_info "Triggering workflow..."

    # Call the webhook with the filename
    local response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"filename\": \"$filename\"}" \
        -w "\n%{http_code}" 2>&1)

    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | head -n -1)

    if [[ "$http_code" =~ ^2 ]]; then
        log_success "Workflow triggered successfully (HTTP $http_code)"
        echo "$body" | head -5
    else
        log_error "Workflow trigger failed (HTTP $http_code)"
        echo "$body"
    fi
}

# Main function
main() {
    echo "========================================="
    echo "  StarTraining Raw Folder Watcher"
    echo "========================================="
    echo ""

    check_prerequisites
    start_services

    # Find Google Drive folder
    log_info "Looking for Google Drive folder..."
    GOOGLE_DRIVE=$(find_google_drive_folder)

    if [ -z "$GOOGLE_DRIVE" ]; then
        log_error "Could not find Google Drive folder"
        echo "Please set GOOGLE_DRIVE manually in this script"
        exit 1
    fi

    log_success "Found Google Drive: $GOOGLE_DRIVE"

    # Check Raw folder exists
    RAW_FOLDER="$GOOGLE_DRIVE/$RAW_FOLDER_NAME"
    if [ ! -d "$RAW_FOLDER" ]; then
        log_error "Raw folder not found: $RAW_FOLDER"
        echo "Please create the 'Raw' folder in your Google Drive"
        exit 1
    fi

    log_success "Watching: $RAW_FOLDER"
    echo ""
    log_info "Waiting for new files... (Ctrl+C to stop)"
    echo ""

    # Track processed files to avoid duplicates (due to multiple events per file)
    declare -A processed_files

    # Watch for file changes
    fswatch -0 --event Created --event Updated --event Renamed "$RAW_FOLDER" | while IFS= read -r -d '' filepath; do
        # Debounce: skip if we processed this file recently
        local now=$(date +%s)
        local last_processed=${processed_files["$filepath"]:-0}
        local diff=$((now - last_processed))

        if [ $diff -lt $DEBOUNCE_SECONDS ]; then
            continue
        fi

        processed_files["$filepath"]=$now
        process_file "$filepath"
    done
}

# Run main
main "$@"
