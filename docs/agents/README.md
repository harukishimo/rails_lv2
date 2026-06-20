# LoopEngineering Agents

作成日: 2026-06-20

## 目的

LoopEngineeringで使う各エージェントの個別プロンプトを管理する。

`docs/agent_prompts.md` は全体サマリー、このディレクトリ配下のmdを各エージェントの実行時プロンプトとして扱う。

## 共通前提

- 対象リポジトリ: `git@github.com:harukishimo/rails_lv2.git`
- ローカル作業ディレクトリ: `/Users/haruki.shimo/Documents/ruby_study_lv2`
- GitHub Issueを開発チケットとして扱う
- Issue本文は `.github/ISSUE_TEMPLATE/loop_development_ticket.md` に従う
- 作成直後のIssueは `loop:review-required` とし、人間確認後に `loop:ready` へ変更する
- 内側エージェントは `loop:ready` のIssueだけを実装対象にする
- 実装loopは標準45分
- 人間確認は原則PRレビューで行い、`human-review` は仕様判断や設計判断が必要な場合に限定する
- 実装Looperの同時並行は最大2
- DB schema/Ridgepole、認証/認可policy、同じmodel/serviceを触るIssueは並列禁止
- 評価資料へ転用できる証跡をIssue、PR、Loop Reportに残す

## 共通参照docs

- `docs/requirements_definition.md`
- `docs/detailed_design.md`
- `docs/evaluation_traceability_draft.md`
- `docs/loop_engineering_plan.md`
- `docs/human_review_timing.md`
- `docs/evaluation_presentation_agenda.md`
- `.github/ISSUE_TEMPLATE/loop_development_ticket.md`

## 外側エージェント

外側エージェントは「何を作るか」「作ってよいか」「どの順で作るか」を決める。原則として実装はしない。

- [Issue Splitter / Registrar](outside/issue_splitter_registrar.md)
- [Issue Quality Reviewer](outside/issue_quality_reviewer.md)
- [Dependency Planner](outside/dependency_planner.md)
- [Traceability Reviewer](outside/traceability_reviewer.md)
- [Design Reviewer](outside/design_reviewer.md)
- [Security Reviewer](outside/security_reviewer.md)
- [Local / Docker Verifier](outside/local_docker_verifier.md)
- [Presentation Prep Agent](outside/presentation_prep_agent.md)

## 内側エージェント

内側エージェントは、既に作成され、人間確認済みで `loop:ready` になったGitHub Issueを読み、実装・テスト・報告・PR作成を行う。Issueがない場合や `loop:review-required` だけの場合は実装を始めない。

- [Loop Orchestrator](inside/loop_orchestrator.md)
- [Implementation Looper A](inside/implementation_looper_a.md)
- [Implementation Looper B](inside/implementation_looper_b.md)
- [Test / QA Agent](inside/test_qa_agent.md)
- [Evidence Collector](inside/evidence_collector.md)

## 起動順

TODO 16開始前:

1. Issue Splitter / Registrar
2. Issue Quality Reviewer
3. Dependency Planner
4. Traceability Reviewer
5. Loop Orchestrator
6. Implementation Looper A
7. 必要時のみImplementation Looper B

必要時起動:

- Security Reviewer
- Local / Docker Verifier
- Presentation Prep Agent
