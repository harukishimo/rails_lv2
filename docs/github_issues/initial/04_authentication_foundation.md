# [LE] 認証基盤実装

## Goal

Deviseによる画面向けsession認証と、API向けJWT/refresh token rotationの土台を実装し、受験者・評価官・管理者の利用前提を作る。

## Context / Linked Docs

- docs/requirements_definition.md
- docs/detailed_design.md
- docs/evaluation_traceability_draft.md
- docs/loop_engineering_plan.md
- docs/agents/inside/implementation_looper_a.md
- docs/agents/outside/security_reviewer.md

## Evaluation Criteria

- R-31
- B-06
- B-08
- R-20
- R-25
- R-30

## Suggested Agent

- Implementation Looper A
- Security Reviewer

## Agent Prompt

- docs/agents/inside/implementation_looper_a.md
- docs/agents/outside/security_reviewer.md

## Review Status

- Current: loop:review-required
- Reviewed by:
- Review note:

## Scope

- Devise導入
- User modelのDevise認証に必要な最低限の属性整備
- Deviseによる画面向けログイン/ログアウト
- API向けJWT access tokenの発行/検証方針
- refresh token rotationのモデル/サービス方針
- 認証エラーの基本レスポンス
- 認証に関するrequest/model/service test

## Out of Scope

- role/user_rolesによる認可本実装
- 評価官対応可能スキル制御
- Google OAuth等の外部IDP本実装
- UIの作り込み

## Acceptance Criteria

- [ ] sessionログイン/ログアウトの基本動作がある
- [ ] Web画面のpassword hash/session管理にDeviseを使っている
- [ ] API JWTの発行/検証処理がある
- [ ] refresh token rotationの永続化/失効方針がある
- [ ] 認証失敗時の扱いがrequest specで確認されている
- [ ] JWT decode時の署名アルゴリズムが明示されている
- [ ] Security Reviewerで確認すべき観点がIssueコメントに残っている

## Implementation Notes

- Web画面の認証はDeviseを使う
- `jwt` gemを使う
- User/RefreshTokenのDB schema変更はRidgepoleの `db/Schemafile` で管理する
- refresh tokenはJWTではなくopaque token digest/rotation/revocation方針
- Deviseは画面の認証土台に限定し、業務固有の認可は後続IssueのPunditで扱う
- API JWT/refresh tokenはDevise任せにせず、`jwt` gemとRefreshTokenモデル/サービスで実装する
- 認可は後続Issueで扱う

## Tests / Verification

- [ ] Devise login/logout request spec
- [ ] Ridgepole dry-run/applyまたは未実行理由
- [ ] JWT発行/検証spec
- [ ] 期限切れtoken spec
- [ ] refresh token rotation spec
- [ ] 認証失敗spec

## Human Review Triggers

- [ ] JWT/refresh token方針を変更する必要がある
- [ ] Devise以外の認証方式へ変更する必要がある
- [ ] User schemaを詳細設計から大きく変更する必要がある
- [ ] Ridgepoleで表現できないschema変更が必要
- [ ] 外部IDPを先に入れる必要が出た
- [ ] セキュリティ上の判断が必要

## Dependencies

- [LE] Rails基盤構築
- [LE] 開発基盤・品質ゲート整備
