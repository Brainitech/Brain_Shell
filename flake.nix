{
  description = "Brain Shell — Modular Quickshell/QML desktop shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # ── Runtime dependencies (required at launch) ──────────────────────
        runtimeDeps = with pkgs; [
          # Core shell runtime
          quickshell
          hyprland
          qt6.full
          qt6ct

          # Audio
          pipewire
          pipewire-pulse
          wireplumber
          playerctl
          mpv-mpris
          mpd-mpris

          # Network / Bluetooth
          networkmanager
          bluez
          bluez-utils

          # Display / input utilities
          brightnessctl
          wl-clipboard
          slurp
          xdg-user-dirs
          xdg-desktop-portal-hyprland

          # System info
          upower
          libnotify
          polkit
          lm_sensors
          rfkill

          # Media & visualiser
          cava
          python3

          # Screen recording
          wf-recorder

          # Wallpaper & theming
          imagemagick
          awww
          matugen

          # Clipboard integration
          wtype
          cliphist

          # Power & hardware management
          envycontrol
          auto-cpufreq

          # Hyprland ecosystem
          hyprsunset
          hyprlock
          hypridle
        ];

        # ── Development extras (not needed at runtime) ─────────────────────
        devDeps = with pkgs; [
          git
          bash
          shellcheck
          python3Packages.python-lsp-server
        ];

        # ── Fonts ──────────────────────────────────────────────────────────
        fonts = with pkgs; [
          (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        ];

        # ── The Brain Shell package ────────────────────────────────────────
        brain-shell = pkgs.stdenv.mkDerivation {
          pname = "brain-shell";
          version = "0.1.0";

          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = runtimeDeps ++ fonts;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/brain-shell
            cp -r . $out/share/brain-shell/

            mkdir -p $out/bin
            makeWrapper ${pkgs.quickshell}/bin/quickshell $out/bin/brain-shell \
              --add-flags "-c $out/share/brain-shell" \
              --set  QT_QPA_PLATFORMTHEME qt6ct \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "A modular Quickshell/QML desktop shell for Hyprland";
            homepage = "https://github.com/Brainitech/Brain_Shell";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "brain-shell";
          };
        };

      in
      {
        # ── Packages ───────────────────────────────────────────────────────
        packages = {
          default = brain-shell;
          brain-shell = brain-shell;
        };

        # ── Dev shell (nix develop) ────────────────────────────────────────
        devShells.default = pkgs.mkShell {
          name = "brain-shell-dev";

          buildInputs = runtimeDeps ++ devDeps ++ fonts;

          shellHook = ''
            export QT_QPA_PLATFORMTHEME=qt6ct
            export BRAIN_SHELL_ROOT="$(pwd)"

            echo ""
            echo "  Brain Shell dev environment"
            echo "  Run:  quickshell -c \$BRAIN_SHELL_ROOT"
            echo "  Lint: shellcheck install.sh dots-extra/install-arch.sh"
            echo ""
          '';
        };

        # ── NixOS module ───────────────────────────────────────────────────
        nixosModules.default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            cfg = config.programs.brain-shell;
          in
          {
            options.programs.brain-shell = {
              enable = lib.mkEnableOption "Brain Shell desktop shell";

              autostart = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Add brain-shell to Hyprland exec-once.";
              };
            };

            config = lib.mkIf cfg.enable {
              environment.systemPackages = [ brain-shell ];

              # This can't even be configured this way, so just tell the user to manually add it to their config or something.

              # wayland.windowManager.hyprland.settings = lib.mkIf cfg.autostart {
              #   exec-once = [
              #     "brain-shell"
              #     "hypridle"
              #     "awww-daemon"
              #     "systemctl --user start hyprpolkitagent"
              #     "wl-paste --type text  --watch cliphist store"
              #     "wl-paste --type image --watch cliphist store"
              #   ];
              # };
            };
          };

        # ── Checks (run by `nix flake check`) ─────────────────────────────
        checks = {
          build = brain-shell;
        };
      }
    );
}
