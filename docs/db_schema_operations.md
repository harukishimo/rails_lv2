# DB Schema Operations

作成日: 2026-06-21

## 目的

この文書は、SkillEvidenceHub のDB schema管理におけるRidgepole運用、dry-run/apply、危険DDLの停止条件、data migration分離、SQLite/PostgreSQL差分を明文化する。

評価基準では R-24 / R-20 / B-12 / B-15 の証跡として参照する。

## Source Of Truth

DB schemaの正はRails migrationではなくRidgepoleで管理する。

- entrypoint: `db/Schemafile`
- table定義: `db/schemas/tables/*.schema`
- 1 table 1 fileを原則にする
- `db/Schemafile` へtable定義を直接書かない
- table fileは番号prefixで読み込み順を固定する

`db/Schemafile` は `db/schemas/tables/*.schema` をsortして読み込むだけにする。これにより、レビュー時は対象tableの差分だけを確認できる。

## Commands

開発環境:

```sh
bin/ridgepole-dry-run
bin/ridgepole-apply
```

test環境:

```sh
RAILS_ENV=test bin/ridgepole-dry-run
RAILS_ENV=test bin/ridgepole-apply
```

CI:

```sh
bin/ci
```

`bin/ci` は以下を実行する。

- `RAILS_ENV=test bin/ridgepole-apply`
- `RAILS_ENV=test bin/ridgepole-dry-run`

## Normal Change Flow

1. 対象tableの `db/schemas/tables/*.schema` を変更する。
2. `bin/ridgepole-dry-run` でSQL差分を確認する。
3. 危険DDLに該当しないことを確認する。
4. `bin/ridgepole-apply` でローカルDBへ適用する。
5. `RAILS_ENV=test bin/ridgepole-dry-run` または `bin/ci` でtest DBとの差分がないことを確認する。
6. Loop Report / PR本文へ実行コマンド、結果、危険DDL判定を書く。

## Human Review Required

以下に該当するDB変更は、実装を止めてIssueへ `human-review` を付ける。

- `drop_table`
- column削除
- column rename
- table rename
- column type変更
- `null: false` 追加で既存データのbackfillが必要な変更
- default追加/変更で既存データへの影響がある変更
- unique index追加
- foreign key追加/変更/削除
- 大量行tableへのindex追加
- long lockが想定されるDDL
- production DBへ直接applyする必要がある変更
- SQLiteで通るがPostgreSQLで互換性が怪しい変更
- schema変更とdata migrationが同一Issueに混ざる変更

Human Reviewでは以下をIssueコメントに残す。

```markdown
## DB Human Review Checkpoint

- Target table:
- Proposed DDL:
- Dry-run output:
- Data migration needed:
- Lock risk:
- SQLite/PostgreSQL difference:
- Rollback/recovery:
- Recommendation:
```

## Data Migration Policy

Ridgepoleにはschema定義だけを置く。既存データの補正、backfill、外部データ投入はRidgepoleに混ぜない。

data migrationが必要な場合は、別Issueまたは専用Rails taskで扱う。

方針:

- task名、対象件数、再実行可否を明記する
- 可能な限りidempotentにする
- 大量データはbatch処理にする
- 実行前後の確認SQLまたはRails console確認をLoop Reportに残す
- schema applyとdata migrationを同じcommitに混ぜない

## SQLite / PostgreSQL Differences

ローカルとtestではSQLiteを使う。将来PostgreSQLへ寄せる場合、以下を注意する。

### Partial Unique Index

論理削除済みデータとの重複を避けるには、PostgreSQLでは `WHERE deleted_at IS NULL` のpartial unique indexが第一候補になる。

SQLiteでは環境・Ridgepole表現差分が出やすいため、現時点では以下で補完する。

- model validation
- service/usecase validation
- `RestoreDuplicateGuard`
- request/model test

PostgreSQL運用へ移す場合は、対象tableごとにpartial unique indexを追加する専用Issueを作る。

### Lock

PostgreSQLではindex追加、foreign key追加、型変更が長いlockを取る場合がある。production相当の変更では、online migration方針を別途確認する。

### Boolean / datetime / JSON

SQLiteとPostgreSQLではboolean、datetime precision、JSON表現に差分がある。Ridgepole dry-runで差分が消えない場合は、DB engine別のオプションを直接入れず、human-reviewで方針を決める。

## Recovery

ローカル開発でschema applyを誤った場合:

```sh
bin/rails db:drop db:create db:prepare
bin/ridgepole-apply
bin/rails db:seed
```

本番相当のDBでは、Ridgepole apply前にbackup/restore手順とrollback planを確認する。destructive changeは人間確認なしに実行しない。

## Current Verification

現時点のCIでは、`bin/ci` にRidgepole apply/dry-runが含まれている。

Issue #27 の確認コマンド:

```sh
RAILS_ENV=test bin/ridgepole-apply
RAILS_ENV=test bin/ridgepole-dry-run
bin/ci
```
