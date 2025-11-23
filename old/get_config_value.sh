##!/bin/bash

# --- 設定値の取得 ---
CONFIG_KEY="$1"

if [ -z "$CONFIG_KEY" ]; then
    echo "エラー: 取得する設定キーを指定してください。" >&2
    exit 1
fi

# 集中管理された環境ロードコマンドを呼び出す
LOAD_ENV_SCRIPT="$(dirname "$0")/load_environment.sh"

# 1. 環境変数のチェックとGHCI_CONNECTOR_ROOTの取得
# load_environment.shが成功すれば $GHCI_CONNECTOR_ROOT の値が返る
CONNECTOR_ROOT=$("$LOAD_ENV_SCRIPT" "$0")

if [ $? -ne 0 ] || [ -z "$CONNECTOR_ROOT" ]; then
    # load_environment.sh でエラーメッセージが出力済み
    exit 1
fi

CONFIG_FILE="$CONNECTOR_ROOT/config.json"

# ⭐ 修正: config.json の存在チェックを追加 (責務の追加)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "【$0 実行中断】致命的なエラー: 設定ファイル $CONFIG_FILE が見つかりません。" >&2
    echo "システム連携を続行できません。config.jsonをルートディレクトリに配置してください。" >&2
    exit 1
fi

# 2. jqを使ってJSONから値を読み込む
CALLER_SCRIPT="$0"
VALUE=$(jq -r ".$CONFIG_KEY" "$CONFIG_FILE" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$VALUE" ]; then
    echo "【$CALLER_SCRIPT 実行中断】エラー: config.jsonからキー '$CONFIG_KEY' の値を取得できませんでした。" >&2
    exit 1
fi

echo "$VALUE"
exit 0
