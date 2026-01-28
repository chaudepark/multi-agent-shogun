---
name: pr
description: GitHub Pull Request作成ワークフロー。事前チェック、タイトル・本文生成、エラーハンドリング。PR作成時に使用。
---

# Pull Request Creation Workflow

PR作成のベストプラクティス。

## When to Use

- 作業完了後にPRを作成する時
- ユーザーが「PR作って」と依頼した時

## Pre-Flight Checklist (CRITICAL)

`gh pr create` を実行する**前に**、必ず以下を確認：

### Step 1: コミットがあるか確認

```bash
git log main..HEAD --oneline
```

Check:
- [ ] 少なくとも1つのコミットがある
- [ ] コミットが意味のあるものである

### Step 2: ブランチがプッシュされているか

```bash
git status
```

Check:
- [ ] リモートより先に進んでいない
- [ ] 先に進んでいる場合は先にプッシュ

### Step 3: 既存PRがないか

```bash
gh pr list --head $(git branch --show-current)
```

### Step 4: ベースブランチの確認

```bash
git branch --show-current
```

Check:
- [ ] 現在のブランチがmain/masterではない

## PR Title Generation

### Single Commit
```bash
git log -1 --pretty=%s
# "feat: add user authentication" → "Add user authentication"
```

### Multiple Commits
- 共通テーマを見つける
- 高レベルのサマリーを使用

**Title Rules**:
- 動詞で始める（Add, Fix, Update, Refactor）
- 具体的だが簡潔に（50-80文字）
- Conventional Commit接頭辞は削除

## PR Body Template

```markdown
## Summary

[1-3文でこのPRが何をするか、なぜするかを説明]

## Changes

- Added X feature
- Fixed Y bug
- Refactored Z for better performance

## Testing

- [ ] All tests pass
- [ ] Type checking passes
- [ ] Manually tested [specific scenarios]

---

Generated with [Claude Code](https://claude.com/claude-code)
```

## The Correct PR Creation Command

**HEREDOC を使用（必須）**:

```bash
gh pr create --title "Add user authentication API endpoint" --body "$(cat <<'EOF'
## Summary

This PR implements user registration and login endpoints.

## Changes

- Added registration request/response schemas
- Implemented authentication integration
- Added comprehensive test coverage

## Testing

- [x] All tests pass
- [x] Type checking passes

---

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## Error Handling

### "No commits between main and HEAD"
**Solution**: コミットを先に作成

### "Pull request already exists"
**Solution**: 既存PRを確認 `gh pr list --head $(git branch --show-current)`

### "Cannot find remote branch"
**Solution**: 先にプッシュ `git push -u origin $(git branch --show-current)`

## Golden Rule

1. **Pre-flight checks** - コミット、プッシュ、既存PR確認
2. **Generate title** - コミットから、簡潔に
3. **Generate body** - サマリー、変更点、テスト
4. **Create PR** - HEREDOCを使用
5. **Verify success** - 作成されたPRを確認
