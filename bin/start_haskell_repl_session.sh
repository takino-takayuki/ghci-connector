#!/bin/bash

# --- 設定 ---
# REPLを起動するコマンド
REPL_COMMAND="cabal repl"
# jqを使ってJSONから値を読み込む
# REPLに使用するtmuxセッション名
CONFIG_FILE="$(dirname "$0")/../config.json"
TMUX_SESSION_NAME=$(jq -r '.tmux_session_name' "$CONFIG_FILE")
#TMUX_TARGET=$(jq -r '.tmux_target_pane' "$CONFIG_FILE")
# プロジェクトルートのパスを引数として受け取る
# -----------------

PROJECT_DIR="$1"

# 1. 引数の検証
if [ -z "$PROJECT_DIR" ]; then
    echo "エラー: プロジェクトルートのパスを指定してください。" >&2
    echo "使用法: $0 /path/to/your/haskell/project" >&2
    exit 1
fi

# パスが存在し、ディレクトリであることを確認
if [ ! -d "$PROJECT_DIR" ]; then
    echo "エラー: 指定されたパス '$PROJECT_DIR' は存在しないか、ディレクトリではありません。" >&2
    exit 1
fi

# 絶対パスに変換 (任意だが推奨)
PROJECT_DIR=$(realpath "$PROJECT_DIR")

# 2. tmuxセッションの存在確認と起動
# 指定されたセッション名を持つセッションが既に存在するかチェック
tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
    # セッションが存在しない場合: 新規セッションを作成し、REPLを起動

    echo "INFO: 新しいtmuxセッション '$TMUX_SESSION_NAME' を作成します。"
    
    # -d: セッションをデタッチモードで作成（すぐにターミナルにアタッチしない）
    # -c: 作業ディレクトリを指定
    # run-shell: ペインで実行する初期コマンドを指定
    tmux new-session -d -s "$TMUX_SESSION_NAME" -c "$PROJECT_DIR" "$REPL_COMMAND"

    echo "INFO: セッション '$TMUX_SESSION_NAME' がプロジェクト '$PROJECT_DIR' で起動しました。"
else
    # セッションが既に存在する場合: 
    # 既存のセッションの作業ディレクトリを変更し、新しいウィンドウでREPLを起動するなどの拡張も考えられますが、
    # シンプルに既存セッションにアタッチするよう促します。
    
    echo "WARNING: tmuxセッション '$TMUX_SESSION_NAME' は既に存在します。"
    echo "         プロジェクトディレクトリが異なる場合は、既存のセッションを終了してください。"
fi

# 3. ユーザーにアタッチを促す
echo ""
echo "セッションにアタッチするには、次のコマンドを使用してください:"
echo "tmux attach -t $TMUX_SESSION_NAME"

# 4. (任意) 続けてセッションにアタッチ
# tmux attach -t "$TMUX_SESSION_NAME"
