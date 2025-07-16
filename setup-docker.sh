#!/bin/bash

# Docker setup script for nostr-claude-bot
# This script automatically handles docker group setup and runs without sudo

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Nostr Claude Bot - Docker Setup ===${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if user is in docker group
check_docker_group() {
    groups $USER | grep -q docker
}

# Function to test docker access
test_docker_access() {
    docker ps >/dev/null 2>&1
}

# Step 1: Check Docker installation
echo -e "${BLUE}Step 1: Checking Docker installation...${NC}"
if ! command_exists docker; then
    echo -e "${RED}Docker is not installed.${NC}"
    echo -e "${YELLOW}Please install Docker first:${NC}"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install docker.io"
    exit 1
else
    echo -e "${GREEN}Docker is installed.${NC}"
fi

# Step 2: Check Docker daemon
echo -e "${BLUE}Step 2: Checking Docker daemon...${NC}"
if ! sudo systemctl is-active --quiet docker; then
    echo -e "${YELLOW}Starting Docker daemon...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "${GREEN}Docker daemon started.${NC}"
else
    echo -e "${GREEN}Docker daemon is running.${NC}"
fi

# Step 3: Check Docker access
echo -e "${BLUE}Step 3: Checking Docker access...${NC}"
if test_docker_access; then
    echo -e "${GREEN}Docker access OK. No sudo required.${NC}"
    DOCKER_CMD="docker"
else
    echo -e "${YELLOW}Docker access requires configuration.${NC}"
    
    # Check if user is in docker group
    if ! check_docker_group; then
        echo -e "${YELLOW}Adding user to docker group...${NC}"
        sudo usermod -aG docker $USER
        echo -e "${GREEN}User added to docker group.${NC}"
    else
        echo -e "${GREEN}User is already in docker group.${NC}"
    fi
    
    # Apply group changes
    echo -e "${YELLOW}Applying group changes...${NC}"
    echo -e "${BLUE}Note: If this fails, please log out and log back in, then run this script again.${NC}"
    
    # Try to apply group changes immediately
    if newgrp docker <<< "docker ps" >/dev/null 2>&1; then
        echo -e "${GREEN}Group changes applied successfully.${NC}"
        DOCKER_CMD="docker"
        # Re-execute script with new group
        echo -e "${YELLOW}Re-executing script with docker group...${NC}"
        exec newgrp docker <<< "$0 $*"
    else
        echo -e "${RED}Cannot apply group changes immediately.${NC}"
        echo -e "${YELLOW}Please run the following commands manually:${NC}"
        echo "  newgrp docker"
        echo "  $0"
        echo -e "${YELLOW}Or log out and log back in, then run this script again.${NC}"
        exit 1
    fi
fi

# Step 4: Check .env file
echo -e "${BLUE}Step 4: Checking configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please create a .env file first:${NC}"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
else
    echo -e "${GREEN}.env file found.${NC}"
fi

# Step 5: Verify configuration
echo -e "${BLUE}Step 5: Verifying configuration...${NC}"
echo -e "${GREEN}Configuration verified.${NC}"

# Step 6: Clean up existing containers
echo -e "${BLUE}Step 6: Cleaning up existing containers...${NC}"
$DOCKER_CMD stop nostr-claude-bot-simple 2>/dev/null || true
$DOCKER_CMD rm nostr-claude-bot-simple 2>/dev/null || true
$DOCKER_CMD rmi nostr-claude-bot-simple 2>/dev/null || true
echo -e "${GREEN}Cleanup completed.${NC}"

# Step 7: Build Docker image
echo -e "${BLUE}Step 7: Building Docker image...${NC}"
$DOCKER_CMD build -f Dockerfile.simple -t nostr-claude-bot-simple .
echo -e "${GREEN}Docker image built successfully!${NC}"

# Step 8: Run the container
echo -e "${BLUE}Step 8: Starting the container...${NC}"
$DOCKER_CMD run -d \
    --name nostr-claude-bot-simple \
    --restart unless-stopped \
    -e NODE_ENV=production \
    -v "$(pwd)/.env:/app/.env:ro" \
    nostr-claude-bot-simple

echo -e "${GREEN}Container started successfully!${NC}"

# Step 9: Show status
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Container Status:${NC}"
$DOCKER_CMD ps | grep nostr-claude-bot-simple || echo "Container not running"
echo ""
echo -e "${YELLOW}Useful Commands (no sudo required):${NC}"
echo "  View logs:        $DOCKER_CMD logs -f nostr-claude-bot-simple"
echo "  Stop container:   $DOCKER_CMD stop nostr-claude-bot-simple"
echo "  Start container:  $DOCKER_CMD start nostr-claude-bot-simple"
echo "  Remove container: $DOCKER_CMD rm -f nostr-claude-bot-simple"
echo "  Rebuild and run:  ./setup-docker.sh"
echo ""

# Step 10: Show initial logs
echo -e "${BLUE}Initial logs:${NC}"
sleep 2
$DOCKER_CMD logs --tail=20 nostr-claude-bot-simple || echo "No logs yet"

echo ""
echo -e "${GREEN}Bot is now running! 🎉${NC}"
echo -e "${YELLOW}Docker group configured - no more sudo required for Docker commands.${NC}"