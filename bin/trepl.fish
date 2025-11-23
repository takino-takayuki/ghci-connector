# ==========================================================
# trepl (Fish Function)
# 目的: カレントHaskellプロジェクトのREPLウィンドウに切り替える (select-window)
# ==========================================================
function trepl
    
    set -l TMUX_SESSION_NAME "haskell_manager"
    set -l PROJECT_ROOT "$PROJECT_ROOT"
    
    if test -z "$PROJECT_ROOT"
        echo "致命的なエラー: 環境変数 \$PROJECT_ROOT が設定されていません。" >&2
        return 1
    end
    
    set -l GET_TARGET_SCRIPT "$PROJECT_ROOT/bin/get_project_and_target.sh"
    
    if not command -v tmux >/dev/null 2>&1
        echo "致命的なエラー: tmux がインストールされていません。" >&2
        return 1
    end
    
    if not test -f "$GET_TARGET_SCRIPT"
        echo "致命的なエラー: プロジェクト検出スクリプトが見つかりません: $GET_TARGET_SCRIPT" >&2
        return 1
    end

    # 1. 共通Bashスクリプトから情報を取得 [PROJECT_NAME, TMUX_TARGET]
    set -l TARGET_INFO (command bash "$GET_TARGET_SCRIPT")

    if test $status -ne 0
        echo "致命的なエラー: プロジェクト情報取得スクリプトが失敗しました。" >&2
        echo "$TARGET_INFO" >&2
        return 1
    end

    # ターゲットをサニタイズ
    set -l TMUX_TARGET (string replace -r '[\s\r\n]+' '' "$TARGET_INFO[2]")
    set -l WINDOW_NAME (string split ":" "$TMUX_TARGET")[2]
    set -l WINDOW_NAME (string replace -r '[\s\r\n]+' '' "$WINDOW_NAME")

    # 2. ウィンドウの存在チェック (tstart_repl_autoが作成済みであることを確認)
    tmux list-windows -t "$TMUX_SESSION_NAME" -F '#{window_name}' 2>/dev/null | grep -q -x -F "$WINDOW_NAME"
    set -l grep_status $status

    if test $grep_status -ne 0
        echo "エラー: REPLウィンドウ '$WINDOW_NAME' が存在しません。" >&2
        echo "解決策: 'tstart_repl_auto' を実行してウィンドウを作成してください。" >&2
        return 1
    end
    
    # 3. ウィンドウに切り替え
    # NOTE: $TMUX_TARGET は haskell_manager:trump2_Haskell_REPL の形式
    # ユーザーが現在tmuxセッションにアタッチしていることを前提とします。
    echo "INFO: tmuxセッション '$TMUX_SESSION_NAME' 内のウィンドウ '$WINDOW_NAME' に切り替えます。" >&2
    
    tmux select-window -t "$TMUX_TARGET"
    
    if test $status -ne 0
        echo "警告: ウィンドウ切り替えコマンドは実行されましたが、tmuxの外部から実行された場合、見た目に変化はありません。" >&2
        echo "tmuxにアタッチしている端末（例: nvimのターミナルペイン）から実行すると効果があります。" >&2
    end
    
    return 0
end