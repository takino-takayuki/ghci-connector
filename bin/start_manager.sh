#!/bin/bash

# --- 1. スクリプトの自己位置特定と設定 ---
# 実行された場所に関わらず、スクリプト自身の親ディレクトリをコネクタのルートとする
CONNECTOR_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- 設定 ---
SESSION_NAME="haskell_manager"  # セッション名を固定
MANAGER_WINDOW_NAME="Main"      # 管理用ウィンドウ名を固定

# --- 2. グローバル環境変数の設定（最重要） ---
# セッションが存在するか否かに関わらず、グローバル変数を設定（更新）します。
# これにより、コネクタフォルダを移動した場合でも、再実行するだけで設定が更新されます。
echo "Setting global environment variable: PROJECT_ROOT=$CONNECTOR_ROOT"
tmux set-environment -g PROJECT_ROOT "$CONNECTOR_ROOT"

# --- 3. セッションが存在するかチェックし、存在しなければ作成 ---
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "--- NEW SESSION SETUP ---"
    echo "tmux セッション '$SESSION_NAME' を新規作成します。"

    # セッションを作成し、最初のウィンドウを管理用としてリネーム
    # -c オプションで、ウィンドウの初期ディレクトリをコネクタのルートに設定します。
    tmux new-session -d -s "$SESSION_NAME" -n "$MANAGER_WINDOW_NAME" -c "$CONNECTOR_ROOT"
    
    echo "Setup complete. The session is now running in detached mode."
else
    echo "--- SESSION ALREADY EXISTS ---"
    echo "既存のセッション '$SESSION_NAME' が見つかりました。"
    echo "PROJECT_ROOT の値が更新されました ($CONNECTOR_ROOT)。"
    echo "ウィンドウ構成は変更されません。"
fi

# --- 4. ユーザーへの通知と次のアクションの促し ---
echo ""
echo "=========================================================="
echo "REPL Manager セットアップ完了"
echo "=========================================================="
echo "PROJECT_ROOT (コネクタのルート) の値は: $CONNECTOR_ROOT"
echo ""
echo "--- 次のステップ ---"
echo "1. セッションにアタッチ: tmux attach -t $SESSION_NAME"
echo "2. Haskellプロジェクトフォルダに移動し、tstart_repl_auto を実行してください。"
echo "=========================================================="

exit 0
