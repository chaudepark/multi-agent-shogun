#!/bin/bash
# =============================================================================
# permission-guard.sh - 権限制御フック（PreToolUse Hook用）
# =============================================================================
# 各ロールに応じたツール使用制限を実施する
#
# Claude Code の .claude/settings.json に以下を追加して使用:
# {
#   "hooks": {
#     "PreToolUse": [
#       {
#         "matcher": "*",
#         "hooks": ["./extensions/hooks/permission-guard.sh"]
#       }
#     ]
#   }
# }
#
# 環境変数（Claude Code から渡される）:
#   CLAUDE_TOOL_NAME: 使用されようとしているツール名
#   CLAUDE_TOOL_INPUT: ツールの入力（JSON）
#
# 終了コード:
#   0: 許可
#   非0: 拒否（標準エラー出力にメッセージ）
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ロール判定
ROLE=$("$SCRIPT_DIR/role-detector.sh" 2>/dev/null || echo "unknown")

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# ツール名が空なら許可（判定できない）
if [[ -z "$TOOL_NAME" ]]; then
    exit 0
fi

# -----------------------------------------------------------------------------
# 権限チェック関数
# -----------------------------------------------------------------------------

# 将軍の権限チェック
check_shogun_permission() {
    local tool="$1"
    local input="$2"

    # 将軍は読み取り系のみ許可
    case "$tool" in
        Read|Glob|Grep|WebFetch|WebSearch)
            return 0  # 許可
            ;;
        Write|Edit)
            # queue/shogun_to_karo.yaml への書き込みのみ許可
            local file_path=$(echo "$input" | jq -r '.file_path // empty' 2>/dev/null || echo "")
            if [[ "$file_path" =~ queue/shogun_to_karo\.yaml$ ]]; then
                return 0
            fi
            # dashboard.md の読み取りは Read で行うべき
            echo "将軍は直接ファイルを編集できません。家老に指示を出してください。" >&2
            return 1
            ;;
        Bash)
            # tmux send-keys と git 系コマンドのみ許可
            local command=$(echo "$input" | jq -r '.command // empty' 2>/dev/null || echo "")
            if [[ "$command" =~ ^tmux\ (send-keys|display-message|capture-pane|list-) ]]; then
                return 0
            fi
            if [[ "$command" =~ ^git\ (status|log|diff|branch) ]]; then
                return 0
            fi
            echo "将軍はコマンド実行を控えるべきです: $command" >&2
            return 1
            ;;
        Task)
            return 0  # エージェント起動は許可
            ;;
        *)
            return 0  # その他は許可（安全側に倒す）
            ;;
    esac
}

# 家老の権限チェック
check_karo_permission() {
    local tool="$1"
    local input="$2"

    case "$tool" in
        Read|Glob|Grep|WebFetch|WebSearch)
            return 0
            ;;
        Write|Edit)
            local file_path=$(echo "$input" | jq -r '.file_path // empty' 2>/dev/null || echo "")
            # 許可されるパス
            if [[ "$file_path" =~ ^(queue/|status/|dashboard\.md|config/) ]]; then
                return 0
            fi
            echo "家老はキュー、ステータス、ダッシュボード以外を編集できません: $file_path" >&2
            return 1
            ;;
        Bash)
            local command=$(echo "$input" | jq -r '.command // empty' 2>/dev/null || echo "")
            # テスト実行は禁止（参謀の仕事）
            if [[ "$command" =~ (npm\ test|pytest|cargo\ test|jest|vitest|go\ test) ]]; then
                echo "家老はテスト実行できません。参謀に委譲してください。" >&2
                return 1
            fi
            # tmux 操作は許可
            if [[ "$command" =~ ^tmux ]]; then
                return 0
            fi
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# 足軽の権限チェック
check_ashigaru_permission() {
    local tool="$1"
    local input="$2"

    # 基本的に全ツール許可
    # ただし、他の足軽の領域は禁止

    case "$tool" in
        Write|Edit)
            local file_path=$(echo "$input" | jq -r '.file_path // empty' 2>/dev/null || echo "")
            # 他の足軽の報告ファイルへの書き込みは禁止
            if [[ "$file_path" =~ queue/reports/ashigaru[0-9]+_report\.yaml$ ]]; then
                # 自分の番号を取得（ペイン名から）
                local pane_title=$(tmux display-message -p '#T' 2>/dev/null || echo "")
                local my_num=$(echo "$pane_title" | grep -oE '[0-9]+' || echo "")
                local file_num=$(echo "$file_path" | grep -oE 'ashigaru([0-9]+)' | grep -oE '[0-9]+')

                if [[ -n "$my_num" && -n "$file_num" && "$my_num" != "$file_num" ]]; then
                    echo "他の足軽の報告ファイルは編集できません: $file_path" >&2
                    return 1
                fi
            fi
            return 0
            ;;
        Bash)
            local command=$(echo "$input" | jq -r '.command // empty' 2>/dev/null || echo "")
            # 他のペインへの send-keys は禁止（割り込み防止）
            if [[ "$command" =~ tmux\ send-keys\ -t ]]; then
                # 家老への報告は post-task-report.sh 経由で行う
                echo "足軽は直接 send-keys できません。報告ファイルに書いてください。" >&2
                return 1
            fi
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# 参謀の権限チェック
check_sanbo_permission() {
    local tool="$1"
    local input="$2"

    case "$tool" in
        Read|Glob|Grep|WebFetch|WebSearch)
            return 0
            ;;
        Write|Edit)
            # 参謀はコードを編集しない
            local file_path=$(echo "$input" | jq -r '.file_path // empty' 2>/dev/null || echo "")
            # テスト結果レポートへの書き込みは許可
            if [[ "$file_path" =~ (test-results|coverage|reports?) ]]; then
                return 0
            fi
            # queue への書き込みは許可
            if [[ "$file_path" =~ ^queue/ ]]; then
                return 0
            fi
            echo "参謀はソースコードを編集できません。テストと検証のみ行ってください: $file_path" >&2
            return 1
            ;;
        Bash)
            local command=$(echo "$input" | jq -r '.command // empty' 2>/dev/null || echo "")
            # テスト実行は許可
            if [[ "$command" =~ (npm\ test|pytest|cargo\ test|jest|vitest|go\ test|make\ test) ]]; then
                return 0
            fi
            # カバレッジ計測は許可
            if [[ "$command" =~ (coverage|nyc|istanbul) ]]; then
                return 0
            fi
            # lint/type-check は許可
            if [[ "$command" =~ (eslint|tsc|mypy|clippy|golangci-lint) ]]; then
                return 0
            fi
            # tmux 操作は許可
            if [[ "$command" =~ ^tmux ]]; then
                return 0
            fi
            # git read 系は許可
            if [[ "$command" =~ ^git\ (status|log|diff|show) ]]; then
                return 0
            fi
            # その他のコマンドは警告を出すが許可
            echo "[警告] 参謀がテスト以外のコマンドを実行: $command" >&2
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------

case "$ROLE" in
    shogun)
        check_shogun_permission "$TOOL_NAME" "$TOOL_INPUT"
        ;;
    karo)
        check_karo_permission "$TOOL_NAME" "$TOOL_INPUT"
        ;;
    ashigaru)
        check_ashigaru_permission "$TOOL_NAME" "$TOOL_INPUT"
        ;;
    sanbo)
        check_sanbo_permission "$TOOL_NAME" "$TOOL_INPUT"
        ;;
    *)
        # 不明なロールは許可（安全側に倒す）
        exit 0
        ;;
esac
