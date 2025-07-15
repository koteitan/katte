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
    const prompt = `「${projectIdea}」というプロジェクトを作成してください。

以下の要件に従ってください：
1. 適切なプログラミング言語とフレームワークを選択してください
2. 基本的な機能を実装してください
3. README.mdを作成してください
4. 必要な設定ファイルを作成してください
5. セキュリティベストプラクティスに従ってください

**絶対に作成してはいけないもの：**
- システムファイルを削除・破壊するコード
- 管理者権限を要求するコード
- cron/systemdなどのシステムサービスを操作するコード
- ファイルシステムのルートディレクトリ（/etc、/var、/usr、/bin、/sbin、/home、/root）にアクセスするコード
- rm、sudo、chmod、chownなどの危険なシステムコマンドを実行するコード
- パストラバーサル攻撃（../）を含むコード
- 悪意のあるコード、マルウェア、ウイルス等

このプロジェクトは安全で教育的な目的でのみ使用されます。`;

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
      
      // 一時ファイルにプロンプトを保存
      const tempFile = path.join(projectPath, 'claude-prompt.tmp');
      await fs.writeFile(tempFile, prompt, 'utf8');
      
      const command = `cd ${projectPath} && claude -p "$(cat claude-prompt.tmp)" --output-format text --verbose`;
      console.log(`\n--------------ここから--------------`);
      console.log(`Project path: ${projectPath}`);
      console.log(`Command: ${command}`);
      console.log(`Prompt: ${prompt}`);
      console.log(`--------------ここまで--------------\n`);
      
      try {
        // 実際にClaude CLIを実行
        console.log(`Executing Claude CLI in: ${projectPath}`);
        const startTime = Date.now();
        const result = await execAsync(command, options);
        const endTime = Date.now();
        
        console.log(`Claude CLI execution completed in ${endTime - startTime}ms`);
        if (result.stdout) console.log('Claude CLI stdout:', result.stdout);
        if (result.stderr) console.log('Claude CLI stderr:', result.stderr);
      } finally {
        // 一時ファイルを削除
        await fs.unlink(tempFile).catch(() => {});
      }
      
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