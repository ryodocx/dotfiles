#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Dotfiles Update Script (update.sh)
#
# このスクリプトは、日々の環境更新（パッケージやツールの最新化）を一括で行うためのものです。
# 定期的に実行することで、すべてのツールチェインを最新の状態に保つことができます。
#
# 主な処理の流れ:
# 1. ~/.dotfiles リポジトリの最新化 (git pull)
# 2. chezmoi テンプレートとローカル設定ファイルの同期 (chezmoi update)
# 3. Nix Flakes のロックファイル (flake.lock) の更新と、システム/ユーザー環境の再適用
#    - macOS: darwin-rebuild switch
#    - WSL/Linux: home-manager switch
# 4. macOS 向けの Homebrew パッケージ更新 (brew update/upgrade)
# 5. Zsh プラグインマネージャ (sheldon) のロックファイル更新
# 6. 開発言語・ランタイムマネージャ (mise) のツール更新
# 7. Gitフック管理ツール (Lefthook) のフック更新
#
# 注意:
# 実行後、Nix の `flake.lock` が更新された場合は、設定を他マシンと同期するために
# git commit および push を手動で行うことを推奨します。
# ==============================================================================
# カラー出力用の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Starting Dotfiles Update ===${NC}"

# 1. ~/.dotfiles リポジトリの最新化
DOTFILES_DIR="$HOME/.dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
    echo -e "${GREEN}--> Pulling latest changes from dotfiles repository...${NC}"
    cd "$DOTFILES_DIR"
    git pull origin v2
else
    echo -e "Warning: $DOTFILES_DIR not found. Skipping git pull."
fi

# 2. chezmoi の同期
if command -v chezmoi >/dev/null 2>&1; then
    echo -e "${GREEN}--> Running chezmoi update...${NC}"
    chezmoi update
fi

# 3. Nix Flakes の更新とシステム/Home-Manager の再適用
if [ -f "$DOTFILES_DIR/flake.nix" ] && command -v nix >/dev/null 2>&1; then
    echo -e "${GREEN}--> Updating Nix flake.lock...${NC}"
    cd "$DOTFILES_DIR"
    nix flake update

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${GREEN}--> Applying macOS nix-darwin configurations...${NC}"
        # nix-darwin の再適用
        darwin-rebuild switch --flake "$DOTFILES_DIR#macbook"
    else
        TARGET_CONFIG="wsl"
        if [ ! -z "${WSL_DISTRO_NAME:-}" ] || grep -q -i "microsoft" /proc/version 2>/dev/null; then
            TARGET_CONFIG="wsl"
        else
            TARGET_CONFIG="linux"
        fi
        echo -e "${GREEN}--> Applying Home Manager configurations ($TARGET_CONFIG)...${NC}"
        # Linux / WSL の Home Manager 再適用
        home-manager switch --flake "$DOTFILES_DIR#${TARGET_CONFIG}"
    fi
fi

# 4. Homebrew の更新 (macOS または Linuxbrew 環境)
if command -v brew >/dev/null 2>&1; then
    echo -e "${GREEN}--> Updating Homebrew formulas and casks...${NC}"
    brew update
    brew upgrade
    brew cleanup
fi

# 5. Sheldon の更新 (Zsh プラグイン)
if command -v sheldon >/dev/null 2>&1; then
    echo -e "${GREEN}--> Updating Sheldon plugins...${NC}"
    sheldon lock --update
fi

# 6. Mise の更新 (開発言語ランタイム)
if command -v mise >/dev/null 2>&1; then
    echo -e "${GREEN}--> Updating Mise runtimes...${NC}"
    mise self-update -y
    mise upgrade -y
fi

# 7. Lefthook hooks のインストール・更新
if command -v lefthook >/dev/null 2>&1; then
    echo -e "${GREEN}--> Installing/Updating Lefthook hooks...${NC}"
    lefthook install
fi

echo -e "${BLUE}=== Dotfiles Update Complete! ===${NC}"
echo -e "Note: If nix 'flake.lock' was modified, please commit and push it to your repository."
