const Anthropic = require('@anthropic-ai/sdk');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

class ClaudeClient {
  constructor(apiKey) {
    this.anthropic = new Anthropic({
      apiKey: apiKey,
    });
  }

  async generateProject(projectIdea, projectPath, execEnv = {}) {
    const prompt = `
「${projectIdea}」というプロジェクトを作成してください。

以下の要件に従ってください：
1. プロジェクトのディレクトリは ${projectPath} に作成されています
2. 適切なプログラミング言語とフレームワークを選択してください
3. 基本的な機能を実装してください
4. README.mdを作成してください
5. 必要な設定ファイルを作成してください
6. セキュリティベストプラクティスに従ってください
7. 悪意のあるコードや危険な操作は含めないでください

プロジェクトを作成したら、作成したファイルの概要と使い方を説明してください。
`;

    try {
      const message = await this.anthropic.messages.create({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 4000,
        temperature: 0,
        system: "あなたはセキュリティを重視するソフトウェアエンジニアです。安全で有用なプロジェクトのみを作成します。",
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ]
      });

      const claudeInstructions = message.content[0].text;
      
      await this.executeClaudeCode(projectPath, claudeInstructions, execEnv);
      
      return this.summarizeProject(projectPath);
    } catch (error) {
      throw new Error(`Claude API error: ${error.message}`);
    }
  }

  async executeClaudeCode(projectPath, instructions, execEnv) {
    try {
      const options = {
        maxBuffer: execEnv.maxBuffer || 1024 * 1024 * 10,
        timeout: execEnv.timeout || 300000,
        env: execEnv.env || process.env
      };
      
      await execAsync(`cd ${projectPath} && claude-code "${instructions}"`, options);
    } catch (error) {
      console.error('Claude Code execution error:', error);
      throw new Error('Failed to execute Claude Code');
    }
  }

  async summarizeProject(projectPath) {
    try {
      const { stdout } = await execAsync(`cd ${projectPath} && ls -la && head -20 README.md 2>/dev/null || echo "No README found"`);
      return `プロジェクトが作成されました:\n\`\`\`\n${stdout}\n\`\`\``;
    } catch (error) {
      return 'プロジェクトの概要を取得できませんでした。';
    }
  }
}

module.exports = { ClaudeClient };