# LoopEngineering実行計画

作成日: 2026-06-20

## この文書の位置づけ

この文書はTODO 13「LoopEngineeringで回す開発フローを設計する」の成果物である。

TODO 16〜17でRailsアプリを実装・ローカル確認する前に、LoopEngineeringが何を入力にし、どの単位で実装し、どの形式で結果を返すかを定義する。

PRで証拠を残す運用は [証拠駆動開発](/Users/haruki.shimo/Documents/ruby_study_lv2/docs/evidence_driven_development.md) で定義する。

## リポジトリ

GitHubリポジトリ:

- `git@github.com:harukishimo/rails_lv2.git`

ローカルリポジトリ:

- `/Users/haruki.shimo/Documents/ruby_study_lv2`

remote:

- `origin`: `git@github.com:harukishimo/rails_lv2.git`

## 基本方針

- GitHub Issueを開発チケットとして扱う。
- GitHub IssueをLoopEngineeringの入力単位にする。
- Issue作成直後は `loop:review-required` とし、人間確認後に `loop:ready` へ変更する。
- Looperは `loop:ready` のIssueだけを実装対象にする。
- LooperはIssue本文、Issueコメント、リンクされたdocs、受け入れ条件を読んでから実装する。
- Issueは「何を作るか」だけでなく、「どの評価基準を満たすか」「どのテストで証明するか」まで含める。
- 1つのIssueは原則1〜3 loopで完了する粒度にする。
- 3 loopを超えるIssueは分割する。
- 1 loopは標準45分とする。
- 1回の定期起動で扱う作業量は1 loopに限定しない。時間、安全性、依存関係が許す範囲で、複数の `loop:ready` Issueを順に進めてよい。
- 夜間連続実行では、人間が事前に `loop:ready` にしたIssueは確認不要とみなし、`loop:ready` がなくなるまでLoopを終了しない。
- 夜間連続実行では、IssueごとのPRは作成しない。Issue単位branchで実装し、ローカルのPR Review Agent相当のレビューでblocking findingがないことを確認してから統合する。
- 最後の対応可能Issueが完了した時点で、そこまでの統合差分に対するまとめPRを1本作成し、IssueごとのLoop ReportとEvidence MatrixをPRコメントへ集約する。
- 人間確認は、`human-review` が必要な仕様判断・設計判断、または最後のまとめPR確認に限定する。通常のコードレビュー待ちではLoopを止めない。

## 1 loopの時間設計

| 種別 | 時間 | 用途 |
| --- | --- | --- |
| 標準loop | 45分 | 実装、テスト、自己レビュー、Issueコメント更新までを行う |
| 短縮loop | 15〜30分 | DB設計、認証/認可、状態遷移などの高リスク箇所の確認に使う |
| 最大loop | 60分 | 45分で区切ると破綻する作業でも、60分を超えたら必ず止める |

人間確認の詳細はTODO 14の [人間レビュー・テコ入れタイミング](/Users/haruki.shimo/Documents/ruby_study_lv2/docs/human_review_timing.md) で定義する。

TODO 13時点では以下を前提にする。

- 夜間連続実行では、IssueごとのPRではなくIssueコメントと最終まとめPRで証跡化する
- 高リスク箇所はLoop Reportと最終まとめPRのEvidence Matrixにリスク、判断内容、テスト結果を明記する
- 要件差分、DB変更方針、認可方針、状態遷移、評価基準未達の恐れで判断が必要な場合のみ即停止する

## GitHub Issue運用

### Issueの役割

GitHub Issueは、Looperが読む開発入力である。

Issueには最低限、以下を含める。

- 目的
- 関連docs
- 対象評価基準
- 対象スコープ
- スコープ外
- 受け入れ条件
- 実装メモ
- 実行すべきテスト
- 人間確認トリガー
- 依存Issue

### Issueとloopの関係

- Issue = Looperが読む入力契約
- loop = Issueを進める45分単位の実行
- 小さいIssueは1 loopで完了してよい
- 大きいIssueは最大3 loopまで許容する
- 3 loopで終わらない場合は、Issueを分割する

### Issueコメント

各loop完了時に、LooperはIssueへコメントする。

Loop Reportは日本語で書く。コマンド名、ファイルパス、ラベル名、エラー本文、評価基準IDなどの固有表現は原文のまま扱う。

コメント形式:

```markdown
## Loop Report

- Loop:
- 所要時間:
- ブランチ:
- 完了したこと:
- 実行テスト:
- 失敗/未実行テスト:
- 対応した評価基準:
- 変更ファイル:
- 残作業:
- ブロッカー:
- 次loop提案:
- 人間レビュー要否:
```

Issueコメントは、実装後にTODO 18の評価資料へ流用できる証跡として扱う。

## Label設計

GitHub Issueには以下のlabelを使う。

