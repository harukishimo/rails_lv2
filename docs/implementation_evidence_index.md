# 実装後評価証跡Index

作成日: 2026-06-21

この文書は #25 のEvidence Collector出力である。TODO 18「実装後のコード・テスト・画面を根拠に、評価基準をすべて網羅する本資料を作成する」へ引き渡す前段証跡として、評価基準IDごとにコード、テスト、画面/デモ導線、Issue/Loop Reportを整理する。

## 使い方

- 本文書は最終発表資料ではない。
- TODO 18では、このIndexから強い証跡を選び、15分発表で見せる順番とスライドに落とす。
- `Strength` が `weak` の項目は、アプリ実装ではなく資料・知識・運用説明で補う項目である。発表時に過剰主張しない。

## 完了Issue証跡

| Issue | 内容 | 主な評価基準 |
| --- | --- | --- |
| [#2](https://github.com/harukishimo/rails_lv2/issues/2) | Rails基盤構築 | R-38, B-03, B-10, B-11, B-12 |
| [#3](https://github.com/harukishimo/rails_lv2/issues/3) | 開発基盤・品質ゲート | R-20, R-37, B-10, B-12, B-14 |
| [#5](https://github.com/harukishimo/rails_lv2/issues/5) | 認証基盤 | R-31, B-06 |
| [#6](https://github.com/harukishimo/rails_lv2/issues/6) | 認可基盤 | R-32, B-07, B-08 |
| [#9](https://github.com/harukishimo/rails_lv2/issues/9) | 受験対象マスタ・評価官対応スキル | R-22, R-25, R-27, B-15 |
| [#10](https://github.com/harukishimo/rails_lv2/issues/10) | 受験表明ライフサイクル | R-03, R-11, R-22, B-15 |
| [#11](https://github.com/harukishimo/rails_lv2/issues/11) | レビュー依頼・提出物・Markdown | R-17, R-25, R-27, R-30 |
| [#12](https://github.com/harukishimo/rails_lv2/issues/12) | レビュー判定・コメント | R-03, R-07, R-26, R-30 |
| [#13](https://github.com/harukishimo/rails_lv2/issues/13) | 面談応募・日程調整 | R-14, R-25, R-30 |
| [#14](https://github.com/harukishimo/rails_lv2/issues/14) | 面談評価官割当 | R-02, R-03, R-28, B-15 |
| [#15](https://github.com/harukishimo/rails_lv2/issues/15) | 合格判定・資格反映 | R-03, R-07, R-26, B-15 |
| [#16](https://github.com/harukishimo/rails_lv2/issues/16) | 状態変更イベント・監査ログ | R-26, R-36 |
| [#17](https://github.com/harukishimo/rails_lv2/issues/17) | Slack・Google Calendar連携 | R-08, R-09, R-10, R-34, R-35, B-05 |
| [#18](https://github.com/harukishimo/rails_lv2/issues/18) | 検索・一覧・評価官キュー | R-28, R-33, B-15 |
| [#20](https://github.com/harukishimo/rails_lv2/issues/20) | 受験対象取込・帳票出力 | R-05, R-15, R-16, R-23 |
| [#23](https://github.com/harukishimo/rails_lv2/issues/23) | 横断テスト・品質保証 | R-07, R-25, R-28, R-37, B-08, B-14, B-15 |
| [#24](https://github.com/harukishimo/rails_lv2/issues/24) | アーキテクチャ・AI・Git補足 | B-01, B-02, B-04, B-05, B-13, R-20 |
| [#26](https://github.com/harukishimo/rails_lv2/issues/26) | Ruby基礎証跡補強 | R-01, R-04, R-13, R-18, R-19, R-21 |
| [#27](https://github.com/harukishimo/rails_lv2/issues/27) | Ridgepole DB変更安全性 | R-24, B-12, B-15 |
| [#32](https://github.com/harukishimo/rails_lv2/issues/32) | 管理者向けユーザー・評価官管理 | R-22, R-25, R-32 |
| [#33](https://github.com/harukishimo/rails_lv2/issues/33) | 日本語対応と表示文言 | R-29, R-30 |
| [#36](https://github.com/harukishimo/rails_lv2/issues/36) | Tailwind CSS導入 | B-10, B-11 |

## Ruby / Rails評価基準

| ID | Code Paths | Test Paths | Screen / Demo | Issue | Strength / Notes |
| --- | --- | --- | --- | --- | --- |
| R-01 | `app/models/role.rb`, `app/value_objects/search_params.rb` | `test/value_objects/search_params_test.rb` | なし | #26 | strong |
| R-02 | `app/services/examiner_suggestion_service.rb`, `app/queries/search/*` | `test/services/examiner_suggestion_service_test.rb` | 面談割当画面 | #14 | strong |
| R-03 | `ExamApplications::TransitionService`, `InterviewApplications::TransitionService`, `ReviewDecisions::CreateService` | `test/services/exam_application_transition_service_test.rb`, `test/integration/evaluation_lifecycle_test.rb` | 受験表明詳細、レビュー詳細、面談詳細 | #10, #12, #15 | strong |
| R-04 | `ReviewApplications::CreateService`, `EvaluationTargets::Importer`, `Integrations::Calendar::EventPayload` | service/value object tests | なし | #26 | strong |
| R-05 | `EvaluationTargets::Importer#build_result`, transaction blocks | `test/services/evaluation_target_importer_test.rb` | 管理者取込画面 | #20 | strong |
| R-06 | dashboard/view helper/search result assembly | `test/requests/dashboard_test.rb`, `test/helpers/application_helper_test.rb` | ダッシュボード | #18, #33 | moderate |
| R-07 | `QualificationGrantService`, `CalendarEventCreateJob`, integration errors | `test/services/qualification_grant_service_test.rb`, `test/jobs/calendar_event_create_job_test.rb` | 面談結果、Calendar失敗表示 | #15, #17, #23 | strong |
| R-08 | `Integrations::*::ClientFactory`, `Exporters::ReportFactory` | `test/services/integrations/client_factory_test.rb`, `test/services/exporters_report_factory_test.rb` | 外部連携設定、帳票出力 | #17, #20 | strong |
| R-09 | `Integrations::BaseClient`, `Exporters::BaseReport` | `test/services/integrations/client_factory_test.rb`, `test/services/exporters_report_factory_test.rb` | なし | #17, #20 | moderate |
| R-10 | Slack/Calendar mock/faraday clients with same interface | job tests | 状態変更後の送信履歴 | #17 | strong |
| R-11 | transition services, `closed_for_business?`, model methods | transition/model tests | 受験表明詳細 | #10, #15 | strong |
| R-12 | `RestoreDuplicateGuard`, controller concerns, Pundit policies | model/policy/controller tests | 管理画面 | #6, #9 | moderate |
| R-13 | `SearchParams`, `EvaluationTargets::ImportRow`, `EventPayload::Payload` | value object tests | なし | #26 | strong |
| R-14 | `InterviewSchedule`, `EvaluationPeriod`, Calendar payload | `test/models/interview_schedule_test.rb`, `test/models/evaluation_period_test.rb`, job tests | 面談日程 | #13, #17 | strong |
| R-15 | CSV/XLSX import with streaming and size checks | `test/services/evaluation_target_importer_test.rb` | 受験対象取込 | #20 | strong |
| R-16 | `Exporters::*`, `caxlsx`, CSV renderer | `test/services/exporters_report_factory_test.rb`, request export tests | 管理者帳票出力 | #20 | strong |
| R-17 | `GithubRepositoryUrlValidator`, markdown/file validations | `test/models/submission_test.rb`, review request tests | レビュー依頼フォーム | #11 | strong |
| R-18 | `EvaluationPeriod#cover?` | `test/models/evaluation_period_test.rb` | 評価期 | #26 | strong |
| R-19 | `ExaminerWorkloadCache` | `test/services/examiner_workload_cache_test.rb` | なし | #26 | strong |
| R-20 | `Gemfile`, `Gemfile.lock`, `bin/bundler-audit`, `config/ci.rb` | `bin/ci` | なし | #3, #24 | strong |
| R-21 | `SearchParams::METHOD_NAMES.each { define_method }` | `test/value_objects/search_params_test.rb` | 検索 | #26 | strong |
| R-22 | ActiveRecord CRUD models/controllers | model/request/integration tests | 管理/受験/レビュー/面談各画面 | #9-#15, #32 | strong |
| R-23 | `EvaluationTargets::Importer`, exporters, jobs | importer/exporter/job tests | 取込/帳票 | #20 | strong |
| R-24 | Ridgepole `db/Schemafile`, `db/schemas/tables/*.schema`, bin commands | `bin/ridgepole-apply`, `bin/ridgepole-dry-run`, `bin/ci` | なし | #27 | strong |
| R-25 | model validations, custom validator, service validations | model/request tests | 入力フォーム全般 | #9-#15, #23, #32 | strong |
| R-26 | `StatusChangeEvent`, `AuditLog`, `after_commit` jobs | status/job/qualification tests | ステータス変更履歴 | #16, #23 | strong |
| R-27 | associations between exam/review/submission/comment/interview | model/integration tests | 詳細画面 | #9-#15 | strong |
| R-28 | `Search::*`, includes/preload, EXPLAIN | `test/requests/search_and_queue_test.rb`, `test/queries/search_query_quality_test.rb` | 検索/評価官キュー | #18, #23 | strong |
| R-29 | Rails views/helpers/Tailwind UI | request smoke, helper tests | 主要画面UI | #19, #33, #36 | moderate |
| R-30 | Controllers delegate to services/policies | request tests | 各CRUD/ワークフロー画面 | #10-#15, #32 | strong |
| R-31 | Devise, JWT, refresh token | `test/requests/devise_sessions_test.rb`, `test/requests/api_v1_auth_test.rb`, `test/services/jwt_token_test.rb` | ログイン/API | #5 | strong |
| R-32 | Pundit policies and role tables | policy/request tests | 管理/評価官/受験者画面 | #6, #32 | strong |
| R-33 | search query objects and allowlist params | search request/value object tests | 受験対象検索、受験者検索、レビューキュー | #18, #26 | strong |
| R-34 | ActiveJob Slack/Calendar, import/export boundaries | job tests | 状態変更後の外部連携 | #17, #20 | strong |
| R-35 | Faraday clients, timeout/retry, WebMock | job/client tests | Slack/Calendar連携 | #17 | strong |
| R-36 | `AuditLog`, authorization audit concern, log filtering | audit/controller/request tests | 監査ログ/認可失敗 | #16 | moderate |
| R-37 | `bin/ci`, model/request/policy/job/integration tests | `bin/ci` | なし | #23 | strong |
| R-38 | Rails app foundation, setup scripts, health/root | `bin/setup`, `bin/dev`, health tests | root/health/login | #2, #3 | strong |

## バックエンド共通評価基準

| ID | Code / Docs | Test / Verification | Demo | Issue | Strength / Notes |
| --- | --- | --- | --- | --- | --- |
| B-01 | `docs/ai_development_review.md` | docs review | AIレビュー補足資料 | #24 | strong as process evidence |
| B-02 | `docs/requirements_definition.md`, `docs/detailed_design.md`, `docs/project_todo.md` | docs link check | 要件/設計説明 | #24, #25 | strong |
| B-03 | `README.md`, `bin/setup`, `bin/dev`, local setup docs | `bin/setup`, local browser確認 | localhost起動 | #2 | moderate; Dockerはストレージ制約により知識/docs補填 |
| B-04 | `docs/architecture_decisions.md`, services/policies/query/value objects | service/policy/request tests | コード説明 | #24 | strong |
| B-05 | integration clients, factories, exporters, DI points | job/client/exporter tests | 外部連携mock説明 | #17, #24 | strong |
| B-06 | Devise session, JWT, refresh token | auth request/service tests | ログイン/API auth | #5 | strong |
| B-07 | Pundit, roles, examiner capabilities | policy/request tests | 権限別画面 | #6 | strong |
| B-08 | Brakeman, bundler-audit, authz tests, sanitizer | `bin/ci`, security tests | セキュリティ説明 | #23 | strong |
| B-09 | REST API auth, ActionCable/GraphQL/OpenAPI docs補足 | API auth tests | API説明 | #5, docs | weak; GraphQL/ActionCableは知識補填扱い |
| B-10 | RuboCop, Tailwind/CSS hygiene | `bin/rubocop`, `bin/ci` | なし | #3, #36 | strong |
| B-11 | Tailwind build, importmap/assets, `bin/dev` | `bin/rails tailwindcss:build`, `bin/ci` | UI画面 | #36 | strong |
| B-12 | Bundler, Gemfile.lock, bundler-audit | `bin/bundler-audit`, `bin/ci` | なし | #3, #27 | strong |
| B-13 | `docs/git_operations.md`, branch/Issue history | GitHub Issues/branches/Loop Reports | Git運用説明 | #24 | strong |
| B-14 | model/request/policy/job/integration tests | `bin/ci` | なし | #23 | strong |
| B-15 | Ridgepole schema, indexes, EXPLAIN, lock/transaction services | Ridgepole apply/dry-run, EXPLAIN/query tests, integration tests | DB設計説明 | #23, #27 | strong locally; PostgreSQL EXPLAINは未取得 |

## 画面 / デモ導線候補

| Demo | 画面 | 見せる評価基準 |
| --- | --- | --- |
| 受験者ログインから受験表明 | `/users/sign_in`, `/exam_applications` | R-22, R-30, R-31, B-06 |
| レビュー依頼作成とMarkdown/提出物 | `/review_applications/new` | R-17, R-25, R-27 |
| 評価官レビューキュー | `/examiner/review_queue` | R-28, R-32, R-33, B-07 |
| 受験者検索と資格確認 | `/examiner/candidates` | R-28, R-32, B-15 |
| 面談割当と日程承認 | `/interview_applications/:id` | R-02, R-03, R-14, R-34 |
| 管理者ユーザー/評価官管理 | `/admin/users`, `/admin/examiner_profiles` | R-22, R-25, R-32 |
| 受験対象取込/帳票出力 | `/admin/evaluation_target_imports/new`, `/admin/exports` | R-15, R-16, R-23 |
| ステータス変更履歴 | 各詳細画面の履歴 | R-26, R-36 |

## Weak Evidence / 補完候補

| 評価基準 | 現状 | 補完案 |
| --- | --- | --- |
| B-03 Docker | ローカル構築は実動確認済み。Dockerはストレージ制約により実行確認を抑制 | TODO 18で「Dockerは知識・手順説明、ローカルは実動証跡」と明記 |
| B-09 GraphQL / ActionCable / OpenAPI | アプリ主要責務外として知識補填扱い。REST API authは実装済み | 発表資料で「必要になれば追加できる設計」としてdocs説明に留める |
| R-29 View / Decorator | Tailwind化とhelper/request smokeはあるが、Decorator専用クラスはない | Presenter/Decoratorは過剰抽象化として未採用理由を説明 |
| R-36 ログ | AuditLog/認可失敗ログはあるが、ログローテート実設定は本番運用外 | 本番SaaS範囲外として運用docsで補足 |
| PostgreSQL EXPLAIN | SQLiteの `EXPLAIN QUERY PLAN` は確認済み | 本番DB採用時にPostgreSQL EXPLAINを追加取得 |

## TODO 18への引き渡し

1. 15分発表では `R-03/R-07/R-24/R-28/R-31/R-32/B-04/B-05/B-08/B-14/B-15` を優先候補にする。
2. 本資料では、各評価基準ごとにこのIndexの `Code Paths` と `Test Paths` を1つ以上載せる。
3. 弱い証跡は隠さず、アプリ責務外・知識補填・後続本番運用で分けて説明する。
4. デモでは、画面操作よりも「その画面の裏でどのservice/policy/testが動いているか」を説明する。
5. 最終PR本文には、このIndexと各IssueのLoop ReportをEvidence Matrixとして集約する。
