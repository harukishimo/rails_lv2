# [LE] 開発基盤・品質ゲート整備

## Goal

RuboCop、テスト実行、依存脆弱性確認、CIの初期方針を整え、後続Issueの品質確認を回せる状態にする。

## Context / Linked Docs

- docs/requirements_definition.md
- docs/detailed_design.md
- docs/evaluation_traceability_draft.md
- docs/loop_engineering_plan.md
- docs/agents/inside/implementation_looper_b.md
- docs/agents/inside/test_qa_agent.md

## Evaluation Criteria

- B-03
- B-10
- B-12
- B-14
- R-20
- R-37
- R-38

## Suggested Agent

- Implementation Looper B
- Test / QA Agent

## Agent Prompt

- docs/agents/inside/implementation_looper_b.md
- docs/agents/inside/test_qa_agent.md

## Review Status

- Current: loop:review-required
- Reviewed by:
- Review note:

## Scope

- RuboCopの導入と初期設定
- test frameworkの初期整備
- bundle audit等の依存確認方針の追加
- GitHub Actionsまたは同等CIの初期設定
- 品質確認コマンドのREADME/docsへの記録

## Out of Scope

- 個別機能の詳細テスト
- 認証/認可のテスト実装
- system testの本格整備
- Docker起動確認

## Acceptance Criteria

- [ ] lintコマンドが定義されている
- [ ] テストコマンドが定義されている
- [ ] 依存脆弱性確認の方針が記録されている
- [ ] CI設定の初期ファイルがある、またはCIを入れない理由がdocsに記録されている
- [ ] 実行した品質確認コマンドがIssueコメントにLoop Reportとして残っている

## Implementation Notes

- Rails基盤構築Issueと衝突する場合は待機する
- DB schema/Ridgepoleや認可policyは触らない

## Tests / Verification

- [ ] lint実行
- [ ] test実行
- [ ] dependency/security check実行または未実行理由の記録
- [ ] CI設定ファイルの構文確認

## Human Review Triggers

- [ ] test frameworkをdocs想定から変更する必要がある
- [ ] CIを入れない判断が必要
- [ ] 大きなGem追加が必要
- [ ] Issueのscopeを超える実装が必要

## Dependencies

- [LE] Rails基盤構築
