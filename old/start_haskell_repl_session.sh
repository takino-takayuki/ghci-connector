#!/bin/bash

# --- 環境設定のロードとチェック ---
LOAD_ENV_SCRIPT="$(dirname "$0")/load_environment.sh"
GET_CONFIG_SCRIPT="$(dirname "$0")/get_config_value.sh"

# 1. スクリプト存在チェック
if [ ! -f "$LOAD_ENV_SCRIPT" ]; then echo "致命的なエラー: $LOAD_ENV_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$GET_CONFIG_SCRIPT" ]; then echo "致命的なエラー: $GET_CONFIG_SCRIPT が見つかりません。" >&2; exit 1; fi

# 2. GHCI_CONNECTOR_ROOTの環境チェック（config.jsonのパス解決のため）
# load_environment.shが成功すれば $GHCI_CONNECTOR_ROOT の値が返るが、ここでは使わない
CONNECTOR_ROOT=$("$LOAD_ENV_SCRIPT" "$0")
if [ $? -ne 0 ]; then exit 1; fi

# 3. 設定値の取得を集中化
TMUX_SESSION_NAME=$("$GET_CONFIG_SCRIPT" "tmux_session_name")
REPL_COMMAND=$("$GET_CONFIG_SCRIPT" "repl_command")
# ⭐ 修正: config.jsonからHaskellプロジェクトルートを取得
HASKELL_PROJECT_DIR=$("$GET_CONFIG_SCRIPT" "haskell_project_root")

if [ $? -ne 0 ]; then exit 1; fi # エラーチェック

# ⭐ 修正: 作業ディレクトリとしてHaskellプロジェクトルートを使用
PROJECT_DIR="$HASKELL_PROJECT_DIR"

# ------------------------------

# 1. パス検証:
if [ ! -d "$PROJECT_DIR" ]; then
    echo "【$0 実行中断】エラー: プロジェクトルート '$PROJECT_DIR' は存在しないか、ディレクトリではありません。" >&2
    exit 1
fi

# 2. tmuxセッションの存在確認と起動
tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
    # セッションが存在しない場合: 新規セッションを作成し、REPLを起動
    echo "INFO: 新しいtmuxセッション '$TMUX_SESSION_NAME' を作成します。"
    
    tmux new-session -d -s "$TMUX_SESSION_NAME" -c "$PROJECT_DIR" "$REPL_COMMAND"

    echo "INFO: セッション '$TMUX_SESSION_NAME' がプロジェクト '$PROJECT_DIR' で起動しました。"
else
    # セッションが既に存在する場合: 
    echo "WARNING: tmuxセッション '$TMUX_SESSION_NAME' は既に存在します。"
    echo "         プロジェクトディレクトリが異なる場合は、既存のセッションを終了してください。"
fi

# 3. ユーザーにアタッチを促す
echo ""
echo "セッションにアタッチするには、次のコマンドを使用してください:"
echo "tmux attach -t $TMUX_SESSION_NAME"

exit 0
