# 人間レビュー・テコ入れタイミング

作成日: 2026-06-20

## この文書の位置づけ

この文書はTODO 14「Loopさせる際の人間のテコ入れタイミングを確定する」の成果物である。

TODO 13の [LoopEngineering実行計画](/Users/haruki.shimo/Documents/ruby_study_lv2/docs/loop_engineering_plan.md) を前提に、LoopEngineeringへ実装を任せる際、どのタイミングで人間が確認し、どの変更は承認なしに進めてよいか、どの変更は止めるべきかを定義する。

## 基本方針

- 人間確認は45分ごとの全loopでは行わない。
- 原則として2 loopごと、つまり90分ごとにまとめて確認する。
- ただし、DB、認証/認可、状態遷移、外部連携、評価基準充足に影響する変更は、定期確認を待たずに確認対象にする。
- 人間確認は「作業の進捗確認」ではなく、「設計判断、仕様差分、評価基準の網羅性、取り返しにくい変更」を見るために行う。
- Looperが判断に迷った場合は、実装を進めずIssueへ `human-review` を付けて止める。

## 確認タイミング

| 種別 | タイミング | 人間が見るもの | Looperの扱い |
| --- | --- | --- | --- |
| 定期確認 | 2 loopごと、約90分ごと | IssueのLoop Report、PR差分、テスト結果、未完了点 | `human-review` が不要なら次Issueへ進んでよい |
| 高リスク確認 | 高リスクIssueの1 loop完了時 | DB、認証/認可、状態遷移、外部連携、transaction、soft deleteの変更 | `human-review` labelを付け、確認まで次の破壊的変更はしない |
| ブロッカー確認 | 仕様矛盾、テスト原因不明、外部連携判断などが出た時 | 何が詰まっているか、選択肢、推奨案 | 作業停止。人間回答後に再開 |
| PR確認 | Issueの受け入れ条件を満たした時 | 変更内容、テスト、評価基準対応、残リスク | 承認後にmerge対象 |
| フェーズ確認 | 主要フェーズ完了時 | 複数Issue横断の整合性、次フェーズに進めるか | 人間承認後に次フェーズへ進む |

## 人間確認が必須の変更

以下は人間確認なしに確定してはいけない。

- DBのテーブル構成変更
- 主要associationの変更
- `ExamApplication`, `ReviewApplication`, `InterviewApplication`, `UserQualification` の責務変更
- 状態名、状態遷移、取消可否、同時進行レビュー制御の変更
- role/user_roles、Pundit policy、対応可能評価スキルの認可方針変更
- JWT、refresh token、session方針の変更
- `paranoia` を使う/使わないなど論理削除方針の変更
- Slack/Google Calendar連携の実API/mock方針の変更
- 評価基準対応表と矛盾する実装方針
- Issueのscopeを超える追加機能
- 15分発表で説明する前提が崩れる変更

## 人間確認なしに進めてよい変更

以下はIssueの受け入れ条件と既存docsに沿っている限り、Looper判断で進めてよい。

- 既に合意済みのモデルに対するvalidation追加
- 既に合意済みの画面に対するフォーム、一覧、詳細の実装
- controllerからservice/usecaseへ処理を移す責務分離
- テスト追加、テストデータ整備、Factory/Fixture追加
- RuboCop指摘の修正
- 明らかなtypo修正
- docs内の実装メモ追記
- mock clientの追加
- 既存方針に沿った例外クラスやvalidatorの追加

## 高リスクIssueの扱い

以下のlabelが付くIssueは高リスクとして扱う。

- `risk:high`
- `area:auth`
- `area:db`
- `area:workflow`
- `area:integration`

高リスクIssueでは、1 loop完了時点で以下をIssueコメントに残す。

```markdown
## Human Review Checkpoint

- Issue:
- Branch:
- Decision Needed:
- Changed Design:
- Affected Evaluation Criteria:
- Tests:
- Risk:
- Recommendation:
```

人間確認が不要と判断できる軽微な実装でも、`risk:high` のIssueではLoop Report内に「なぜ人間確認不要と判断したか」を書く。

## 定期確認で見る項目

2 loopごとの定期確認では、以下を見る。

