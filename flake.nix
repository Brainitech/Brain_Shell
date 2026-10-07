{
  description = "Brain Shell - Modular session shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      getBrainShellDeps = pkgs: with pkgs; [
        quickshell
        hyprland
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwayland
        qt6Packages.qt6ct
        pipewire
        wireplumber
        pulseaudio
        networkmanager
        bluez
        brightnessctl
        upower
        libnotify
        polkit
        python3
        wl-clipboard
        slurp
        grim
        grimblast
        xdg-user-dirs
        xdg-utils
        wtype
        imagemagick
        wf-recorder
        cava
        playerctl
        mpv
        awww
        matugen
        lm_sensors
        hyprlock
        hypridle
        hyprsunset
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        cliphist
        git
        hyprpolkitagent
        kitty
        qt6.qtmultimedia
        qt6.qt5compat
        util-linux
        mpvScripts.mpris
        mpd-mpris
        ranger
        coreutils
        findutils
        gawk
        gnused
        iproute2
        iputils
        procps
      ];
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        brainShellDeps = getBrainShellDeps pkgs;
        brainShellPkg = pkgs.stdenv.mkDerivation {
          pname = "brain-shell";
          version = "0.2.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/share/brain-shell
            cp -r $src/src $src/shell.qml $out/share/brain-shell/
            chmod +x $out/share/brain-shell/src/scripts/*.sh 2>/dev/null || true

            mkdir -p $out/bin
            cat > $out/bin/.brain-shell-unwrapped <<'EOF'
#!/bin/sh
if [ -z "$BRAIN_SHELL_CONFIG_DIR" ]; then
    export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"
fi

if [ "$1" = "ipc" ]; then
    shift
    exec quickshell ipc -p "@out@/share/brain-shell" "$@"
else
    if [ -x "@out@/share/brain-shell/src/scripts/init_user_dir.sh" ]; then
        "@out@/share/brain-shell/src/scripts/init_user_dir.sh" || true
    fi
    exec quickshell -p "@out@/share/brain-shell" "$@"
fi
EOF
            substituteInPlace $out/bin/.brain-shell-unwrapped --replace-fail "@out@" "$out"
            chmod +x $out/bin/.brain-shell-unwrapped

            makeWrapper $out/bin/.brain-shell-unwrapped $out/bin/brain-shell \
              --prefix PATH : "${pkgs.lib.makeBinPath brainShellDeps}" \
              --set BRAIN_SHELL_INSTALL_DIR "$out/share/brain-shell" \
              --run '[ -z "$BRAIN_SHELL_CONFIG_DIR" ] && export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"' \
              --set BRAIN_SHELL_NIX "1"
          '';
        };
        defaultApp = {
          type = "app";
          program = "${brainShellPkg}/bin/brain-shell";
        };
      in {
        packages.default = brainShellPkg;
        packages.brain-shell = brainShellPkg;

        apps.default = defaultApp;
        apps.brain-shell = defaultApp;

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
          brainShellDeps = getBrainShellDeps pkgs;
        in {
          options.programs.brain-shell = {
            enable = mkEnableOption "Brain Shell session";
          };

          config = mkIf cfg.enable {
            environment.systemPackages = brainShellDeps ++ [ self.packages.${pkgs.system}.default pkgs.pulseaudio ];

            programs.hyprland.enable = mkDefault true;

            fonts.packages = with pkgs; [
              nerd-fonts.jetbrains-mono
              nerd-fonts.symbols-only
            ];

            environment.variables.QT_QPA_PLATFORMTHEME = "qt6ct";

            services.pipewire = {
              enable = mkDefault true;
              alsa.enable = mkDefault true;
              pulse.enable = mkDefault true;
            };
            services.blueman.enable = mkDefault true;
            services.upower.enable = mkDefault true;

            xdg.portal = {
              enable = mkDefault true;
              extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
            };
          };
        };

      homeManagerModules = rec {
        default = { config, pkgs, lib, ... }:
          let
            cfg = config.programs.brain-shell;
          in {
            options.programs.brain-shell = {
              enable = lib.mkEnableOption "Brain Shell UI";

              package = lib.mkOption {
                type = lib.types.package;
                default = self.packages.${pkgs.system}.brain-shell;
                defaultText = lib.literalExpression "self.packages.\${pkgs.system}.brain-shell";
                description = "The Brain Shell package to install.";
              };

              extraPackages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                example = lib.literalExpression "[ pkgs.envycontrol pkgs.gpu-screen-recorder ]";
                description = "Additional packages to add to the user environment alongside Brain Shell.";
              };

              hyprland = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether to automatically add Brain Shell to Hyprland autostart (exec_once).";
                };

                configType = lib.mkOption {
                  type = lib.types.enum [ "hyprlang" "lua" ];
                  default = "lua";
                  description ="Hyprland configuration format in use.";
                };
              };
            };

            # Note on mutable state and Home Manager boundary:
            # Brain Shell initializes and manages its runtime state dynamically at
            # ~/.config/Brain_Shell (e.g., shell_prefs.json, wallpaper.json, tasks.json,
            # colors.json, and keybinds.json) via init_user_dir.sh and Quickshell.
            # These files MUST remain mutable and are NOT managed via home.file or
            # xdg.configFile to avoid breaking runtime persistence and the in-shell settings editor.
            #
            # Hyprland config injection:
            # When Home Manager manages Hyprland (wayland.windowManager.hyprland.enable = true),
            # this module injects the Brain Shell autostart/rules/keybinds via extraConfig using
            # the format specified by programs.brain-shell.hyprland.configType.
            # When hyprland.enable = false (user manages Hyprland manually), Brain Shell's
            # init_user_dir.sh automatically injects the source line on first launch instead.
            config = lib.mkIf cfg.enable (
             let
                hmHyprlandEnabled = config.wayland.windowManager.hyprland.enable or false;
                isLua = cfg.hyprland.configType == "lua";
                
               brainShellExtraConfig = if isLua then
                  "-- >>> Brain Shell Autostart & Integration >>>\nlocal bs = os.getenv(\"HOME\") .. \"/.config/Brain_Shell/BrainShell-hyprland.lua\"\nlocal f = io.open(bs, \"r\")\nif f then f:close(); dofile(bs) end\n-- <<< Brain Shell Autostart & Integration <<<"
                else
                  "# >>> Brain Shell Autostart & Integration >>>\nsource = ~/.config/Brain_Shell/BrainShell-hyprland.conf\n# <<< Brain Shell Autostart & Integration <<<"; 
              in {
                home.packages = [ cfg.package ] ++ cfg.extraPackages;

                home.sessionVariables.BRAIN_SHELL_CONFIG_TYPE = cfg.hyprland.configType;

                wayland.windowManager.hyprland = lib.mkIf (cfg.hyprland.enable && hmHyprlandEnabled) {
                  extraConfig = brainShellExtraConfig;
                };
              }
            );
          };

        brain-shell = default;
      };
    };
}