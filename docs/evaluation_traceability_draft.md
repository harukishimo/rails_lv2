# 評価基準仮対応表

作成日: 2026-06-20

## この文書の位置づけ

この文書はTODO 6「各評価基準に対して、アプリのどの機能・設計・実装・テストで満たすかを仮対応表にする」の成果物である。

対象アプリは `SkillEvidenceHub`。受験者が受験対象マスタから受験したい言語/Lvを選択して受験表明を行い、その受験単位に紐づけて提出物ファイルまたはGitHubリポジトリとMarkdown形式の任意コメントを登録し、対応可能な評価官がレビュー・差し戻し・承認を行うRailsアプリとして扱う。評価基準本文や詳細カテゴリは外部ナレッジシステムで管理され、このアプリは外部ナレッジ参照を保持する。評価面談応募も同じ受験単位に紐づけ、評価官の自動フィルイン、割り振り確定、希望日時承認、Google Calendar連携、面談後の合格判定、取得資格反映、受験クローズを行う。

## 前提

- この表は実装前の仮対応表である。
- 実装後は、各行の「設計・実装予定」を実際のコードパス、テストパス、画面、API、設定ファイルへ置き換える。
- 発表資料の作成、15分面談で話す項目の選定はアプリ責務外。ただし、評価資料作成時に説明優先度を決めやすいよう「説明注力度」を仮で付ける。
- 説明注力度は、Wordメモから抽出した「Why」「概念理解」「AI出力レビュー」「標準との差分」「具体的実装証拠」を重視して付ける。

## 説明注力度

- 高: 面談で重点説明候補。試験官の深掘りが想定される。
- 中: 質問されたら実物で説明できるようにする。
- 低: 設定・資料・テストで証明する補助項目。

## Ruby/Rails側評価基準

