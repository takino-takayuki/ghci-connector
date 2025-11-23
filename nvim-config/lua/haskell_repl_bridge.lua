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
-- Separately handles process startup errors and script execution errors
-- ⭐ デバッグ用修正: 戻り値の型をチェックし、ログに出力します ⭐
local function execute_sync_command(command_parts)
    local result = { code = -1, stdout = "", stderr = "" }
    local process_failed = false

    -- vim.systemは配列形式のコマンドを受け付ける
    -- NOTE: コールバックを渡さないことで同期実行になる
    local ok, job = pcall(vim.system, command_parts, { text = true })

    if not ok then
        -- プロセス起動失敗 (例: bash, git などのコマンドが見つからない)
        result.stderr = string.format("プロセス起動失敗: %s", job)
        process_failed = true
        return result, process_failed
    end

    local actual_result = job -- まずは job 自体を結果テーブルとみなす

    -- 戻り値が Job オブジェクトであった場合 (Jobオブジェクトは .code が nil の可能性が高い)
    if actual_result and type(actual_result) == 'table' and actual_result.code == nil then
        -- Job オブジェクトの可能性があるため、:wait() を試みる
        local wait_ok, wait_result = pcall(actual_result.wait, actual_result)
        
        if wait_ok and wait_result and type(wait_result) == 'table' and wait_result.code ~= nil then
            actual_result = wait_result
        else
            -- :wait() も失敗または結果が不正
            local job_dump = vim.inspect(job)
            result.stderr = string.format("致命的なエラー: vim.systemがJobオブジェクトを返しましたが、wait()で結果を取得できませんでした。 (wait_ok: %s, wait_result_type: %s). Job Dump: %s", tostring(wait_ok), type(wait_result), job_dump)
            process_failed = true
            return result, process_failed
        end
    end
    
    -- 最終的な結果テーブルのチェックと格納
    if actual_result and type(actual_result) == 'table' and actual_result.code ~= nil then
        result.code = actual_result.code
        -- stdout/stderr が nil の可能性があるため、空文字列でフォールバック
        result.stdout = actual_result.stdout or ""
        result.stderr = actual_result.stderr or ""
    else
        -- 予期しない型の結果 (致命的なエラー)
        local job_type = type(job)
        local job_dump = vim.inspect(job)
        -- ⭐ ここに到達した場合、デバッグ情報が result.stderr に入る ⭐
        result.stderr = string.format("致命的なエラー: vim.systemが予期しない型の結果を返しました (Type: %s)。Job Dump: %s", job_type, job_dump)
        process_failed = true
    end

    return result, process_failed
end


