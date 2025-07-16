# Nostr Claude Bot - Docker Setup Guide

完全にクリーンな状態から nostr-claude-bot を Docker で安全に実行するためのガイドです。

## 🚀 クイックスタート

### 1. 完全セットアップ（推奨）
```bash
./setup-from-scratch.sh
```
このスクリプトは以下を自動で行います：
- Docker のインストール（必要な場合）
- ユーザーの Docker グループへの追加
- Docker サービスの開始
- 既存のコンテナ/イメージのクリーンアップ
- .env ファイルの作成
- Docker イメージのビルド
- コンテナの起動

### 2. 既に Docker がある場合
```bash
./quick-start.sh
```

### 3. クリーンアップ
```bash
./cleanup-docker.sh
```

## 📋 必要な設定

### .env ファイルの設定
スクリプト実行後、`.env` ファイルを編集して以下を設定してください：

```env
# あなたの Nostr 秘密鍵（64文字の16進数文字列）
NOSTR_PRIVATE_KEY=your_actual_private_key_here

# 使用する Nostr リレーのURL（カンマ区切り）
NOSTR_RELAYS=wss://relay.damus.io,wss://nos.lol,wss://relay.nostr.band

# 生成されたプロジェクトの保存場所
PROJECT_BASE_PATH=./generated-projects

# 同時実行可能なプロジェクト数
MAX_CONCURRENT_PROJECTS=5
```

### Nostr 秘密鍵の生成方法
```bash
# コマンドラインで生成
openssl rand -hex 32

# または以下のサイトを使用
# https://nostrtool.com/
```

## 🔧 使用方法

### 基本操作
```bash
# ログを確認
docker logs -f nostr-claude-bot-simple

# コンテナを停止
docker stop nostr-claude-bot-simple

# コンテナを開始
docker start nostr-claude-bot-simple

# コンテナを削除
docker rm -f nostr-claude-bot-simple
```

### 再起動/再ビルド
```bash
# 完全に再セットアップ
./cleanup-docker.sh
./setup-from-scratch.sh

# または単純に再起動
./quick-start.sh
```

## 🛡️ セキュリティ機能

- **非rootユーザー実行**: コンテナ内で非特権ユーザーとして実行
- **読み取り専用マウント**: .env ファイルは読み取り専用でマウント
- **分離された環境**: Docker による完全な環境分離
- **リソース制限**: メモリとCPU使用量の制限
- **ネットワーク分離**: 独立したDockerネットワーク

## 📁 ディレクトリ構成

```
nostr-claude-bot/
├── setup-from-scratch.sh    # 完全セットアップスクリプト
├── quick-start.sh           # クイックスタートスクリプト
├── cleanup-docker.sh        # クリーンアップスクリプト
├── Dockerfile.simple        # シンプルなDockerfile
├── .env.example            # 設定ファイルテンプレート
├── .env                    # 実際の設定ファイル（作成後）
├── generated-projects/     # 生成されたプロジェクト
└── logs/                   # ログファイル
```

## 🔍 トラブルシューティング

### Docker 権限エラー
```bash
# ユーザーを docker グループに追加
sudo usermod -aG docker $USER

# 新しいシェルを開始
newgrp docker

# または一度ログアウト/ログインしてください
```

### コンテナが起動しない
```bash
# ログを確認
docker logs nostr-claude-bot-simple

# .env ファイルを確認
cat .env

# 完全クリーンアップ後に再実行
./cleanup-docker.sh
./setup-from-scratch.sh
```

### ポート/ネットワークエラー
```bash
# 使用されていないDockerリソースをクリーンアップ
docker system prune -a

# ネットワークをリセット
docker network prune -f
```

## ⚠️ 重要な注意事項

1. **秘密鍵の管理**: `.env` ファイルの秘密鍵は絶対に公開しないでください
2. **Claude CLI**: 現在の設定では Claude CLI はコンテナ内で使用できません
3. **リレー接続**: インターネット接続が必要です
4. **ログの確認**: 定期的にログを確認してエラーがないか確認してください

## 🔄 アップデート

```bash
# 最新コードを取得
git pull

# 再ビルド
./cleanup-docker.sh
./setup-from-scratch.sh
```

## 📞 サポート

問題が発生した場合は、以下の情報を含めてご連絡ください：
- 実行したスクリプト
- エラーメッセージ
- `docker logs nostr-claude-bot-simple` の出力
- 使用している OS とバージョン