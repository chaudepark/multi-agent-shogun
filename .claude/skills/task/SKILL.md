---
name: task
description: タスク実装ワークフロー。アトミックコミット、Conventional Commits、進捗管理。実装開始時に使用。
---

# Task Implementation Workflow

タスク実装のベストプラクティスをまとめたスキル。

## When to Use

- 機能実装やバグ修正時
- コミット作成時
- 進捗報告が必要な時

## Core Principles

### 1. Small, Meaningful, Atomic Commits

1コミット = 1責任

**Bad Example**:
```bash
git commit -m "task complete"
git commit -m "WIP"
```

**Good Example**:
```bash
git commit -m "feat: add user registration endpoint"
git commit -m "test: add unit tests for user service"
git commit -m "fix: resolve authentication token expiration bug"
```

### 2. Conventional Commits Format

| Type       | Usage                             |
| ---------- | --------------------------------- |
| `feat`     | New feature                       |
| `fix`      | Bug fix                           |
| `test`     | Adding or updating tests          |
| `refactor` | Code refactoring (no feature/fix) |
| `chore`    | Build, config, dependency updates |
| `docs`     | Documentation only                |
| `style`    | Formatting (no code change)       |
| `perf`     | Performance improvement           |

### 3. Commit Workflow

1. 機能を実装
2. テストを書く（TDD推奨）
3. アトミックコミットを作成
4. 次の機能へ

```bash
# Stage specific files (not git add .)
git add src/feature.ts src/feature.test.ts

# Commit with conventional format
git commit -m "feat: add user registration with email validation"
```

## Task Completion Checklist

### Commit Quality
- [ ] 各コミットが単一責任
- [ ] Conventional Commits形式
- [ ] 論理的な順序

### Code Quality
- [ ] 型チェック通過
- [ ] Lint通過
- [ ] テスト通過

## FAQs

### Q: コミットはどれくらい小さくすべき？

A: **意味のある最小単位**。1テスト + 1実装 = 1コミット。

### Q: コミット前にスカッシュすべき？

A: **No**。アトミックコミットを保持。レビュアーが実装の流れを追える。

### Q: 何かを忘れた場合は？

A: 新しいコミットを作成。amendしない。

## Golden Rule

1. **Implement** - 機能を実装
2. **Test** - テストを書く
3. **Commit** - アトミックコミット
4. **Repeat** - 繰り返す
