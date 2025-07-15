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
    
    return projectPath;
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