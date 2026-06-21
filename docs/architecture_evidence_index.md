# アーキテクチャ・AI・Git証跡Index

作成日: 2026-06-21

この文書は #24 のEvidence Collector出力である。TODO 18の本資料へ転用するため、評価基準、機能、コードパス、テスト、Issueリンクを整理する。

| Evaluation Criteria | Feature / Topic | Code Paths | Test Paths | Issue / Evidence Links | Notes for TODO 18 |
| --- | --- | --- | --- | --- | --- |
| B-01 | AI出力レビュー | なし。アプリ機能外 | なし。資料レビュー対象 | `docs/ai_development_review.md`, #24 | 「AI機能」ではなく「AI出力を自責でレビューした記録」として説明する |
| B-02 | 要件定義・基本設計 | なし。docs成果物 | docsリンク確認 | `docs/requirements_definition.md`, `docs/detailed_design.md`, `docs/project_todo.md` | 要件変更時はdocsを更新する運用 |
| B-04 | アーキテクチャ構成 | `app/services/*`, `app/policies/*`, `app/queries/search/*`, `app/value_objects/*` | `test/integration/evaluation_lifecycle_test.rb`, service/policy/request tests | `docs/architecture_decisions.md`, #24 | Rails MVC + service/usecase + policy + query/value object |
| B-05 | 凝集と結合 / DI | `app/services/integrations/*`, `app/services/exporters/*`, `CalendarEventCreateJob.client_factory`, `SlackDeliveryJob.client_factory` | `test/jobs/calendar_event_create_job_test.rb`, `test/jobs/slack_delivery_job_test.rb`, `test/services/exporters_report_factory_test.rb` | `docs/architecture_decisions.md`, #24 | 実API/mockをFactoryで差し替える |
| B-13 | Git | なし。運用資料と履歴 | GitHub Issue/branch/Loop Report確認 | `docs/git_operations.md`, #23, #24, #26, #27 | revert/cherry-pick/stash/resetの使い分けを説明する |
| R-20 | gem / bundler | `Gemfile`, `Gemfile.lock`, `bin/bundler-audit`, `config/ci.rb` | `bin/ci`, `bin/bundler-audit check --update` | `docs/git_operations.md`, `docs/db_schema_operations.md` | gem採用理由と脆弱性確認を説明する |

## Evidence Matrix Gaps

- 本番PostgreSQLでのEXPLAIN結果は未取得。ローカルSQLiteでは `test/queries/search_query_quality_test.rb` で確認済み。
- Docker起動確認はストレージ制約により知識・docsで補完する方針。ローカル起動を第一級手順として扱う。
- 15分発表資料の本作成はTODO 18で行う。このIssueでは資料の素材整理までに留める。
