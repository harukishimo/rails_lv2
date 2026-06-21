# アーキテクチャ判断メモ

作成日: 2026-06-21

この文書は #24 の成果物であり、評価面談で `B-04 アーキテクチャ構成` と `B-05 凝集と結合` を説明するための補足資料である。

## 採用した全体構成

`SkillEvidenceHub` はRails MVCを土台にしつつ、業務判断をcontroller/modelへ寄せすぎない構成にした。

| 層 | 主なコードパス | 役割 |
| --- | --- | --- |
| Controller | `app/controllers/*` | 認証、認可、入力受け渡し、画面遷移 |
| Policy | `app/policies/*` | role、状態、対応可能評価スキルによる認可 |
| Model | `app/models/*` | association、validation、enum、論理削除、軽量な状態問い合わせ |
| Service / Usecase | `app/services/*` | 状態遷移、レビュー判定、面談割当、資格反映、外部連携 |
| Query Object | `app/queries/search/*` | allowlistされた検索、includes/preload、pagination |
| Value Object | `app/value_objects/*` | 検索条件、取込行、payloadなどの不変値 |
| Integration Client | `app/services/integrations/*` | Slack/Google Calendarの実client/mock client/Factory |
| Job | `app/jobs/*` | Slack送信、Calendar登録の非同期処理 |

## DDD / Clean Architectureの扱い

フルDDDや厳密なClean Architectureは採用していない。理由は、このアプリが1日開発の評価用ミニマルアプリであり、過度な抽象化は説明量と実装量を増やすためである。

ただし、次の思想は採用した。

- Entityに近いもの: `ExamApplication`, `ReviewApplication`, `InterviewApplication`, `UserQualification`
- Value Object: `SearchParams`, `EvaluationTargets::ImportRow`, `Integrations::Calendar::EventPayload::Payload`
- Usecase: `ExamApplications::CreateService`, `ReviewApplications::CreateService`, `ReviewDecisions::CreateService`, `QualificationGrantService`
- Interface境界に近いもの: `Integrations::Slack::ClientFactory`, `Integrations::Calendar::ClientFactory`
- Policy境界: Pundit policyに認可判断を集約

採用しなかったもの:

- Repository層: ActiveRecordのrelationとquery objectで十分なため追加しない。
- Domain Event基盤: `StatusChangeEvent` と `SlackDeliveryJob` で要件を満たせるため、汎用イベントバスは作らない。
- ワークフローエンジン: 状態遷移はserviceとenumで説明できる粒度に留める。

## Rails標準との差分

| 項目 | Rails標準に寄せた部分 | あえて差分を作った部分 | 理由 |
| --- | --- | --- | --- |
| 認証 | Devise session認証 | APIは `jwt` gemでaccess/refresh tokenを分離 | Web/APIの責務が違うため |
| DB変更 | ActiveRecord model/validation | Rails migration主体ではなくRidgepole + `db/schemas/tables/*.schema` | DB差分レビューとdry-run証跡を残しやすい |
| 業務処理 | ActiveRecord transaction/association | service/usecaseに状態遷移と副作用を分離 | Controller肥大化とcallback依存を避ける |
| 認可 | Rails controller filter | Pundit policy | role、状態、対応可能スキルを一箇所で説明するため |
| 外部連携 | ActiveJob | Factory/Client/Mockを追加 | DIで実API/mockを差し替え、テストを安定させるため |
| CSS | Rails asset pipeline | Tailwind utility中心 | 独自CSS肥大化を避けるため |

## 高凝集・疎結合の具体例

| 観点 | コードパス | 説明 |
| --- | --- | --- |
| レビュー申請 | `app/services/review_applications/*` | 作成、更新、取消、状態変更記録を名前空間で分離 |
| 面談応募 | `app/services/interview_applications/*`, `app/services/interview_schedules/*` | 面談作成、評価官割当、日程作成/承認/却下を分離 |
| 資格反映 | `app/services/qualification_grant_service.rb` | 合格判定、資格作成、受験クローズを同一transactionに集約 |
| 外部連携 | `app/services/integrations/slack/*` | Faraday実clientとmock clientを同じinterfaceで扱う。Google Calendar登録は現行フローでは使用しない |
| 検索 | `app/queries/search/*`, `app/value_objects/search_params.rb` | Controllerから検索条件の組立を分離し、未知パラメータを拒否 |
| 帳票 | `app/services/exporters/*` | CSV/XLSX renderingと帳票種別を分離 |

## DIとテスト容易性

| 対象 | DI / 差し替え箇所 | テスト |
| --- | --- | --- |
| Slack | `SlackDeliveryJob.client_factory` | `test/jobs/slack_delivery_job_test.rb` |
| Export | `Exporters::ReportFactory` | `test/services/exporters_report_factory_test.rb` |
| Search | `SearchParams` + query object | `test/value_objects/search_params_test.rb`, `test/requests/search_and_queue_test.rb` |

外部API credentialがないローカル環境ではmock clientを使い、実HTTPはWebMockでstubする。これにより、評価面談時もローカルで安定して確認できる。

## 評価資料へ転用する証跡

| 評価基準 | 主要証跡 |
| --- | --- |
| B-04 | この文書、`app/services/*`, `app/policies/*`, `app/queries/search/*`, `app/value_objects/*` |
| B-05 | `Integrations::*`, `Exporters::*`, `Search::*`, DI可能なjob tests |
| B-02 | `docs/requirements_definition.md`, `docs/detailed_design.md`, `docs/project_todo.md` |
| B-01 | `docs/ai_development_review.md` |
| R-20 | `Gemfile`, `Gemfile.lock`, `bin/bundler-audit`, `docs/db_schema_operations.md` |
