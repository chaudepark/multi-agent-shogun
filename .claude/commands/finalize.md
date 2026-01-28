# Finalize

変更をコミットして作業を完了する。

**Usage**:

- `/finalize` → mainに直接マージ
- `/finalize pr` → レビュー用にPRを作成
- `/finalize <number>` → 既存PR #number にプッシュ

---

## Arguments

$ARGUMENTS

---

## Procedure

### Step 1: 変更を確認

`git-status` エージェントに委譲。

### Step 2: 品質チェック

順番に各エージェントに委譲:

1. **Lint & Typecheck** → `lint-typecheck` エージェント
2. **Tests** → `test-runner` エージェント

チェックが失敗した場合、問題を修正してから続行。

### Step 3: コミット作成

`git-commit` エージェントに委譲:

- Type: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`
- Scope: 影響範囲
- Description: 変更に基づく短い説明
- Body: 必要に応じて詳細説明

### Step 4: プッシュ/マージ

**Step 1のgit-statusの結果から現在の場所を判断し、適切なフローを選択。**

#### Location Detection

| Location | How to Identify                    |
| -------- | ---------------------------------- |
| main     | ブランチが `main`                  |
| worktree | パスに `/worktrees/` を含む        |
| feature  | `main` でなく、worktreeでもない    |

#### Flow Selection

| Location | Argument   | Flow                         |
| -------- | ---------- | ---------------------------- |
| main     | (empty)    | `git-push`                   |
| main     | `pr`       | `git-push` → `git-pr-create` |
| main     | `<number>` | `git-push`                   |
| worktree | (empty)    | マージ → push → cleanup      |
| worktree | `pr`       | `git-push` → `git-pr-create` |
| worktree | `<number>` | `git-push`                   |
| feature  | (empty)    | マージ → push → cleanup      |
| feature  | `pr`       | `git-push` → `git-pr-create` |
| feature  | `<number>` | `git-push`                   |

---

## Agent Summary

| Step | Agent              | Responsibility       |
| ---- | ------------------ | -------------------- |
| 1    | `git-status`       | 変更を表示           |
| 2a   | `lint-typecheck`   | Lint + 型チェック    |
| 2b   | `test-runner`      | テスト実行           |
| 3    | `git-commit`       | コミット作成         |
| 4a   | `git-push`         | リモートにプッシュ   |
| 4b   | `git-pr-create`    | PR作成 (`pr` の場合) |

---

## Constraints

- **DO NOT** execute `npm run lint`, `npm run test` directly
- **DO NOT** execute `git status`, `git add`, `git commit`, `git push` directly
- **DO** delegate each step to the appropriate agent
