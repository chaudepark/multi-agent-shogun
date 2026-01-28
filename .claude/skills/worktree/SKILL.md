---
name: worktree
description: Git worktree作成。独立した開発環境を用意。/worktree <branch-name> で使用。
model: haiku
allowed-tools: Bash, Read
context: fork
agent: worktree-starter
---

# Worktree Creation

Git worktreeを作成して、独立した開発環境を用意する。

## Usage

```
/worktree <branch-name>
```

## Arguments

$ARGUMENTS

## Instructions

1. `$ARGUMENTS` が空の場合、ブランチ名を尋ねる
2. `worktree-add $ARGUMENTS` を実行
3. `git worktree list` で確認
4. worktreeの場所とブランチ名を報告

## How It Works

```bash
# Worktree作成
worktree-add feature-new-feature

# 確認
git worktree list

# 結果例
/home/user/work/project           abc1234 [main]
/home/user/work/worktrees/project/feature-new-feature  def5678 [feature/new-feature]
```

## Notes

- ブランチ名の最初の `-` は `/` に変換される
  - `feature-foo` → ブランチ `feature/foo`
- worktree内で独立して作業可能
- 完了後は `worktree-remove` で削除
