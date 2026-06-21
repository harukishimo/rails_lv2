# 開発クローズ準備メモ

作成日: 2026-06-21

## 位置づけ

この文書は、TODO 16「Railsアプリを実装する」と TODO 17「ローカルで起動して確認できる状態にする」を閉じ、TODO 10〜12 と TODO 18 の資料作成へ進むための引き継ぎメモである。

## 開発クローズ判定

- Railsアプリはローカルで起動できる
- 主要な受験表明、レビュー依頼、面談応募、面談評価官割り当て、日程承認、Slack通知、面談結果登録、取得資格反映を確認済み
- 管理者、受験者、評価官の主要画面と権限別ヘッダーを確認済み
- 受験対象、評価官、ユーザー、評価期、受験表明、レビュー依頼、面談応募のseedデータを整備済み
- Google Calendar登録は通常フローから廃止し、面談確定時はSlack通知で扱う方針へ変更済み
- 最新の全体テストは `bin/rails test` で成功済み

## 資料作成へ引き渡す主な証跡

| 種別 | 参照先 |
| --- | --- |
| 要件定義 | `docs/requirements_definition.md` |
| 詳細設計 | `docs/detailed_design.md` |
| 評価基準仮対応表 | `docs/evaluation_traceability_draft.md` |
| 実装後証跡Index | `docs/implementation_evidence_index.md` |
| AI開発レビュー補足 | `docs/ai_development_review.md` |
| アーキテクチャ判断 | `docs/architecture_decisions.md` |
| 品質・テスト証跡 | `docs/quality_test_evidence.md` |
| Ruby基礎証跡 | `docs/ruby_foundation_evidence.md` |
| Ridgepole運用証跡 | `docs/db_schema_operations.md` |

## クローズ前の残作業

1. 未コミット差分を確認する
2. `bin/rails test` を再実行する
3. `bin/ridgepole-dry-run` または同等のSchemafile確認を再実行する
4. `codex/nightly-loop-integration` をpushする
5. `main` 向けのまとめPRを作成する
6. レビュアーエージェントで統合差分を確認する
7. GitHub上で開発完了Issueをcloseする

## close候補Issue

開発実装・検証の対象として扱ったIssueは、まとめPRのレビュー後にcloseする。

| Issue | 内容 |
| --- | --- |
| #2 | Rails基盤構築 |
| #3 | 開発基盤・品質ゲート |
| #5 | 認証基盤 |
| #6 | 認可基盤 |
| #9 | 受験対象マスタ・評価官対応スキル |
| #10 | 受験表明ライフサイクル |
| #11 | レビュー依頼・提出物・Markdown |
| #12 | レビュー判定・コメント |
| #13 | 面談応募・日程調整 |
| #14 | 面談評価官割当 |
| #15 | 合格判定・資格反映 |
| #16 | 状態変更イベント・監査ログ |
| #17 | Slack通知連携 |
| #18 | 検索・一覧・評価官キュー |
| #20 | 受験対象取込・帳票出力 |
| #23 | 横断テスト・品質保証 |
| #24 | アーキテクチャ・AI・Git補足 |
| #26 | Ruby基礎証跡補強 |
| #27 | Ridgepole DB変更安全性 |
| #32 | 管理者向けユーザー・評価官管理 |
| #33 | 日本語対応と表示文言 |
| #36 | Tailwind CSS導入 |

## 次フェーズ

- TODO 10: 15分発表でピックアップする項目を決める
- TODO 11: 15分発表用のデモシナリオを作成する
- TODO 12: 想定質問に対して、アプリ・コード・資料のどこを見せるかを整理する
- TODO 18: 実装後のコード・テスト・画面を根拠に、評価基準をすべて網羅する本資料を作成する

## 資料作成時の注意

- 15分発表では全評価基準を口頭で読み上げず、代表機能と証跡をピックアップする
- 全評価基準の網羅性は付録の対応表で担保する
- Google Calendarは仕様変更により通常フローから外したため、発表ではSlack通知への変更理由を明示する
- GraphQL、ActionCable、Dockerなど実装対象外または知識補填扱いの項目は、過剰に実装済みと主張しない
- AIリテラシーはアプリ機能ではなく、開発中のAI出力レビュー方法として説明する
