#!/bin/bash

# --- 環境設定のロードとチェック ---
GET_CONFIG_SCRIPT="$(dirname "$0")/get_config_value.sh"
START_SCRIPT_PATH="$(dirname "$0")/start_haskell_repl_session.sh"

# 1. スクリプト存在チェック
if [ ! -f "$GET_CONFIG_SCRIPT" ]; then echo "致命的なエラー: $GET_CONFIG_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$START_SCRIPT_PATH" ]; then echo "致命的なエラー: $START_SCRIPT_PATH が見つかりません。" >&2; exit 1; fi

# 2. 設定値の取得を集中化
TMUX_TARGET=$("$GET_CONFIG_SCRIPT" "tmux_target_pane")
if [ $? -ne 0 ]; then exit 1; fi

# 3. ソフトリスタートコマンドを送信
echo "INFO: REPLセッションに ':quit' コマンドを送信します。" >&2
tmux send-keys -t "$TMUX_TARGET" ":quit" Enter

# 4. 新しいセッションを起動
# start_haskell_repl_session.sh の中で tmux has-session チェックが行われ、セッションが存在しない場合にのみ起動される
"$START_SCRIPT_PATH"

# 5. 結果出力
if [ $? -eq 0 ]; then
    echo "INFO: ソフトリスタートを完了しました。" >&2
else
    echo "WARNING: ソフトリスタート中にエラーが発生した可能性があります。" >&2
fi

exit $?
