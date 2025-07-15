require('dotenv').config();
const WebSocket = require('ws');
global.WebSocket = WebSocket;

const { NostrBot } = require('./src/nostrBot');
const { ProjectManager } = require('./src/projectManager');
const { ClaudeClient } = require('./src/claudeClient');

async function main() {
  const claudeClient = new ClaudeClient(); // No API key needed for CLI
  const projectManager = new ProjectManager(process.env.PROJECT_BASE_PATH);
  const bot = new NostrBot({
    privateKey: process.env.NOSTR_PRIVATE_KEY,
    relays: process.env.NOSTR_RELAYS.split(','),
    claudeClient,
    projectManager
  });

  await bot.start();
  console.log('Nostr Claude Bot started successfully!');
  console.log('Listening for "○○作りたい" messages...');
}

main().catch(console.error);