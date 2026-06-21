{ pkgs, ... }: {
  # nix-darwin system configuration for macOS

  # Dock
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    tilesize = 48;
    orientation = "bottom";
    mru-spaces = false;
  };

  # Finder
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    ShowPathbar = true;
    FXEnableExtensionChangeWarning = false;
    _FXShowPosixPathInTitle = true;
  };

  # Global defaults (Keyboard, Mouse, etc.)
  system.defaults.NSGlobalDomain = {
    KeyRepeat = 2;
    InitialKeyRepeat = 15;
    AppleShowAllExtensions = true;
    "com.apple.swipescrolldirection" = false; # Disable natural scroll (for mouse)
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Homebrew Casks (for GUI Apps)
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    taps = [
      "manaflow-ai/cmux"
    ];
    casks = [
      "keepassxc"
      "manaflow-ai/cmux/cmux"
      "raycast"
      "arc"
    ];
  };

  # Fonts
  fonts.packages = with pkgs; [
    udev-gothic-nf
  ];

  system.stateVersion = 4;
}
