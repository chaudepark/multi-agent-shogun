---
name: double-check
description: 作業完了確認スキル。変更ファイルの確認、TDDペアリング検証、抜け漏れ検出。コミット前に使用。
allowed-tools: Bash, Read, Grep, Glob
---

# Double-Check: Work Completion Verification

実装完了後の抜け漏れを防ぐダブルチェックスキル。

## When to Use

- 実装作業完了後
- `/tdd` や `/finalize` の前
- コミット前の最終確認

## Procedure

### Step 1: 変更ファイルを収集

```bash
# ステージ済み + 未ステージの変更を取得
git diff --name-only HEAD
git diff --name-only --cached
```

両方の出力をマージして重複を除去。

### Step 2: TDDペアリング検証

各実装ファイルに対応するテストファイルの存在と変更状態を確認。

#### File Correspondence Map

| Implementation Pattern | Test Pattern           |
| ---------------------- | ---------------------- |
| `src/**/*.ts`          | `src/**/*.test.ts`     |
| `src/**/*.js`          | `src/**/*.test.js`     |
| `src/**/*.py`          | `src/**/test_*.py`     |
| `lib/**/*.rb`          | `spec/**/*_spec.rb`    |

#### Evaluation Logic

1. **実装ファイルが変更された場合**:
   - 対応するテストファイルが存在するか？
   - テストファイルも変更されているか？
   - 変更されていない場合は警告

2. **テストファイルのみ変更された場合**:
   - 許可（テスト追加など）

3. **除外対象**:
   - `*.test.ts` / `*.spec.ts` 自体
   - `*.d.ts` (型定義)
   - `*.config.*` (設定ファイル)
   - `index.ts` (re-exportのみ)

### Step 3: レポート生成

```markdown
## Double-Check Report

**Status**: All Passed / Warnings / Issues Found

### 変更ファイル一覧

| Status | File                         | Type           |
| ------ | ---------------------------- | -------------- |
| OK     | src/services/user/create.ts   | Implementation |
| OK     | src/services/user/create.test.ts | Test        |
| WARN   | src/utils/format.ts          | No test update |

### TDD ペアリング検証

| Implementation File        | Test File        | Status              |
| -------------------------- | ---------------- | ------------------- |
| OK src/services/user/create.ts | OK create.test.ts | Paired & updated |
| WARN src/utils/format.ts   | - format.test.ts | Test not updated    |

### 推奨アクション

1. `src/utils/format.test.ts` を確認・更新してください

### Next Steps

- [ ] 問題を解決 → `/tdd` → `/finalize`
```

## Status Criteria

| Status       | Condition                                          |
| ------------ | -------------------------------------------------- |
| All Passed   | 全実装ファイルに対応テストあり、両方変更済み |
| Warnings     | テスト未更新、または除外ファイルのみ変更       |
| Issues Found | テストファイルが存在しない                     |

## Workflow Integration

```
[Implementation Complete]
    |
/double-check  <- This skill
    |
/tdd           <- Fix/run tests
    |
/finalize      <- Commit & push
```

## Notes

- このスキルは検証のみ、自動修正はしない
- 問題発見時はユーザーにアクションを促す
- `/tdd` スキルとの併用推奨
