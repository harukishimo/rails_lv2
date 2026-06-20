# [LE] 認可基盤実装

## Goal

roles/user_roles、Pundit policy、対応可能評価スキル制御の土台を作り、受験者・評価官・管理者で操作できる範囲を分離する。

## Context / Linked Docs

- docs/requirements_definition.md
- docs/detailed_design.md
- docs/evaluation_traceability_draft.md
- docs/loop_engineering_plan.md
- docs/agents/inside/implementation_looper_a.md
- docs/agents/outside/security_reviewer.md

## Evaluation Criteria

- R-32
- B-07
- B-08
- R-11
- R-25
- R-30

## Suggested Agent

- Implementation Looper A
- Security Reviewer

## Agent Prompt

- docs/agents/inside/implementation_looper_a.md
- docs/agents/outside/security_reviewer.md

## Review Status

- Current: loop:review-required
- Reviewed by:
- Review note:

## Scope

- Role/UserRoleのモデル・関連・seed方針
- roleをenumではなくmaster/joinで扱う実装
- Pundit導入とApplicationPolicyの土台
- 管理者/受験者/評価官の基本policy
- 対応可能評価スキル制御のための基礎モデル方針
- policy specの初期整備

## Out of Scope

- 受験表明やレビュー依頼の詳細policy
- 評価官マスタの全画面実装
- 受験者検索の本実装
- UIの作り込み

## Acceptance Criteria

- [ ] roles/user_rolesの基本モデルがある
- [ ] roleがenumではなくmaster/joinで表現されている
- [ ] Pundit policyの基本構成がある
- [ ] 管理者/受験者/評価官の基本認可テストがある
- [ ] 対応可能評価スキル制御を後続Issueで拡張できる構造になっている
- [ ] Security Reviewerで確認すべき観点がIssueコメントに残っている

## Implementation Notes

- 認証基盤のUserを前提にする
- roles/user_roles等のDB schema変更はRidgepoleの `db/schemas/tables/*.schema` で1 table 1 fileとして管理する
- 認可漏れは評価官から深掘りされやすいため、policy specを必須にする
- 対応可能評価スキルの詳細は受験対象マスタIssue以降で拡張する

## Tests / Verification

- [ ] Role/UserRole model spec
- [ ] Ridgepole dry-run/applyまたは未実行理由
- [ ] ApplicationPolicy spec
- [ ] 管理者/受験者/評価官の基本policy spec
- [ ] 権限外アクセスのrequest spec

## Human Review Triggers

- [ ] role設計をmaster/join以外に変更する必要がある
- [ ] Pundit以外の認可方式へ変更する必要がある
- [ ] 対応可能評価スキル制御のDB設計変更が必要
- [ ] Ridgepoleで表現できないschema変更が必要
- [ ] 認可方針に曖昧さがある

## Dependencies

- [LE] Rails基盤構築
- [LE] 開発基盤・品質ゲート整備
- [LE] 認証基盤実装
