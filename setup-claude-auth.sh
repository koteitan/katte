#!/bin/bash

# Claude CLI authentication setup script
# This script handles the one-time browser authentication for Claude CLI

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Claude CLI Authentication Setup ===${NC}"
echo ""

# Check if user can run docker without sudo
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
else
    DOCKER_CMD="sudo docker"
    echo -e "${YELLOW}Using sudo for Docker commands...${NC}"
fi

# Step 1: Check if authentication already exists
echo -e "${BLUE}Step 1: Checking existing authentication...${NC}"
if [ -d "./claude-config" ] && [ -f "./claude-config/config.json" ]; then
    echo -e "${GREEN}Claude authentication already exists!${NC}"
    echo -e "${YELLOW}If you need to re-authenticate, remove ./claude-config directory first.${NC}"
    echo "  rm -rf ./claude-config"
    exit 0
fi

# Step 2: Build authentication image
echo -e "${BLUE}Step 2: Building Claude authentication image...${NC}"
$DOCKER_CMD build -f Dockerfile.claude-auth -t claude-auth .
echo -e "${GREEN}Authentication image built successfully!${NC}"

# Step 3: Create config directory
echo -e "${BLUE}Step 3: Creating configuration directory...${NC}"
mkdir -p ./claude-config
echo -e "${GREEN}Configuration directory created.${NC}"

# Step 4: Start authentication container
echo -e "${BLUE}Step 4: Starting authentication container...${NC}"
echo -e "${YELLOW}This will open a browser authentication process.${NC}"
echo -e "${YELLOW}Please follow the instructions in the container output.${NC}"
echo ""

# Stop and remove existing auth container if any
$DOCKER_CMD stop claude-auth 2>/dev/null || true
$DOCKER_CMD rm claude-auth 2>/dev/null || true

# Run authentication container interactively
echo -e "${BLUE}Starting Claude authentication...${NC}"
echo -e "${YELLOW}Please complete the browser authentication process.${NC}"
echo -e "${YELLOW}After authentication, press Ctrl+C to exit, then the script will continue.${NC}"
echo ""

$DOCKER_CMD run -it \
    --name claude-auth \
    -p 8080:8080 \
    claude-auth \
    bash -c "claude auth; echo 'Authentication completed! Press Ctrl+C to exit.'; trap 'exit 0' INT; sleep 3600 & wait"

# Step 5: Copy authentication config
echo -e "${BLUE}Step 5: Copying authentication configuration...${NC}"
if $DOCKER_CMD cp claude-auth:/root/.claude/.credentials.json ./claude-config/.credentials.json 2>/dev/null; then
    echo -e "${GREEN}Authentication configuration copied successfully!${NC}"
else
    echo -e "${RED}Failed to copy authentication configuration.${NC}"
    echo -e "${YELLOW}Trying alternative locations...${NC}"
    
    # Try alternative locations where Claude might store config
    for config_path in "/root/.claude/.credentials.json" "/root/.claude/config.json" "/app/.claude/.credentials.json" "/root/.config/claude/.credentials.json"; do
        if $DOCKER_CMD cp "claude-auth:$config_path" ./claude-config/.credentials.json 2>/dev/null; then
            echo -e "${GREEN}Found configuration at $config_path!${NC}"
            break
        fi
    done
    
    # If still failed, show what files exist
    if [ ! -f "./claude-config/.credentials.json" ]; then
        echo -e "${YELLOW}Checking what files exist in the container...${NC}"
        $DOCKER_CMD exec claude-auth find /root -name "*claude*" -type f 2>/dev/null || true
        $DOCKER_CMD exec claude-auth find /app -name "*claude*" -type f 2>/dev/null || true
        echo -e "${RED}Could not find Claude configuration file.${NC}"
        echo -e "${YELLOW}Please check if the authentication was completed successfully.${NC}"
        exit 1
    fi
fi

# Step 6: Verify authentication
echo -e "${BLUE}Step 6: Verifying authentication...${NC}"
if [ -f "./claude-config/.credentials.json" ]; then
    echo -e "${GREEN}Authentication file exists: ./claude-config/.credentials.json${NC}"
    echo -e "${BLUE}Configuration preview:${NC}"
    head -3 ./claude-config/.credentials.json 2>/dev/null || echo "Configuration file is present but not readable as text"
else
    echo -e "${RED}Authentication file not found!${NC}"
    exit 1
fi

# Step 7: Cleanup
echo -e "${BLUE}Step 7: Cleaning up...${NC}"
$DOCKER_CMD stop claude-auth 2>/dev/null || true
$DOCKER_CMD rm claude-auth 2>/dev/null || true
echo -e "${GREEN}Cleanup completed.${NC}"

# Step 8: Next steps
echo ""
echo -e "${GREEN}=== Authentication Setup Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Authentication is now saved in ./claude-config/"
echo "2. You can now run the full Claude-integrated bot:"
echo "   ./setup-claude-full.sh"
echo ""
echo -e "${BLUE}Note: Keep ./claude-config/ secure and don't commit it to version control!${NC}"