| Label | 意味 |
| --- | --- |
| `loop:review-required` | Issue作成後、人間確認待ち。Looperは実装しない |
| `loop:ready` | Looperが着手可能 |
| `loop:in-progress` | Looperが作業中 |
| `loop:blocked` | 仕様、環境、認証、外部要因で停止中 |
| `loop:done` | Issueの受け入れ条件を満たした |
| `human-review` | 人間確認が必要 |
| `risk:high` | DB、認証/認可、状態遷移、外部連携など高リスク |
| `type:feature` | 機能実装 |
| `type:test` | テスト追加/修正 |
| `type:docs` | docs更新 |
| `type:infra` | Docker、CI、環境構築 |
| `area:auth` | 認証/認可 |
| `area:db` | DB、migration、model |
| `area:workflow` | 受験表明、レビュー、面談、資格反映 |
| `area:integration` | Slack、Google Calendar、外部API |
| `area:quality` | test、lint、security check |
| `evidence` | 評価資料へ転用する証跡がある |

GitHub Projectsを使う場合は、以下のstatusを使う。

- Backlog
- Review Required
- Ready
- In Progress
- Human Review
- Blocked
- Done

GitHub Projectsを使わない場合は、labelで同等の状態を表現する。

## Branch/統合/PR運用

### Branch

Issueごとにbranchを切る。

命名:

```text
codex/issue-<issue-number>-<short-slug>
```

例:

```text
codex/issue-12-review-application
```

夜間連続実行で複数Issueを進める場合、各Issue branchは最新の統合ブランチから作成する。

統合ブランチ:

```text
codex/nightly-loop-integration
```

`codex/nightly-loop-integration` は夜間中のmain相当の統合先として扱う。最後にこのブランチから `main` へまとめPRを作成する。

### Commit

commit messageにはIssue番号を含める。

例:

```text
Implement review application submission flow

Refs #12
```

### Issue branch push

Issue単位branchの受け入れ条件を満たしたら、PRを作らずに以下を行う。

1. 対象テストと必要な品質チェックを実行する
2. ローカルのPR Review Agent相当を起動し、`main...issue_branch` または `codex/nightly-loop-integration...issue_branch` のdiffをレビューさせる
3. blocking findingがあれば修正し、再レビューする
4. blocking findingがなければIssue branchをpushする
5. `codex/nightly-loop-integration` に取り込む
6. 統合後に必要なテストを再実行する
7. IssueへLoop ReportとEvidence Matrixをコメントする
8. Issue labelを `loop:done` にする

### Pull Request

夜間連続実行では、IssueごとのPRは作成しない。

最後の対応可能Issueが完了し、`loop:ready` がなくなった時点で、`codex/nightly-loop-integration` から `main` へのまとめPRを作成する。

まとめPR本文には以下を含める。

- 対応Issue一覧
- Issueごとの実装内容
- Issueごとの実行テスト
- IssueごとのEvidence Matrix
- IssueごとのPR Review Agent相当レビュー結果
- 人間確認が必要な点

まとめPRでは、本文またはコメントに以下を含める。

```text
Closes #<issue-number>
Closes #<issue-number>
...
```

### Evidence Driven PR

PRは、実装差分だけでなく「なぜ要件・評価基準を満たしたと言えるか」を示す証拠として扱う。

夜間連続実行では、IssueごとのEvidence MatrixをIssueコメントに残し、最後のまとめPRへ集約する。

Evidence Matrixには最低限、以下を記載する。

- 要件 / 評価基準ID
- 証拠となるコード、設定、画面、Issue、Loop Report
- 確認方法となるテスト、コマンド、手動確認手順
- 未検証項目または残リスク

「テストが通った」だけでは証拠として不十分とする。どの評価基準を、どのコード・テスト・画面・設定で担保したかをPR上で追える状態にする。

高リスクIssueでは、Evidence Matrixに加えて、DB schema/Ridgepole、認証/認可、状態遷移、外部連携の判断内容をIssueコメントとまとめPRの `Security / DB / State Transition Notes` に書く。

## Looperの作業手順

1. `loop:ready` のIssueを読む。`loop:review-required` のIssueは読んでも実装しない
2. Issue本文、最新コメント、関連docsを読む
3. 受け入れ条件と評価基準対応を確認する
4. branchを作成する
5. 45分loopで実装する
6. 対象テストを実行する
7. 変更差分を自己レビューする
8. ローカルのPR Review Agent相当を起動し、Issue branch差分をレビューする
9. blocking findingがあれば、指摘をもとにLooperが修正し、再度レビューする
10. blocking findingがなければIssue branchをpushする
11. `codex/nightly-loop-integration` に取り込む
12. 統合後に必要なテストを再実行する
13. IssueへLoop ReportとEvidence Matrixをコメントする
14. Issueを `loop:done` に更新する
15. 未完了なら次loop提案をIssueへ残す
16. 人間判断が必要な場合のみ `human-review` を付けて停止する
17. 時間・依存関係に問題がなければ、次の `loop:ready` Issueへ進む
18. `loop:ready` がなくなったら、まとめPRを作成し、すべてのIssueの証跡をPR本文またはコメントへ集約する

