#!/bin/bash

# View results script for nostr-claude-bot
# This script helps view and extract generated projects from the Docker container

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== View Generated Projects ===${NC}"
echo ""

# Check if user can run docker without sudo
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
else
    DOCKER_CMD="sudo docker"
    echo -e "${YELLOW}Using sudo for Docker commands...${NC}"
fi

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  $0 list                    # List all generated projects"
    echo "  $0 show <project_name>     # Show project details"
    echo "  $0 copy <project_name>     # Copy project to host"
    echo "  $0 copy-all                # Copy all projects to host"
    echo "  $0 logs                    # Show bot logs"
    echo ""
}

# Check if container is running
check_container() {
    if ! $DOCKER_CMD ps | grep -q nostr-claude-bot-full; then
        echo -e "${RED}Container 'nostr-claude-bot-full' is not running!${NC}"
        echo -e "${YELLOW}Please start the container first:${NC}"
        echo "  ./setup-claude-full.sh"
        exit 1
    fi
}

# List all generated projects
list_projects() {
    echo -e "${BLUE}Generated Projects:${NC}"
    $DOCKER_CMD exec nostr-claude-bot-full ls -la /app/generated-projects/ 2>/dev/null || {
        echo -e "${YELLOW}No projects found or container not accessible.${NC}"
        return 1
    }
}

# Show project details
show_project() {
    local project_name="$1"
    if [ -z "$project_name" ]; then
        echo -e "${RED}Please specify a project name.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Project Details: $project_name${NC}"
    $DOCKER_CMD exec nostr-claude-bot-full find "/app/generated-projects/$project_name" -type f -name "*.md" -o -name "*.txt" -o -name "*.json" | head -10 | while read file; do
        echo -e "${YELLOW}=== $file ===${NC}"
        $DOCKER_CMD exec nostr-claude-bot-full head -20 "$file"
        echo ""
    done
}

# Copy project to host
copy_project() {
    local project_name="$1"
    if [ -z "$project_name" ]; then
        echo -e "${RED}Please specify a project name.${NC}"
        return 1
    fi
    
    local dest_dir="./results/$project_name"
    mkdir -p "./results"
    
    echo -e "${BLUE}Copying project '$project_name' to $dest_dir...${NC}"
    $DOCKER_CMD cp "nostr-claude-bot-full:/app/generated-projects/$project_name" "$dest_dir"
    echo -e "${GREEN}Project copied successfully!${NC}"
    echo -e "${YELLOW}Location: $dest_dir${NC}"
}

# Copy all projects to host
copy_all_projects() {
    echo -e "${BLUE}Copying all projects to ./results/...${NC}"
    mkdir -p "./results"
    
    $DOCKER_CMD cp "nostr-claude-bot-full:/app/generated-projects/." "./results/"
    echo -e "${GREEN}All projects copied successfully!${NC}"
    echo -e "${YELLOW}Location: ./results/${NC}"
}

# Show bot logs
show_logs() {
    echo -e "${BLUE}Bot Logs:${NC}"
    $DOCKER_CMD logs --tail=50 nostr-claude-bot-full
}

# Main logic
case "${1:-}" in
    "list")
        check_container
        list_projects
        ;;
    "show")
        check_container
        show_project "$2"
        ;;
    "copy")
        check_container
        copy_project "$2"
        ;;
    "copy-all")
        check_container
        copy_all_projects
        ;;
    "logs")
        check_container
        show_logs
        ;;
    *)
        show_usage
        ;;
esac