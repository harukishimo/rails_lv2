# Ruby基礎証跡メモ

作成日: 2026-06-21

この文書は #26 の補助証跡である。業務仕様を増やすのではなく、既存の検索、受験対象取込、Google Calendar payload、評価官候補選定の補助実装としてRuby基礎項目を説明できるコードパスを整理する。

| 評価基準 | コードパス | 説明 |
| --- | --- | --- |
| R-01 変数・定数 | `SearchParams::CONTEXTS`, `EvaluationTargets::ImportRow::PERMITTED_ATTRIBUTES`, `Integrations::Calendar::EventPayload::PAYLOAD_KEYS` | allowlistやpayload keyをfreeze済み定数として固定し、実行時の破壊的変更を防ぐ |
| R-04 メソッド | `Search::BaseSearch`, `EvaluationTargets::Importer`, `Integrations::Calendar::EventPayload` | controllerに検索・取込・payload組立を置かず、小さいメソッドへ分解している |
| R-13 Struct | `SearchParams`, `EvaluationTargets::ImportRow`, `Integrations::Calendar::EventPayload::Payload` | 入力値を不変値オブジェクト化し、業務処理へ渡す値の形を明確にする |
| R-18 Range | `EvaluationPeriod#cover?` | 評価期の開始日・終了日の境界を `Range#cover?` で判定する |
| R-19 Thread / Mutex | `ExaminerWorkloadCache` | 評価官候補の月次対応数スナップショットを `Mutex#synchronize` で保護し、同時アクセス時の共有Hash破壊を避ける |
| R-21 メタプログラミング | `SearchParams::METHOD_NAMES.each { define_method(...) }` | allowlistに存在する検索条件だけアクセサを生成し、未知パラメータは `SearchParams::UnknownKeyError` で拒否する |

`ExaminerWorkloadCache` はDB更新の排他制御ではなく、評価官候補選定時に参照する小さな集計スナップショットである。DB整合性は既存のvalidation、transaction、lock方針に委ねる。
