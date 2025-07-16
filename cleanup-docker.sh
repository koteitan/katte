#!/bin/bash

# Complete Docker cleanup script
# This script removes all containers, images, and volumes related to the bot

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Docker Cleanup Script ===${NC}"
echo ""

# Check if user can run docker without sudo
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
else
    DOCKER_CMD="sudo docker"
    echo -e "${YELLOW}Using sudo for Docker commands...${NC}"
fi

# Stop and remove all related containers
echo -e "${BLUE}Stopping and removing containers...${NC}"
for container in nostr-claude-bot-simple nostr-claude-bot nostr-claude-bot-secure nostr-claude-bot-full claude-executor claude-auth; do
    if $DOCKER_CMD ps -a --format "table {{.Names}}" | grep -q "^$container$"; then
        echo "Stopping and removing container: $container"
        $DOCKER_CMD stop $container 2>/dev/null || true
        $DOCKER_CMD rm $container 2>/dev/null || true
    fi
done

# Remove all related images
echo -e "${BLUE}Removing images...${NC}"
for image in nostr-claude-bot-simple nostr-claude-bot nostr-claude-bot-secure nostr-claude-bot-full claude-executor claude-auth; do
    if $DOCKER_CMD images --format "table {{.Repository}}" | grep -q "^$image$"; then
        echo "Removing image: $image"
        $DOCKER_CMD rmi $image 2>/dev/null || true
    fi
done

# Remove dangling images
echo -e "${BLUE}Removing dangling images...${NC}"
$DOCKER_CMD image prune -f

# Remove unused volumes
echo -e "${BLUE}Removing unused volumes...${NC}"
$DOCKER_CMD volume prune -f

# Remove unused networks
echo -e "${BLUE}Removing unused networks...${NC}"
$DOCKER_CMD network prune -f

echo -e "${GREEN}Docker cleanup completed!${NC}"
echo ""
echo -e "${YELLOW}You can now run ./setup-docker.sh to start fresh.${NC}"