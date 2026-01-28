#!/bin/bash
# =============================================================================
# role-detector.sh - ロール判定スクリプト
# =============================================================================
# tmuxペイン名・セッション名からエージェントのロールを判定する
#
# 使用方法:
#   ./role-detector.sh           # 現在のペインのロールを出力
#   ./role-detector.sh --json    # JSON形式で詳細情報を出力
#
# 出力:
#   shogun / karo / ashigaru / sanbo のいずれか
# =============================================================================

set -euo pipefail

# JSON出力モードかどうか
JSON_MODE=false
if [[ "${1:-}" == "--json" ]]; then
    JSON_MODE=true
fi

# tmux環境かどうか確認
if [[ -z "${TMUX:-}" ]]; then
    if $JSON_MODE; then
        echo '{"role":"unknown","error":"not in tmux session"}'
    else
        echo "unknown"
    fi
    exit 1
fi

# tmux情報を取得
SESSION_NAME=$(tmux display-message -p '#S' 2>/dev/null || echo "")
PANE_TITLE=$(tmux display-message -p '#T' 2>/dev/null || echo "")
PANE_INDEX=$(tmux display-message -p '#P' 2>/dev/null || echo "")

# ロールを判定
determine_role() {
    # セッション名で判定（最優先）
    case "$SESSION_NAME" in
        "shogun")
            echo "shogun"
            return
            ;;
        "sanbo")
            echo "sanbo"
            return
            ;;
        "multiagent")
            # multiagentセッション内はペイン名/インデックスで判定
            case "$PANE_TITLE" in
                "karo")
                    echo "karo"
                    return
                    ;;
                ashigaru*)
                    echo "ashigaru"
                    return
                    ;;
            esac
            # ペイン名が設定されていない場合はインデックスで判定
            if [[ "$PANE_INDEX" == "0" ]]; then
                echo "karo"
            else
                echo "ashigaru"
            fi
            return
            ;;
    esac

    # ペイン名のみで判定（フォールバック）
    case "$PANE_TITLE" in
        "shogun")
            echo "shogun"
            ;;
        "karo")
            echo "karo"
            ;;
        ashigaru*)
            echo "ashigaru"
            ;;
        "sanbo")
            echo "sanbo"
            ;;
        *)
            # デフォルトは shogun（将軍のペインは名前が設定されていない場合がある）
            echo "shogun"
            ;;
    esac
}

ROLE=$(determine_role)

# 出力
if $JSON_MODE; then
    cat <<EOF
{
  "role": "$ROLE",
  "session": "$SESSION_NAME",
  "pane_title": "$PANE_TITLE",
  "pane_index": "$PANE_INDEX"
}
EOF
else
    echo "$ROLE"
fi
