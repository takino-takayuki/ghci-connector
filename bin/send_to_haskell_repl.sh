#!/bin/bash

# --- 1. デバッグトレースを明示的に無効化する ---
set +x 

# REPLが実行されているtmuxのターゲットを指定
CONFIG_FILE="$(dirname "$0")/../config.json"
# jqを使ってJSONから値を読み込む
TMUX_TARGET=$(jq -r '.tmux_target_pane' "$CONFIG_FILE")

# スクリプトに渡された最初の引数（送信したいテキスト）を変数に格納
COMMAND_TO_SEND="$1"

if [ -z "$COMMAND_TO_SEND" ]; then
    echo "エラー: 送信するテキストが指定されていません。" >&2
    exit 1
fi

# tmux send-keys コマンドを使用してテキストをREPLペインに送信
# 1. テキストを送信 ('Enter'キーは押さない)
# > /dev/null 2>&1 を追加し、全ての出力を破棄
tmux send-keys -t "$TMUX_TARGET" -- "$COMMAND_TO_SEND" > /dev/null 2>&1

# 2. 続けて Enter キーを送信して実行
# > /dev/null 2>&1 を追加し、全ての出力を破棄
tmux send-keys -t "$TMUX_TARGET" Enter > /dev/null 2>&1

# 成功終了
exit 0
