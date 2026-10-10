# NixOS module — system-level configuration.
self:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.brain-shell;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.programs.brain-shell = {
    enable = lib.mkEnableOption "Brain Shell session";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${system}.default;
      defaultText = lib.literalExpression "brain-shell.packages.\${system}.default";
      description = "The Brain Shell package to install.";
    };

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "kitty";
      description = "Terminal emulator used by Brain Shell keybinds.";
    };

    wallpaperDaemon = lib.mkOption {
      type = lib.types.enum [
        "awww"
        "hyprpaper"
        "swaybg"
      ];
      default = "awww";
      description = "Wallpaper daemon to use with Brain Shell.";
    };

    # Previously referenced as cfg.hyprlandIntegration.format, which only
    # existed in the Home Manager module and broke NixOS evaluation.
    configFormat = lib.mkOption {
      type = lib.types.enum [
        "lua"
        "conf"
      ];
      default = "lua";
      description = "Hyprland config format Brain Shell should use (Lua for Hyprland 0.55+).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.hyprland.enable;
        message = "programs.brain-shell requires programs.hyprland.enable = true.";
      }
    ];

    environment.systemPackages = (import ../deps.nix pkgs) ++ [ cfg.package ];

    programs.hyprland.enable = lib.mkDefault true;
    security.polkit.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    networking.networkmanager.enable = lib.mkDefault true;

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];

    environment.variables = {
      QT_QPA_PLATFORMTHEME = "qt6ct";
      BRAIN_SHELL_TERMINAL = cfg.terminal;
      BRAIN_SHELL_WALLPAPER_DAEMON = cfg.wallpaperDaemon;
      BRAIN_SHELL_CONFIG_TYPE = cfg.configFormat;
    };

    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };
    services.blueman.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;

    xdg.portal = {
      enable = lib.mkDefault true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
}
