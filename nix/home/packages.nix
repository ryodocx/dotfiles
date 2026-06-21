{ pkgs, ... }: {
  home.packages = with pkgs; [
    # ── 環境管理 ──
    chezmoi
    git
    age
    socat

    # ── シェル関連・履歴 ──
    starship
    atuin
    sheldon
    zoxide
    fzf

    # ── モダン CLI 代替 ──
    eza
    bat
    fd
    ripgrep
    delta
    dust
    btop
    yazi
    zellij

    # ── 開発環境 ──
    mise
    lazygit
    gitleaks
    lefthook
    shellcheck
    shfmt
    alejandra
  ];
}


