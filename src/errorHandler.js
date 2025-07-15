class ErrorHandler {
  constructor() {
    this.errorCounts = new Map();
    this.errorLog = [];
    this.maxErrorsPerUser = 5;
    this.errorWindow = 3600000; // 1時間
  }

  recordError(pubkey, error) {
    const now = Date.now();
    
    // エラーログに記録
    this.errorLog.push({
      pubkey,
      error: error.message,
      stack: error.stack,
      timestamp: now
    });
    
    // ユーザーごとのエラーカウント更新
    const userErrors = this.errorCounts.get(pubkey) || [];
    const recentErrors = userErrors.filter(time => now - time < this.errorWindow);
    recentErrors.push(now);
    this.errorCounts.set(pubkey, recentErrors);
    
    return recentErrors.length;
  }

  getErrorCount(pubkey) {
    const now = Date.now();
    const userErrors = this.errorCounts.get(pubkey) || [];
    return userErrors.filter(time => now - time < this.errorWindow).length;
  }

  shouldBlockUser(pubkey) {
    return this.getErrorCount(pubkey) >= this.maxErrorsPerUser;
  }

  formatErrorMessage(error) {
    // ユーザーに表示する安全なエラーメッセージ
    const safeErrors = {
      'Rate limit exceeded': 'リクエストが多すぎます。しばらくお待ちください。',
      'Invalid project idea': 'プロジェクトのアイデアが無効です。',
      'Project creation failed': 'プロジェクトの作成に失敗しました。',
      'Timeout': 'タイムアウトしました。もう一度お試しください。',
      'API error': 'APIエラーが発生しました。'
    };
    
    for (const [key, message] of Object.entries(safeErrors)) {
      if (error.message.includes(key)) {
        return message;
      }
    }
    
    return 'エラーが発生しました。';
  }

  getRecentErrors(minutes = 60) {
    const cutoff = Date.now() - (minutes * 60 * 1000);
    return this.errorLog.filter(log => log.timestamp > cutoff);
  }

  clearOldErrors() {
    const cutoff = Date.now() - (24 * 3600000); // 24時間
    this.errorLog = this.errorLog.filter(log => log.timestamp > cutoff);
    
    // 古いエラーカウントも削除
    for (const [pubkey, errors] of this.errorCounts.entries()) {
      const recentErrors = errors.filter(time => time > cutoff);
      if (recentErrors.length === 0) {
        this.errorCounts.delete(pubkey);
      } else {
        this.errorCounts.set(pubkey, recentErrors);
      }
    }
  }
}

module.exports = { ErrorHandler };