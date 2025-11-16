#!/bin/bash

# --- 依存スクリプトのパス定義 ---
LOAD_ENV_SCRIPT="$(dirname "$0")/load_environment.sh"
GET_CONFIG_SCRIPT="$(dirname "$0")/get_config_value.sh"

# 1. 致命的なエラーチェック: 依存スクリプトの存在確認
if [ ! -f "$LOAD_ENV_SCRIPT" ]; then echo "致命的なエラー: $LOAD_ENV_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$GET_CONFIG_SCRIPT" ]; then echo "致命的なエラー: $GET_CONFIG_SCRIPT が見つかりません。" >&2; exit 1; fi

# 2. ⭐ 修正: load_environment.shの出力を変数に格納し、STDOUTに出力させない
CONNECTOR_ROOT=$("$LOAD_ENV_SCRIPT" "$0")
if [ $? -ne 0 ]; then exit 1; fi

# 3. 設定値の取得を集中化
TMUX_TARGET=$("$GET_CONFIG_SCRIPT" "tmux_target_pane")
if [ $? -ne 0 ]; then exit 1; fi

# 4. 送信するテキストの取得
TEXT_TO_SEND="$1"

if [ -z "$TEXT_TO_SEND" ]; then
    echo "エラー: 送信するテキストが指定されていません。" >&2
    exit 1
fi

# --- 6. tmux send-keys コマンドを使用してテキストとEnterキーを送信 ---
# コマンドとEnterキーを一度に送信し、全てのエラーと出力を破棄 (>/dev/null 2>&1)
# NOTE: C-m は Enter キー（キャリッジリターン）の代替です。
tmux send-keys -t "$TMUX_TARGET" -- "$TEXT_TO_SEND" C-m > /dev/null 2>&1

# tmux コマンド自体の実行に失敗した場合のチェック（オプション）
# ただし、tmux コマンドがエラー終了した場合、>&2 でリダイレクトされるため
# 上記の /dev/null 2>&1 で抑制されています。
# 厳密なエラーチェックをしたい場合は、上記行の後に以下を追加できます。
# if [ $? -ne 0 ]; then
#     echo "警告: tmux send-keys の実行に失敗した可能性があります (ターゲット: $TMUX_TARGET)。" >&2
# fi

# 成功終了

exit 0