- Issueの受け入れ条件が満たされているか
- 実行したテストと失敗/skipしたテスト
- 評価基準IDとの対応に漏れがないか
- 実装が要件定義・詳細設計と矛盾していないか
- 追加された仕様判断がないか
- 次のIssueへ進んでよいか
- 人間が先に確認すべきPR/Issueがないか

定期確認は細かなコードレビューではない。深いコードレビューはPR確認で行う。

## PR確認で見る項目

PR確認では、以下を確認する。

- Issue本文の受け入れ条件を満たしているか
- PR本文にIssue番号、実装内容、テスト、評価基準対応があるか
- 重要なファイル差分が説明と一致しているか
- 失敗テスト、未実行テスト、未解決TODOが残っていないか
- 評価資料へ転用する証跡がIssue/PRに残っているか
- merge後に次Issueへ進める状態か

PRをmergeしてよい条件:

- 必須テストが通っている
- 受け入れ条件を満たしている
- `human-review` の未解決事項がない
- 評価基準との対応がIssueまたはPRに記録されている

## フェーズ確認

以下の境目では、人間確認を必須にする。

| フェーズ | 確認する内容 |
| --- | --- |
| Rails基盤完了 | ローカル起動、Gem方針、DB、テスト基盤、Docker/ローカル構築方針 |
| 認証/認可完了 | session/JWT/refresh token、role/user_roles、Pundit、認可テスト |
| DB/ドメイン完了 | ER、association、状態、論理削除、index、migration |
| レビュー/面談ワークフロー完了 | 受験表明、レビュー依頼、面談応募、資格反映の業務整合性 |
| 外部連携完了 | Slack送信履歴、Google Calendar登録、mock/実連携、retry |
| ローカル確認完了 | TODO 17完了。TODO 10〜12に進めるか |

## 停止条件

Looperは以下の場合、必ず作業を止める。

- Issueの受け入れ条件と要件定義が矛盾している
- 詳細設計と実装しようとしている構造が矛盾している
- DB設計の修正なしでは実装できない
- 認可ルールが曖昧で、誤って情報を見せる可能性がある
- 状態遷移の正解が判断できない
- 既存Issueのscopeを超える実装が必要
- 評価基準を満たす証跡が作れない可能性がある
- テスト失敗の原因が15分以上不明
- 外部連携を実APIで動かすかmockで止めるか判断が必要

停止時はIssueに以下をコメントする。

```markdown
## Blocked

- Reason:
- Current State:
- Options:
- Recommended Option:
- Impact:
- Needed Decision:
```

## 人間レビューコメントの扱い

人間が確認した結果は、IssueまたはPRにコメントとして残す。

コメント例:

```markdown
## Human Review Result

- Decision: approved / changes requested / split issue / stop
- Notes:
- Required Changes:
- Approved To Continue:
```

口頭やチャットで決めた内容も、最終的にはIssue/PRに転記する。これはTODO 18で評価資料を作る際の証跡にするためである。

## GitHub label運用

人間確認に関係するlabelは以下の通り。

| Label | 付けるタイミング | 外すタイミング |
| --- | --- | --- |
| `loop:review-required` | Issue作成直後 | 人間が内容を確認し、実装可能と判断した時 |
| `loop:ready` | 人間がIssueを実装可能と判断した時 | Looperが着手して `loop:in-progress` にする時 |
| `human-review` | 人間判断が必要になった時 | 人間がIssue/PRに判断を書いた時 |
| `loop:blocked` | Looperが進められない時 | ブロック理由が解消した時 |
| `risk:high` | 高リスクIssue作成時 | 原則外さない |
| `evidence` | 評価資料に転用できる証跡がある時 | 原則外さない |
| `loop:done` | 受け入れ条件を満たした時 | 原則外さない |

Issue Splitter / Registrar や Issue Quality Reviewer は `loop:ready` を付けない。`loop:ready` への変更は人間が行う。

## TODO 15への接続

TODO 15では、このレビュータイミングを前提に、サブエージェント構成と役割分担を確定する。

特に以下を定義する。

- Issue分割エージェントが作るIssueを誰がレビューするか
- Issue品質レビューエージェントが確認する項目
- 評価基準トレーサビリティエージェントが確認する漏れ
- 実装後証跡収集エージェントが集めるIssue/PR/Loop Report
