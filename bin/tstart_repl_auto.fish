# ==========================================================
# tstart_repl_auto (Fish Function)
# 目的: 既存の 'haskell_manager' tmuxセッションに、カレントHaskellプロジェクトの
#       REPLウィンドウを作成し、cabal replを実行する。
#       プロジェクト名とターゲット決定のロジックは外部Bashスクリプトに依存する。
# ==========================================================
function tstart_repl_auto
    
    set -l TMUX_SESSION_NAME "haskell_manager"
    set -l PROJECT_ROOT "$PROJECT_ROOT"
    
    if test -z "$PROJECT_ROOT"
        echo "致命的なエラー: 環境変数 \$PROJECT_ROOT が設定されていません。" >&2
        echo "解決策: コネクタフォルダで bin/start_manager.sh/fish を実行し、tmuxにアタッチしてください。" >&2
        return 1
    end
    
    set -l GET_TARGET_SCRIPT "$PROJECT_ROOT/bin/get_project_and_target.sh"
    
    # 1. 依存スクリプトとtmuxの存在チェック
    if not command -v tmux >/dev/null 2>&1
        echo "致命的なエラー: tmux がインストールされていません。" >&2
        return 1
    end
    
    if not test -f "$GET_TARGET_SCRIPT"
        echo "致命的なエラー: プロジェクト検出スクリプトが見つかりません。" >&2
        echo "パス: $GET_TARGET_SCRIPT が存在しません。PROJECT_ROOT が正しいか確認してください。" >&2
        return 1
    end

    # ----------------------------------------
    # 1. 必要な変数の定義とチェック
    # ----------------------------------------
    
    # tmuxセッション 'haskell_manager' が存在するか確認
    if not tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null
        echo "致命的なエラー: 全体管理tmuxセッション '$TMUX_SESSION_NAME' が見つかりません。" >&2
        echo "解決策: コネクタフォルダで bin/start_manager.sh を実行してください。" >&2
        return 1
    end

    set -l PROJECT_DIR (pwd)

    # 2. 共通Bashスクリプトから情報を取得 [PROJECT_NAME, TMUX_TARGET]
    set -l TARGET_INFO (command bash "$GET_TARGET_SCRIPT")

    if test $status -ne 0
        echo "$TARGET_INFO" >&2
        return 1
    end

    # Bashスクリプトの出力2行を取得
    set -l PROJECT_NAME "$TARGET_INFO[1]"
    set -l TMUX_TARGET "$TARGET_INFO[2]" # 例: haskell_manager:MyProject_Haskell_REPL
    
    # ⭐ 修正 1: 正規表現でCR/LFを含む全ての空白文字を確実に除去し、文字列比較の問題を回避
    set -l PROJECT_NAME (string replace -r '[\s\r\n]+' '' "$PROJECT_NAME")
    set -l TMUX_TARGET (string replace -r '[\s\r\n]+' '' "$TMUX_TARGET")

    set -l WINDOW_NAME (string split ":" "$TMUX_TARGET")[2] 
    set -l WINDOW_NAME (string replace -r '[\s\r\n]+' '' "$WINDOW_NAME")

    echo "INFO: プロジェクト名: $PROJECT_NAME" >&2
    echo "INFO: ターゲット: $TMUX_TARGET" >&2
    
    # ----------------------------------------
    # 3. 既存のウィンドウチェックと作成 (grepによる堅牢なチェック)
    # ----------------------------------------

    # ⭐ 修正 2: Fishの string match の代わりに grep を使用し、特殊文字による判定ミスを回避
    # -x (完全一致), -F (固定文字列) を指定
    tmux list-windows -t "$TMUX_SESSION_NAME" -F '#{window_name}' 2>/dev/null | grep -q -x -F "$WINDOW_NAME"
    set -l grep_status $status

    if test $grep_status -eq 0
        echo "INFO: 既存のREPLウィンドウ '$WINDOW_NAME' が見つかりました。新しいウィンドウは作成しません。" >&2
    else
    
      echo "INFO: REPLウィンドウを作成中: $WINDOW_NAME" >&2
      
      # ----------------------------------------
      # 4. 新規ウィンドウの作成とコマンド実行
      # ----------------------------------------
      
      # -c "$PROJECT_DIR" を指定し、カレントディレクトリを設定
      tmux new-window -d -t "$TMUX_SESSION_NAME:" -n "$WINDOW_NAME" -c "$PROJECT_DIR"
      
      if test $status -ne 0
          echo "致命的なエラー: tmuxウィンドウの作成に失敗しました。" >&2
          return 1
      end
      
      # ⭐ 修正 3: new-window直後の競合状態を避けるため、0.2秒待機する
      sleep 0.2
      
      # ターゲットウィンドウにコマンドを送信 (cabal repl 実行)
      tmux send-keys -t "$TMUX_TARGET" "cabal repl" \n
      
      if test $status -ne 0
          echo "致命的なエラー: 'cabal repl' の送信に失敗しました。ターゲット: $TMUX_TARGET (send-keys 終了コード: $status)" >&2
          # ウィンドウは作成されたため、成功として終了する
          return 0
      end

      echo "INFO: REPLウィンドウ '$WINDOW_NAME' を作成し、'cabal repl' を実行しました。" >&2

    end

    # ----------------------------------------
    # ⭐ 5. trepl を呼び出してウィンドウを自動で切り替える (追加)
    # ----------------------------------------
    echo "INFO: REPLウィンドウ '$WINDOW_NAME' に切り替えます..." >&2
    trepl
    
    if test $status -ne 0
        echo "警告: trepl関数によるウィンドウ切り替えに失敗しました。tmuxにアタッチしているか確認してください。" >&2
    end
    
    return 0
end
