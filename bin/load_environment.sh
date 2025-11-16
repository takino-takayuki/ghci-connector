#!/bin/bash

CALLER_SCRIPT="$1"
if [ -z "$CALLER_SCRIPT" ]; then
    CALLER_SCRIPT="不明なスクリプト"
fi

# --- 1. GHCI_CONNECTOR_ROOT のチェック ---
PROJECT_ROOT="$GHCI_CONNECTOR_ROOT"

if [ -z "$PROJECT_ROOT" ]; then
    echo "【${CALLER_SCRIPT} 実行中断】致命的なエラー: 環境変数 GHCI_CONNECTOR_ROOT が設定されていません。" >&2
    echo "システム連携を続行できません。プロジェクトルートを設定してください。" >&2
    exit 1
fi

# ⭐ 修正: config.json のチェックを削除 (処理の責務を分離)

# 標準出力で PROJECT_ROOT の値を返す
echo "$PROJECT_ROOT"

# 成功終了
exit 0
