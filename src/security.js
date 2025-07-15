class SecurityManager {
  constructor() {
    this.rateLimiter = new Map();
    this.blacklist = new Set();
    this.maxRequestsPerHour = 10;
    this.maxProjectSize = 50 * 1024 * 1024; // 50MB
    this.allowedProjectTypes = [
      'webapp', 'api', 'cli-tool', 'library', 'game', 'bot', 
      'todo', 'calculator', 'converter', 'visualizer'
    ];
    this.bannedKeywords = [
      'virus', 'malware', 'hack', 'exploit', 'ddos', 'spam',
      'phishing', 'ransomware', 'trojan', 'backdoor'
    ];
  }

  checkRateLimit(pubkey) {
    const now = Date.now();
    const userHistory = this.rateLimiter.get(pubkey) || [];
    
    // 1時間以内のリクエストをフィルター
    const recentRequests = userHistory.filter(time => now - time < 3600000);
    
    if (recentRequests.length >= this.maxRequestsPerHour) {
      return { allowed: false, reason: 'Rate limit exceeded' };
    }
    
    recentRequests.push(now);
    this.rateLimiter.set(pubkey, recentRequests);
    
    return { allowed: true };
  }

  validateProjectIdea(idea) {
    // 長さチェック
    if (!idea || idea.length < 2 || idea.length > 100) {
      return { valid: false, reason: 'Project idea must be between 2-100 characters' };
    }
    
    // 禁止キーワードチェック
    const lowerIdea = idea.toLowerCase();
    for (const banned of this.bannedKeywords) {
      if (lowerIdea.includes(banned)) {
        return { valid: false, reason: `Contains banned keyword: ${banned}` };
      }
    }
    
    // 基本的なサニタイゼーション
    const sanitized = this.sanitizeInput(idea);
    if (sanitized !== idea) {
      return { valid: false, reason: 'Contains invalid characters' };
    }
    
    return { valid: true, sanitized };
  }

  sanitizeInput(input) {
    // 危険な文字を除去
    return input
      .replace(/[<>]/g, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '')
      .replace(/[\x00-\x1F\x7F]/g, '')
      .trim();
  }

  isUserBlacklisted(pubkey) {
    return this.blacklist.has(pubkey);
  }

  addToBlacklist(pubkey, reason) {
    this.blacklist.add(pubkey);
    console.log(`User ${pubkey} blacklisted: ${reason}`);
  }

  validateProjectPath(path) {
    // パストラバーサル攻撃を防ぐ
    if (path.includes('..') || path.includes('~')) {
      return false;
    }
    return true;
  }

  createSafeExecutionEnvironment() {
    return {
      timeout: 300000, // 5分のタイムアウト
      maxBuffer: 10 * 1024 * 1024, // 10MB
      env: {
        ...process.env,
        NODE_ENV: 'production',
        SAFE_MODE: 'true'
      }
    };
  }
}

module.exports = { SecurityManager };