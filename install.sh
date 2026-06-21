#!/bin/bash
set -e

# Cross-platform dotfiles bootstrap script

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
echo "Applying Nix configurations..."
if [ "${OS_TYPE}" = "darwin" ]; then
    nix run github:LnL7/nix-darwin -- switch --flake .#macbook
else
    TARGET_CONFIG="wsl"
    if [ "${IS_WSL}" = "false" ]; then
        TARGET_CONFIG="linux"
    fi
    nix run github:nix-community/home-manager -- switch --flake .#${TARGET_CONFIG}
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
chezmoi init --source="$(pwd)"
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