| ID | 評価項目 | 満たす機能 | 設計・実装予定 | テスト予定 | 説明注力度 |
| --- | --- | --- | --- | --- | --- |
| R-01 | 変数・定数 | ロール、評価ステータス、許可操作の定義 | `Role`, `ReviewStatus`, `AllowedAction` などをfreeze済み定数または不変値として管理し、破壊的変更を避ける | 定数が破壊的変更されないこと、許可操作が想定値で固定されることをmodel/unit testで確認 | 中 |
| R-02 | 式 | 進捗集計、提出状況集計、レビュー判定、評価官自動フィルイン | 複雑な条件式を `ReviewProgressCalculator`, `SubmissionEligibilityPolicy`, `ExaminerSuggestionService`, `SearchQuery` などへ分離 | 集計結果、境界条件、nil/空配列時、評価官フィルイン候補順位をunit testで確認 | 中 |
| R-03 | 条件分岐 | 受験ライフサイクル、レビュー申請ワークフロー | `ExamApplicationTransitionService`, `ReviewTransitionService` でガード節・早期リターンを使い、不正状態遷移を早期に止める | 状態ごとの許可/不許可遷移、合格判定後のクローズ可否をservice/policy testで確認 | 高 |
| R-04 | メソッド | 提出物登録、レビュー依頼、差し戻し対応 | controllerに処理を置かず、サービス内もSRPを保つ小さいprivate methodへ分解 | service testで各責務の戻り値と副作用を確認 | 高 |
| R-05 | ブロック | 受験対象取込、通知送信、トランザクション処理 | 取込処理でブロックを受け取り、行ごとの処理を差し替え可能にする。lambda/procの使い分けを説明できる構造にする | proc/lambdaの引数チェック、取込ハンドラ差し替え、transaction blockのrollbackを確認 | 中 |
| R-06 | ハッシュ/配列 | ダッシュボード集計、検索結果整形 | Enumerableで受験対象、提出物、レビュー履歴を集計・整形する | 集計対象の絞り込み、grouping、並び順をunit testで確認 | 中 |
| R-07 | 例外処理 | 取込失敗、状態遷移失敗、外部連携失敗 | `ImportError`, `InvalidTransitionError`, `ExternalIntegrationError` など粒度別例外を定義し、UI/API/jobで扱い分ける | 例外種別ごとの表示、APIエラー、job retry/discardを確認 | 高 |
| R-08 | クラス | Slack送信、帳票生成、外部API連携 | FactoryパターンとDIで `SlackClientFactory`, `ExporterFactory`, `CalendarClient` を生成・差し替え可能にする | factory選択、DIによるmock差し替え、外部依存なしのunit testを確認 | 高 |
| R-09 | 継承 / super | 外部連携基底クラス、帳票生成基底クラス | `Integrations::BaseClient`, `Exporters::BaseExporter` に共通処理を集約し、未実装メソッドは `NotImplementedError` で明示 | 子クラス未実装時の例外、superで共通処理が呼ばれることを確認 | 高 |
| R-10 | ポリモーフィズム | Slack通知、Google Calendar連携、Mock連携 | `notify` や `create_event` など同一インターフェースで呼び出し、呼び出し側から具体クラス分岐を排除 | 複数clientを同じ呼び出しで扱えること、分岐が不要なことをunit testで確認 | 高 |
| R-11 | カプセル化 | 言語/Lv選択、提出物状態、レビュー状態 | 状態変更を直接カラム更新させず、状態遷移サービスや値オブジェクト経由にする | 直接変更できない業務ルール、公開メソッド経由の変更をmodel/service testで確認 | 高 |
| R-12 | モジュール | 監査ログ、テナントスコープ、検索allowlist | `Auditable`, `TenantScoped`, `Searchable` concernを使い、include/extend/prependの役割を分ける | concern適用クラスの振る舞い、scope適用、method lookup影響を確認 | 中 |
| R-13 | Struct | 取込行、検索条件、Google CalendarイベントPayload | `ImportRow`, `SearchParams`, `CalendarEventPayload` を不変値オブジェクトとして扱う | keyword_init、freeze、値の受け渡し、意図しない変更が起きないことを確認 | 中 |
| R-14 | 日付・時間 | 評価期、提出期限、面談日時、資格取得日、Google Calendar登録 | `Time.zone` とActiveSupportを使い、Asia/Tokyo基準で期限・面談日時・資格取得日を扱う | timezone変換、期限判定、Calendar登録日時、資格取得日をmodel/service testで確認 | 高 |
| R-15 | ファイル操作 | 受験対象Excel/CSV取込、提出物ファイルアップロード | CSVは `foreach`、Excelはstreaming可能な読み取りを使い、大容量を一括展開しない | 大量行取込、メモリに依存しない処理単位、取込エラー行の扱いを確認 | 高 |
| R-16 | 外部連携（PDF/Excel） | 受験対象マスタ、レビュー結果、提出状況の出力 | Excel出力は `caxlsx` 等、PDF出力は `prawn` 等で実装。発表資料生成ではなく管理帳票出力に使う | 出力ファイルの生成、文字化け、件数、権限ごとの出力可否を確認 | 中 |
| R-17 | 正規表現 | GitHub URL、添付ファイル名、タグ入力の検証 | 入力長制限、危険な正規表現回避、必要に応じて `Regexp.timeout` を設定する | 正常/異常URL、長大入力、ReDoS想定入力のvalidation testを確認 | 高 |
| R-18 | 範囲（Range） | 評価期、提出期限、面談日時、期間検索 | 日付範囲は `cover?` を中心に使い、期間検索や期限内判定でinclude?との差分を説明できるようにする | 期限境界、開始/終了日、日付範囲検索をunit/request testで確認 | 中 |
| R-19 | 並行処理（スレッド） | 集計キャッシュ更新、競合説明用サービス | `Mutex` を使った共有資源保護の小さなサービスを用意し、レースコンディションを説明できるようにする | Mutexなし/ありの差分、共有カウンタやキャッシュ更新の安全性をunit testで確認 | 中 |
| R-20 | gem / bundler | 依存管理、脆弱性チェック、アップデート方針 | `Gemfile`, `Gemfile.lock`, `bundle audit`, バージョン制約、アップデート手順をdocsに残す | `bundle exec bundle-audit`、CI上の依存チェック、deprecation対応メモを確認 | 中 |
| R-21 | メタプログラミング | 提出物種別、検索条件、enum周辺の共通化 | 追跡可能性を損なわない範囲で、allowlistベースの定義生成や検索条件定義を行う | 定義された項目だけが有効になること、未知項目が拒否されることをunit testで確認 | 中 |
| R-22 | ActiveRecord CRUD | 受験対象マスタ、受験表明、提出物、レビュー、面談応募、取得資格 | 基本CRUDを実装し、一覧では関連を `includes` してN+1を防ぐ | request/system test、bulletまたはquery count確認でN+1対策を確認 | 高 |
| R-23 | 一括処理 | 受験対象取込、帳票出力、提出状況集計 | `find_each`, `in_batches`, ActiveJobを使い、大量データを分割処理する | 大量データseedでbatch処理、job実行、途中失敗時の再実行を確認 | 高 |
| R-24 | マイグレーション | 受験対象マスタ、提出物、レビュー、監査ログ | Ridgepoleを導入し、`db/Schemafile`、dry-run確認、apply手順、危険DDL回避、データパッチ、リリース順序をdocs化する | Ridgepole dry-run/check、apply、rollback相当の復旧手順、data migrationのdry runを確認 | 中 |
| R-25 | バリデーション | GitHub URL、提出物、受験表明、Markdownコメント、面談日時、取得資格 | `GithubRepositoryUrlValidator`, `SubmissionFileValidator`, `ExamApplicationValidator`, `MarkdownCommentValidator`, `InterviewScheduleValidator`, `UserQualificationValidator` 等を作る | custom validatorの正常/異常系、重複受験表明、Markdownサニタイズ、期限外登録、資格重複をmodel testで確認 | 高 |
| R-26 | コールバック | 監査ログ、通知予約、状態変更履歴、取得資格反映 | `after_commit` で監査ログ・通知予約を行い、transaction rollback時に副作用が残らないようにする。資格反映は明示的なusecase内transactionで行い、安易なcallback依存にしない | rollback時に通知/監査ログが作られないこと、commit後に作られること、資格反映の原子性を確認 | 高 |
| R-27 | 関連付け | 提出物種別、添付、コメント、通知先 | 提出物をSTIまたはポリモーフィック関連で表現し、コメント/添付先を汎用化する | 関連の作成、削除制約、N+1対策、STI/ポリモーフィック挙動をmodel testで確認 | 中 |
| R-28 | 複雑なクエリ | 受験対象検索、提出状況一覧、レビュー一覧 | `preload/eager_load/includes` を画面用途ごとに使い分け、SQL発行回数とメモリ負荷を説明できるようにする | query count、検索条件、joinが必要な条件、並び順をrequest/unit testで確認 | 高 |
| R-29 | View / Decorator | レビューコメント保存、ステータス変更履歴表示 | Turboだけに閉じず、必要箇所はfetch/Stimulusで非同期保存し、Presenter/Decoratorで表示責務を分離する | system testで非同期更新、request testでAPI応答、decorator unit testを確認 | 中 |
| R-30 | Controller | 提出物登録、レビュー、Calendar登録 | Controllerは認可・入力受け渡しに留め、業務処理はservice/usecaseへ委譲。機密パラメータはfilterする | request testで振る舞い、service testで業務ロジック、ログに機密値が出ないことを確認 | 高 |
| R-31 | 認証 | Deviseによる画面ログイン、API JWT、Google連携 | 画面はDeviseのCookie/session、APIはJWT + refresh token。外部IDPはローカル再現可能なOmniAuth/Google OAuth相当を用意する | login/logout、JWT発行/検証/期限切れ、refresh token rotationをrequest testで確認 | 高 |
| R-32 | 認可 | 管理者、受験者、評価官、対応可能評価スキル、テナント | PunditでRBAC、テナントスコープ、状態別操作制御、評価官の対応可能スキル制御を実装する | policy testで管理者/受験者/評価官/対応外評価官の閲覧・編集・承認可否を確認 | 高 |
| R-33 | 検索 | 受験対象検索、提出状況検索、レビュー検索、受験者検索 | Ransackをallowlistで制御し、言語・FW・Lv・ステータス・レビューコメント・取得資格で検索する | 許可検索条件、拒否条件、複数モデル検索、index利用をrequest/unit testで確認 | 高 |
| R-34 | 非同期・タスク | 受験対象取込、帳票出力、Slack/Calendar連携 | ActiveJobで非同期化し、冪等性キー、retry_on/discard_on、処理済み管理を実装する | job retry、二重実行防止、失敗時状態、再実行の安全性をjob testで確認 | 高 |
| R-35 | HTTPクライアント / 外部API連携 | Slack通知、Google Calendar予定作成 | base URL、認証情報、timeout、5xx/timeout時のexponential backoffを持つclientを作る | WebMock等で5xx/timeout/retry、認証ヘッダ、payloadをunit/job testで確認 | 高 |
| R-36 | ログ / その他 | 監査ログ、認可失敗ログ、操作ログ | Rails log filtering、AuditLogモデル、ログローテート設定、追跡IDを設計する | 重要操作ログ、認可失敗ログ、機密値フィルタ、監査ログ検索を確認 | 高 |
| R-37 | テスト | 全体テスト構成、CI、seed/factory | model/request/policy/job/system test、Factory、テストユーティリティ、CIを整備する | CIで全テスト、lint、bundle auditを実行する | 高 |
| R-38 | 基盤構築 | Railsアプリ基盤、認証、権限、開発支援 | Rails新規構築、認証、権限、複数ロール、scaffold方針、Ridgepole/Schemafile運用、util、local/docker setupを整備する | `bin/setup`, `bin/dev`, Ridgepole dry-run/apply、docker compose、初期seed、system smoke testを確認 | 高 |

