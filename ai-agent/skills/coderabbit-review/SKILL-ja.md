---
name: coderabbit-review
description: CodeRabbit を使ってコードレビューを実行する。CodeRabbit レビューを指示された場合は必ずこのスキルを使用すること。
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# CodeRabbit Review
このスキルは、CodeRabbit CLI を使用したコードレビューの実行方法と、受け取ったフィードバックへの対応方法を提供します。

## Instructions
1. `coderabbit auth status` で認証状態を確認する。未ログインの場合は、`coderabbit auth login` でログインするようユーザーに促す。
2. git status に基づいて、コミット前の変更とコミット済みの変更のどちらをレビューするか判断する。
3. サンドボックスを無効にして、適切な CodeRabbit コマンドを実行する:
   - コミット前の変更: `coderabbit --plain --type uncommitted`
   - コミット済みの変更: `coderabbit --plain --type committed`
4. 「Review Completed」というメッセージが表示されたら、レビュープロセスが完了したことを示す。
5. CodeRabbit からのレビューコメントがない場合は、問題が見つからなかったことをユーザーに伝える。
6. レビューコメントがある場合は、以下のように対応する:
   - 明らかなバグ、コーディング規約違反、セキュリティ問題、パフォーマンス改善の指摘は、すぐに修正する。
   - 過度に厳格な指摘、トレードオフを伴う変更、大規模なアーキテクチャ変更が必要な場合は、変更を行う前にユーザーに判断を仰ぐ。
7. CodeRabbit から受け取ったコメントの要約と、各コメントに対して行った対応をユーザーに報告する。

## Note
- CodeRabbit のレビューは 5 分以上かかる場合があるので、しばらくお待ちください。
- ユーザーとのコミュニケーションは日本語で行うこと。
