local M = {}

-- 環境変数からプロジェクトルートを取得
local PROJECT_ROOT = vim.env.GHCI_CONNECTOR_ROOT

-- プロジェクトルートが設定されているか確認
if not PROJECT_ROOT then
    vim.notify("エラー: 環境変数 GHCI_CONNECTOR_ROOT が設定されていません。REPL連携が無効化されます。", vim.log.levels.ERROR)
    return M
end

-- 環境変数を使ってスクリプトへの絶対パスを構築
local SCRIPT_PATH = PROJECT_ROOT .. '/bin/send_to_haskell_repl.sh'
local RESTART_SCRIPT_PATH = PROJECT_ROOT .. '/bin/restart_haskell_repl_session.sh' -- ⭐ ソフトリスタート
local KILL_RESTART_PATH = PROJECT_ROOT .. '/bin/kill_and_restart_repl.sh'         -- ⭐ ハードリスタート

---- 1. nvimからシェルスクリプトを呼び出す関数
--M.send_text_to_repl = function(text)
--    -- スクリプトの存在チェック
--    if vim.fn.executable(SCRIPT_PATH) == 0 then
--        vim.notify("エラー: REPL送信スクリプトが見つかりません: " .. SCRIPT_PATH, vim.log.levels.ERROR)
--        return
--    end
--
--    -- 送信テキストをシェル用にエスケープ
--    local escaped_text = vim.fn.shellescape(text)
--
--    -- シェルスクリプトに引数を渡して実行
--    local command = string.format('%s %s', SCRIPT_PATH, escaped_text)
--    
--    -- 非同期実行でnvimをブロックしないようにする（システム関数を使用）
--    vim.fn.system(command)
--
--    vim.notify('REPLにコマンドを送信しました', vim.log.levels.INFO, { title = "Haskell REPL" })
--end

-- 1. nvimからシェルスクリプトを呼び出す関数
M.send_text_to_repl = function(text)
    -- スクリプトの存在チェック
    if vim.fn.executable(SCRIPT_PATH) == 0 then
        vim.notify("エラー: REPL送信スクリプトが見つかりません: " .. SCRIPT_PATH, vim.log.levels.ERROR)
        return
    end

    -- 複数行チェックと :{ :} ラッピングの処理を追加
    -- Luaのstring.findで改行文字(\n)が含まれているかチェックします
    if string.find(text, "\n") then
        -- 複数行の場合、:{ <改行> ... <改行> :} の形式で囲む
        text = ":{\n" .. text .. "\n:}"
        vim.notify('INFO: 複数行のため :{ :} で囲んで送信します', vim.log.levels.INFO, { title = "Haskell REPL" })
    end

    -- 送信テキストをシェル用にエスケープ
    local escaped_text = vim.fn.shellescape(text)

    -- シェルスクリプトに引数を渡して実行
    local command = string.format('%s %s', SCRIPT_PATH, escaped_text)
    
    -- 非同期実行でnvimをブロックしないようにする（システム関数を使用）
    vim.fn.system(command)

    vim.notify('REPLにコマンドを送信しました', vim.log.levels.INFO, { title = "Haskell REPL" })
end

-- 2. キーマップ設定
M.setup_keymaps = function()
    -- 1.ノーマルモード: ファイル全体をリロード
    vim.keymap.set('n', '<leader>rr', function()
        M.send_text_to_repl(':r')
    end, { desc = "REPL: ファイルをリロード" })

    -- 2. ⭐ ノーマルモード: バッファ全体を送信 (NEW: <leader>rb)
    vim.keymap.set('n', '<leader>rb', function()
        -- 現在のバッファ番号 (0) の全行を取得
        -- 0: 開始行 (1行目), -1: 終了行 (最終行), false: 末尾の改行を含まない
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        
        -- 行リストを改行文字で結合して単一の文字列にする
        local text = table.concat(lines, '\n')

        if text == '' then
            vim.notify('エラー: バッファにテキストがありません', vim.log.levels.WARN, { title = "Haskell REPL" })
            return
        end
        
        M.send_text_to_repl(text)
    end, { desc = "REPL: バッファ全体を送信" })

    -- 2. ⭐ ノーマルモード: <leader>re (カーソル行を実行) を新設
    vim.keymap.set('n', '<leader>re', function()
        local text = vim.fn.getline('.')
        if text == nil or text == '' then
            vim.notify('エラー: カーソル行にテキストがありません', vim.log.levels.WARN, { title = "Haskell REPL" })
            return
        end

        M.send_text_to_repl(text)
    end, { desc = "REPL: カーソル行を実行" }) -- n, <leader>re の定義

    -- 3. ⭐ ビジュアルモード: <leader>re (選択範囲を実行) の修正
    vim.keymap.set('v', '<leader>re', function()
        -- 1. 選択範囲をレジスタ 'z' にヤンクし、Visual Modeを終了する
        vim.cmd('normal! "zy') 

        -- 2. レジスタ 'z' のテキストを取得
        local text = vim.fn.getreg('z', 1) 
        
        if text == nil or text == '' then
            vim.notify('エラー: 選択範囲が空です', vim.log.levels.WARN, { title = "Haskell REPL" })
            return
        end

        -- vim.notify(">>> <leader>re text " .. text, vim.log.levels.INFO) -- ★ログ追加 6
        M.send_text_to_repl(text)
    end, { desc = "REPL: 選択範囲を実行" }) -- v, <leader>re の定義

    -- ⭐ NEW: ノーマルモード: ソフトリスタート (ペイン内再実行)
    vim.keymap.set('n', '<leader>rs', function()
        if vim.fn.executable(RESTART_SCRIPT_PATH) == 0 then
            vim.notify("エラー: REPLリスタートスクリプトが見つかりません: " .. RESTART_SCRIPT_PATH, vim.log.levels.ERROR)
            return
        end

        vim.notify('REPLセッションのソフトリスタートを開始します...', vim.log.levels.WARN, { title = "Haskell REPL" })
        local command = string.format('%s %s', RESTART_SCRIPT_PATH, vim.fn.shellescape(PROJECT_ROOT))
        vim.fn.system(command)
        vim.notify('REPLセッションのソフトリスタートが完了しました。', vim.log.levels.INFO, { title = "Haskell REPL" })
    end, { desc = "REPL: ソフトリスタート (プロセス再実行)" })

    -- ⭐ NEW: ノーマルモード: ハードリスタート (セッション強制終了・再起動)
    vim.keymap.set('n', '<leader>rk', function()
        if vim.fn.executable(KILL_RESTART_PATH) == 0 then
            vim.notify("エラー: REPL強制終了スクリプトが見つかりません: " .. KILL_RESTART_PATH, vim.log.levels.ERROR)
            return
        end

        vim.notify('REPLセッションのハードリスタートを開始します...', vim.log.levels.ERROR, { title = "Haskell REPL" })
        local command = string.format('%s %s', KILL_RESTART_PATH, vim.fn.shellescape(PROJECT_ROOT))
        vim.fn.system(command)
        vim.notify('REPLセッションのハードリスタートが完了しました。', vim.log.levels.INFO, { title = "Haskell REPL" })
    end, { desc = "REPL: ハードリスタート (セッション強制終了)" })

end

return M
