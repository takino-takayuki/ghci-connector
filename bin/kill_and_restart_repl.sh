#!/bin/bash

# --- 設定 ---
# config.jsonから設定を読み込む
CONFIG_FILE="$(dirname "$0")/../config.json"
TMUX_SESSION_NAME=$(jq -r '.tmux_session_name' "$CONFIG_FILE")
START_SCRIPT_PATH="$(dirname "$0")/start_haskell_repl_session.sh"

# プロジェクトルートのパスを引数として受け取る
PROJECT_DIR="$1"

# 1. 引数の検証
if [ -z "$PROJECT_DIR" ]; then
    echo "エラー: プロジェクトルートのパスを指定してください。" >&2
    exit 1
fi

# 2. 既存セッションの停止（リスタート部分）
echo "INFO: 既存のtmuxセッション '$TMUX_SESSION_NAME' の確認と停止を開始します。"

# セッションが既に存在するかチェック
tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null

if [ $? = 0 ]; then
    # セッションが存在する場合: 停止
    echo "INFO: セッション '$TMUX_SESSION_NAME' を停止します..."
    tmux kill-session -t "$TMUX_SESSION_NAME"
    echo "INFO: セッションを停止しました。"
else
    # セッションが存在しない場合
    echo "WARNING: 停止対象のセッション '$TMUX_SESSION_NAME' は存在しません。"
fi

# 3. 新しいセッションの起動
echo ""
echo "INFO: 新しいセッションの起動を開始します..."

# 既存の起動スクリプトを使用してREPLを再起動
# $PROJECT_DIR を引数として渡す
"$START_SCRIPT_PATH" "$PROJECT_DIR"

# 成功終了
exit 0
