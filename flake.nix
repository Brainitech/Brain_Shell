{
  description = "Brain Shell - Modular session shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "brain-shell";
          src = ./.;
          phases = [ "installPhase" ];
          installPhase = ''
           mkdir -p $out
           cp -r $src/src $src/shell.qml $out/
         '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            python3
          ];
        };
      }
    ) // {
      nixosModules.default = { config, pkgs, lib, ... }:
        with lib;
        let
          cfg = config.programs.brain-shell;
          brainShellDeps = with pkgs; [
            quickshell
            hyprland
            qt6.qtbase
            qt6.qtdeclarative
            qt6.qtwayland
            qt6Packages.qt6ct
            pipewire
            wireplumber
            networkmanager
            bluez
            brightnessctl
            upower
            libnotify
            polkit
            python3
            wl-clipboard
            slurp
            xdg-user-dirs
            wtype
            imagemagick
            wf-recorder
            cava
            playerctl
            awww
            matugen
            lm_sensors
            hyprlock
            hypridle
            hyprsunset
            hyprshutdown
            xdg-desktop-portal-hyprland
            cliphist
            nerd-fonts.jetbrains-mono
            nerd-fonts.symbols-only
            git
          ];
        in {
          options.programs.brain-shell = {
            enable = mkEnableOption "Brain Shell session";
          };

          config = mkIf cfg.enable {
            environment.systemPackages = brainShellDeps ++ [ self.packages.${pkgs.system}.default ];

            fonts.packages = with pkgs; [
              nerd-fonts.jetbrains-mono
              nerd-fonts.symbols-only
            ];

            environment.variables.QT_QPA_PLATFORMTHEME = "qt6ct";

            services.pipewire.enable = true;
            services.blueman.enable = true;
          };
        };
    };
}
