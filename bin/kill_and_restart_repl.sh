#!/bin/bash

# --- 環境設定のロードとチェック ---
GET_CONFIG_SCRIPT="$(dirname "$0")/get_config_value.sh"
START_SCRIPT_PATH="$(dirname "$0")/start_haskell_repl_session.sh"

# 1. スクリプト存在チェック
if [ ! -f "$GET_CONFIG_SCRIPT" ]; then echo "致命的なエラー: $GET_CONFIG_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$START_SCRIPT_PATH" ]; then echo "致命的なエラー: $START_SCRIPT_PATH が見つかりません。" >&2; exit 1; fi

# 2. 設定値の取得を集中化
TMUX_SESSION_NAME=$("$GET_CONFIG_SCRIPT" "tmux_session_name")
if [ $? -ne 0 ]; then exit 1; fi

# 3. 既存のtmuxセッションを強制終了
echo "INFO: 既存のtmuxセッション '$TMUX_SESSION_NAME' を強制終了します。" >&2
tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null

# 4. 新しいセッションの起動
echo "INFO: 新しいREPLセッションを起動します。" >&2
"$START_SCRIPT_PATH"

if [ $? -eq 0 ]; then
    echo "INFO: ハードリスタートを完了しました。" >&2
else
    echo "WARNING: ハードリスタート中にエラーが発生した可能性があります。" >&2
fi

exit $?
