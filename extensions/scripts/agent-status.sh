#!/bin/bash
# =============================================================================
# agent-status.sh - エージェント状態確認スクリプト
# =============================================================================
# 全エージェントの状態を一覧表示する
#
# 使用方法:
#   ./agent-status.sh          # 全エージェントの状態を表示
#   ./agent-status.sh --json   # JSON形式で出力
#   ./agent-status.sh --wake   # アイドル状態のエージェントを起こす
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 色定義
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# エージェントの状態を判定
get_agent_status() {
    local target="$1"
    local output

    # tmux セッションが存在するか確認
    local session="${target%%:*}"
    if ! tmux has-session -t "$session" 2>/dev/null; then
        echo "not_running"
        return
    fi

    # ペインの内容を取得
    output=$(tmux capture-pane -t "$target" -p 2>/dev/null | tail -20)

    if [[ -z "$output" ]]; then
        echo "empty"
        return
    fi

    # 処理中のインジケータ
    if echo "$output" | grep -qE "(thinking|Esc to interrupt)"; then
        echo "thinking"
        return
    fi

    if echo "$output" | grep -qE "(Effecting|Boondoggling|Puzzling)"; then
        echo "working"
        return
    fi

    # プロンプト待ち（アイドル）
    if echo "$output" | grep -qE "^(❯|>|\$) *$"; then
        echo "idle_prompt"
        return
    fi

    # Claude のプロンプト待ち
    if echo "$output" | grep -qE "bypass permissions on"; then
        echo "idle_claude"
        return
    fi

    # 入力待ち
    if echo "$output" | grep -qE "\?\s*$"; then
        echo "waiting_input"
        return
    fi

    echo "unknown"
}

# 状態を色付きで表示
format_status() {
    local status="$1"

    case "$status" in
        thinking|working)
            echo -e "${GREEN}●${NC} $status"
            ;;
        idle_prompt|idle_claude)
            echo -e "${YELLOW}○${NC} idle"
            ;;
        waiting_input)
            echo -e "${CYAN}?${NC} waiting"
            ;;
        not_running)
            echo -e "${RED}✗${NC} not running"
            ;;
        *)
            echo -e "${BLUE}?${NC} $status"
            ;;
    esac
}

# 全エージェントの状態を表示
show_all_status() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  🏯 multi-agent-shogun エージェント状態${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    local agents=(
        "shogun:0.0|将軍|SHOGUN"
        "multiagent:0.0|家老|KARO"
        "multiagent:0.1|足軽1|ASHIGARU1"
        "multiagent:0.2|足軽2|ASHIGARU2"
        "multiagent:0.3|足軽3|ASHIGARU3"
        "multiagent:0.4|足軽4|ASHIGARU4"
        "multiagent:0.5|足軽5|ASHIGARU5"
        "multiagent:0.6|足軽6|ASHIGARU6"
        "multiagent:0.7|足軽7|ASHIGARU7"
        "multiagent:0.8|足軽8|ASHIGARU8"
        "sanbo:0.0|参謀|SANBO"
    )

    local idle_count=0
    local working_count=0
    local not_running_count=0

    echo -e "  ${YELLOW}役職${NC}      ${YELLOW}ターゲット${NC}         ${YELLOW}状態${NC}"
    echo "  ─────────────────────────────────────────"

    for agent_info in "${agents[@]}"; do
        IFS='|' read -r target name_ja name_en <<< "$agent_info"
        local status=$(get_agent_status "$target")
        local formatted=$(format_status "$status")

        printf "  %-8s  %-18s  %s\n" "$name_ja" "$target" "$formatted"

        case "$status" in
            idle_prompt|idle_claude)
                ((idle_count++))
                ;;
            thinking|working)
                ((working_count++))
                ;;
            not_running)
                ((not_running_count++))
                ;;
        esac
    done

    echo ""
    echo "  ─────────────────────────────────────────"
    echo -e "  ${GREEN}稼働中${NC}: $working_count  ${YELLOW}待機中${NC}: $idle_count  ${RED}停止${NC}: $not_running_count"
    echo ""

    # 報告ファイルの状態も表示
    echo -e "  ${CYAN}📋 報告ファイル状態${NC}"
    echo "  ─────────────────────────────────────────"

    for i in {1..8}; do
        local report_file="$PROJECT_ROOT/queue/reports/ashigaru${i}_report.yaml"
        if [[ -f "$report_file" ]]; then
            local status=$(grep -E "^status:" "$report_file" 2>/dev/null | head -1 | awk '{print $2}')
            local task_id=$(grep -E "^task_id:" "$report_file" 2>/dev/null | head -1 | awk '{print $2}')

            case "$status" in
                done)
                    echo -e "  足軽$i: ${GREEN}done${NC} (task: $task_id)"
                    ;;
                failed)
                    echo -e "  足軽$i: ${RED}failed${NC} (task: $task_id)"
                    ;;
                in_progress)
                    echo -e "  足軽$i: ${YELLOW}in_progress${NC} (task: $task_id)"
                    ;;
                idle|null)
                    echo -e "  足軽$i: ${BLUE}idle${NC}"
                    ;;
                *)
                    echo -e "  足軽$i: $status"
                    ;;
            esac
        fi
    done

    # 参謀の報告も確認
    local sanbo_report="$PROJECT_ROOT/queue/reports/sanbo_report.yaml"
    if [[ -f "$sanbo_report" ]]; then
        local status=$(grep -E "^status:" "$sanbo_report" 2>/dev/null | head -1 | awk '{print $2}')
        echo -e "  参謀 : ${BLUE}$status${NC}"
    fi

    echo ""
}

