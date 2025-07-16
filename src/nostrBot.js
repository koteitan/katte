const { SimplePool, nip19, getPublicKey } = require('nostr-tools');
const { SecurityManager } = require('./security');
const { ErrorHandler } = require('./errorHandler');

class NostrBot {
  constructor({ privateKey, relays, claudeClient, projectManager }) {
    // nsec形式の場合はhexに変換
    if (privateKey.startsWith('nsec1')) {
      this.privateKey = nip19.decode(privateKey).data;
    } else {
      this.privateKey = privateKey;
    }
    this.publicKey = getPublicKey(this.privateKey);
    this.relays = relays;
    this.claudeClient = claudeClient;
    this.projectManager = projectManager;
    this.pool = new SimplePool();
    this.activeProjects = new Map();
    this.security = new SecurityManager();
    this.errorHandler = new ErrorHandler();
    
    // 定期的に古いエラーをクリーンアップ
    setInterval(() => {
      this.errorHandler.clearOldErrors();
    }, 3600000); // 1時間ごと
  }

  async start() {
    console.log('Connecting to relays:', this.relays);
    
    const sub = this.pool.subscribeMany(
      this.relays,
      [
        {
          kinds: [1],
          since: Math.floor(Date.now() / 1000),
        }
      ],
      {
        onevent: async (event) => {
          console.log('Received event:', event.id, 'from', event.pubkey.slice(0, 8), ':', event.content);
          await this.handleEvent(event);
        },
        oneose: () => {
          console.log('End of stored events');
        }
      }
    );

    process.on('SIGINT', () => {
      sub.close();
      this.pool.close(this.relays);
      process.exit(0);
    });
  }

  async handleEvent(event) {
    const content = event.content;
    
    // 様々なパターンに対応
    const patterns = [
      /(.+?)作りたい/,      // ○○作りたい
      /(.+?)ほしい/,        // ○○ほしい
      /(.+?)欲しい/,        // ○○欲しい
      /(.+?)が欲しい/,      // ○○が欲しい
      /(.+?)がほしい/,      // ○○がほしい
      /(.+?)を作って/,      // ○○を作って
      /(.+?)作って/,        // ○○作って
      /(.+?)を実装して/,    // ○○を実装して
      /(.+?)実装して/,      // ○○実装して
      /(.+?)を生成して/,    // ○○を生成して
      /(.+?)生成して/,      // ○○生成して
    ];
    
    let projectMatch = null;
    for (const pattern of patterns) {
      projectMatch = content.match(pattern);
      if (projectMatch) break;
    }
    
    if (!projectMatch) return;

    const projectIdea = projectMatch[1];
    const eventId = event.id;
    const pubkey = event.pubkey;
    
    // 重複チェック
    if (this.activeProjects.has(eventId)) return;
    
    // ブラックリストチェック
    if (this.security.isUserBlacklisted(pubkey)) {
      console.log(`Blocked request from blacklisted user: ${pubkey}`);
      return;
    }
    
    // レート制限チェック
    const rateCheck = this.security.checkRateLimit(pubkey);
    if (!rateCheck.allowed) {
      console.log(`Rate limit exceeded for ${pubkey}: ${rateCheck.reason}`);
      return;
    }
    
    // 入力検証
    const validation = this.security.validateProjectIdea(projectIdea);
    if (!validation.valid) {
      console.log(`Invalid project idea from ${pubkey}: ${validation.reason}`);
      return;
    }
    
    console.log(`Detected project request: "${projectIdea}" from ${pubkey.slice(0, 8)}...`);
    
    this.activeProjects.set(eventId, true);
    
    try {
      await this.replyToEvent(event, `プロジェクト「${validation.sanitized}」を作成開始します！`);
      
      const projectPath = await this.projectManager.createProject(validation.sanitized);
      
      // パス検証
      if (!this.security.validateProjectPath(projectPath)) {
        throw new Error('Invalid project path');
      }
      
      const claudeResponse = await this.claudeClient.generateProject(
        validation.sanitized, 
        projectPath,
        this.security.createSafeExecutionEnvironment()
      );
      
      await this.replyToEvent(event, `プロジェクト「${validation.sanitized}」の作成が完了しました！\n\nパス: ${projectPath}\n\n${claudeResponse}`);
      
    } catch (error) {
      console.error('Error creating project:', error);
      
      // エラーを記録
      const errorCount = this.errorHandler.recordError(pubkey, error);
      
      // エラーが頻発する場合はブラックリストに追加
      if (this.errorHandler.shouldBlockUser(pubkey)) {
        this.security.addToBlacklist(pubkey, 'Too many errors');
      }
      
      // エラーメッセージは送信せず、ログに記録のみ
      console.log(`Project creation failed for ${pubkey}: ${error.message}`);
    } finally {
      this.activeProjects.delete(eventId);
    }
  }

  async replyToEvent(originalEvent, content) {
    const replyEvent = {
      kind: 1,
      pubkey: this.publicKey,
      created_at: Math.floor(Date.now() / 1000),
      tags: [
        ['e', originalEvent.id],
        ['p', originalEvent.pubkey]
      ],
      content: content
    };

    const signedEvent = await this.signEvent(replyEvent);
    await this.pool.publish(this.relays, signedEvent);
  }

  async signEvent(event) {
    const { sig, id } = await require('nostr-tools').finalizeEvent(event, this.privateKey);
    return { ...event, sig, id };
  }
}

module.exports = { NostrBot };
