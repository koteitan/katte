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
      "allowedTools": [
        "Read",
        "WriteFile(*)",        // プロジェクト内のみ書き込み許可
        "Edit(*)",             // プロジェクト内のみ編集許可
        "MultiEdit(*)",        // プロジェクト内のみ複数編集許可
        "Write(*)",            // プロジェクト内のみ新規ファイル作成許可
        
        // 安全なBashコマンドのみ許可（実行ファイル禁止）
        "Bash(ls *)",          // lsコマンドのみ
        "Bash(cat *)",         // catコマンドのみ
        "Bash(grep *)",        // grepコマンドのみ
        "Bash(mkdir *)",       // mkdirコマンドのみ
        "Bash(touch *)",       // touchコマンドのみ
        "Bash(echo *)",        // echoコマンドのみ
        "Bash(pwd)",           // pwdコマンドのみ
        "Bash(head *)",        // headコマンドのみ
        "Bash(tail *)",        // tailコマンドのみ
        "Bash(wc *)",          // wcコマンドのみ
        
        // パッケージマネージャーは初期化のみ許可
        "Bash(npm init *)",    // npm initのみ
        "Bash(npm install *)", // npm installのみ
        "Bash(git init)",      // git initのみ
        "Bash(git add *)",     // git addのみ
        "Bash(git commit *)",  // git commitのみ
        
        // 組み込みツールを優先使用
        "LS",
        "Grep",
        "Glob"
      ],
      "security": {
        "preventParentDirAccess": true,
        "restrictToProjectDir": true,
        "blockExecutables": true
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