# 証拠駆動開発

作成日: 2026-06-20

## 目的

`SkillEvidenceHub` の開発では、実装完了を「コードを書いたこと」ではなく、「要件・評価基準を満たした証拠をPR上で説明できること」として扱う。

この運用により、評価面談で以下を説明できる状態にする。

- どの評価基準を満たしたか
- どのコード、設定、画面、テストが証拠になるか
- どの確認方法で担保したか
- 残リスクや未検証項目が何か

## 基本ルール

- Issueは「満たすべき要件・評価基準」を定義する。
- 実装は「要件・評価基準を満たす証拠」を作る。
- PRは「なぜ満たしたと言えるか」をEvidence Matrixで説明する。
- Reviewでは、コード差分だけでなく証拠の十分性を確認する。

## Evidence Matrix

すべての実装PRは、`.github/PULL_REQUEST_TEMPLATE.md` の `Evidence Matrix` を埋める。

| 要件 / 評価基準 | 証拠 | 確認方法 | 残リスク |
| --- | --- | --- | --- |
| R-31 認証 | Devise session login/logout実装 | request test | なし |

### 要件 / 評価基準

Issueに記載されたAcceptance Criteria、`R-xx`、`B-xx` を書く。

### 証拠

以下のいずれかを具体的に書く。

- コードパス
- テストパス
- 設定ファイル
- 画面名/操作手順
- Issue/Loop Report
- docs

### 確認方法

以下のいずれかを具体的に書く。

- 実行したテストコマンド
- 通過したCI
- 手動確認手順
- セキュリティ/DB/状態遷移の確認内容

### 残リスク

未検証項目、後続Issueへ送る項目、mock止まりの外部連携などを書く。残リスクがない場合は「なし」と書く。

## PRレビュー観点

PRレビューでは以下を見る。

- Evidence Matrixが埋まっているか
- 要件/評価基準と証拠が対応しているか
- 証拠がコード、テスト、画面、設定のいずれかに紐づいているか
- テストだけでなく、なぜその実装で要件を満たすかが説明されているか
- 未検証項目や残リスクが隠れていないか

## LoopEngineeringでの扱い

Implementation Looperは、Issue完了時にEvidence Matrixを含むPRを作成する。

Test / QA Agentは、テスト結果だけでなくEvidence Matrixの妥当性も確認する。

Evidence Collectorは、PR上のEvidence MatrixをTODO 18の評価資料へ転用する。
