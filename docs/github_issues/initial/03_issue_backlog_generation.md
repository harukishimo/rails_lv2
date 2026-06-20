# [LE] 初期Issueバックログ作成・依存整理

## Goal

要件定義、詳細設計、評価基準対応表をもとに、TODO 16以降で使うGitHub Issueバックログを作成し、すべて人間確認待ちの `loop:review-required` にする。

## Context / Linked Docs

- docs/requirements_definition.md
- docs/detailed_design.md
- docs/evaluation_traceability_draft.md
- docs/loop_engineering_plan.md
- docs/agents/outside/issue_splitter_registrar.md
- docs/agents/outside/issue_quality_reviewer.md
- docs/agents/outside/dependency_planner.md
- docs/agents/outside/traceability_reviewer.md

## Evaluation Criteria

- B-02
- B-14
- R-37

## Suggested Agent

- Issue Splitter / Registrar
- Issue Quality Reviewer
- Dependency Planner
- Traceability Reviewer

## Agent Prompt

- docs/agents/outside/issue_splitter_registrar.md
- docs/agents/outside/issue_quality_reviewer.md
- docs/agents/outside/dependency_planner.md
- docs/agents/outside/traceability_reviewer.md

## Review Status

- Current: loop:review-required
- Reviewed by:
- Review note:

## Scope

- 後続の主要IssueをGitHub Issueとして作成する
- 作成直後のIssueには `loop:review-required` を付ける
- `loop:ready` は付けない
- IssueごとにEvaluation Criteria、Suggested Agent、Agent Prompt、Acceptance Criteria、Tests、Dependenciesを入れる
- Dependency Plannerの初期整理をIssueコメントまたはdocsに残す
- Traceability Reviewerで評価基準漏れを確認する
- DB schema変更を含むIssueはRidgepole/Schemafile前提で分割する
- 主要業務フローが一通り動いた後に実施する `[LE] 主要画面の最低限UI/UX整備` Issueを作成する

## Out of Scope

- 実装作業
- `loop:ready` への変更
- PR作成
- 評価資料の本作成

## Acceptance Criteria

- [ ] 後続IssueがGitHub上に作成されている
- [ ] 作成Issueはすべて `loop:review-required` である
- [ ] 作成Issueに `loop:ready` が付いていない
- [ ] 主要Issueに評価基準IDが入っている
- [ ] 主要Issueに依存関係が記載されている
- [ ] `[LE] 主要画面の最低限UI/UX整備` Issueが作成され、主要業務フロー実装後の依存として定義されている
- [ ] 評価基準の明らかな漏れがIssueコメントまたはdocsに記録されている

## Implementation Notes

- このIssueはLoopEngineeringの外側作業である
- 人間が確認してから個別Issueを `loop:ready` に変更する
- GitHub CLIで作成する場合も、Organization access不要のfine-grained PATのみ使う
- DB schema変更IssueのAcceptance Criteriaには、Schemafile変更、Ridgepole dry-run、Ridgepole applyまたは未実行理由を含める
- UI/UX整備Issueは、受験者/評価官のナビゲーション、一覧/詳細/作成/編集/承認/却下の導線、ステータスバッジ、取消不可操作の注意喚起、フォームエラー、flash、空状態、デモで説明しやすい画面順をScopeに含める
- UI/UX整備Issueでは、本格的なデザインシステム構築、過度な装飾、業務フローを変える大幅な画面仕様変更はOut of Scopeにする

## Tests / Verification

- [ ] `gh issue list --label loop:review-required`
- [ ] `gh issue list --label loop:ready`
- [ ] 作成Issueのサンプリング確認

## Human Review Triggers

- [ ] Issue粒度が大きすぎる
- [ ] 評価基準IDの割り当てに迷いがある
- [ ] 実装順に判断が必要
- [ ] Issueのscopeを超える作業が必要

## Dependencies

- なし
