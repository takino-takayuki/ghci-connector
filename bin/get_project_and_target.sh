#!/bin/bash

# ==========================================================
# get_project_and_target.sh (Bash)
# 目的: カレントディレクトリからプロジェクト名とtmuxターゲット文字列を抽出し、
#       それぞれを新しい行に標準出力に出力する。
#
# 出力フォーマット (2行):
# 1行目: <PROJECT_NAME>
# 2行目: <TMUX_TARGET>
# ==========================================================

# 依存するセッション名を固定
TMUX_SESSION_NAME="haskell_manager"

# 1. カレントディレクトリからプロジェクト名を自動抽出
PROJECT_DIR=$(pwd)
CABAL_FILE=$(find "$PROJECT_DIR" -maxdepth 1 -type f -name "*.cabal" -print -quit 2>/dev/null)
PROJECT_NAME=""

if [ -f "$PROJECT_DIR/cabal.project" ]; then
    PROJECT_NAME=$(basename "$PROJECT_DIR")
elif [ -n "$CABAL_FILE" ]; then
    PROJECT_NAME=$(basename "$CABAL_FILE" .cabal)
else
    # プロジェクト名が見つからない場合、エラーメッセージを出して終了
    echo "エラー: cabalプロジェクトルートではありません。'.cabal' または 'cabal.project' が見つかりません。" >&2
    exit 1
fi

# 2. ターゲットペインの動的な決定
WINDOW_NAME="${PROJECT_NAME}_Haskell_REPL"
TMUX_TARGET="$TMUX_SESSION_NAME:$WINDOW_NAME"

# 3. 結果を標準出力に出力 (呼び出し元で read で受け取る)
echo "$PROJECT_NAME"
echo "$TMUX_TARGET"

exit 0
