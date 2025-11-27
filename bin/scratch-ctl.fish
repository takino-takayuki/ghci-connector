function scratch-ctl
    # ... (既存のコード: コマンド引数チェック、SCRATCH_REPO_DIR 設定、cd "$SCRATCH_DIR") ...
    if test (count $argv) -lt 1
        echo "使用方法: scratch-ctl (new|save|load|list)" >&2
        return 1
    end

    set -l command $argv[1]
    set -l SCRATCH_FILE "current_scratch.hs"
    set -l SCRATCH_DIR $SCRATCH_REPO_DIR

    if not test -d "$SCRATCH_DIR/.git"
        echo "エラー: スクラッチリポジトリ $SCRATCH_DIR/.git が見つかりません。先に git init を実行してください。" >&2
        return 1
    end

    cd "$SCRATCH_DIR"
    
    switch "$command"
    
    # ... (既存の case "save" のコード) ...
    case "save"
        set -l name $argv[2]
        set -l commit_msg "Scratch: "

        if not test -f "$SCRATCH_FILE"
            echo "エラー: 保存する $SCRATCH_FILE がありません。" >&2
            return 1
        end

        set -l timestamp (date +%Y%m%d_%H%M%S)

        if test -n "$name"
            set -l new_filename "$timestamp"_"$name".hs
            set commit_msg $commit_msg"Saved as $name"
        else
            set -l new_filename "$timestamp"_scratch.hs
            set commit_msg $commit_msg"Autosave"
        end

        mv "$SCRATCH_FILE" "$new_filename"
        git add "$new_filename"
        git commit -m "$commit_msg"
        
        echo "INFO: スクラッチを $new_filename として履歴に保存しました。"
        
    # ... (既存の case "new" のコード) ...
    case "new"
        scratch-ctl save
        
        set -l template_content "module Main where\n\nmain :: IO ()\nmain = putStrLn \"Scratchpad\"\n\n-- ここに落書きコードを記述 --\n"
        echo -e "$template_content" > "$SCRATCH_FILE"
        
        git reset "$SCRATCH_FILE" 2>/dev/null
        
        echo "INFO: 白紙の $SCRATCH_FILE を作成しました。"
        
    case "list"
        # Gitログから過去のコミットとファイル名を取得し、整形して表示
        echo "--- スクラッチ履歴 ---"
        echo "ID（コミットハッシュ） | タイムスタンプID_名前"
        echo "--------------------------------------------------------"
        
        # Gitログを整形して出力（ハッシュとコミットメッセージ）
        # %h: 短いハッシュ, %s: サブジェクト
        git log --oneline --grep="^Scratch:" --pretty=format:'%h %s' | while read -l line
            set -l hash (string split ' ' $line)[1]
            set -l message (string join ' ' $line[2..-1])
            
            # コミットメッセージからファイル名を取得
            set -l filename (git show --pretty=format: --name-only $hash | grep -E '^[0-9]{8}_[0-9]{6}_.*\.hs$')

            # 出力 (例: 5a3c6d Saved as MyTest -> 5a3c6d MyTest.hs)
            if test -n "$filename"
                echo "$hash | $filename"
            end
        end
        echo "--------------------------------------------------------"
        
        # current_scratch.hs が存在するか警告
        if test -f "$SCRATCH_FILE"
            echo "※ 注: 'current_scratch.hs' はまだ履歴に保存されていません。"
        end
        
    case "load"
        set -l target_id $argv[2]
        
        if test -z "$target_id"
            echo "使用方法: scratch-ctl load <コミットハッシュ or ファイル名（タイムスタンプID含む）>" >&2
            return 1
        end

        # 1. 現在のスクラッチを自動保存
        scratch-ctl save

        # 2. 履歴からファイルを検索
        set -l commit_hash ""
        set -l file_to_load ""

        # 引数が短いハッシュの場合
        if string match -r '^[0-9a-f]{4,8}$' $target_id
            set commit_hash (git rev-parse --short $target_id 2>/dev/null)
            if test -n "$commit_hash"
                # そのコミットが持つファイルを検索 (通常1つ)
                set file_to_load (git show --pretty=format: --name-only $commit_hash | grep -E '^[0-9]{8}_[0-9]{6}_.*\.hs$')
            end
        end

        # 引数がファイル名（ID含む）の場合
        if test -z "$file_to_load"
            set file_to_load $target_id
            # ファイル名に対応するコミットハッシュを特定（複雑なため、ここではファイル名が直接指定されたものとして扱う）
            set commit_hash (git log --all --grep="^Scratch:" --pretty=format:'%h' -- "$target_id" | head -n 1)
        end
        
        if test -z "$file_to_load"
            echo "エラー: 指定されたID/ファイル名 '$target_id' に対応するスクラッチが見つかりません。" >&2
            return 1
        end

        # 3. Gitからファイルをチェックアウトし、current_scratch.hsにコピー
        echo "INFO: '$file_to_load' (ハッシュ: $commit_hash) を復元します..."

        # 該当ファイルを一時的に取り出し、current_scratch.hsに上書き
        git checkout $commit_hash -- "$file_to_load"
        mv "$file_to_load" "$SCRATCH_FILE"

        # current_scratch.hs を作業ツリーに残すため reset する
        git reset -- "$SCRATCH_FILE" 2>/dev/null
        
        echo "INFO: スクラッチ '$file_to_load' が '$SCRATCH_FILE' としてロードされました。"

    case "*"
        echo "不明なコマンドです: $command" >&2
        return 1
    end
end
