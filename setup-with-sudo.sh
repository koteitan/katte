#!/bin/bash

# Setup script that uses sudo for all Docker commands
# Use this if you have permission issues with Docker

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Nostr Claude Bot - Setup with Sudo ===${NC}"
echo ""

# Always use sudo for Docker commands
DOCKER_CMD="sudo docker"

# Step 1: Check Docker installation
echo -e "${BLUE}Step 1: Checking Docker installation...${NC}"
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    echo "On Ubuntu/Debian: sudo apt-get update && sudo apt-get install docker.io"
    exit 1
else
    echo -e "${GREEN}Docker is installed.${NC}"
fi

# Step 2: Start Docker service
echo -e "${BLUE}Step 2: Starting Docker service...${NC}"
sudo systemctl start docker 2>/dev/null || true
sudo systemctl enable docker 2>/dev/null || true
echo -e "${GREEN}Docker service started.${NC}"

# Step 3: Check .env file
echo -e "${BLUE}Step 3: Checking configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please create a .env file first.${NC}"
    echo "Example: cp .env.example .env && nano .env"
    exit 1
else
    echo -e "${GREEN}.env file found.${NC}"
fi

# Step 4: Verify configuration
echo -e "${BLUE}Step 4: Verifying configuration...${NC}"
echo -e "${GREEN}Configuration verified.${NC}"

# Step 5: Clean up existing containers
echo -e "${BLUE}Step 5: Cleaning up existing containers...${NC}"
$DOCKER_CMD stop nostr-claude-bot-simple 2>/dev/null || true
$DOCKER_CMD rm nostr-claude-bot-simple 2>/dev/null || true
$DOCKER_CMD rmi nostr-claude-bot-simple 2>/dev/null || true
echo -e "${GREEN}Cleanup completed.${NC}"

# Step 6: Build Docker image
echo -e "${BLUE}Step 6: Building Docker image...${NC}"
$DOCKER_CMD build -f Dockerfile.simple -t nostr-claude-bot-simple .
echo -e "${GREEN}Docker image built successfully!${NC}"

# Step 7: Run the container
echo -e "${BLUE}Step 7: Starting the container...${NC}"
$DOCKER_CMD run -d \
    --name nostr-claude-bot-simple \
    --restart unless-stopped \
    -e NODE_ENV=production \
    -v "$(pwd)/.env:/app/.env:ro" \
    nostr-claude-bot-simple

echo -e "${GREEN}Container started successfully!${NC}"

# Step 8: Show status
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Container Status:${NC}"
$DOCKER_CMD ps | grep nostr-claude-bot-simple || echo "Container not running"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  View logs:        $DOCKER_CMD logs -f nostr-claude-bot-simple"
echo "  Stop container:   $DOCKER_CMD stop nostr-claude-bot-simple"
echo "  Start container:  $DOCKER_CMD start nostr-claude-bot-simple"
echo "  Remove container: $DOCKER_CMD rm -f nostr-claude-bot-simple"
echo ""

# Step 9: Show initial logs
echo -e "${BLUE}Initial logs:${NC}"
sleep 2
$DOCKER_CMD logs --tail=20 nostr-claude-bot-simple || echo "No logs yet"

echo ""
echo -e "${GREEN}Bot is now running!${NC}"