# JSON形式で出力
show_json() {
    local agents=(
        "shogun:0.0|shogun"
        "multiagent:0.0|karo"
        "multiagent:0.1|ashigaru1"
        "multiagent:0.2|ashigaru2"
        "multiagent:0.3|ashigaru3"
        "multiagent:0.4|ashigaru4"
        "multiagent:0.5|ashigaru5"
        "multiagent:0.6|ashigaru6"
        "multiagent:0.7|ashigaru7"
        "multiagent:0.8|ashigaru8"
        "sanbo:0.0|sanbo"
    )

    echo "{"
    echo '  "timestamp": "'$(date -Iseconds)'",'
    echo '  "agents": {'

    local first=true
    for agent_info in "${agents[@]}"; do
        IFS='|' read -r target name <<< "$agent_info"
        local status=$(get_agent_status "$target")

        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi

        echo -n "    \"$name\": {\"target\": \"$target\", \"status\": \"$status\"}"
    done

    echo ""
    echo "  }"
    echo "}"
}

# アイドル状態のエージェントを起こす
wake_idle_agents() {
    echo ""
    echo -e "${CYAN}アイドル状態のエージェントを起動中...${NC}"
    echo ""

    local woke_count=0

    # 家老がアイドルなら起こす
    local karo_status=$(get_agent_status "multiagent:0.0")
    if [[ "$karo_status" == "idle_prompt" || "$karo_status" == "idle_claude" ]]; then
        echo -e "  ${YELLOW}家老${NC} を起動中..."
        tmux send-keys -t multiagent:0.0 "起動確認。queue/shogun_to_karo.yaml と queue/reports/ を確認し、次のアクションを実行せよ。"
        sleep 0.5
        tmux send-keys -t multiagent:0.0 Enter
        ((woke_count++))
    fi

    # 足軽がアイドルで、タスクがあれば起こす
    for i in {1..8}; do
        local status=$(get_agent_status "multiagent:0.$i")
        local task_file="$PROJECT_ROOT/queue/tasks/ashigaru${i}.yaml"

        if [[ "$status" == "idle_prompt" || "$status" == "idle_claude" ]]; then
            # タスクファイルを確認
            if [[ -f "$task_file" ]]; then
                local task_status=$(grep -E "^  status:" "$task_file" 2>/dev/null | head -1 | awk '{print $2}')
                if [[ "$task_status" == "assigned" ]]; then
                    echo -e "  ${YELLOW}足軽$i${NC} を起動中（タスクあり）..."
                    tmux send-keys -t "multiagent:0.$i" "queue/tasks/ashigaru${i}.yaml にタスクがある。確認して即実行せよ。"
                    sleep 0.3
                    tmux send-keys -t "multiagent:0.$i" Enter
                    ((woke_count++))
                fi
            fi
        fi
    done

    # 参謀がアイドルで、タスクがあれば起こす
    local sanbo_status=$(get_agent_status "sanbo:0.0")
    if [[ "$sanbo_status" == "idle_prompt" || "$sanbo_status" == "idle_claude" ]]; then
        local sanbo_task="$PROJECT_ROOT/queue/tasks/sanbo.yaml"
        if [[ -f "$sanbo_task" ]]; then
            local task_status=$(grep -E "^  status:" "$sanbo_task" 2>/dev/null | head -1 | awk '{print $2}')
            if [[ "$task_status" == "assigned" ]]; then
                echo -e "  ${YELLOW}参謀${NC} を起動中（タスクあり）..."
                tmux send-keys -t sanbo:0.0 "queue/tasks/sanbo.yaml にタスクがある。確認して即実行せよ。"
                sleep 0.3
                tmux send-keys -t sanbo:0.0 Enter
                ((woke_count++))
            fi
        fi
    fi

    echo ""
    if [[ $woke_count -eq 0 ]]; then
        echo -e "  ${BLUE}起動が必要なエージェントはありませんでした${NC}"
    else
        echo -e "  ${GREEN}$woke_count 名のエージェントを起動しました${NC}"
    fi
    echo ""
}

# =============================================================================
# メイン処理
# =============================================================================

case "${1:-}" in
    --json)
        show_json
        ;;
    --wake)
        wake_idle_agents
        ;;
    --help|-h)
        cat << EOF
使用方法: $(basename "$0") [オプション]

オプション:
  --json    JSON形式で出力
  --wake    アイドル状態のエージェントを起こす
  --help    このヘルプを表示

例:
  $(basename "$0")          # 状態一覧を表示
  $(basename "$0") --wake   # アイドルなエージェントを起こす
EOF
        ;;
    "")
        show_all_status
        ;;
    *)
        echo "不明なオプション: $1"
        echo "$(basename "$0") --help でヘルプを表示"
        exit 1
        ;;
esac
