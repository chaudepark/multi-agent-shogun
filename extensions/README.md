# multi-agent-shogun 拡張機能

このディレクトリには、multi-agent-shogun の独自拡張機能が含まれています。

## ディレクトリ構成

```
extensions/
├── README.md                    # このファイル
├── hooks/                       # Claude Code フック
│   ├── role-detector.sh         # ロール判定スクリプト
│   ├── post-task-report.sh      # 報告自動化フック
│   └── permission-guard.sh      # 権限制御フック
├── policies/                    # ロール別ポリシー
│   └── sanbo-policy.md          # 参謀の詳細ポリシー
├── scripts/                     # ユーティリティスクリプト
│   └── inject-project-rules.sh  # プロジェクトルール取り込み
└── templates/
    └── settings.local.json.template
```

## 拡張機能一覧

### 1. ロール判定（role-detector.sh）
tmuxペイン名からエージェントのロール（shogun/karo/ashigaru/sanbo）を判定します。

### 2. 報告自動化（post-task-report.sh）
足軽がタスク完了報告を書き込んだ際、自動的に家老に通知を送ります。

### 3. 権限制御（permission-guard.sh）
各ロールに応じたツール使用制限を実施します。

### 4. 参謀ロール
テスト実行専門のエージェントを追加します。

### 5. プロジェクトルール取り込み
対象プロジェクトの CLAUDE.md や設定ファイルを自動読み込みします。

## upstream 追従について

このリポジトリは fork 構成で運用されています：

- `main` ブランチ: upstream 追従用（変更しない）
- `sarai/main` ブランチ: 独自拡張を含む作業ブランチ

upstream の更新を取り込む際は：

```bash
git fetch upstream
git checkout main
git merge upstream/main
git checkout sarai/main
git rebase main
```
