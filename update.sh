#!/usr/bin/env bash
set -euo pipefail

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
        nix run nix-darwin -- switch --flake "$DOTFILES_DIR"
    else
        echo -e "${GREEN}--> Applying Home Manager configurations...${NC}"
        # Linux / WSL の Home Manager 再適用
        nix run nixpkgs#home-manager -- switch --flake "$DOTFILES_DIR"
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

echo -e "${BLUE}=== Dotfiles Update Complete! ===${NC}"
echo -e "Note: If nix 'flake.lock' was modified, please commit and push it to your repository."
