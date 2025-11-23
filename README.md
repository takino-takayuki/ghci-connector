# **🌉 ghci-connector**

**ghci-connector** は、Neovimから、tmuxで独立して起動・常駐するHaskell REPLセッション（GHCi）へコマンドを確実に送信するためのシンプルなコネクタ群です。

本プロジェクトは、Haskellプロジェクトの開発体験を向上させることを目的としており、Neovimの再起動に依存しない堅牢なREPL環境を提供します。

## **⚠️ 使用上の注意 (重要)**

このシステムを使用するにあたり、以下の点に**必ず**注意してください。

1. **Haskellビルドツール**:  
   * **現在、このシステムは cabal のプロジェクト管理にのみ対応しています。stack を利用したプロジェクトには未対応です。**  
2. **対応シェル環境はFish Shellのみ**:  
   * **現状、このプロジェクトのシェルスクリプトは、**Fish Shell\*\* (.fish) の環境でのみ動作が保証されています。\*\* Bash等の他のシェル環境では動作しません。  
3. **REPLサーバーの事前起動が必須**:  
   * 本システムは、**既にtmux上にREPLサーバー（GHCi）が起動していること**を前提として動作します。  
4. **カレントディレクトリの仕様**:  
   * REPLにコマンドを送るNeovimのインスタンスは、**送りたいHaskellプロジェクトのルートディレクトリ**をカレントディレクトリとして起動している必要があります。

## **🚀 導入と利用方法**

### **1\. 前提条件**

* **Neovim (nvim)**: v0.8.0 以降を推奨。  
* **tmux**: セッション管理用。  
* **Haskell Tool Chain**: cabal を利用できる環境。  
* **Fish Shell**: スクリプト実行環境として必須。

### **2\. セットアップ手順**

#### **A. プロジェクトのクローン**

このリポジトリを任意の場所にクローンします。  
（例: \~/.config/nvim/ghci-connector など）  
git clone \[リポジトリのURL\] /path/to/ghci-connector

#### **B. binディレクトリへのパス設定 (必須)**

ghci-connector/bin ディレクトリに含まれる実行ファイル (start\_manager.sh, send\_to\_haskell\_repl.sh など) をどこからでも実行できるように、**このディレクトリにPATHを通してください**。

**Fish Shellの場合の例（\~/.config/fish/config.fishに追記）**:

\# ghci-connector の bin ディレクトリにパスを追加  
set \-l CONNECTOR\_ROOT /path/to/ghci-connector \# クローンしたパスに修正してください  
set \-gx PATH $PATH $CONNECTOR\_ROOT/bin

#### **C. シェル関数とNeovimモジュールのインストール (シンボリックリンク)**

システムの各機能を利用できるように、fishの関数ディレクトリとNeovimのランタイムパスにシンボリックリンクを作成します。

| ファイル | リンク元 | リンク先 | 目的 |
| :---- | :---- | :---- | :---- |
| \*.fish | ghci-connector/bin/\*.fish | \~/.config/fish/functions/ | Fish Shell関数 (tstart\_repl\_auto, trepl) として登録 |
| haskell\_repl\_bridge.lua | ghci-connector/lua/haskell\_repl\_bridge.lua | \~/.config/nvim/lua/haskell\_repl\_bridge.lua | Neovimモジュールとして登録 |

\# リンク元のディレクトリを設定 (クローンした場所に合わせて再度変更してください)  
CONNECTOR\_ROOT="/path/to/ghci-connector" 

\# \--------------------------------  
\# 1\. Fish Shell 関数 (tstart\_repl\_auto, trepl) の登録  
\# \--------------------------------  
mkdir \-p \~/.config/fish/functions/  
ln \-sf "$CONNECTOR\_ROOT/bin/tstart\_repl\_auto.fish" \~/.config/fish/functions/tstart\_repl\_auto.fish  
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

#### **ステップ B: REPLウィンドウの作成とNeovimの起動 (クライアント)**

\*\*（端末②）\*\*で行う操作です。これはNeovimからREPLにコードを送信したいHaskellプロジェクトごとに行います。

1. \*\*端末②（管理セッション以外の任意のtmux端末であればOK）\*\*を立ち上げ、**Haskellプロジェクトのルートディレクトリに移動**します。  
   \# 端末②  
   cd \~/path/to/your/HaskellProject

2. **REPLの自動起動とウィンドウ切り替え**を実行します。  
   \# 端末②  
   tstart\_repl\_auto

   * このコマンドは、管理セッション内にプロジェクト専用のREPLウィンドウを作成し、cabal replを実行します。  
   * 実行後、端末②の画面は自動的にその**新しいREPLウィンドウ**に切り替わります。  
3. **REPLウィンドウ内でNeovimを起動**します。  
   \# 端末② (REPLウィンドウ内)  
   nvim  
