---
name: tdd
description: TDDワークフロー実行。Red-Green-Refactorサイクル。テスト駆動開発時に使用。
---

# TDD Test Runner

Red-Green-Refactorサイクルによるテスト駆動開発ワークフロー。

## TDD Cycle

```
+-------------------------------------------------------------+
|                                                             |
|   RED ----------> GREEN ----------> REFACTOR                |
|    |                |                    |                  |
|    v                v                    v                  |
|  Write           Write              Clean up                |
|  failing         minimal            code while              |
|  test            code to            keeping tests           |
|                  pass               green                   |
|                                                             |
|    +-------------------------------------+                  |
|                  Repeat                                     |
+-------------------------------------------------------------+
```

## Common Test Commands

| Language   | Test Command                     |
| ---------- | -------------------------------- |
| Node.js    | `npm test` / `pnpm test`         |
| Python     | `pytest`                         |
| Rust       | `cargo test`                     |
| Go         | `go test ./...`                  |
| Ruby       | `bundle exec rspec`              |
| Java       | `./gradlew test` / `mvn test`    |

## Test Structure (General)

```
Describe: functionName
  It: should return expected result when given valid input
    - Arrange: Set up test data
    - Act: Call the function
    - Assert: Verify the result

  It: should throw error when input is invalid
    - Expect error to be thrown
```

## TDD Workflow

### 1. RED: 失敗するテストを書く

```bash
# テストを実行 - 失敗するはず
npm test src/services/users/create-user.test.ts
# Expected: FAIL
```

### 2. GREEN: テストを通す最小限のコードを書く

```bash
# テストを実行 - 成功するはず
npm test src/services/users/create-user.test.ts
# Expected: PASS
```

### 3. REFACTOR: テストを維持しながらリファクタリング

```bash
# テストを実行 - まだ成功するはず
npm test src/services/users/create-user.test.ts
# Expected: PASS (still)
```

### 4. VERIFY: 関連テストを全て実行

```bash
npm test src/services/users/
```

## Test File Naming Conventions

| Language | Convention                |
| -------- | ------------------------- |
| TypeScript/JavaScript | `*.test.ts`, `*.spec.ts` |
| Python   | `test_*.py`, `*_test.py`  |
| Rust     | `#[test]` in same file or `tests/` dir |
| Go       | `*_test.go`               |
| Ruby     | `*_spec.rb`               |

## Checklist

TDD完了前に確認:

- [ ] テストファイルが実装と同じ場所にある
- [ ] テスト説明が明確
- [ ] 各テスト前にモックをクリア
- [ ] 具体的なアサーションを使用
- [ ] エッジケースをカバー（null, undefined, empty, invalid）
- [ ] エラーパスをテスト

## Best Practices

1. **テストを先に書く** - 実装の前にテストを書く
2. **最小限の実装** - テストを通すだけのコードを書く
3. **1つずつ** - 一度に1つのテストケースに集中
4. **リファクタリング** - テストが緑のうちにコードを改善
5. **繰り返す** - 次の機能へ進む
