# Worktree

Git worktreeを作成して独立した開発環境を用意。

**Usage**:

```
/worktree <branch-name>
```

---

## Arguments

$ARGUMENTS

---

## Procedure

### Step 1: ブランチ名の確認

`$ARGUMENTS` が空の場合、ブランチ名を尋ねる。

### Step 2: Worktree作成

```bash
worktree-add $ARGUMENTS
```

### Step 3: 確認

```bash
git worktree list
```

### Step 4: 報告

- Worktreeの場所
- 作成されたブランチ名

---

## Notes

- ブランチ名の最初の `-` は `/` に変換される
  - `feature-foo` → ブランチ `feature/foo`
- worktree内で独立して作業可能
- 完了後は `worktree-remove` で削除

---

## Example

```bash
# 作成
/worktree feature-user-auth

# 結果
# Branch: feature/user-auth
# Location: ~/work/worktrees/project/feature-user-auth
```
