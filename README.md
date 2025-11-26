# **🌉 ghci-connector**

**ghci-connector** は、Neovimから、tmuxで独立して起動・常駐するHaskell REPLセッション（GHCi）へコマンドを確実に送信するためのシンプルなコネクタ群です。

本プロジェクトは、Haskellプロジェクトの開発体験を向上させることを目的としており、Neovimの再起動に依存しない堅牢なREPL環境を提供します。

## **⚠️ 使用上の注意 (重要)**

このシステムを使用するにあたり、以下の点に**必ず**注意してください。

1. **Haskellビルドツール**:  
   * **現在、このシステムは cabal のプロジェクト管理にのみ対応しています。stack を利用したプロジェクトには未対応です。** 2\. **対応シェル環境はFish Shellのみ**:  
   * **現状、このプロジェクトのシェルスクリプトは、Fish Shell (.fish) の環境でのみ動作が保証されています。** Bash等の他のシェル環境では動作しません。  
2. **REPLサーバーの事前起動が必須**:  
   * 本システムは、**既にtmux上にREPLサーバー（GHCi）が起動していること**を前提として動作します。  
3. **カレントディレクトリの仕様**:  
   * REPLにコマンドを送るNeovimのインスタンスは、**送りたいHaskellプロジェクトのルートディレクトリ**をカレントディレクトリとして起動している必要があります。

## **🚀 導入と利用方法**

### **1\. 前提条件**

* **Neovim (nvim)**: v0.8.0 以降を推奨。  
* **tmux**: セッション管理用。  
* **Haskell Tool Chain**: cabal を利用できる環境。  
* **Fish Shell**: スクリプト実行環境。

### **2\. 初期セットアップ（シンボリックリンクの作成）**

プロジェクトフォルダ直下にある setup.sh を実行し、必要なシンボリックリンクを作成します。

\# コネクタフォルダのルートに移動  
cd /path/to/ghci-connector

\# 初期セットアップスクリプトを実行  
./setup.sh

**setup.sh が行うこと:**

CONNECTOR\_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

\# \--------------------------------  
\# 1\. Fish Shell 関数 (tstart\_repl\_auto, trepl) の登録  
\# \--------------------------------  
mkdir \-p \~/.config/fish/functions/  
ln \-sf "\$CONNECTOR\_ROOT/bin/tstart\_repl\_auto.fish" \~/.config/fish/functions/tstart\_repl\_auto.fish  
ln \-sf "$CONNECTOR\_ROOT/bin/trepl.fish" \~/.config/fish/functions/trepl.fish

\# \--------------------------------  
\# 2\. Neovim Lua モジュール (haskell\_repl\_bridge) の登録  
\# \--------------------------------  
mkdir \-p \~/.config/nvim/lua/  
ln \-sf "$CONNECTOR\_ROOT/lua/haskell\_repl\_bridge.lua" \~/.config/nvim/lua/haskell\_repl\_bridge.lua

echo "INFO: シンボリックリンクの作成が完了しました。"

### **3\. 詳細な運用手順 (サーバー/クライアント)**

このシステムは、サーバー（REPL管理セッション）とクライアント（コード送信を行う端末）を分離して運用することを前提としています。

#### **ステップ A: REPL管理セッション (サーバー) の起動**

\*\*（端末①）\*\*で行う操作です。管理セッションは一度起動すれば基本的に常駐します。

1. **端末①を立ち上げて、tmuxコマンドでログイン**します。  
2. **start\_manager.shを実行**し、セッションを作成・アタッチします。  
   * これにより、haskell\_managerという名前のtmuxセッションが起動し、コネクタのルートパスが環境変数 PROJECT\_ROOT として設定されます。

\# 端末① (tmuxセッション内)  
start\_manager.sh

3. **Haskellプロジェクトのルートディレクトリに移動**します。

cd \~/path/to/my-haskell-project

4. **tstart\_repl\_auto を実行**し、REPLウィンドウを作成・起動します。  
   * プロジェクト名に基づいた名前（例：my-haskell-project\_Haskell\_REPL）でウィンドウが作成され、cabal repl コマンドが自動で実行されます。  
   * REPLが起動したら、ctrl-b c (新しいウィンドウ作成) や ctrl-b p / ctrl-b n (ウィンドウ切り替え) で他の作業に戻って構いません。

\# 端末① (tmuxセッション内、Haskellプロジェクトルート)  
tstart\_repl\_auto

#### **ステップ B: クライアント (Neovim) の操作**

\*\*（端末②）\*\*または \*\*（端末①）\*\*のtmuxセッション外で行う操作です。

1. **カレントディレクトリをHaskellプロジェクトのルートに移動**してから、Neovimを起動します。  
   cd \~/path/to/my-haskell-project  
   nvim .

2. **Neovim内で以下のキーマップを使用し、REPLとの対話を行います。**

| キーマップ | モード | 説明 |
| :---- | :---- | :---- |
| \<leader\>re | ノーマル/ビジュアル | \*\*選択範囲（ビジュアル）**または**現在行（ノーマル）\*\*をGHCiブロックとしてREPLに送信・実行します。 |
| \<leader\>rL | ノーマル | **ファイルバッファ全体**をGHCiブロックとしてREPLに送信・実行します。 |
| \<leader\>rs | ノーマル | **【ソフトリスタート / Test環境】** REPLをTestコンポーネントでリスタートします。（デフォルト） |
| \<leader\>rm | ノーマル | **【ソフトリスタート / Main環境】** REPLをMainコンポーネントでリスタートします。 |
| \<leader\>rl | ノーマル | **【ソフトリスタート / Lib環境】** REPLをLibraryコンポーネントでリスタートします。 |

**補足:**

* tstart\_repl\_auto は、REPLウィンドウが既に存在する場合は新規作成せずに終了します。  
* trepl コマンドを使用すると、REPLウィンドウに直接切り替えることができます。

\# 端末② (tmuxセッション外、Fish Shell)  
trepl  
