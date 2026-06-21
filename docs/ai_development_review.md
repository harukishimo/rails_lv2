# AI開発レビュー記録

作成日: 2026-06-20

## この文書の位置づけ

この文書は、バックエンド共通評価基準の `AIリテラシー` を補足するための資料である。

`AIリテラシー` は `SkillEvidenceHub` のアプリ機能として実装するものではない。開発者がAIを用いてアプリケーションを構築する過程で、AIの出力をどのようにレビューし、どの判断で採用・修正・不採用にしたかを示す。

## 記録する観点

- AIに依頼した内容
- AIの出力概要
- そのまま採用しなかった理由
- 採用した場合の修正点
- 不採用にした場合の理由
- 設計観点のレビュー
- 凝集度・結合度のレビュー
- セキュリティ観点のレビュー
- テスト容易性のレビュー
- 評価基準との対応確認

## レビュー記録テンプレート

| 日付 | 対象 | AI出力概要 | 判断 | レビュー観点 | 修正・不採用理由 | 最終反映先 |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-20 | 要件定義・Issue分割 | 評価基準を満たすアプリ題材、業務フロー、GitHub Issue粒度の案 | 修正採用 | スコープ、評価基準網羅性、LoopEngineeringで読める粒度 | 「ピックアップ項目だけ満たす」方向に寄らないよう、全評価基準を満たす前提へ修正。Issueは人間確認後 `loop:ready` にする運用へ変更 | `docs/requirements_definition.md`, `docs/detailed_design.md`, GitHub Issues |
| 2026-06-20 | DB/Ridgepole運用 | `db/Schemafile` にまとめる案、Ridgepole apply/dry-run手順 | 修正採用 | DB変更安全性、保守性、レビュー容易性 | 1ファイル集中は変更衝突とレビュー負荷が高いため、1 table 1 fileの `db/schemas/tables/*.schema` 方針へ修正 | `db/Schemafile`, `db/schemas/tables/*.schema`, `docs/db_schema_operations.md` |
| 2026-06-20 | 認証/認可 | Devise session、JWT、Pundit policyの実装案 | 修正採用 | 標準gem活用、責務分離、セキュリティ | 独自認証へ寄せずDevise/JWT/Punditを明示利用。API認証と画面sessionを分離し、policy testで確認 | `app/controllers/api/v1/auth_controller.rb`, `app/services/jwt_token.rb`, `app/policies/*`, `test/requests/api_v1_auth_test.rb` |
| 2026-06-20 | 外部連携 | Slack/Google Calendar連携を直接HTTP呼び出しで実装する案 | 修正採用 | 凝集度、結合度、DI、テスト容易性 | controller/jobから直接Faradayを呼ばず、Factory/Client/Mockへ分離。実連携credentialがないローカルではmockを使う | `app/services/integrations/*`, `test/jobs/slack_delivery_job_test.rb`, `test/jobs/calendar_event_create_job_test.rb` |
| 2026-06-21 | Ruby基礎証跡補強 | 値オブジェクト、Range、Mutex、メタプログラミングの追加案 | 修正採用 | 不自然な機能追加を避ける、既存業務補助として説明できるか | 評価基準のためだけの独立サンプルにせず、検索、取込、Calendar payload、評価官候補集計に接続 | `app/value_objects/*`, `app/services/examiner_workload_cache.rb`, `docs/ruby_foundation_evidence.md` |
| 2026-06-21 | 横断テスト | 主要業務フローとEXPLAINのテスト追加案 | 修正採用 | 証拠駆動、過剰なE2E化の回避、CI時間 | ブラウザsystem testではなく、サービス層統合テストとquery EXPLAIN testを追加。画面確認は手動デモとrequest smokeで補完 | `test/integration/evaluation_lifecycle_test.rb`, `test/queries/search_query_quality_test.rb`, `docs/quality_test_evidence.md` |

## 運用方針

- 実装フェーズでAIに依頼した主要な設計・コード生成・テスト生成は、この表に記録する。
- 小さな文言修正や単純な補完は全件記録しなくてよい。
- 評価面談では、AIを使ったこと自体ではなく、AI出力を自責でレビューした根拠としてこの資料を使う。

## レビューで見た観点

- 設計: Rails標準のMVCに寄せつつ、状態遷移、外部連携、帳票、取込、資格反映はservice/usecaseへ分離した。
- 凝集度: `ReviewApplications::*`, `InterviewApplications::*`, `Integrations::*`, `Exporters::*` のように業務責務ごとに名前空間を分けた。
- 結合度: Slack/Calendarはclient factoryとmock clientを経由し、jobやserviceが外部APIの具体実装に直接依存しないようにした。
- セキュリティ: Devise/JWT/Pundit、Markdown sanitize、GitHub URL validation、Brakeman、bundler-auditで確認した。
- テスト容易性: 外部連携はmock/stub、QueryはEXPLAIN、主要業務はintegration testで検証できるようにした。
- 評価基準適合性: IssueごとのLoop ReportとEvidence Matrixで `R-xx` / `B-xx` とコードパスを紐づけた。
