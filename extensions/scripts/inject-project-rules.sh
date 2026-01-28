#!/bin/bash
# =============================================================================
# inject-project-rules.sh - プロジェクトルール取り込みスクリプト
# =============================================================================
# 対象プロジェクトの CLAUDE.md や設定ファイルを読み込み、
# エージェントに渡すコンテキストを生成する
#
# 使用方法:
#   ./inject-project-rules.sh <project_id>
#   ./inject-project-rules.sh --list
#
# 出力:
#   標準出力に読み込むべきファイルパスを出力
#   または、--output オプションで指定したファイルに書き込み
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/projects.yaml"

# 色付き出力
log_info() {
    echo -e "\033[1;33m[INFO]\033[0m $1" >&2
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

log_success() {
    echo -e "\033[1;32m[OK]\033[0m $1" >&2
}

# ヘルプ表示
show_help() {
    cat << EOF
使用方法: $(basename "$0") [オプション] <project_id>

オプション:
  --list              登録済みプロジェクト一覧を表示
  --output <file>     出力先ファイルを指定
  --format <format>   出力形式 (paths|content|yaml) デフォルト: paths
  --help              このヘルプを表示

引数:
  project_id          対象プロジェクトのID（config/projects.yaml で定義）

例:
  $(basename "$0") example-project
  $(basename "$0") --list
  $(basename "$0") --format content example-project
EOF
}

# プロジェクト一覧表示
list_projects() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "config/projects.yaml が見つかりません"
        exit 1
    fi

    echo "登録済みプロジェクト:"
    echo "========================"

    # yq がなければ grep でパース
    if command -v yq &> /dev/null; then
        yq '.projects[].id' "$CONFIG_FILE" 2>/dev/null | while read -r id; do
            local path=$(yq ".projects[] | select(.id == \"$id\") | .path" "$CONFIG_FILE" 2>/dev/null)
            echo "  - $id"
            echo "    path: $path"
        done
    else
        # yq がない場合は簡易パース
        grep -E "^\s+-?\s*id:" "$CONFIG_FILE" | awk '{print "  - " $NF}'
    fi
}

# プロジェクト情報取得
get_project_info() {
    local project_id="$1"
    local field="$2"

    if command -v yq &> /dev/null; then
        yq ".projects[] | select(.id == \"$project_id\") | .$field" "$CONFIG_FILE" 2>/dev/null
    else
        log_error "yq が必要です。インストールしてください: sudo apt install yq"
        exit 1
    fi
}

# 読み込むべきファイルを検出
detect_rule_files() {
    local project_path="$1"
    local files=()

    # CLAUDE.md
    if [[ -f "$project_path/CLAUDE.md" ]]; then
        files+=("$project_path/CLAUDE.md")
    fi

    # .claude/rules/*.md
    if [[ -d "$project_path/.claude/rules" ]]; then
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$project_path/.claude/rules" -name "*.md" -print0 2>/dev/null)
    fi

    # .cursorrules（Cursor互換）
    if [[ -f "$project_path/.cursorrules" ]]; then
        files+=("$project_path/.cursorrules")
    fi

    # .github/copilot-instructions.md（Copilot互換）
    if [[ -f "$project_path/.github/copilot-instructions.md" ]]; then
        files+=("$project_path/.github/copilot-instructions.md")
    fi

    # プロジェクト固有の設定ファイル
    for config in "tsconfig.json" "package.json" "pyproject.toml" "Cargo.toml" "go.mod"; do
        if [[ -f "$project_path/$config" ]]; then
            files+=("$project_path/$config")
        fi
    done

    printf '%s\n' "${files[@]}"
}

# ファイル内容を結合して出力
output_content() {
    local files=("$@")

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "# ======================================================================"
            echo "# File: $file"
            echo "# ======================================================================"
            cat "$file"
            echo ""
            echo ""
        fi
    done
}

# YAML形式で出力
output_yaml() {
    local project_id="$1"
    shift
    local files=("$@")

    echo "project_id: $project_id"
    echo "timestamp: $(date -Iseconds)"
    echo "files:"
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "  - path: $file"
            echo "    exists: true"
            echo "    size: $(stat -c %s "$file" 2>/dev/null || echo 0)"
        fi
    done
}

# =============================================================================
# メイン処理
# =============================================================================

OUTPUT_FILE=""
OUTPUT_FORMAT="paths"
PROJECT_ID=""

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --list)
            list_projects
            exit 0
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
        *)
            PROJECT_ID="$1"
            shift
            ;;
    esac
done

# プロジェクトID必須
if [[ -z "$PROJECT_ID" ]]; then
    log_error "プロジェクトIDを指定してください"
    show_help
    exit 1
fi

# 設定ファイル確認
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "config/projects.yaml が見つかりません"
    exit 1
fi

# プロジェクトパス取得
PROJECT_PATH=$(get_project_info "$PROJECT_ID" "path")

if [[ -z "$PROJECT_PATH" || "$PROJECT_PATH" == "null" ]]; then
    log_error "プロジェクト '$PROJECT_ID' が見つかりません"
    list_projects
    exit 1
fi

# パス展開（~をホームディレクトリに）
PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"

# パス存在確認
if [[ ! -d "$PROJECT_PATH" ]]; then
    log_error "プロジェクトパスが存在しません: $PROJECT_PATH"
    exit 1
fi

log_info "プロジェクト: $PROJECT_ID"
log_info "パス: $PROJECT_PATH"

# ルールファイル検出
mapfile -t RULE_FILES < <(detect_rule_files "$PROJECT_PATH")

if [[ ${#RULE_FILES[@]} -eq 0 ]]; then
    log_info "読み込むルールファイルがありません"
    exit 0
fi

log_success "検出されたファイル: ${#RULE_FILES[@]} 件"

# 出力
output() {
    case "$OUTPUT_FORMAT" in
        paths)
            printf '%s\n' "${RULE_FILES[@]}"
            ;;
        content)
            output_content "${RULE_FILES[@]}"
            ;;
        yaml)
            output_yaml "$PROJECT_ID" "${RULE_FILES[@]}"
            ;;
        *)
            log_error "不明な出力形式: $OUTPUT_FORMAT"
            exit 1
            ;;
    esac
}

if [[ -n "$OUTPUT_FILE" ]]; then
    output > "$OUTPUT_FILE"
    log_success "出力先: $OUTPUT_FILE"
else
    output
fi
