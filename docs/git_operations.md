# Git運用・復旧手順メモ

作成日: 2026-06-21

この文書は #24 の成果物であり、評価基準 `B-13 Git` と `R-20 gem / bundler` の補足資料である。

## ブランチ運用

通常のLoopEngineeringでは、Issueごとにbranchを切り、最後に統合ブランチへ取り込む。

| 用途 | 命名 |
| --- | --- |
| Issue branch | `codex/issue-<issue-number>-<short-slug>` |
| 夜間統合branch | `codex/nightly-loop-integration` |
| 最終PR | `codex/nightly-loop-integration` -> `main` |

実施例:

- `codex/issue-27-ridgepole-schema-operations`
- `codex/issue-26-ruby-foundation-evidence`
- `codex/issue-23-cross-cutting-quality-tests`

## 基本手順

```bash
git checkout codex/nightly-loop-integration
git checkout -b codex/issue-<number>-<slug>
git status --short --branch
git add <changed-files>
git commit -m "<summary>" -m "Refs #<number>"
git push -u origin codex/issue-<number>-<slug>
git checkout codex/nightly-loop-integration
git merge --ff-only codex/issue-<number>-<slug>
git push origin codex/nightly-loop-integration
```

IssueごとのPRは作らず、IssueコメントにLoop ReportとEvidence Matrixを残す。`loop:ready` がなくなったら、統合ブランチから `main` へのまとめPRを作成する。

## 復旧手順

| 状況 | 優先する操作 | 理由 |
| --- | --- | --- |
| 未stageの変更を確認したい | `git diff` | 破壊せず確認できる |
| 未stageの一部だけ取り消したい | `git restore -- <file>` | 対象ファイルだけ戻せる。実行前に差分確認する |
| stage済みを戻したい | `git restore --staged <file>` | 作業ツリーを残したままstageだけ外せる |
| commit済みだが未push | `git commit --amend` または新commit | 履歴整理が可能。ただし共有前だけ |
| push済みcommitを取り消したい | `git revert <commit>` | 共有履歴を壊さない |
| 別branchの修正だけ取り込みたい | `git cherry-pick <commit>` | 必要commitだけ選べる |
| 一時退避したい | `git stash push -m "<reason>"` | branch切替前の退避に使う |
| 履歴を確認したい | `git log --oneline --decorate --graph --all` | branch関係を把握できる |
| 誤操作の直後 | `git reflog` | 直前のHEAD位置を探せる |

`git reset --hard` は原則使わない。必要な場合は、失われる差分を確認し、人間承認を取る。

## コンフリクト対応

1. `git status --short` で衝突ファイルを確認する。
2. 該当ファイルを開き、Issueのscope外の変更を巻き込まない。
3. 解消後に対象テストを実行する。
4. `git add` してcommitする。
5. Loop Reportに衝突内容、判断、テスト結果を残す。

## Issue labelとの関係

| Label | Git上の状態 |
| --- | --- |
| `loop:ready` | 着手前。統合ブランチからissue branchを作成できる |
| `loop:in-progress` | issue branchで作業中 |
| `loop:done` | issue branchがpush済みで、統合ブランチへ取り込み済み |
| `human-review` | Git操作より前に人間判断が必要 |

## gem / bundler運用

- gem追加時は目的を `Gemfile` コメントまたはIssueに残す。
- `bundle install` 後は `Gemfile.lock` をcommitする。
- CIで `bin/bundler-audit check --update` を実行し、既知脆弱性を確認する。
- gem更新は機能Issueと混ぜず、可能なら依存更新Issueとして分離する。
