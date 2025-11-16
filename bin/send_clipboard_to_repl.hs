#!/bin/bash

# --- 設定 ---
CONFIG_FILE="$(dirname "$0")/../config.json"
SENDER_SCRIPT="$(dirname "$0")/send_to_haskell_repl.sh"
ENSURE_RUNNING_SCRIPT="$(dirname "$0")/ensure_repl_is_running.sh" # 自動起動スクリプト
# -----------------

# プロジェクトルートのパスを引数として受け取る (Neovimから渡されることを想定)
PROJECT_DIR="$1"
if [ -z "$PROJECT_DIR" ]; then
    echo "エラー: プロジェクトルートのパスを指定してください。" >&2
    exit 1
fi

# 1. REPLセッションの存在確認と自動起動 (シェルスクリプトで完結)
# 既存の自動起動スクリプトを呼び出し、REPLの起動を保証する
"$ENSURE_RUNNING_SCRIPT" "$PROJECT_DIR"

if [ $? -ne 0 ]; then
    echo "エラー: REPLセッションの起動に失敗しました。" >&2
    exit 1
fi

# 2. クリップボードの内容を取得 (シェルスクリプトで完結)
CLIPBOARD_CONTENT=""
if command -v pbpaste >/dev/null 2>&1; then
    CLIPBOARD_CONTENT=$(pbpaste)
elif command -v xclip >/dev/null 2>&1; then
    CLIPBOARD_CONTENT=$(xclip -selection clipboard -o)
elif command -v xsel >/dev/null 2>&1; then
    CLIPBOARD_CONTENT=$(xsel -b)
else
    echo "エラー: クリップボード取得ツール (pbpaste, xclip, xsel) が見つかりません。環境設定を確認してください。" >&2
    exit 1
fi

if [ -z "$CLIPBOARD_CONTENT" ]; then
    echo "エラー: クリップボードが空か、内容を取得できませんでした。" >&2
    exit 1
fi

# 3. 複数行チェックと :{ :} ラッピング (シェルスクリプトで完結)
COMMAND_TO_SEND="$CLIPBOARD_CONTENT"
# 改行文字が含まれているかチェック (grep -q $'\n' を使用)
if echo "$CLIPBOARD_CONTENT" | grep -q $'\n'; then
    # 複数行の場合、:{ \n ... \n :} の形式で囲む
    COMMAND_TO_SEND=":{\n$CLIPBOARD_CONTENT\n:}"
fi

# 4. 既存の送信スクリプトを呼び出す
if [ ! -f "$SENDER_SCRIPT" ]; then
    echo "エラー: 送信スクリプト $SENDER_SCRIPT が見つかりません。" >&2
    exit 1
fi

# 最終的なコマンド文字列を引数として渡し、REPLに送信
"$SENDER_SCRIPT" "$COMMAND_TO_SEND"

echo "INFO: クリップボードの内容をREPLに送信しました。" >&2
exit $?