## 各Issueの受け入れ条件

Issueの受け入れ条件は、最低限以下を満たす。

- 実装対象の機能が動作する
- 該当するmodel/request/policy/job/system等のテストがある
- 失敗するテストが残っていない
- 関連する評価基準IDがIssueコメントまたはまとめPRに記録されている
- ローカルのPR Review Agent相当でblocking findingがない
- 仕様判断が必要な未解決事項がIssueコメントに残っている
- 実装がdocsの要件・詳細設計と矛盾していない

## 停止条件

Looperは以下の場合、作業を止めてIssueへ記録する。

- 要件定義と詳細設計が矛盾している
- DB設計の変更が必要になった
- 認可方針の変更が必要になった
- 状態遷移の業務ルールに不明点が出た
- 評価基準を満たせない可能性が出た
- テストが連続で失敗し、原因が不明なまま15分以上経過した
- 外部連携の実装で実APIかmockかの判断が必要になった
- 実装範囲がIssueのスコープを超えた

## 初期Issue分割案

実装前に、GitHub Issuesとして以下を作成する。

| Issue案 | 概要 | 主な評価領域 | Risk |
| --- | --- | --- | --- |
| Rails基盤構築 | Rails app、Gemfile、DB、基本設定、ローカル起動 | B-03, B-10, B-11, B-12, B-14 | high |
| 開発基盤/CI | RuboCop、test、bundle audit、CI、bin/setup/bin/dev | B-03, B-10, B-12, B-14 | medium |
| 認証基盤 | session認証、API JWT、refresh token rotation | R-31, B-06, B-08 | high |
| 認可基盤 | roles/user_roles、Pundit、対応可能スキル制御 | R-32, B-07, B-08 | high |
| 受験対象マスタ | 言語/Lv/外部ナレッジ参照、評価官対応スキル | R-22, R-25, R-33, B-15 | high |
| 受験表明 | ExamApplication、受験開始、状態管理 | R-03, R-11, R-22, B-15 | high |
| レビュー依頼 | ReviewApplication、Submission、Markdown、取消 | R-15, R-17, R-25, R-27 | high |
| レビュー判定 | ReviewDecision、ReviewComment、差し戻し/承認/却下 | R-03, R-07, R-26, B-14 | high |
| 面談応募 | InterviewApplication、取消不可、注意喚起 | R-03, R-14, R-25, B-15 | high |
| 評価官割り当て | 自動フィルイン、手動変更、面談対応数集計 | R-02, R-06, R-28, B-15 | high |
| Calendar/Slack連携 | StatusChangeEvent、SlackDelivery、Calendar job | R-34, R-35, B-05, B-09 | high |
| 合格判定/資格反映 | InterviewResult、UserQualification、transaction | R-03, R-07, R-26, B-15 | high |
| 検索/一覧 | 受験者検索、レビューキュー、取得資格閲覧 | R-28, R-33, B-15 | medium |
| 主要画面の最低限UI/UX整備 | 主要業務フロー接続後に、ナビゲーション、導線、ステータス表示、フォームエラー、注意喚起、空状態を整える | B-02, B-14, B-15, R-37 | medium |
| 取込/帳票 | CSV/Excel取込、Excel/PDF出力 | R-15, R-16, R-23 | medium |
| REST/GraphQL/ActionCable | API、OpenAPI、GraphQL、リアルタイム通知 | B-09, R-29, R-30 | medium |
| ローカル/Docker確認 | Docker構築、ローカル構築、seed、起動確認 | B-03, R-38 | high |
| 評価証跡整理 | 実装後の証跡メモ、テスト結果、画面確認ログ | B-02, B-14, R-37 | medium |

## 初期Issueテンプレート

Issue作成時は、`.github/ISSUE_TEMPLATE/loop_development_ticket.md` を使う。

このテンプレートにより、LooperはIssueだけを読んでも以下を判断できる。

- 何を作るか
- なぜ作るか
- どの評価基準を満たすか
- どこまで作れば完了か
- どのテストを実行するか
- いつ人間確認を求めるか

## TODO 14への接続

TODO 14では、この計画を前提に、人間のテコ入れタイミングを詳細化する。

特に以下を決める。

- まとめPRレビューで何を見るか
- 高リスクIssueでどの時点で `human-review` を付けて止めるか
- 人間確認時の報告フォーマット
- 人間が承認するまで進めてはいけない変更
