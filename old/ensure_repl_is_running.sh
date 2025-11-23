#!/bin/bash

# --- 依存スクリプトのパス定義 ---
LOAD_ENV_SCRIPT="$(dirname "$0")/load_environment.sh"
GET_CONFIG_SCRIPT="$(dirname "$0")/get_config_value.sh"
START_SCRIPT_PATH="$(dirname "$0")/start_haskell_repl_session.sh"

# 1. 致命的なエラーチェック: 依存スクリプトの存在確認
if [ ! -f "$LOAD_ENV_SCRIPT" ]; then echo "致命的なエラー: $LOAD_ENV_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$GET_CONFIG_SCRIPT" ]; then echo "致命的なエラー: $GET_CONFIG_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$START_SCRIPT_PATH" ]; then echo "致命的なエラー: $START_SCRIPT_PATH が見つかりません。" >&2; exit 1; fi

# 2. 環境チェック (GHCI_CONNECTOR_ROOTの存在確認)
# このステップは、config.jsonへのアクセスに必要なツールルートの存在を保証する
"$LOAD_ENV_SCRIPT" "$0"
if [ $? -ne 0 ]; then exit 1; fi

# 3. 設定値の取得を集中化
TMUX_SESSION_NAME=$("$GET_CONFIG_SCRIPT" "tmux_session_name")
if [ $? -ne 0 ]; then 
    # エラーメッセージは get_config_value.sh が出力済み
    exit 1 
fi

# 4. tmuxセッションの存在確認
tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
    # セッションが存在しない場合: 起動スクリプトを実行
    echo "INFO: REPLセッション '$TMUX_SESSION_NAME' が起動していません。自動起動します。" >&2
    
    # start_haskell_repl_session.sh を呼び出す (引数は不要)
    "$START_SCRIPT_PATH"
    
    # 起動スクリプトが失敗したら、このスクリプトも終了
    if [ $? -ne 0 ]; then
        echo "エラー: REPLセッションの自動起動に失敗しました。" >&2
        exit 1
    fi
fi

exit 0
