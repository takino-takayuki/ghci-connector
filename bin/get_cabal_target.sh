#!/bin/bash

# ==========================================================
# get_cabal_target.sh
# 目的: プロジェクト名とコンポーネントタイプから、完全な cabal repl ターゲット文字列を返す。
# 使用法: get_cabal_target.sh <PROJECT_NAME> <COMPONENT_TYPE>
# 出力: <PROJECT_NAME>:<TARGET_TYPE>:<TARGET_NAME>
# ==========================================================

PROJECT_NAME="$1"
COMPONENT_TYPE="$2"

if [ -z "$PROJECT_NAME" ] || [ -z "$COMPONENT_TYPE" ]; then
    echo "エラー: プロジェクト名とコンポーネントタイプが必要です。" >&2
    exit 1
fi

# lib/test/main のエイリアスを Cabal ターゲットに変換
case "$COMPONENT_TYPE" in
    main)
        # executable (例: repl-formatter:exe:repl-formatter)
        TARGET_TYPE="exe"
        TARGET_NAME="$PROJECT_NAME"
        ;;
    lib)
        # library (例: repl-formatter:lib:repl-formatter)
        TARGET_TYPE="lib"
        TARGET_NAME="$PROJECT_NAME"
        ;;
    test)
        # test-suite (例: repl-formatter:test:repl-formatter-test)
        TARGET_TYPE="test"
        # 慣例としてテストスイート名は '<プロジェクト名>-test' と仮定
        TARGET_NAME="${PROJECT_NAME}-test"
        ;;
    *)
        echo "エラー: 不正なコンポーネントタイプです: $COMPONENT_TYPE (許容値: main, lib, test)" >&2
        exit 1
        ;;
esac

echo "$PROJECT_NAME:$TARGET_TYPE:$TARGET_NAME"
exit 0
