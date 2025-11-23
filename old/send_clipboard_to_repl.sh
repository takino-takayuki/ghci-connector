#!/bin/bash

# --- 依存スクリプトのパス定義 ---
LOAD_ENV_SCRIPT="$(dirname "$0")/load_environment.sh"
ENSURE_RUNNING_SCRIPT="$(dirname "$0")/ensure_repl_is_running.sh"
SENDER_SCRIPT="$(dirname "$0")/send_to_haskell_repl.sh"

# 1. 致命的なエラーチェック: 依存スクリプトの存在確認
if [ ! -f "$LOAD_ENV_SCRIPT" ]; then echo "致命的なエラー: $LOAD_ENV_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$ENSURE_RUNNING_SCRIPT" ]; then echo "致命的なエラー: $ENSURE_RUNNING_SCRIPT が見つかりません。" >&2; exit 1; fi
if [ ! -f "$SENDER_SCRIPT" ]; then echo "致命的なエラー: $SENDER_SCRIPT が見つかりません。" >&2; exit 1; fi

# 2. 環境チェック (GHCI_CONNECTOR_ROOTの存在確認)
# load_environment.shの実行は、config.jsonへのアクセスに必要なGHCI_CONNECTOR_ROOTの存在を保証する
"$LOAD_ENV_SCRIPT" "$0"
if [ $? -ne 0 ]; then 
    # load_environment.sh でエラーメッセージは出力済み
    exit 1 
fi

# 3. REPLセッションの存在確認と自動起動
"$ENSURE_RUNNING_SCRIPT"

if [ $? -ne 0 ]; then
    echo "エラー: REPLセッションの起動に失敗しました。" >&2
    exit 1
fi

# 4. クリップボードの内容を取得
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

# 5. 複数行チェックと :{ :} ラッピング
COMMAND_TO_SEND="$CLIPBOARD_CONTENT"

if echo "$CLIPBOARD_CONTENT" | grep -q $'\n'; then
    # 複数行の場合、GHCiのブロックコメント構文でラップ
    # 注意: echo -e で \n を改行として解釈させる必要がある。
    # ここでは、文字列全体を単一の引数として渡すためにecho -eを使わず、
    # 複数行のGHCi入力に適した形式（各行を個別に送信）を検討すべき。

    # 一旦、echo -eが有効な環境向けに修正
    # COMMAND_TO_SEND=":{\n$CLIPBOARD_CONTENT\n:}" を修正し、echo -eで評価されるようにする
    # $CLIPBOARD_CONTENTの中にも改行が含まれているため、シェル変数の展開を利用する
    
    # 実行時の問題を回避するため、ここでは単純に改行を\nとして扱う文字列を生成する
    # そして send_to_haskell_repl.sh 側で処理できるようにする。

    # 複数行全体を単一の文字列として渡し、send_to_haskell_repl.shに処理を委譲
    COMMAND_TO_SEND=":{\n$CLIPBOARD_CONTENT\n:}"
fi

# 6. 既存の送信スクリプトを呼び出す
"$SENDER_SCRIPT" "$COMMAND_TO_SEND"

echo "INFO: クリップボードの内容をREPLに送信しました。" >&2
exit $?
