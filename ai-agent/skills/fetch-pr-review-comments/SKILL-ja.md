---
name: fetch-pr-review-comments
description: ユーザーがPRコメントの確認、レビュー対応、レビュー指摘の修正を求めた場合は必ずこのスキルを使用すること。現在のブランチに対応するGitHub PRから未解決のレビューコメントを取得する。
---

# PR レビューコメント取得

現在のブランチに対応する GitHub プルリクエストから未解決のレビューコメントを取得します。

## 使い方

このスキルディレクトリ内のスクリプトを実行して未解決のレビューコメントを取得:

```bash
bash ~/.claude/skills/fetch-pr-review-comments/get_unresolved_review_comments.sh
```

## 備考

- `gh` CLI の認証が必要
- プルリクエストが紐付いているブランチでのみ動作