## バックエンド共通側評価基準

| ID | 評価項目 | 満たす機能 | 設計・実装予定 | テスト予定 | 説明注力度 |
| --- | --- | --- | --- | --- | --- |
| B-01 | AIリテラシー | アプリ機能ではなく開発補足資料で証明 | AIを用いて `SkillEvidenceHub` を開発する際、AI出力をそのまま採用せず、設計・凝集度・結合度・セキュリティ・テスト容易性・評価基準適合性の観点でレビューした記録を別資料に残す | アプリの自動テスト対象ではない。資料レビューで、AI出力、採用/不採用判断、修正理由、最終コードとの差分を確認する | 高 |
| B-02 | システム要件定義/基本設計 | docs群、要件定義、スコープ管理 | 要件、制約、リスク、優先度、関係者、合意事項をdocs化し、後続変更はこのdocsを更新する運用にする | docsレビュー、要件と対応表の整合チェック、必要ならMarkdown lintを確認 | 高 |
| B-03 | 環境構築 / Docker | Docker構築、ローカル構築 | Dockerfile/docker-composeでRails、DB、Redisを起動可能にし、ストレージ事情に配慮してローカル構築も第一級手順にする | `bin/setup`, `bin/dev`, `docker compose up` の起動確認を行う | 高 |
| B-04 | アーキテクチャ構成 | service/usecase、値オブジェクト、外部連携境界 | Rails MVCに加え、usecase/service、value object、integration client、policyで責務分離する。クリーン/DDDの対応図をdocs化する | 依存方向のレビュー、service単体テスト、architecture doc確認 | 高 |
| B-05 | 凝集と結合 | 通知、取込、帳票、認可の分離 | Slack/Calendar/MockをDIし、外部サービス具体実装へ直接依存しない。取込・帳票・認可も責務分離する | mock差し替え、密結合を避けたunit test、外部依存なしテストを確認 | 高 |
| B-06 | 認証 | Devise session認証、JWT、refresh token | 画面はDeviseによるCookie/session、APIはaccess token + refresh token rotationで実装する | login/logout、JWT期限切れ、refresh token再発行、古いtoken無効化をrequest testで確認 | 高 |
| B-07 | 認可 | RBAC、テナントスコープ、policy | 権限テーブル、ロール、リソース、操作を設計し、Pundit policyとpolicy testで表現する | 管理者/受験者/評価官/別テナントの閲覧・編集・承認可否を確認 | 高 |
| B-08 | OWASP | アクセス制御、暗号、Injection、認証失敗対策 | Broken Access Control、Cryptographic Failures、Injection、Authentication Failuresへの対策をコードとdocsに紐づける | 認可漏れ、SQL injection回避、password hash、session reset、入力制限をtest/security checkで確認 | 高 |
| B-09 | 通信規格 | REST API、GraphQL、ActionCable、OpenAPI | `/api/v1` REST、GraphQL Query/Mutation、ActionCable通知、OpenAPI定義を用意。gRPCは `.proto` 例と比較説明をdocsに残す | request test、GraphQL spec、ActionCable test、OpenAPI lint/表示確認を行う | 高 |
| B-10 | フォーマッター/リンター | RuboCop、formatter、pre-commit | RuboCop設定、必要なルールカスタマイズ、overcommitまたはpre-commit hookを用意する | CIとローカルでrubocop実行、hook動作確認を行う | 中 |
| B-11 | ビルドツール | JS/CSS build、環境変数、hot reload | jsbundling/cssbundling等を使い、entrypoint、出力先、環境変数、本番build、hot reloadを説明できる構成にする | `bin/dev`、production build、環境変数注入、asset配信を確認 | 中 |
| B-12 | パッケージマネージャー | Bundler、脆弱性チェック、更新方針 | Gemfile/Gemfile.lock、バージョン制約、bundle audit、依存更新方針をdocs化する | bundle install、bundle audit、CI上の依存チェックを確認 | 中 |
| B-13 | Git | 開発履歴、復旧手順、運用メモ | branch/commit方針、stash/rebase/reset/revert/cherry-pickの使い分けをdocsに残し、実開発履歴と紐づける | Git運用メモのレビュー、必要に応じて操作ログ/コミット履歴を確認 | 低 |
| B-14 | テスト / ユニットテスト | APIテスト、DBテスト、mock/stub | request/model/policy/job/system test、外部APIのmock/stub、テストDB分離、Factory/Fixtureを整備する | CIで全テスト、外部API stub、transaction rollback、factory整合性を確認 | 高 |
| B-15 | データベース | EXPLAIN、index、受験対象DB設計、受験表明、評価官マスタ、資格反映、ロック | 受験対象、受験表明、レビュー申請、提出物、レビュー、面談応募、面談結果、取得資格、評価官対応スキル、ステータス変更イベント、Slack送信履歴、監査ログのschemaを設計し、index、EXPLAIN、lock_version、FOR UPDATE方針を持つ | EXPLAIN結果、index有無、重複受験表明防止、評価官自動フィルイン、割り振り確定、資格重複防止、楽観/悲観ロック、競合更新をmodel/integration testで確認 | 高 |

## 要確認項目の吸収方針

Excel上で本文が空欄だった `その他開発知見 / トランザクション処理・個人情報マスキング` は正式評価対象か要確認。ただし、後続設計では以下で吸収可能なようにする。

| 要確認項目 | 吸収する機能 | 設計・実装予定 | テスト予定 |
| --- | --- | --- | --- |
| トランザクション処理 | レビュー申請、状態遷移、提出物登録、監査ログ | 複数モデル更新はtransactionでまとめ、rollback時に通知・監査ログの副作用が残らない設計にする | transaction成功/失敗、rollback、副作用抑制をservice/model testで確認 |
| 個人情報マスキング | ユーザー情報、メールアドレス、ログ、CSV/Excel出力 | ログのfilter、権限別表示、エクスポート時のmask optionを用意する | 権限別表示、ログ出力、export時のmask有無をrequest/unit testで確認 |

## TODO 7への接続

TODO 7では、この仮対応表を前提に要件定義書へ落とし込む。

要件定義書では、以下を明確にする。

- 業務要件
- 機能要件
- 非機能要件
- スコープ外
- ロールと権限
- データモデル
- API方針
- 外部連携方針
- テスト方針
- ローカル構築とDocker構築の両方の方針
