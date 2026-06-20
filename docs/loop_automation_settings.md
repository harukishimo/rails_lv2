# LoopEngineering定期実行設定

作成日: 2026-06-20

## この文書の位置づけ

この文書はTODO 15の成果物である。

LoopEngineeringを定期実行するためのエージェント設定、起動条件、停止条件、Codex automationの設定方針を定義する。

## 結論

定期実行は、Codex heartbeat automationで行う。

ただし、現時点ではGitHub Issue分割が未完了のため、automationは `PAUSED` で作成する。TODO 15の後半でIssueを登録し、人間が開始を承認した後に `ACTIVE` 化する。

## Automation設定

| 項目 | 設定 |
| --- | --- |
| Automation ID | `loopengineering-runner` |
| Name | `LoopEngineering Runner` |
| Kind | `heartbeat` |
| Destination | current thread |
| Schedule | 45分ごと |
| Status | `PAUSED` |
| 目的 | GitHub Issueを読んで、時間と安全性が許す範囲で実装・検証・記録を進める |

## 起動前提

`ACTIVE` にする前に、以下を満たす必要がある。

- GitHub Issueが作成されている
- 人間確認済みのIssueに `loop:ready` labelが付いている
- 作成直後のIssueは `loop:review-required` とし、automationは実装対象にしない
- Issue本文が `.github/ISSUE_TEMPLATE/loop_development_ticket.md` に従っている
- `docs/agent_prompts.md` が最新である
- `docs/agents/` 配下の個別Agentプロンプトが最新である
- `docs/loop_engineering_plan.md` が最新である
- `docs/human_review_timing.md` が最新である
- GitHub CLIまたはGitHub連携がIssue/PR操作できる状態である
- 人間がLoopEngineering開始を承認している

## 定期実行エージェントの責務

定期実行エージェントは、毎回以下を行う。

1. `docs/loop_engineering_plan.md` を読む
2. `docs/human_review_timing.md` を読む
3. `docs/agents/README.md` を読む
4. 起動対象Agentの個別mdを `docs/agents/` 配下から読む
5. GitHub Issueの状態を確認する
6. `loop:ready` のIssueから着手候補を選ぶ
7. `loop:review-required`, `human-review`, `loop:blocked` のIssueは実装対象にしない
8. 最大2並列制約を確認する
9. DB/認可/同一model/serviceの並列禁止を確認する
10. 必要なAgentを選ぶ
11. 時間、安全性、依存関係が許す範囲で、複数の `loop:ready` Issueを順に進めてよい
12. IssueごとにLoop Reportを残す
13. 完了したIssueはPRを作成し、人間確認はPRレビューへ回す
14. 仕様判断や設計判断が必要な場合のみ `human-review` を付けて止める

## 人間確認の扱い

人間確認は45分ごとや2 loopごとには強制しない。

定期実行エージェントは、完了したIssueに対してPRを作成し、通常の確認はPRレビューへ回す。

`human-review` は、要件差分、DB/認可/状態遷移の方針変更、評価基準未達の恐れ、Issue scope超過など、PRレビュー前に人間判断が必要な場合だけ付ける。

## 定期実行Prompt

Codex automationに設定するpromptは以下。

```text
rails_lv2 プロジェクトのLoopEngineering Runnerとして動作してください。

目的:
GitHub IssueをLoopEngineeringの入力として読み、時間と安全性が許す範囲で実装・検証・記録を進める。

必ず読む資料:
- docs/loop_engineering_plan.md
- docs/human_review_timing.md
- docs/agents/README.md
- 起動対象Agentの個別md
- docs/requirements_definition.md
- docs/detailed_design.md
- docs/evaluation_traceability_draft.md

実行ルール:
- `loop:ready` のGitHub Issueだけを対象にする。
- `loop:review-required`, `human-review`, `loop:blocked` のIssueは実装対象にしない。
- 実装Looperの同時並行は最大2まで。
- DB schema/Ridgepole、認証/認可policy、同じmodel/serviceを触るIssueは並列禁止。
- 高リスクIssueでは docs/human_review_timing.md の確認条件を守り、リスクと判断内容をLoop Report/PR本文に残す。
- Issue本文、最新コメント、関連docsを読んでから作業する。
- 1回の起動で、時間と安全性が許す範囲で複数の `loop:ready` Issueを順に進めてよい。
- Issueごとに日本語のLoop Reportを残す。コマンド名、ファイルパス、ラベル名、エラー本文、評価基準IDなどの固有表現は原文のまま扱う。
- Issueの受け入れ条件を満たしたらPRを作成し、人間確認はPRレビューへ回す。
- 要件差分、DB変更方針、認可方針、状態遷移変更、評価基準未達の恐れがあり人間判断が必要な場合だけ、作業を止めてIssueに `human-review` を付ける。

出力:
- 対象Issue一覧
- 起動したAgent
- 実施内容
- 実行テスト
- Loop Report（日本語）
- 作成PR
- 次に必要なAction
- Human Review Needed
```

## 起動しない条件

以下の場合、定期実行エージェントは実装を進めない。

- `loop:ready` のIssueがない
- Issueが `loop:review-required` のまま
- GitHub Issueを取得できない
- 作業対象Issueに受け入れ条件がない
- 評価基準IDがIssueにない
- 依存Issueが未完了
- `human-review` が残っている
- ローカル作業ツリーに未確認の衝突がある
- 同じmodel/serviceを触る別branch/PRが進行中

## 起動タイミングが限定されるAgent

以下のAgentは定期実行で常時起動しない。

| Agent | 起動条件 |
| --- | --- |
| Security Reviewer | 認証/認可、JWT、外部連携、ログ、OWASP観点に触れたIssue完了時 |
| Local / Docker Verifier | Rails基盤構築後、Docker追加後、TODO 17直前 |
| Presentation Prep Agent | TODO 17完了後 |

## Active化するタイミング

以下が完了したら、`LoopEngineering Runner` を `ACTIVE` にする。

1. TODO 15でサブエージェント構成が確定
2. Issue Splitter / Registrarが初期Issueを登録
3. Issue Quality Reviewerが主要Issueを確認し、人間が `loop:ready` に変更
4. Dependency Plannerが実装順を整理
5. Traceability Reviewerが評価基準漏れを確認
6. 人間が開始を承認

## 停止するタイミング

以下の場合、automationは `PAUSED` に戻す。

- `human-review` が複数Issueに溜まった
- DB設計の再検討が必要
- 認証/認可方針が未確定
- 主要テストが連続失敗
- GitHub Issueと実装内容がズレている
- TODO 17が完了し、TODO 10〜12へ移る

## TODO 16への接続

TODO 16を開始する時点では、以下が揃っている状態を目指す。

- 初期GitHub Issue
- Issue品質レビュー結果
- 依存関係整理結果
- 評価基準トレーサビリティ確認結果
- `LoopEngineering Runner` automation
- `LoopEngineering Runner` の `ACTIVE` 化判断
