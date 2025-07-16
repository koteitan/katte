#!/bin/bash

# Claude-integrated nostr-claude-bot setup script
# This script runs the bot with full Claude CLI integration in Docker

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Nostr Claude Bot - Full Integration Setup ===${NC}"
echo ""

# Check if user can run docker without sudo
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
else
    DOCKER_CMD="sudo docker"
    echo -e "${YELLOW}Using sudo for Docker commands...${NC}"
fi

# Step 1: Check authentication
echo -e "${BLUE}Step 1: Checking Claude authentication...${NC}"
if [ ! -f "./claude-config/.credentials.json" ]; then
    echo -e "${RED}Claude authentication not found!${NC}"
    echo -e "${YELLOW}Please run the authentication setup first:${NC}"
    echo "  ./setup-claude-auth.sh"
    exit 1
else
    echo -e "${GREEN}Claude authentication found.${NC}"
fi

# Step 2: Check .env file
echo -e "${BLUE}Step 2: Checking configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please create a .env file first:${NC}"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
else
    echo -e "${GREEN}.env file found.${NC}"
fi

# Step 3: Clean up existing containers
echo -e "${BLUE}Step 3: Cleaning up existing containers...${NC}"
$DOCKER_CMD stop nostr-claude-bot-full 2>/dev/null || true
$DOCKER_CMD rm nostr-claude-bot-full 2>/dev/null || true
$DOCKER_CMD rmi nostr-claude-bot-full 2>/dev/null || true
echo -e "${GREEN}Cleanup completed.${NC}"

# Step 4: Build Docker image
echo -e "${BLUE}Step 4: Building Docker image with Claude integration...${NC}"
$DOCKER_CMD build -f Dockerfile.claude-full -t nostr-claude-bot-full .
echo -e "${GREEN}Docker image built successfully!${NC}"

# Step 5: Run the container
echo -e "${BLUE}Step 5: Starting the container...${NC}"
$DOCKER_CMD run -d \
    --name nostr-claude-bot-full \
    --restart unless-stopped \
    -e NODE_ENV=production \
    -e NOSTR_PRIVATE_KEY="$(grep NOSTR_PRIVATE_KEY .env | cut -d'=' -f2)" \
    -e NOSTR_RELAYS="$(grep NOSTR_RELAYS .env | cut -d'=' -f2)" \
    -e PROJECT_BASE_PATH="$(grep PROJECT_BASE_PATH .env | cut -d'=' -f2)" \
    -e MAX_CONCURRENT_PROJECTS="$(grep MAX_CONCURRENT_PROJECTS .env | cut -d'=' -f2)" \
    nostr-claude-bot-full

echo -e "${GREEN}Container started successfully!${NC}"

# Step 6: Show status
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Container Status:${NC}"
$DOCKER_CMD ps | grep nostr-claude-bot-full || echo "Container not running"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  View logs:          $DOCKER_CMD logs -f nostr-claude-bot-full"
echo "  Stop container:     $DOCKER_CMD stop nostr-claude-bot-full"
echo "  Start container:    $DOCKER_CMD start nostr-claude-bot-full"
echo "  Remove container:   $DOCKER_CMD rm -f nostr-claude-bot-full"
echo "  View results:       ./view-results.sh"
echo ""
echo -e "${BLUE}Security Features:${NC}"
echo "- ✅ No host filesystem mounts"
echo "- ✅ Complete Docker isolation"
echo "- ✅ Claude CLI runs entirely in container"
echo "- ✅ Generated projects stored in container"
echo ""

# Step 7: Show initial logs
echo -e "${BLUE}Initial logs:${NC}"
sleep 2
$DOCKER_CMD logs --tail=20 nostr-claude-bot-full || echo "No logs yet"

echo ""
echo -e "${GREEN}Bot is now running with full Claude integration! 🎉${NC}"
echo -e "${YELLOW}The bot can now generate actual projects using Claude CLI.${NC}"