#!/bin/bash

# --- 依存スクリプトのパス定義 ---
# 🌟 修正: 共通ロジックスクリプトのパスを追加
GET_TARGET_SCRIPT="$(dirname "$0")/get_project_and_target.sh"
# TMUX_SESSION_NAME="haskell_manager" <-- 削除

# スクリプトの存在チェック
if [ ! -f "$GET_TARGET_SCRIPT" ]; then
    echo "致命的なエラー: 依存スクリプト '$GET_TARGET_SCRIPT' が見つかりません。" >&2
    exit 1
fi
if ! command -v tmux &> /dev/null; then
    echo "致命的なエラー: tmux がインストールされていません。" >&2
    exit 1
fi


# 1. 🌟 修正: 共通スクリプトからプロジェクト名とターゲットを取得
TARGET_INFO=$("$GET_TARGET_SCRIPT")
if [ $? -ne 0 ]; then
    # get_project_and_target.sh のエラーメッセージをそのまま出力させる
    echo "$TARGET_INFO" >&2
    exit 1
fi

PROJECT_NAME=$(echo "$TARGET_INFO" | head -n 1)
TMUX_TARGET=$(echo "$TARGET_INFO" | tail -n 1)


# 2. ソフトリスタートコマンドを送信
# cabal repl に :quit を送信して終了させます。
echo "INFO: REPLセッション '$TMUX_TARGET' に ':quit' コマンドを送信します。" >&2
tmux send-keys -t "$TMUX_TARGET" ":quit" C-m

if [ $? -ne 0 ]; then
    # REPLウィンドウが存在しない可能性がある場合は、リスタートを試みずに警告を出す
    echo "警告: REPLウィンドウ '$TMUX_TARGET' が存在しないか、コマンド送信に失敗しました。" >&2
    echo "INFO: tstart_repl_auto を実行してウィンドウを起動してください。" >&2
    exit 1
fi

# 3. REPLを再実行 (cd は既に完了しているため、cabal repl のみでOK)
echo "INFO: REPLセッション '$TMUX_TARGET' で 'cabal repl' を再実行します。" >&2
#tmux send-keys -t "$TMUX_TARGET" "cabal repl" C-m
tmux send-keys -t "$TMUX_TARGET" "cabal repl repl-formatter:exe:repl-formatter --ghc-options='-ghci-script=./.ghci'" C-m
# 4. 結果出力
if [ $? -eq 0 ]; then
    echo "INFO: ソフトリスタートを完了しました。" >&2
else
    echo "WARNING: ソフトリスタート中にエラーが発生した可能性があります。" >&2
fi

exit $?
