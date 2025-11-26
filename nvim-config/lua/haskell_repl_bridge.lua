local M = {}

-- 環境変数からプロジェクトルートを取得
-- NOTE: start_manager.shでPROJECT_ROOTとして設定される
local PROJECT_ROOT = vim.env.PROJECT_ROOT

-- 環境変数を使ってBashスクリプトへの絶対パスを構築 (PROJECT_ROOTがnilの場合でもパス文字列自体は生成しておく)
local BASE_PATH = PROJECT_ROOT or "/tmp/haskell_repl_connector" -- 仮のパスを設定
local SCRIPT_PATH = BASE_PATH .. '/bin/send_to_haskell_repl.sh'
local RESTART_SCRIPT_PATH = BASE_PATH .. '/bin/restart_haskell_repl_session.sh'
local GET_TARGET_SCRIPT_PATH = BASE_PATH .. '/bin/get_project_and_target.sh'

-- Utility function: Executes shell commands synchronously and returns results
local function execute_sync_command(command_parts)
    local result = { code = -1, stdout = "", stderr = "" }
    local process_failed = false

    local ok, job = pcall(vim.system, command_parts, { text = true })

    if not ok then
        result.stderr = string.format("プロセス起動失敗: %s", job)
        process_failed = true
        return result, process_failed
    end

    local actual_result = job
    result.code = actual_result.code
    result.stdout = actual_result.stdout
    result.stderr = actual_result.stderr
    
    return result, process_failed
end

-- ==========================================================
-- 1. REPLにテキストを送信する
-- ==========================================================
-- NOTE: ユーザーの命名に合わせて M.send_text_to_repl を使用
M.send_text_to_repl = function(text)
    -- PROJECT_ROOTの最終チェック
    if not PROJECT_ROOT then
        vim.notify(
            "REPL送信失敗: 環境変数 PROJECT_ROOT が設定されていません。REPL起動スクリプトを実行してください。", 
            vim.log.levels.ERROR, 
            { title = "Haskell REPL" }
        )
        return
    end

    -- スクリプトの存在チェック
    if vim.fn.executable(SCRIPT_PATH) == 0 then
        vim.notify("エラー: REPL送信スクリプトが見つかりません: " .. SCRIPT_PATH, vim.log.levels.ERROR)
        return
    end

    -- GHCiブロックとして送信するためにエスケープ
    local escaped_text = text:gsub("'", "'\\''") -- シングルクォートをエスケープ
    
    local ghci_block = string.format(
        ":{\n%s\n:}\n", 
        vim.trim(escaped_text)
    )

    -- コマンドを配列形式で構築
    local command_parts = { 'bash', SCRIPT_PATH, ghci_block }
    
    -- 非同期実行
    local ok, err_or_job = pcall(vim.system, command_parts, { text = true }, function(job)
        -- プロセスが完了した場合の処理
        vim.schedule(function()
            if job.code ~= 0 then
                vim.notify(
                    string.format('REPL送信失敗 (Code: %d): %s', job.code, job.stderr), 
                    vim.log.levels.ERROR,
                    { title = "Haskell REPL" }
                )
            else
                vim.notify("REPLに送信しました。", vim.log.levels.INFO, { title = "Haskell REPL" })
            end
        end)
    end)

    -- プロセスの起動に失敗した時の処理
    if not ok then
        local err = err_or_job
        vim.notify(
            string.format('REPL送信スクリプトの実行に失敗しました: %s', err), 
            vim.log.levels.ERROR,
            { title = "Haskell REPL" }
        )
    end
end

