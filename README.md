# 🌉 nvim-haskell-tmux-repl-manager

Neovim (Haskell-tools.nvim) と、完全に分離された常駐REPLセッションを連携させるためのシンプルな管理スクリプト群です。

本プロジェクトは、REPLのセッション情報を `tmux` を使用して Neovim とは独立したターミナルで常駐させ、Neovimからはシェルスクリプトを介してコマンドを遠隔送信する運用を実現します。

## 🌟 特徴

* **完全な分離**: Neovimの再起動に関わらず、Haskell REPLセッション（GHCi）を維持します。
* **tmux連携**: `tmux send-keys` コマンドを利用し、REPLペインへ安全かつ確実にテキストコマンドを送信します。
* **シンプルなプロトコル**: コマンド送信ロジックを単一のシェルスクリプトに集約し、管理を容易にします。
* **HLSとの共存**: `haskell-tools.nvim` (HLS) によるLSP機能と競合せず、並行して利用できます。

## 🚀 前提条件

このプロジェクトを使用するには、以下のツールがシステムにインストールされ、動作している必要があります。

* **Neovim (`nvim`)**: v0.8.0 以降を推奨。
* **tmux**: セッション管理用。
* **Haskell Tool Chain**: `cabal` または `stack` を含む。
* **haskell-tools.nvim**: NeovimでのHaskellプロジェクト管理のため。

## 🛠️ セットアップ

### 1. プロジェクトのクローン

このリポジトリを任意の場所にクローンします。

```bash
git clone [https://github.com/your-username/nvim-haskell-tmux-repl-manager.git](https://github.com/your-username/nvim-haskell-tmux-repl-manager.git)
cd nvim-haskell-tmux-repl-manager
