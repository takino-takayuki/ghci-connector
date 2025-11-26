#!/bin/bash

# ⭐ 修正 1: 最初の引数からコンポーネントタイプを取得 (デフォルトは 'test')
COMPONENT_TYPE="${1:-test}"

# --- 依存スクリプトのパス定義 ---
# 🌟 修正: 共通ロジックスクリプトのパスを追加
GET_TARGET_SCRIPT="$(dirname "$0")/get_project_and_target.sh"
# TMUX_SESSION_NAME="haskell_manager" <-- 削除
# ⭐ 修正 2: get_cabal_target.sh のパスを追加
GET_CABAL_TARGET_SCRIPT="$(dirname "$0")/get_cabal_target.sh"

# スクリプトの存在チェック
if [ ! -f "$GET_TARGET_SCRIPT" ] || [ ! -f "$GET_CABAL_TARGET_SCRIPT" ]; then
    echo "致命的なエラー: 依存スクリプトが見つかりません。" >&2
    exit 1
fi

if [ ! -f "$GET_TARGET_SCRIPT" ]; then
    echo "致命的なエラー: 依存スクリプト '$GET_TARGET_SCRIPT' が見つかりません。" >&2
    exit 1
fi

if ! command -v tmux &> /dev/null; then
    echo "致命的なエラー: tmux がインストールされていません。" >&2
    exit 1
fi


# 1. 共通スクリプトからプロジェクト名とターゲットを取得
TARGET_INFO=$("$GET_TARGET_SCRIPT")
if [ $? -ne 0 ]; then
    # get_project_and_target.sh のエラーメッセージをそのまま出力させる
    echo "$TARGET_INFO" >&2
    exit 1
fi

PROJECT_NAME=$(echo "$TARGET_INFO" | head -n 1)
TMUX_TARGET=$(echo "$TARGET_INFO" | tail -n 1)

# ⭐ 修正 3: 新規スクリプトを使って cabal ターゲットを取得
CABAL_TARGET=$("$GET_CABAL_TARGET_SCRIPT" "$PROJECT_NAME" "$COMPONENT_TYPE")
if [ $? -ne 0 ]; then
    echo "致命的なエラー: cabalターゲットの取得に失敗しました。" >&2
    echo "$CABAL_TARGET" >&2
    exit 1
fi

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
#tmux send-keys -t "$TMUX_TARGET" "cabal repl repl-formatter:exe:repl-formatter --ghc-options='-ghci-script=./.ghci'" C-m
tmux send-keys -t "$TMUX_TARGET" "cabal repl $CABAL_TARGET --ghc-options='-ghci-script=./.ghci'" C-m

if [ $? -ne 0 ]; then
    echo "警告: 'cabal repl' コマンドの再送信に失敗しました..." >&2
    exit 1
fi

echo "INFO: REPLセッションを '$COMPONENT_TYPE' 環境で再起動しました。" >&2
exit 0