-- ==========================================================
-- 2. セッションリスタート (コンポーネント指定可能)
-- ==========================================================
M.restart_repl_session = function(comp_type)
    -- デフォルトを 'test' に設定
    local component = comp_type or 'test' 
    
    if not PROJECT_ROOT then
        vim.notify("エラー: 環境変数 PROJECT_ROOT が設定されていません。REPL起動スクリプトを実行してください。", vim.log.levels.ERROR, { title = "Haskell REPL" })
        return
    end

    if vim.fn.executable(RESTART_SCRIPT_PATH) == 0 then
        vim.notify("エラー: REPLリスタートスクリプトが見つかりません: " .. RESTART_SCRIPT_PATH, vim.log.levels.ERROR, { title = "Haskell REPL" })
        return
    end

    vim.notify('REPLセッションのソフトリスタートを開始します (環境: ' .. component .. ')...', vim.log.levels.WARN, { title = "Haskell REPL" })
    
    -- コマンドにコンポーネントタイプを引数として追加
    local command_parts = { 'bash', RESTART_SCRIPT_PATH, component } 

    -- 非同期実行
    local ok, err_or_job = pcall(vim.system, command_parts, { text = true }, function(job)
        -- プロセスが完了した場合の処理
        vim.schedule(function()
            if job.code ~= 0 then
                vim.notify(
                    string.format('REPLリスタート失敗 (Code: %d): %s', job.code, job.stderr), 
                    vim.log.levels.ERROR,
                    { title = "Haskell REPL" }
                )
            else
                vim.notify(
                    string.format('REPLセッションのソフトリスタートが完了しました (環境: %s)。', component),
                    vim.log.levels.INFO, 
                    { title = "Haskell REPL" }
                )
            end
        end)
    end)

    -- プロセスの起動に失敗した時の処理
    if not ok then
        local err = err_or_job
        vim.notify(
            string.format('プロセス起動失敗: %s', err),
            vim.log.levels.ERROR,
            { title = "Haskell REPL" }
        )
    end
end


-- ==========================================================
-- 3. キーマップとユーザー操作関数 (修正済み)
-- ==========================================================

-- ファイル全体を実行: <leader>rL (大文字 L) 
vim.keymap.set('n', '<leader>rL', function()
    -- バッファ全体の内容を取得
    local start_line = 1
    local end_line = vim.api.nvim_buf_line_count(0)
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local text = table.concat(lines, '\n')
    
    M.send_text_to_repl(text)
end, { desc = "REPL: ファイル全体を実行 (<leader>rL)" })

-- 現在行の実行: <leader>re 
vim.keymap.set('n', '<leader>re', function()
    local current_line = vim.fn.line('.')
    local lines = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)
    local text = lines[1] or ""
    
    if vim.trim(text) ~= "" then
        M.send_text_to_repl(text)
    else
        vim.notify("現在行が空のため、REPLに送信しませんでした。", vim.log.levels.INFO, { title = "Haskell REPL" })
    end
end, { desc = "REPL: 現在行を実行 (<leader>re)" })


-- ビジュアルモード: 選択範囲を実行 
vim.keymap.set('v', '<leader>re', function()
    local start_line = vim.fn.line('v')
    local end_line = vim.fn.line('.')
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local text = table.concat(lines, '\n')
    
    M.send_text_to_repl(text)
end, { desc = "REPL: 選択範囲を実行" })

-- --- REPL リスタート (コンポーネント切り替え対応) ---

-- 🌟 テスト環境でリスタート (デフォルト): <leader>rs 
vim.keymap.set('n', '<leader>rs', function()
    -- 引数なしは 'test' (デフォルト) で実行される
    M.restart_repl_session() 
end, { desc = "REPL: ソフトリスタート (Test環境)" })

-- 🌟 メイン実行環境でリスタート: <leader>rm 
vim.keymap.set('n', '<leader>rm', function()
    M.restart_repl_session('main')
end, { desc = "REPL: メイン環境でリスタート" })

-- 🌟 ライブラリ環境でリスタート: <leader>rl 
vim.keymap.set('n', '<leader>rl', function()
    M.restart_repl_session('lib')
end, { desc = "REPL: ライブラリ環境でリスタート" })


-- 💡 <leader>ra に割り当てられていたキーマップを削除しました。


return M
