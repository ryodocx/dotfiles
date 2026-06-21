{ pkgs, user, email, isDarwin, ... }: {
  imports = [
    ./packages.nix
  ];

  home = {
    username = user;
    homeDirectory = if isDarwin then "/Users/${user}" else "/home/${user}";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
