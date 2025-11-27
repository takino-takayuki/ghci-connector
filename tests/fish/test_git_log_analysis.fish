# =================================================================
# Gitログ解析テストスクリプト (Fish Shell)
# 目的: git log --pretty=format:'%h %s' の出力を模倣し、
#       ハッシュとメッセージの分割ロジックが正しく動作するか確認する。
# =================================================================

function test_log_analysis
    # 模擬的な git log の出力を定義
    # 実際には `git log ... | while read ...` のパイプラインから入力される
    set -l mock_log_output (
        echo '5a3c6d Scratch: My first function definition'
        echo 'b2f91e Scratch: Second attempt with list comprehensions'
        echo 'c7e8f0 Scratch: Simple bug fix'
    )

    echo "--- 模擬Gitログ解析開始 ---"
    
    # Fish Shellで配列をループし、各行を $line に読み込む
    for line in $mock_log_output
        
        # オリジナルの解析ロジック
        set -l hash (string split ' ' $line)[1]
        set -l message (string join ' ' $line[2..-1])
        
        # 結果の出力
        echo "入力行: $line"
        echo "  -> ハッシュ (\$hash): $hash"
        echo "  -> メッセージ (\$message): $message"
        echo "--------------------------"
    end

    echo "--- 模擬Gitログ解析完了 ---"
end

# 関数を実行
test_log_analysis

# fish test_git_log_analysis.fish
#
# **想定される出力:**
#
# --- 模擬Gitログ解析開始 ---
# 入力行: 5a3c6d Scratch: My first function definition
#   -> ハッシュ ($hash): 5a3c6d
#   -> メッセージ ($message): Scratch: My first function definition
# --------------------------
# 入力行: b2f91e Scratch: Second attempt with list comprehensions
#   -> ハッシュ ($hash): b2f91e
#   -> メッセージ ($message): Scratch: Second attempt with list comprehensions
# --------------------------
# 入力行: c7e8f0 Scratch: Simple bug fix
#   -> ハッシュ ($hash): c7e8f0
#   -> メッセージ ($message): Scratch: Simple bug fix
# --------------------------
# --- 模擬Gitログ解析完了 ---
