#!/bin/bash

# --- 依存スクリプトのパス定義 ---
# 🌟 修正: 共通ロジックスクリプトのパスを追加
GET_TARGET_SCRIPT="$(dirname "$0")/get_project_and_target.sh"

# スクリプトの存在チェック
if [ ! -f "$GET_TARGET_SCRIPT" ]; then
    echo "致命的なエラー: 依存スクリプト '$GET_TARGET_SCRIPT' が見つかりません。" >&2
    exit 1
fi
if ! command -v tmux &> /dev/null; then
    echo "致命的なエラー: tmux がインストールされていません。" >&2
    exit 1
fi


# 1. nvimから渡された引数の取得
# 1番目の引数: 送信するテキスト
TEXT_TO_SEND="$1"

if [ -z "$TEXT_TO_SEND" ]; then
    echo "エラー: 必要な引数 (TEXT_TO_SEND) が不足しています。" >&2
    exit 1
fi

# 2. 🌟 修正: 共通スクリプトからプロジェクト名とターゲットを取得
# 標準出力の1行目を PROJECT_NAME、2行目を TMUX_TARGET に格納
TARGET_INFO=$("$GET_TARGET_SCRIPT")
if [ $? -ne 0 ]; then
    # get_project_and_target.sh のエラーメッセージをそのまま出力させる
    echo "$TARGET_INFO" >&2
    exit 1
fi

PROJECT_NAME=$(echo "$TARGET_INFO" | head -n 1)
TMUX_TARGET=$(echo "$TARGET_INFO" | tail -n 1)


# 3. tmux send-keys コマンドを使用してテキストとEnterキーを送信
# C-m は Enter キーに相当
tmux send-keys -t "$TMUX_TARGET" -- "$TEXT_TO_SEND" C-m > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "警告: tmux send-keys の実行に失敗しました。ターゲットウィンドウ '$TMUX_TARGET' が開いているか、tstart_repl_autoを実行しているか確認してください。" >&2
    exit 1
fi

exit 0
