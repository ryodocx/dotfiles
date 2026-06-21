{ pkgs, user, email, isDarwin, isWSL, ... }: {
  imports = [
    ./packages.nix
  ] ++ (if isDarwin then [ ./darwin.nix ] else [ ./linux.nix ]);

  home = {
    username = user;
    homeDirectory = if isDarwin then "/Users/${user}" else "/home/${user}";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
