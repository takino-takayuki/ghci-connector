#!/bin/bash

# --- Haskellプロジェクトルートをconfig.jsonに設定するスクリプト ---
# 実行方法: ./bin/set_project_root.sh /path/to/your/haskell/project

# 1. 引数（新しいプロジェクトパス）のチェック
PROJECT_PATH="$1"

if [ -z "$PROJECT_PATH" ]; then
    echo "エラー: Haskellプロジェクトルートのパスを指定してください。" >&2
    exit 1
fi

# 2. ツール環境のロード
LOAD_ENV_SCRIPT="$(dirname "$0")/load_environment.sh"

if [ ! -f "$LOAD_ENV_SCRIPT" ]; then
    echo "致命的なエラー: 環境ロードスクリプト $LOAD_ENV_SCRIPT が見つかりません。" >&2
    exit 1
fi

# GHCI_CONNECTOR_ROOT (ツールルート) を取得し、環境チェックを実行
CONNECTOR_ROOT=$("$LOAD_ENV_SCRIPT" "$0")
if [ $? -ne 0 ] || [ -z "$CONNECTOR_ROOT" ]; then
    # load_environment.sh でエラーメッセージが出力済み
    exit 1
fi

CONFIG_FILE="$CONNECTOR_ROOT/config.json"

# config.json の存在チェック
if [ ! -f "$CONFIG_FILE" ]; then
    echo "【$0 実行中断】致命的なエラー: 設定ファイル $CONFIG_FILE が見つかりません。" >&2
    echo "ツールルート '$CONNECTOR_ROOT' にconfig.jsonを配置してください。" >&2
    exit 1
fi

# 3. config.json の値を更新
TEMP_FILE=$(mktemp)

# jqを使って 'haskell_project_root' の値を更新し、テンポラリファイルに出力
# --arg path "$PROJECT_PATH" でシェル変数をjqに安全に渡す
jq --arg path "$PROJECT_PATH" '.haskell_project_root = $path' "$CONFIG_FILE" > "$TEMP_FILE"

if [ $? -ne 0 ]; then
    echo "エラー: config.jsonの更新に失敗しました。jqの実行を確認してください。" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi

# 更新されたファイルを元の場所へ移動（原子的な更新）
mv "$TEMP_FILE" "$CONFIG_FILE"

echo "======================================================"
echo "✅ Haskellプロジェクトルートを config.json に設定しました。"
echo "   haskell_project_root = $PROJECT_PATH"
echo "======================================================"

exit 0
