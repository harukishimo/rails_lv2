# 横断テスト証跡メモ

作成日: 2026-06-21

この文書は #23 の補助証跡である。評価資料へ転用できるよう、主要な品質観点とテスト/CIコマンドの対応を整理する。

| 評価基準 | 証跡 | 確認方法 |
| --- | --- | --- |
| R-07 例外処理 | `test/services/qualification_grant_service_test.rb`, `test/jobs/calendar_event_create_job_test.rb`, `test/services/status_change_event_record_service_test.rb` | 例外時のrollback、retry/discard、機密値redactionを確認 |
| R-25 バリデーション | `test/models/*`, `test/requests/review_applications_test.rb`, `test/requests/interview_applications_test.rb` | model/request testで入力制約と業務制約を確認 |
| R-28 複雑なクエリ | `test/requests/search_and_queue_test.rb`, `test/queries/search_query_quality_test.rb` | N+1抑制のquery countと `relation.explain` を確認 |
| R-37 テスト | `bin/ci`, `bin/rails test`, `bin/rubocop` | CIでtest/lint/security checkを一括実行 |
| B-08 OWASP | `bin/brakeman`, `bin/bundler-audit`, 認可policy/request tests | 静的解析、依存脆弱性、認可境界を確認 |
| B-14 テスト / ユニットテスト | `test/integration/evaluation_lifecycle_test.rb` と既存model/request/policy/job tests | 業務フロー、外部API mock、transaction、soft delete、policyを横断確認 |
| B-15 データベース | `test/queries/search_query_quality_test.rb`, soft delete model tests, Ridgepole CI step | EXPLAIN、論理削除、Ridgepole dry-run/applyを確認 |

`test/integration/evaluation_lifecycle_test.rb` は、受験表明、レビュー承認、面談応募、評価官割当、日程承認、Google Calendar mock登録、合格判定、資格反映、受験クローズまでを1本で確認する。
