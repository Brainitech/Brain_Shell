{
  description = "Brain Shell - Modular session shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core runtime
            quickshell
            hyprland
            qt6.full
            qt6ct
            
            # System tools
            pipewire
            pipewire-pulse
            wireplumber
            networkmanager
            bluez
            bluez-utils
            brightnessctl
            upower
            libnotify
            polkit
            python3
            wl-clipboard
            slurp
            xdg-user-dirs
            
            # Screen recording
            wf-recorder
            cava
            
            # Wallpaper & theming
            imagemagick
            awww
            matugen
            
            # Clipboard
            wtype
            
            # Power & hardware
            lm_sensors
            rfkill
            envycontrol
            auto-cpufreq
            nbfc
            
            # Hyprland ecosystem
            hyprsunset
            hyprlock
            hypridle
            xdg-desktop-portal-hyprland
            
            # Fonts
            nerd-fonts.jetbrains-mono
            
            # Optional but recommended
            cliphist
            hyprshutdown
            
            # Development tools
            git
          ];

          shellHook = ''
            export QT_QPA_PLATFORMTHEME=qt6ct
          '';
        };

        devShells.default = self.packages.default;
      }
    );
}
