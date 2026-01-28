#!/bin/bash
# =============================================================================
# setup.sh - multi-agent-shogun セットアップスクリプト
# =============================================================================
# 初回インストール時に実行してください。
# - Claude Code のフック設定
# - 必要なディレクトリの作成
# - 依存パッケージの確認
#
# 使用方法:
#   ./setup.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 色付き出力
log_info() {
    echo -e "\033[1;33m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[OK]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;35m[WARN]\033[0m $1"
}

# バナー表示
show_banner() {
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║\033[0m  \033[1;33m🏯 multi-agent-shogun セットアップ\033[0m                          \033[1;31m║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
}

show_banner

# =============================================================================
# STEP 1: 依存パッケージの確認
# =============================================================================
log_info "依存パッケージを確認中..."

MISSING_DEPS=()

# tmux
if ! command -v tmux &> /dev/null; then
    MISSING_DEPS+=("tmux")
fi

# inotify-tools (ウォッチドッグ用)
if ! command -v inotifywait &> /dev/null; then
    MISSING_DEPS+=("inotify-tools")
fi

# yq (YAML処理用、オプション)
if ! command -v yq &> /dev/null; then
    log_warn "yq が見つかりません（オプション）。一部機能が制限されます。"
fi

# Claude Code
if ! command -v claude &> /dev/null; then
    MISSING_DEPS+=("claude (Claude Code CLI)")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    log_error "以下のパッケージがインストールされていません:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "インストール方法:"
    echo "  sudo apt update && sudo apt install -y tmux inotify-tools"
    echo "  npm install -g @anthropic-ai/claude-code"
    echo ""

    read -p "続行しますか？ (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    log_success "依存パッケージ: OK"
fi

# =============================================================================
# STEP 2: ディレクトリ構造の作成
# =============================================================================
log_info "ディレクトリ構造を作成中..."

# 必要なディレクトリ
DIRS=(
    "queue/tasks"
    "queue/reports"
    "queue/research"
    "status"
    "logs"
    "memory"
    "context"
    "output"
    ".claude"
)

for dir in "${DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "  作成: $dir/"
    fi
done

log_success "ディレクトリ構造: OK"

# =============================================================================
# STEP 3: 初期ファイルの作成
# =============================================================================
log_info "初期ファイルを作成中..."

# 足軽用タスクファイル
for i in {1..8}; do
    TASK_FILE="queue/tasks/ashigaru${i}.yaml"
    if [[ ! -f "$TASK_FILE" ]]; then
        cat > "$TASK_FILE" << EOF
task:
  task_id: null
  parent_cmd: null
  description: null
  target_path: null
  status: idle
  timestamp: ""
EOF
        log_info "  作成: $TASK_FILE"
    fi
done

# 足軽用報告ファイル
for i in {1..8}; do
    REPORT_FILE="queue/reports/ashigaru${i}_report.yaml"
    if [[ ! -f "$REPORT_FILE" ]]; then
        cat > "$REPORT_FILE" << EOF
worker_id: ashigaru${i}
task_id: null
timestamp: ""
status: idle
result: null
EOF
        log_info "  作成: $REPORT_FILE"
    fi
done

# 参謀用タスクファイル
SANBO_TASK="queue/tasks/sanbo.yaml"
if [[ ! -f "$SANBO_TASK" ]]; then
    cat > "$SANBO_TASK" << EOF
task:
  task_id: null
  parent_cmd: null
  type: null
  target_project: null
  target_path: null
  test_command: null
  additional_commands: []
  timestamp: ""
  status: idle
EOF
    log_info "  作成: $SANBO_TASK"
fi

# 参謀用報告ファイル
SANBO_REPORT="queue/reports/sanbo_report.yaml"
if [[ ! -f "$SANBO_REPORT" ]]; then
    cat > "$SANBO_REPORT" << EOF
task_id: null
parent_cmd: null
timestamp: ""
status: idle
verification_type: null
results:
  tests:
    total: 0
    passed: 0
    failed: 0
    skipped: 0
  coverage:
    line: 0
    branch: 0
  lint:
    errors: 0
    warnings: 0
issues: []
recommendation: null
skill_candidate:
  name: null
  reason: null
EOF
    log_info "  作成: $SANBO_REPORT"
fi

# 将軍→家老キュー
SHOGUN_QUEUE="queue/shogun_to_karo.yaml"
if [[ ! -f "$SHOGUN_QUEUE" ]]; then
    echo 'queue: []' > "$SHOGUN_QUEUE"
    log_info "  作成: $SHOGUN_QUEUE"
fi

# マスターステータス
MASTER_STATUS="status/master_status.yaml"
if [[ ! -f "$MASTER_STATUS" ]]; then
    cat > "$MASTER_STATUS" << EOF
last_updated: ""
active_project: null
agents:
  shogun: idle
  karo: idle
  ashigaru1: idle
  ashigaru2: idle
  ashigaru3: idle
  ashigaru4: idle
  ashigaru5: idle
  ashigaru6: idle
  ashigaru7: idle
  ashigaru8: idle
  sanbo: idle
EOF
    log_info "  作成: $MASTER_STATUS"
fi

log_success "初期ファイル: OK"

# =============================================================================
# STEP 4: Claude Code フック設定
# =============================================================================
log_info "Claude Code フック設定を作成中..."

CLAUDE_SETTINGS=".claude/settings.json"
CREATE_HOOKS=false

# 既存の設定があれば確認
if [[ -f "$CLAUDE_SETTINGS" ]]; then
    log_warn "既存の設定ファイルが見つかりました: $CLAUDE_SETTINGS"
    read -p "上書きしますか？ (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CREATE_HOOKS=true
    else
        log_info "フック設定をスキップしました"
    fi
else
    CREATE_HOOKS=true
fi

if [[ "$CREATE_HOOKS" == "true" ]]; then
    cat > "$CLAUDE_SETTINGS" << 'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": ["./extensions/hooks/permission-guard.sh"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": ["./extensions/hooks/post-task-report.sh"]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Read",
      "Write", 
      "Edit",
      "Bash",
      "Glob",
      "Grep"
    ]
  }
}
EOF
    log_success "フック設定を作成しました: $CLAUDE_SETTINGS"
fi

# =============================================================================
# STEP 5: 設定ファイルの確認
# =============================================================================
log_info "設定ファイルを確認中..."

# config/settings.yaml
if [[ ! -f "config/settings.yaml" ]]; then
    cat > "config/settings.yaml" << 'EOF'
# multi-agent-shogun 設定ファイル
language: ja  # ja, en, es, zh, ko, fr, de 等

# スクリーンショットの保存場所
screenshot_path: "/tmp/screenshots"

# Claude モデル設定
models:
  shogun: opus
  karo: sonnet
  ashigaru: sonnet
  sanbo: sonnet
EOF
    log_info "  作成: config/settings.yaml"
fi

log_success "設定ファイル: OK"

# =============================================================================
# STEP 6: 実行権限の確認
# =============================================================================
log_info "スクリプトの実行権限を確認中..."

SCRIPTS=(
    "shutsujin_departure.sh"
    "extensions/hooks/role-detector.sh"
    "extensions/hooks/post-task-report.sh"
    "extensions/hooks/permission-guard.sh"
    "extensions/scripts/watchdog.sh"
    "extensions/scripts/agent-status.sh"
    "extensions/scripts/inject-project-rules.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" && ! -x "$script" ]]; then
        chmod +x "$script"
        log_info "  実行権限付与: $script"
    fi
done

log_success "実行権限: OK"

# =============================================================================
# 完了
# =============================================================================
echo ""
echo -e "\033[1;32m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;32m║\033[0m  \033[1;37m✅ セットアップ完了！\033[0m                                      \033[1;32m║\033[0m"
echo -e "\033[1;32m╚══════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo "次のステップ:"
echo ""
echo "  1. 出陣（全エージェント起動）:"
echo "     ./shutsujin_departure.sh"
echo ""
echo "  2. ウォッチドッグ付きで出陣:"
echo "     ./shutsujin_departure.sh -w"
echo ""
echo "  3. 将軍の本陣にアタッチ:"
echo "     tmux attach-session -t shogun"
echo ""
echo "  4. エージェント状態確認:"
echo "     ./extensions/scripts/agent-status.sh"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  天下布武！準備完了！"
echo "════════════════════════════════════════════════════════════════"
echo ""
