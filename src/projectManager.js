const fs = require('fs').promises;
const path = require('path');

class ProjectManager {
  constructor(basePath) {
    this.basePath = basePath || './generated-projects';
  }

  async createProject(projectIdea) {
    await this.ensureBasePathExists();
    
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const safeName = projectIdea.replace(/[^a-zA-Z0-9ぁ-んァ-ヶー一-龯]/g, '_');
    const projectName = `${safeName}_${timestamp}`;
    const projectPath = path.join(this.basePath, projectName);
    
    await fs.mkdir(projectPath, { recursive: true });
    
    // Claude Code用のセキュリティ設定を作成
    await this.createClaudeSettings(projectPath);
    
    return projectPath;
  }

  async createClaudeSettings(projectPath) {
    const claudeDir = path.join(projectPath, '.claude');
    await fs.mkdir(claudeDir, { recursive: true });
    
    const settings = {
      "permissions": {
        "allow": [
          "Read(*)",           // ファイル読み取り権限
          "Write(*)",          // ファイル作成権限
          "Edit(*)",           // ファイル編集権限
          "MultiEdit(*)",      // 複数ファイル編集権限
          "LS(*)",             // ディレクトリ一覧権限
          "Grep(*)",           // 検索権限
          "Glob(*)"            // パターンマッチング権限
        ],
        "deny": [
          "Bash(*)"            // Bashコマンド実行を禁止
        ],
        "defaultMode": "acceptEdits"
      }
    };
    
    const settingsPath = path.join(claudeDir, 'settings.json');
    await fs.writeFile(settingsPath, JSON.stringify(settings, null, 2));
    
    console.log(`Claude security settings created at: ${settingsPath}`);
  }

  async ensureBasePathExists() {
    try {
      await fs.access(this.basePath);
    } catch {
      await fs.mkdir(this.basePath, { recursive: true });
    }
  }

  async listProjects() {
    await this.ensureBasePathExists();
    const projects = await fs.readdir(this.basePath);
    return projects;
  }

  async deleteProject(projectName) {
    const projectPath = path.join(this.basePath, projectName);
    await fs.rm(projectPath, { recursive: true, force: true });
  }
}

module.exports = { ProjectManager };