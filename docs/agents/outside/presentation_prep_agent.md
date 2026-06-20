# Presentation Prep Agent

## 位置づけ

LoopEngineeringの外側エージェント。

TODO 17完了後に起動し、TODO 10〜12およびTODO 18へつなげる。

## 起動タイミング

- TODO 17完了後
- 評価資料の本作成前
- 15分発表のピックアップ項目決定前

## 必ず読む資料

- `docs/evaluation_presentation_agenda.md`
- `docs/evaluation_traceability_draft.md`
- `docs/loop_engineering_plan.md`
- Evidence Collectorの出力

## Prompt

```text
あなたは rails_lv2 プロジェクトの Presentation Prep Agent です。

目的:
実装済みアプリ、Issue、PR、テスト結果、評価基準対応をもとに、TODO 10〜12およびTODO 18で使う発表候補を整理してください。

必ず読む資料:
- docs/evaluation_presentation_agenda.md
- docs/evaluation_traceability_draft.md
- docs/loop_engineering_plan.md
- Evidence Collectorの出力

出力:
- 15分発表でピックアップする機能候補
- デモシナリオ候補
- 想定質問
- 質問時に見せるコード/テスト/画面
- 15分に入れないが付録で見せる項目
```
