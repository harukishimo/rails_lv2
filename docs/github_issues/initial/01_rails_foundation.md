# [LE] Rails基盤構築

## Goal

`SkillEvidenceHub` のRailsアプリ基盤を作成し、ローカルで最小起動できる状態にする。

## Context / Linked Docs

- docs/requirements_definition.md
- docs/detailed_design.md
- docs/evaluation_traceability_draft.md
- docs/loop_engineering_plan.md
- docs/agents/inside/implementation_looper_a.md

## Evaluation Criteria

- B-03
- B-10
- B-11
- B-12
- B-14
- R-20
- R-38

## Suggested Agent

- Implementation Looper A

## Agent Prompt

- docs/agents/inside/implementation_looper_a.md

## Review Status

- Current: loop:review-required
- Reviewed by:
- Review note:

## Scope

- Railsアプリの初期構築
- Gemfile/Gemfile.lockの作成
- DB接続設定の初期化
- Ridgepole導入と `db/Schemafile` の初期化
- `bin/setup` と `bin/dev` の初期整備
- READMEまたはdocsへのローカル起動手順の初期メモ追加
- 最小のhealth checkまたはroot画面の作成

## Out of Scope

- 認証/認可の本実装
- ドメインモデルの詳細実装
- Docker本実装
- CI本実装
- 評価資料の本作成

## Acceptance Criteria

- [ ] Railsアプリがリポジトリ内に作成されている
- [ ] `bin/setup` の初期方針が用意されている
- [ ] `bin/dev` または同等のローカル起動手順が用意されている
- [ ] 最小画面またはhealth checkで起動確認できる
- [ ] 採用したRails/Ruby/DB方針がREADMEまたはdocsに記録されている
- [ ] Ridgepoleと `db/Schemafile` の初期方針が用意されている
- [ ] 実行した確認コマンドがIssueコメントにLoop Reportとして残っている

## Implementation Notes

- PCストレージ制約があるため、Docker必須ではなくローカル起動を第一級に扱う
- Docker構築は後続Issueで扱う
- DBスキーマ管理はRails migration主体ではなくRidgepoleを使う
- Rails標準migrationは、gem初期導入などRidgepoleで表現しづらい補助用途に限定する
- 不明なRailsバージョン差分があれば、実装前にIssueコメントで報告する

## Tests / Verification

- [ ] `bin/rails -v`
- [ ] `bin/rails db:prepare` または同等のDB準備
- [ ] `bundle exec ridgepole --help` または同等のRidgepole導入確認
- [ ] `bin/rails test` または初期テストコマンド
- [ ] ローカル起動確認

## Human Review Triggers

- [ ] DB種別をdocsから変更する必要がある
- [ ] Rails major version選定で迷いがある
- [ ] ローカル構築が成立せずDocker前提に寄せる必要がある
- [ ] Issueのscopeを超える実装が必要

## Dependencies

- なし
