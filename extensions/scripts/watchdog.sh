#!/bin/bash
# =============================================================================
# watchdog.sh - エージェント監視・自動再起動スクリプト
# =============================================================================
# 報告ファイルの変更を監視し、家老を自動的に起こす
# inotifywait を使用してイベント駆動で動作（ポーリングなし）
#
# 使用方法:
#   ./watchdog.sh              # フォアグラウンドで実行
#   ./watchdog.sh --daemon     # バックグラウンドで実行
#   ./watchdog.sh --stop       # 停止
#   ./watchdog.sh --status     # 状態確認
#
# 依存:
#   - inotify-tools (sudo apt install inotify-tools)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PID_FILE="$PROJECT_ROOT/.watchdog.pid"
LOG_FILE="$PROJECT_ROOT/logs/watchdog.log"

# 色付き出力
log_info() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[1;33m[$timestamp] [INFO]\033[0m $1"
    echo "[$timestamp] [INFO] $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_success() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[1;32m[$timestamp] [OK]\033[0m $1"
    echo "[$timestamp] [OK] $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[1;31m[$timestamp] [ERROR]\033[0m $1" >&2
    echo "[$timestamp] [ERROR] $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_watch() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[1;36m[$timestamp] [WATCH]\033[0m $1"
    echo "[$timestamp] [WATCH] $1" >> "$LOG_FILE" 2>/dev/null || true
}

# ログディレクトリ作成
mkdir -p "$PROJECT_ROOT/logs"

# ヘルプ表示
show_help() {
    cat << EOF
使用方法: $(basename "$0") [オプション]

オプション:
  --daemon        バックグラウンドで実行
  --stop          実行中のウォッチドッグを停止
  --status        状態確認
  --help          このヘルプを表示

動作:
  - queue/reports/ ディレクトリを監視
  - 報告ファイルが更新されたら家老を起こす
  - 家老が応答しない場合は将軍に通知

依存パッケージ:
  sudo apt install inotify-tools
EOF
}

# inotifywait の存在確認
check_dependencies() {
    if ! command -v inotifywait &> /dev/null; then
        log_error "inotifywait が見つかりません"
        log_error "インストール: sudo apt install inotify-tools"
        exit 1
    fi
}

# tmux セッションの存在確認
check_tmux_sessions() {
    local missing=()

    for session in shogun multiagent sanbo; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            missing+=("$session")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "tmux セッションが見つかりません: ${missing[*]}"
        log_error "先に shutsujin_departure.sh を実行してください"
        return 1
    fi

    return 0
}

# 家老が処理中かどうか確認
is_karo_busy() {
    local output=$(tmux capture-pane -t multiagent:0.0 -p 2>/dev/null | tail -10)

    # 処理中のインジケータ
    if echo "$output" | grep -qE "(thinking|Esc to interrupt|Effecting|Boondoggling|Puzzling)"; then
        return 0  # busy
    fi

    return 1  # idle
}

# 家老を起こす
wake_karo() {
    local reason="$1"

    log_watch "家老を起こします: $reason"

    # 家老が処理中なら待機
    if is_karo_busy; then
        log_info "家老は処理中。起動をスキップ"
        return 0
    fi

    # send-keys で起こす（2回に分ける）
    tmux send-keys -t multiagent:0.0 "報告ファイルが更新された。queue/reports/ を確認し、dashboard.md を更新せよ。"
    sleep 0.5
    tmux send-keys -t multiagent:0.0 Enter

    log_success "家老を起動しました"
}

# 報告ファイルの内容を確認
check_report_status() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    local status=$(grep -E "^status:" "$file" 2>/dev/null | head -1 | awk '{print $2}')

    case "$status" in
        done|completed|completed_partial|failed|blocked)
            return 0  # 要対応
            ;;
        in_progress|assigned|pending)
            return 1  # 対応不要（作業中）
            ;;
        *)
            # 不明なステータスも念のため要対応とする
            log_info "不明なステータス: $status ($(basename "$file"))"
            return 0
            ;;
    esac
}

# メインの監視ループ
watch_loop() {
    local watch_dir="$PROJECT_ROOT/queue/reports"

    log_info "ウォッチドッグ起動"
    log_info "監視ディレクトリ: $watch_dir"

    # ディレクトリ存在確認
    if [[ ! -d "$watch_dir" ]]; then
        log_error "監視ディレクトリが存在しません: $watch_dir"
        exit 1
    fi

    # inotifywait で監視
    inotifywait -m -e close_write,moved_to "$watch_dir" --format '%w%f' 2>/dev/null | while read -r file; do
        # YAML ファイルのみ対象
        if [[ ! "$file" =~ \.yaml$ ]]; then
            continue
        fi

        log_watch "ファイル変更検知: $(basename "$file")"

        # 報告のステータスを確認
        if check_report_status "$file"; then
            # 少し待ってから起こす（書き込み完了を待つ）
            sleep 1
            wake_karo "$(basename "$file") が更新された"
        else
            log_info "ステータスが要対応ではない。スキップ"
        fi
    done
}

# デーモンとして起動
start_daemon() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_error "ウォッチドッグは既に実行中です (PID: $pid)"
            exit 1
        fi
    fi

    log_info "デーモンモードで起動中..."

    nohup "$0" > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    log_success "ウォッチドッグを起動しました (PID: $pid)"
    log_info "ログ: $LOG_FILE"
}

# デーモン停止
stop_daemon() {
    if [[ ! -f "$PID_FILE" ]]; then
        log_error "ウォッチドッグは実行されていません"
        exit 1
    fi

    local pid=$(cat "$PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        rm -f "$PID_FILE"
        log_success "ウォッチドッグを停止しました (PID: $pid)"
    else
        log_error "プロセスが見つかりません (PID: $pid)"
        rm -f "$PID_FILE"
    fi
}

# 状態確認
show_status() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_success "ウォッチドッグは実行中です (PID: $pid)"
            echo ""
            echo "最新のログ:"
            tail -10 "$LOG_FILE" 2>/dev/null || echo "(ログなし)"
            return 0
        fi
    fi

    log_info "ウォッチドッグは実行されていません"
    return 1
}

# =============================================================================
# メイン処理
# =============================================================================

case "${1:-}" in
    --daemon)
        check_dependencies
        check_tmux_sessions || exit 1
        start_daemon
        ;;
    --stop)
        stop_daemon
        ;;
    --status)
        show_status
        ;;
    --help|-h)
        show_help
        ;;
    "")
        check_dependencies
        check_tmux_sessions || exit 1
        watch_loop
        ;;
    *)
        log_error "不明なオプション: $1"
        show_help
        exit 1
        ;;
esac
