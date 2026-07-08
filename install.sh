#!/bin/bash
set -e

# ==============================================================================
# Dotfiles Bootstrap Script (install.sh)
#
# このスクリプトは、新しいマシンで最初に一度だけ実行するセットアップ用スクリプトです。
# macOS、Linux、および WSL (Windows Subsystem for Linux) に対応しています。
#
# 主な処理の流れ:
# 1. OSの判定 (macOS / Linux / WSL)
# 2. Nix パッケージマネージャのインストール (未インストールの場合のみ)
# 3. macOS の場合は Homebrew のインストール (nix-darwin のため)
# 4. Nix Flakes を使ったシステム・パッケージ構成の適用 (nix-darwin または home-manager)
# 5. WSL環境の場合、Windows側の OpenSSH Agent (Windows Hello対応) と連携するための
#    npiperelay.exe を自動ダウンロード・配置
# 6. chezmoi の初期化とローカル設定（dotfiles）の展開
# 7. Gitフック管理ツール (Lefthook) の初期設定
# 8. デフォルトシェルを zsh に変更
#
# 前提条件:
# - git がインストールされていること
# - インターネット接続があること
# ==============================================================================

# Parse arguments
DOTFILES_OS_USER="${USER:-}"
DOTFILES_GIT_USER=""
DOTFILES_GIT_EMAIL=""
# NOTE: To prevent secret leakage via process arguments (ps), DOTFILES_GITHUB_TOKEN
# must be set via environment variable or interactive prompt, NOT command line flags.
DOTFILES_GITHUB_TOKEN="${DOTFILES_GITHUB_TOKEN:-}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --os-user) DOTFILES_OS_USER="$2"; shift 2 ;;
        --git-user) DOTFILES_GIT_USER="$2"; shift 2 ;;
        --git-email) DOTFILES_GIT_EMAIL="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --os-user <username>       Set OS username (default: \$USER)"
            echo "  --git-user <username>      Set Git username"
            echo "  --git-email <email>        Set Git email address"
            echo "  -h, --help                 Show this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Prompt for missing variables
if [ -z "$DOTFILES_OS_USER" ]; then
    read -p "Enter your OS username [${USER}]: " input
    DOTFILES_OS_USER="${input:-${USER}}"
fi
if [ -z "$DOTFILES_GIT_USER" ]; then
    read -p "Enter your Git username: " DOTFILES_GIT_USER
fi
if [ -z "$DOTFILES_GIT_EMAIL" ]; then
    read -p "Enter your Git email address: " DOTFILES_GIT_EMAIL
fi
if [ -z "$DOTFILES_GITHUB_TOKEN" ]; then
    read -s -p "Enter your GitHub Personal Access Token (for this machine only): " DOTFILES_GITHUB_TOKEN
    echo ""
fi

# 1. OS & WSL Detection
OS="$(uname -s)"
case "${OS}" in
    Darwin*)  OS_TYPE="darwin" ;;
    Linux*)   OS_TYPE="linux" ;;
    *)        echo "Unsupported OS: ${OS}"; exit 1 ;;
esac

IS_WSL=false
if [ "${OS_TYPE}" = "linux" ] && grep -q -i "microsoft" /proc/version; then
    IS_WSL=true
fi

echo "Detected OS: ${OS_TYPE} (WSL: ${IS_WSL})"

# 2. Nix Installation (if missing)
if ! command -v nix >/dev/null 2>&1; then
    echo "Nix not found. Installing Nix via Determinate Systems installer..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
fi

# 2.5. Homebrew Installation (macOS only, required by nix-darwin homebrew module)
if [ "${OS_TYPE}" = "darwin" ] && ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3. Apply Nix (nix-darwin for macOS / home-manager for Linux)
echo "Configuring flake.nix for user: ${DOTFILES_OS_USER}..."
sed -e "s/user = \"[^\"]*\"/user = \"${DOTFILES_OS_USER}\"/g" flake.nix > flake.nix.tmp && mv flake.nix.tmp flake.nix

echo "Applying Nix configurations..."
if [ "${OS_TYPE}" = "darwin" ]; then
    nix run github:LnL7/nix-darwin -- switch --flake .#darwin
else
    nix run github:nix-community/home-manager -- switch --flake .#linux
fi

# 4. Automate npiperelay.exe setup for WSL
if [ "${IS_WSL}" = "true" ]; then
    WIN_USER_PROFILE_WINPATH=$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
    WIN_USER_PROFILE_WSLPATH=$(wslpath "$WIN_USER_PROFILE_WINPATH" 2>/dev/null)
    WIN_BIN_DIR="${WIN_USER_PROFILE_WSLPATH}/bin"
    
    if [ ! -f "${WIN_BIN_DIR}/npiperelay.exe" ]; then
        echo "npiperelay.exe not found on Windows host. Downloading..."
        mkdir -p "${WIN_BIN_DIR}"
        TEMP_DIR=$(mktemp -d)
        
        # Download and extract npiperelay
        curl -sSfL "https://github.com/jstarks/npiperelay/releases/latest/download/npiperelay_windows_amd64.zip" -o "${TEMP_DIR}/npiperelay.zip"
        unzip -q "${TEMP_DIR}/npiperelay.zip" -d "${TEMP_DIR}"
        mv "${TEMP_DIR}/npiperelay.exe" "${WIN_BIN_DIR}/"
        rm -rf "${TEMP_DIR}"
        echo "npiperelay.exe successfully placed in ${WIN_BIN_DIR}"
    fi
fi

# 5. Initialize and apply chezmoi
echo "Initializing and applying chezmoi dotfiles..."
CHEZMOI_ARGS=("--source=$(pwd)")
if [ -n "$DOTFILES_GIT_USER" ]; then
    CHEZMOI_ARGS+=("--promptString" "user=${DOTFILES_GIT_USER}")
fi
if [ -n "$DOTFILES_GIT_EMAIL" ]; then
    CHEZMOI_ARGS+=("--promptString" "email=${DOTFILES_GIT_EMAIL}")
fi
if [ -n "$DOTFILES_GITHUB_TOKEN" ]; then
    export DOTFILES_GITHUB_TOKEN
fi

chezmoi init "${CHEZMOI_ARGS[@]}"
chezmoi apply

# 5.5. Initialize Lefthook in the repository
if command -v lefthook >/dev/null 2>&1; then
    echo "Initializing Lefthook git hooks..."
    lefthook install
fi

# 6. Change shell to zsh (if necessary)
ZSH_PATH=$(command -v zsh)
if [ "${SHELL}" != "${ZSH_PATH}" ] && [ -n "${ZSH_PATH}" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "${ZSH_PATH}"
fi

echo "🎉 Dotfiles setup completed successfully! Please restart your terminal."
