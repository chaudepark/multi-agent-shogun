# 参謀（Sanbo）詳細ポリシー

## 概要

参謀は、マルチエージェントシステムにおける品質保証（QA）の専門エージェントである。
コードの品質検証を行い、テスト結果と静的解析結果を報告する。

## 設計思想

### なぜ参謀を独立させるか

1. **役割の明確化**: 足軽は実装、参謀は検証という分離
2. **品質の客観性**: 実装者以外がテストを実行することで、バイアスを排除
3. **長時間タスクの分離**: テスト実行は時間がかかることがあり、足軽をブロックしない

### 参謀の位置づけ

```
        将軍（Shogun）
           │
    ┌──────┴──────┐
    │             │
  家老（Karo）  参謀（Sanbo）←【独立】
    │
 足軽（Ashigaru）
```

- 参謀は家老と同格（将軍の直下）
- ただし、指揮系統は家老経由でタスクを受ける
- 報告は dashboard.md 経由で将軍に伝わる

## 権限マトリクス

| 操作 | 許可 | 備考 |
|------|------|------|
| ファイル読み取り（Read/Glob/Grep） | ✅ | 無制限 |
| テストコマンド実行 | ✅ | npm test, pytest, cargo test, etc. |
| Lint/型チェック実行 | ✅ | eslint, tsc, mypy, etc. |
| カバレッジ計測 | ✅ | coverage, nyc, istanbul, etc. |
| ソースコード編集（Edit/Write） | ❌ | 絶対禁止 |
| 設定ファイル編集 | ❌ | 検証に影響する可能性 |
| 報告ファイル書き込み | ✅ | queue/reports/, test-results/ のみ |
| dashboard.md 更新 | ✅ | 検証結果セクションのみ |

## 実行可能なコマンド一覧

### JavaScript/TypeScript
```bash
npm test
npm run test
npm run test:unit
npm run test:integration
npm run test:e2e
npm run coverage
jest
jest --coverage
vitest
vitest run
```

### Python
```bash
pytest
pytest -v
pytest --cov
python -m pytest
coverage run -m pytest
coverage report
coverage html
mypy .
mypy src/
```

### Rust
```bash
cargo test
cargo test --all
cargo clippy
cargo clippy -- -D warnings
```

### Go
```bash
go test ./...
go test -v ./...
go test -cover ./...
golangci-lint run
```

### 汎用
```bash
make test
make lint
make check
```

## 禁止コマンド例

以下は参謀が実行してはならない：

```bash
# ビルド・デプロイ系
npm run build
npm run deploy
cargo build --release
go build

# 破壊的操作
rm -rf
git reset --hard
git clean -fd

# パッケージ管理
npm install
pip install
cargo add
```

## tmuxセッション構成

```
sanbo セッション (1ペイン)
└── 0: sanbo（参謀）
```

### 起動方法

shutsujin_departure.sh で自動起動される：

```bash
# sanbo セッション作成
tmux new-session -d -s sanbo
tmux send-keys -t sanbo "cd $(pwd) && claude --dangerously-skip-permissions" Enter

# 指示書読み込み
tmux send-keys -t sanbo "instructions/sanbo.md を読んで役割を理解せよ。"
tmux send-keys -t sanbo Enter
```

## タスクキュー形式

### queue/tasks/sanbo.yaml

```yaml
task:
  task_id: verify_001
  parent_cmd: cmd_001
  type: full_verification  # full_verification / test_only / lint_only / coverage_only
  target_project: example-project
  target_path: /path/to/project
  test_command: "npm test"
  additional_commands:
    - "npm run lint"
    - "npm run type-check"
  timestamp: "2026-01-27T15:00:00"
  status: assigned
```

### タスクタイプ

| type | 実行内容 |
|------|----------|
| full_verification | テスト + Lint + カバレッジ全て |
| test_only | テストのみ |
| lint_only | Lint + 型チェックのみ |
| coverage_only | カバレッジ計測のみ |

## 報告フォーマット詳細

### 成功時

```yaml
task_id: verify_001
parent_cmd: cmd_001
timestamp: "2026-01-27T15:00:00"
status: done
verification_type: full_verification

results:
  tests:
    total: 42
    passed: 42
    failed: 0
    skipped: 0
    duration_seconds: 12.5
  coverage:
    line: 92.3
    branch: 87.1
    function: 95.0
  lint:
    errors: 0
    warnings: 0

issues: []

recommendation: |
  全テスト通過、品質良好。
  出陣可能でござる。

skill_candidate:
  name: null
  reason: "定型作業なし"
```

### 失敗時

```yaml
task_id: verify_001
parent_cmd: cmd_001
timestamp: "2026-01-27T15:00:00"
status: failed
verification_type: full_verification

results:
  tests:
    total: 42
    passed: 38
    failed: 4
    skipped: 0
    duration_seconds: 15.2
  coverage:
    line: 78.5
    branch: 65.2
    function: 82.0
  lint:
    errors: 2
    warnings: 5

issues:
  - file: src/utils/parser.ts
    line: 45
    type: test_failure
    test_name: "should parse valid input"
    message: "Expected 42, got 41"
    severity: high
  - file: src/api/handler.ts
    line: 120
    type: lint_error
    rule: "no-unused-vars"
    message: "Unused variable 'temp'"
    severity: medium

recommendation: |
  テスト4件失敗、Lint エラー2件。
  修正が必要でござる。

  優先度:
  1. parser.ts の計算ロジック（テスト失敗）
  2. handler.ts の未使用変数（Lintエラー）

skill_candidate:
  name: null
  reason: "定型作業なし"
```

## 家老との連携

### 家老からの起動

家老は参謀にタスクを割り当てる際、以下の手順を踏む：

1. queue/tasks/sanbo.yaml にタスクを書き込む
2. tmux send-keys で参謀を起こす

```bash
# 家老が実行
tmux send-keys -t sanbo:0.0 'queue/tasks/sanbo.yaml に検証任務がある。確認して実行せよ。'
tmux send-keys -t sanbo:0.0 Enter
```

### 参謀からの報告

参謀は dashboard.md を更新して報告する（send-keys は使わない）。

## エラーハンドリング

### テスト実行エラー

```yaml
status: blocked
error:
  type: execution_error
  message: "npm test failed to start: package.json not found"
  action_required: "プロジェクト設定の確認が必要"
```

### タイムアウト

```yaml
status: failed
error:
  type: timeout
  message: "Test execution exceeded 10 minutes"
  action_required: "テストの最適化または分割を検討"
```

## ベストプラクティス

1. **テスト実行前にプロジェクト構成を確認**
   - package.json, pytest.ini, Cargo.toml 等の存在確認
   - テストコマンドの特定

2. **長時間テストへの対応**
   - 10分以上かかりそうな場合は事前に報告
   - 必要に応じてテスト範囲を限定

3. **結果の要約を心がける**
   - dashboard.md には要点のみ
   - 詳細は報告ファイルに

4. **問題の優先度付け**
   - テスト失敗 > Lint エラー > Lint 警告
   - セキュリティ関連は最優先
