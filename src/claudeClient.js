const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const path = require('path');
const execAsync = promisify(exec);

class ClaudeClient {
  constructor(apiKey) {
    // Claude CLI uses system configuration, no API key needed here
  }

  async generateProject(projectIdea, projectPath, execEnv = {}) {
    const prompt = `「${projectIdea}」というプロジェクトを作成してください。\n\n以下の要件に従ってください：\n1. 適切なプログラミング言語とフレームワークを選択してください\n2. 基本的な機能を実装してください\n3. README.mdを作成してください\n4. 必要な設定ファイルを作成してください\n5. セキュリティベストプラクティスに従ってください\n6. 悪意のあるコードや危険な操作は含めないでください`;

    await this.executeClaudeCode(projectPath, prompt, execEnv);
    
    return this.summarizeProject(projectIdea, projectPath);
  }

  async executeClaudeCode(projectPath, prompt, execEnv) {
    try {
      const options = {
        maxBuffer: execEnv.maxBuffer || 1024 * 1024 * 10,
        timeout: execEnv.timeout || 600000, // 10分
        env: execEnv.env || process.env,
        killSignal: 'SIGKILL'
      };
      
      // Claude CLIコマンドを出力のみ（テスト用）
      const command = `cd ${projectPath} && claude -p "${prompt}" --output-format text --verbose`;
      console.log(`\n--------------ここから--------------`);
      console.log(`Project path: ${projectPath}`);
      console.log(`Command: ${command}`);
      console.log(`Prompt: ${prompt}`);
      console.log(`--------------ここまで--------------\n`);
      
      // 実際にClaude CLIを実行
      console.log(`Executing Claude CLI in: ${projectPath}`);
      const startTime = Date.now();
      const result = await execAsync(command, options);
      const endTime = Date.now();
      
      console.log(`Claude CLI execution completed in ${endTime - startTime}ms`);
      if (result.stdout) console.log('Claude CLI stdout:', result.stdout);
      if (result.stderr) console.log('Claude CLI stderr:', result.stderr);
      
    } catch (error) {
      console.error('Claude CLI execution error:', error);
      throw new Error('Failed to execute Claude CLI');
    }
  }

  async summarizeProject(projectIdea, projectPath) {
    return `「${projectIdea}」プロジェクトが作成されました！`;
  }
}

module.exports = { ClaudeClient };