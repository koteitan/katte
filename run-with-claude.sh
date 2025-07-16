#!/bin/bash

# Docker run script with Claude CLI from host
set -e

# Find claude binary location
CLAUDE_PATH=$(which claude 2>/dev/null || echo "")

if [ -z "$CLAUDE_PATH" ]; then
    echo "Error: Claude CLI not found on host system!"
    echo "Please install Claude CLI first: https://claude.ai/docs/claude-cli"
    exit 1
fi

echo "Found Claude CLI at: $CLAUDE_PATH"

# Find Claude config directory
CLAUDE_CONFIG_DIR="$HOME/.claude"
if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
    echo "Warning: Claude config directory not found at $CLAUDE_CONFIG_DIR"
    echo "You may need to run 'claude auth' first"
fi

echo "Building Docker image..."
sudo docker build -f Dockerfile.simple -t nostr-claude-bot-with-claude .

echo "Stopping existing container if any..."
sudo docker stop nostr-claude-bot-with-claude 2>/dev/null || true
sudo docker rm nostr-claude-bot-with-claude 2>/dev/null || true

echo "Starting nostr-claude-bot container with Claude CLI..."
sudo docker run -d \
  --name nostr-claude-bot-with-claude \
  --restart unless-stopped \
  -e NODE_ENV=production \
  -v "$(pwd)/.env:/app/.env:ro" \
  -v "$(pwd)/generated-projects:/app/generated-projects" \
  -v "$CLAUDE_PATH:/usr/local/bin/claude:ro" \
  -v "$CLAUDE_CONFIG_DIR:/root/.claude:ro" \
  -v "/usr/bin/node:/usr/bin/node:ro" \
  --network host \
  nostr-claude-bot-with-claude

echo ""
echo "Container started with Claude CLI integration!"
echo ""
echo "Useful commands:"
echo "  View logs:        sudo docker logs -f nostr-claude-bot-with-claude"
echo "  Stop container:   sudo docker stop nostr-claude-bot-with-claude"
echo "  Start container:  sudo docker start nostr-claude-bot-with-claude"
echo "  Remove container: sudo docker rm -f nostr-claude-bot-with-claude"