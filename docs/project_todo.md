# プロジェクトTODO

作成日: 2026-06-20

## 進め方

- TODO番号は会話上の参照番号として維持するが、実行順はフェーズに従って調整する。
- TODO 1〜9は、メイン担当としてCodexと壁打ちしながら進める。
- TODO 13〜15で、LoopEngineeringに渡す前の開発フロー、人間レビュータイミング、サブエージェント構成を確定する。
- TODO 16〜17は、LoopEngineeringに実装・検証のループを任せる。
- TODO 10〜12は、実装・ローカル確認が終わった後、TODO 18の直前に実施する。
- 必要に応じて、調査・分類・設計レビューなどのサブエージェントを構築する。
- 評価資料は、実装前に本格作成しない。実装前はアジェンダと資料レイアウトに留め、実装後にコード・テスト・画面を根拠として本資料を作成する。

## TODO（実行順）

- TODO 1: Excelから全評価基準を漏れなく抽出する
- TODO 2: Wordメモから評価官の注視ポイントを抽出する
- TODO 3: 評価基準を「Rails特化」「バックエンド共通」に分類する
- TODO 4: 評価基準全体を満たせるミニマルアプリケーションの条件を定義する
- TODO 5: 作成するアプリケーションの機能概要・題材を確定する
- TODO 6: 各評価基準に対して、アプリのどの機能・設計・実装・テストで満たすかを仮対応表にする
- TODO 7: 要件定義書を作成する
- TODO 8: 画面一覧、機能一覧、DB設計、権限設計、バリデーション、エラーハンドリング、テスト方針を定義する
- TODO 9: 評価資料のアジェンダと資料レイアウトだけを先に作成する
- TODO 13: LoopEngineeringで回す開発フローを設計する
- TODO 14: Loopさせる際の人間のテコ入れタイミングを確定する
- TODO 15: 生やすサブエージェント構成と役割分担を確定する
- TODO 16: Railsアプリを実装する
- TODO 17: ローカルで起動して確認できる状態にする
- TODO 10: 15分発表でピックアップする項目を決める
- TODO 11: 15分発表用のデモシナリオを作成する
- TODO 12: 想定質問に対して、アプリ・コード・資料のどこを見せるかを整理する
- TODO 18: 実装後のコード・テスト・画面を根拠に、評価基準をすべて網羅する本資料を作成する
- TODO 19: 評価基準対応表・発表資料・デモ手順とアプリの整合性を最終確認する

## フェーズ分け

### Phase 1: 評価基準の把握

- TODO 1: Excelから全評価基準を漏れなく抽出する
- TODO 2: Wordメモから評価官の注視ポイントを抽出する
- TODO 3: 評価基準を分類する

成果物:

- 評価基準一覧
- 評価官注視ポイント
- Rails/Ruby側とバックエンド共通側の分類

### Phase 2: 要件定義

- TODO 4: ミニマルアプリケーションの条件定義
- TODO 5: アプリ題材・機能概要の確定
- TODO 6: 評価基準との仮対応表作成
- TODO 7: 要件定義書作成
- TODO 8: 画面・機能・DB・権限・テスト方針の定義

成果物:

- 要件定義書
- 機能概要
- 画面一覧
- DB設計
- 権限設計
- テスト方針
- 詳細設計書
- 評価基準仮対応表

### Phase 3: 発表・資料の骨子作成

- TODO 9: 評価資料のアジェンダと資料レイアウト作成

成果物:

- 評価資料アジェンダ
- 資料レイアウト

### Phase 4: LoopEngineering設計

- TODO 13: LoopEngineeringで回す開発フロー設計
- TODO 14: 人間のテコ入れタイミング確定
- TODO 15: サブエージェント構成・役割分担確定

成果物:

- LoopEngineering実行計画
- 人間レビュータイミング一覧
- サブエージェント構成表

### Phase 5: 実装・検証

- TODO 16: Railsアプリ実装
- TODO 17: ローカル起動・動作確認

成果物:

- ローカルで動くRailsアプリ
- 実装済み機能
- テスト結果
- 動作確認結果

### Phase 6: 発表内容・デモ・想定質問の確定

- TODO 10: 15分発表でピックアップする項目決定
- TODO 11: 15分発表用デモシナリオ作成
- TODO 12: 想定質問と提示箇所の整理

成果物:

- 15分発表でピックアップする機能・評価基準
- 15分デモシナリオ
- 想定質問対応表

### Phase 7: 評価資料の本作成

- TODO 18: 実装後の根拠を用いた評価資料作成

成果物:

- 評価基準対応表
- 15分発表資料
- デモ手順
- 想定質問回答メモ

### Phase 8: 最終整合性確認

- TODO 19: 評価基準対応表・発表資料・デモ手順・アプリの整合性確認

成果物:

- 最終確認結果
- 修正漏れ一覧

## 現在の進捗

- TODO 1: 完了
- TODO 2: 完了
- TODO 3: 完了
- TODO 4: 完了
- TODO 5: 完了
- TODO 6: 完了
- TODO 7: 完了
- TODO 8: 完了
- TODO 9: 完了
- TODO 13: 完了
- TODO 14: 完了
- TODO 15: 完了
- TODO 16: 完了
- TODO 17: 完了
- TODO 10: 未着手
- TODO 10〜12: TODO 18の本資料作成前に実施
- 次に着手するTODO: TODO 10

## 現在の成果物ファイル

- TODO 1〜3: `docs/evaluation_inventory.md`
- TODO 4: `docs/minimal_app_conditions.md`
- TODO 5: `docs/app_concept.md`
- TODO 6: `docs/evaluation_traceability_draft.md`
- TODO 7: `docs/requirements_definition.md`
- TODO 8: `docs/detailed_design.md`
- TODO 9: `docs/evaluation_presentation_agenda.md`
- TODO 13: `docs/loop_engineering_plan.md`
- TODO 13: `.github/ISSUE_TEMPLATE/loop_development_ticket.md`
- TODO 14: `docs/human_review_timing.md`
- TODO 15: `docs/agent_prompts.md`
- TODO 15: `docs/agents/README.md`
- TODO 15: `docs/agents/inside/*.md`
- TODO 15: `docs/agents/outside/*.md`
- TODO 15: `docs/loop_automation_settings.md`
- TODO 16〜17: Railsアプリ本体、`docs/implementation_evidence_index.md`
- 初期GitHub Issue本文: `docs/github_issues/initial/*.md`

## 初期GitHub Issue

すべて作成直後の状態は `loop:review-required`。人間確認後に必要なものだけ `loop:ready` へ変更する。

- #2: [LE] Rails基盤構築
- #3: [LE] 開発基盤・品質ゲート整備
- #4: [LE] 初期Issueバックログ作成・依存整理
- #5: [LE] 認証基盤実装
- #6: [LE] 認可基盤実装
