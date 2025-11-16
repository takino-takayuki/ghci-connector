#!/bin/bash

# --- 設定 ---
CONFIG_FILE="$(dirname "$0")/../config.json"
TMUX_TARGET_PANE=$(jq -r '.tmux_target_pane' "$CONFIG_FILE")
REPL_COMMAND=$(jq -r '.repl_command' "$CONFIG_FILE")
# -----------------

PROJECT_DIR="$1"
if [ -z "$PROJECT_DIR" ]; then
    echo "エラー: プロジェクトルートのパスが指定されていません。" >&2
    exit 1
fi

# 2. ペイン内部でREPLコマンドを再実行（ソフトリスタート）
echo "INFO: ペイン内部でREPLコマンドを再実行（ソフトリスタート）します。"

# ⭐ 修正箇所: 既存のプロセスを中断せず、GHCi終了コマンド ':quit' を送信
tmux send-keys -t "$TMUX_TARGET_PANE" ':quit' Enter

# GHCiが終了し、シェルが応答するまで待機 (GHCiは比較的速く終了するため、1.0秒で十分なはずです)
sleep 1.0 

# ペインをクリア (不要な出力を消す)
tmux send-keys -t "$TMUX_TARGET_PANE" 'clear' Enter

# 画面リセットまで待機
sleep 0.5 

# REPLコマンドを再送信
tmux send-keys -t "$TMUX_TARGET_PANE" "$REPL_COMMAND" Enter

echo "INFO: REPLの再起動コマンドをペインに送信しました。"

exit 0