---- ユーティリティ関数: プロジェクトとREPLターゲット情報を取得
-- 成功時は tmux_target (文字列) を返し、失敗時は nil とエラーメッセージ (文字列) を返す
local function get_project_and_target()
    -- 1. PROJECT_ROOTの存在チェック
    if not PROJECT_ROOT then
        return nil, "環境変数 PROJECT_ROOT が設定されていません。REPL起動スクリプトを実行してください。"
    end
    
    -- スクリプトパス
    local script_path = GET_TARGET_SCRIPT_PATH
    if vim.fn.executable(script_path) == 0 then
        return nil, string.format("エラー: プロジェクト検出スクリプトが見つかりません: %s", script_path)
    end
    
    -- コマンドを配列形式で構築
    local command_parts = { 'bash', script_path }
    
    -- 2. 同期コマンド実行
    local result, process_failed = execute_sync_command(command_parts)

    -- ⭐ デバッグ用ログ: 結果全体をメッセージ履歴に出力します ⭐
    local debug_message = string.format(
        "DEBUG(get_target) - Process Failed: %s | Code: %d\nSTDOUT: %s\nSTDERR: %s",
        tostring(process_failed),
        result.code,
        vim.trim(result.stdout),
        vim.trim(result.stderr)
    )
    vim.api.nvim_echo({{debug_message, 'Comment'}}, true, {})
    -- ユーザーに通知するためにも、メッセージをレジスタに格納
    vim.fn.setreg('l', debug_message)
    -- ⭐ デバッグ用ログここまで ⭐

    if process_failed then
        -- プロセス起動失敗または致命的なLuaエラー (エラーメッセージは execute_sync_command で設定済み)
        return nil, result.stderr
    end

    if result.code ~= 0 then
        -- スクリプト実行失敗 (スクリプト内でエラーが発生)
        local error_message = string.format("プロジェクト検出スクリプトの実行に失敗しました (Code: %d)。STDERR:\n%s\nSTDOUT:\n%s", 
                                             result.code, result.stderr, result.stdout)
        return nil, error_message
    end
    
    -- 3. 結果の解析
    local output_lines = vim.split(vim.trim(result.stdout), '\n')
    
    if #output_lines ~= 2 then
        local error_message = string.format("プロジェクト検出スクリプトの出力行数が不正です (%d行)。STDOUT:\n%s", 
                                             #output_lines, result.stdout)
        return nil, error_message
    end

    -- 期待される出力:
    -- Line 1: PROJECT_NAME (例: trump2)
    -- Line 2: TMUX_TARGET (例: haskell_manager:trump2_Haskell_REPL)
    -- local project_name = output_lines[1] -- 現在は使用しない
    local tmux_target = output_lines[2]
    
    return tmux_target
end


---- 2. REPLを起動してアタッチする
-- REPL起動スクリプトのパスを解決し、tmux targetを取得してからスクリプトを実行する
M.start_repl_auto = function()
    vim.notify('Haskell REPLセッションの起動/アタッチを開始します...', vim.log.levels.INFO, { title = "Haskell REPL" })

    -- 1. ターゲット情報の取得
    local tmux_target, error_msg = get_project_and_target()

    if not tmux_target then
        -- エラーが発生した場合、get_project_and_targetで設定された詳細なエラーメッセージを通知
        vim.notify(
            'REPL起動失敗: ' .. error_msg, 
            vim.log.levels.ERROR, 
            { title = "Haskell REPL" }
        )
        return
    end

    -- 2. コマンド構築と実行 (fishインタプリタを使って関数を実行)
    local command_parts = { 'fish', '-c', 'tstart_repl_auto' }
    
    -- 非同期実行
    local ok, err_or_job = pcall(vim.system, command_parts, { text = true }, function(job)
        -- プロセスが完了した場合の処理
        vim.schedule(function()
            if job.code ~= 0 then
                -- job.stderrにはFish関数内でのエラーメッセージが入るはず
                vim.notify(
                    string.format('REPL起動失敗 (Code: %d): %s', job.code, job.stderr), 
                    vim.log.levels.ERROR,
                    { title = "Haskell REPL" }
                )
            else
                vim.notify('REPLセッションの起動/アタッチが完了しました。', vim.log.levels.INFO, { title = "Haskell REPL" })
            end
        end)
    end)

    -- プロセスの起動に失敗した時の処理
    if not ok then
        local err = err_or_job
        vim.notify(
            string.format('Fishシェルの起動に失敗しました: %s', err), 
            vim.log.levels.ERROR,
            { title = "Haskell REPL" }
        )
    end
end


---- 3. REPLにテキストを送信する
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


---- 4. キーマップとユーザー操作関数

-- ⭐ 修正: ファイル全体を実行する機能を <leader>rE (大文字) に移動 ⭐
vim.keymap.set('n', '<leader>rl', function()
    -- バッファ全体の内容を取得
    local start_line = 1
    local end_line = vim.api.nvim_buf_line_count(0)
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local text = table.concat(lines, '\n')
    
    M.send_text_to_repl(text)
end, { desc = "REPL: ファイル全体を実行 (<leader>rE)" })

-- ⭐ 修正: <leader>re を現在行の実行に割り当て ⭐
vim.keymap.set('n', '<leader>re', function()
    -- 現在のカーソル行番号を取得 (1ベース)
    local current_line = vim.fn.line('.')
    -- その行のテキストを取得 (Lua APIは0ベースのインデックス)
    local lines = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)
    local text = lines[1] or ""
    
    -- 空行でなければ送信
    if vim.trim(text) ~= "" then
        M.send_text_to_repl(text)
    else
        vim.notify("現在行が空のため、REPLに送信しませんでした。", vim.log.levels.INFO, { title = "Haskell REPL" })
    end
end, { desc = "REPL: 現在行を実行 (<leader>re)" })


-- ビジュアルモード: 選択範囲を実行 (変更なし)
vim.keymap.set('v', '<leader>re', function()
    -- 選択範囲を取得
    local start_line = vim.fn.line('v')
    local end_line = vim.fn.line('.')
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local text = table.concat(lines, '\n')
    
    M.send_text_to_repl(text)
end, { desc = "REPL: 選択範囲を実行" })

-- ノーマルモード: ソフトリスタート (ペイン内再実行)
vim.keymap.set('n', '<leader>rs', function()

    -- PROJECT_ROOTのチェックを先に行う
    if not PROJECT_ROOT then
        vim.notify("REPLリスタート失敗: 環境変数 PROJECT_ROOT が設定されていません。REPL起動スクリプトを実行してください。", vim.log.levels.ERROR, { title = "Haskell REPL" })
        return
    end

    if vim.fn.executable(RESTART_SCRIPT_PATH) == 0 then
        vim.notify("エラー: REPLリスタートスクリプトが見つかりません: " .. RESTART_SCRIPT_PATH, vim.log.levels.ERROR, { title = "Haskell REPL" })
        return
    end

    vim.notify('REPLセッションのソフトリスタートを開始します...', vim.log.levels.WARN, { title = "Haskell REPL" })
    
    -- コマンドを配列形式で構築
    local command_parts = { 'bash', RESTART_SCRIPT_PATH }

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
                vim.notify('REPLセッションのソフトリスタートが完了しました。', vim.log.levels.INFO, { title = "Haskell REPL" })
            end
        end)
    end)

    -- プロセスの起動に失敗した時の処理
    if not ok then
        local err = err_or_job
        vim.notify(
            string.format('REPLリスタートスクリプトの実行に失敗しました: %s', err), 
            vim.log.levels.ERROR,
            { title = "Haskell REPL" }
        )
    end
end, { desc = "REPL: ソフトリスタート" })

-- REPL起動コマンドのキーマップ (ノーマルモード)
vim.keymap.set('n', '<leader>ra', M.start_repl_auto, { desc = "REPL: REPLを起動/アタッチ" })


return M
