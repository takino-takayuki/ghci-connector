function scratch-ctl
    # コマンド引数のチェック
    if test (count $argv) -lt 1
        echo "使用方法: scratch-ctl (new|save|load|list)" >&2
        return 1
    end

    set -l command $argv[1]
    set -l SCRATCH_FILE "current_scratch.hs"
    set -l SCRATCH_DIR $SCRATCH_REPO_DIR

    # 必須ディレクトリとGitリポジトリの存在確認
    if not test -d "$SCRATCH_DIR/.git"
        echo "エラー: スクラッチリポジトリ $SCRATCH_DIR/.git が見つかりません。先に git init を実行してください。" >&2
        return 1
    end

    # スクラッチリポジトリに移動
    cd "$SCRATCH_DIR"

    switch "$command"
    case "save"
        set -l name $argv[2]
        set -l commit_msg "Scratch: "

        # ファイルが存在しない場合はエラー
        if not test -f "$SCRATCH_FILE"
            echo "エラー: 保存する $SCRATCH_FILE がありません。" >&2
            return 1
        end

        # 1. タイムスタンプIDの生成 (例: 20251127_215700)
        set -l timestamp (date +%Y%m%d_%H%M%S)

        # 2. ファイル名とコミットメッセージの決定
        if test -n "$name"
            set -l new_filename "$timestamp"_"$name".hs
            set commit_msg $commit_msg"Saved as $name"
        else
            set -l new_filename "$timestamp"_scratch.hs
            set commit_msg $commit_msg"Autosave"
        end

        # 3. リネームとGitコミット
        mv "$SCRATCH_FILE" "$new_filename"
        git add "$new_filename"
        git commit -m "$commit_msg"
        
        # ログメッセージ
        echo "INFO: スクラッチを $new_filename として履歴に保存しました。"
        
    case "new"
        # 1. 現在のスクラッチを保存 (名前なしで自動保存)
        scratch-ctl save
        
        # 2. 基本フォーマット（テンプレート）の内容を新しい current_scratch.hs として作成
        set -l template_content "module Main where\n\nmain :: IO ()\nmain = putStrLn \"Scratchpad\"\n\n-- ここに落書きコードを記述 --\n"
        echo -e "$template_content" > "$SCRATCH_FILE"
        
        # 3. Gitの追跡から外す (新しい白紙を誤ってコミットしないため)
        git reset "$SCRATCH_FILE" 2>/dev/null
        
        echo "INFO: 白紙の $SCRATCH_FILE を作成しました。"
        
    case "*"
        echo "不明なコマンドです: $command" >&2
        return 1
    end
end