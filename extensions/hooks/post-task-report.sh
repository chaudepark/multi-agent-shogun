#!/bin/bash
# =============================================================================
# post-task-report.sh - 報告自動化フック（PostToolUse Hook用）
# =============================================================================
# 足軽がタスク完了報告を書き込んだ際、自動的に家老に通知を送る
#
# Claude Code の .claude/settings.json に以下を追加して使用:
# {
#   "hooks": {
#     "PostToolUse": [
#       {
#         "matcher": "Write",
#         "hooks": ["./extensions/hooks/post-task-report.sh"]
#       }
#     ]
#   }
# }
#
# 環境変数（Claude Code から渡される）:
#   CLAUDE_TOOL_NAME: 使用されたツール名
#   CLAUDE_TOOL_INPUT: ツールの入力（JSON）
#   CLAUDE_TOOL_OUTPUT: ツールの出力
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ロール判定
ROLE=$("$SCRIPT_DIR/role-detector.sh" 2>/dev/null || echo "unknown")

# 足軽以外は何もしない
if [[ "$ROLE" != "ashigaru" ]]; then
    exit 0
fi

# Write ツール以外は何もしない
if [[ "${CLAUDE_TOOL_NAME:-}" != "Write" ]]; then
    exit 0
fi

# ツール入力からファイルパスを取得
FILE_PATH=$(echo "${CLAUDE_TOOL_INPUT:-}" | jq -r '.file_path // empty' 2>/dev/null || echo "")

# 報告ファイルパターンにマッチするか確認
if [[ ! "$FILE_PATH" =~ queue/reports/ashigaru[0-9]+_report\.yaml$ ]]; then
    exit 0
fi

# 報告ファイルが存在するか確認
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# ステータスを確認
STATUS=$(grep -E '^status:' "$FILE_PATH" 2>/dev/null | head -1 | awk '{print $2}' || echo "")

# done または failed の場合のみ通知
if [[ "$STATUS" != "done" && "$STATUS" != "failed" ]]; then
    exit 0
fi

# 足軽番号を取得
ASHIGARU_NUM=$(echo "$FILE_PATH" | grep -oE 'ashigaru[0-9]+' | grep -oE '[0-9]+')

# タスクIDを取得（あれば）
TASK_ID=$(grep -E '^task_id:' "$FILE_PATH" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")

# 家老に通知を送る
# multiagent セッションの pane 0 が家老
KARO_TARGET="multiagent:0.0"

# 通知メッセージを作成
if [[ "$STATUS" == "done" ]]; then
    NOTIFY_MSG="【報告】足軽${ASHIGARU_NUM}がタスク${TASK_ID}を完了しました。報告ファイル: ${FILE_PATH}"
else
    NOTIFY_MSG="【報告】足軽${ASHIGARU_NUM}がタスク${TASK_ID}で問題発生。報告ファイル: ${FILE_PATH}"
fi

# tmux send-keys で家老を起こす（Enter で送信、C-m は禁止）
tmux send-keys -t "$KARO_TARGET" "$NOTIFY_MSG" Enter 2>/dev/null || true

# ログ出力（デバッグ用）
echo "[post-task-report] Notified karo: $NOTIFY_MSG" >&2
