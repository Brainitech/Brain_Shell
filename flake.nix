{
  description = "Brain Shell - Modular session shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Brain Shell only targets Linux (Wayland/Hyprland requirement).
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];

      forLinuxSystems = f: nixpkgs.lib.genAttrs linuxSystems (system:
        f system (import nixpkgs { inherit system; })
      );

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
    {
      packages = forLinuxSystems (system: pkgs:
        let
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
#!/usr/bin/env bash
if [ -z "$BRAIN_SHELL_CONFIG_DIR" ]; then
    export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"
fi

if [ "$1" = "ipc" ]; then
    shift
    exec quickshell ipc -p "@out@/share/brain-shell" "$@"
fi

if [ -x "@out@/share/brain-shell/src/scripts/init_user_dir.sh" ]; then
    "@out@/share/brain-shell/src/scripts/init_user_dir.sh" || true
fi

# Ensure daemons are killed when shell exits.
cleanup() {
    kill $(jobs -p) 2>/dev/null
}
trap cleanup EXIT

# Start session daemons.
''${BRAIN_SHELL_WALLPAPER_DAEMON:-awww-daemon} &
hypridle &
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

if [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]]; then
    if systemctl --user list-unit-files hyprpolkitagent.service >/dev/null 2>&1; then
        systemctl --user start hyprpolkitagent
    elif command -v hyprpolkitagent >/dev/null 2>&1; then
        hyprpolkitagent &
    fi
fi

quickshell -p "@out@/share/brain-shell" "$@"
EOF
              substituteInPlace $out/bin/.brain-shell-unwrapped --replace-fail "@out@" "$out"
              chmod +x $out/bin/.brain-shell-unwrapped

              makeWrapper $out/bin/.brain-shell-unwrapped $out/bin/brain-shell \
                --prefix PATH : "${pkgs.lib.makeBinPath brainShellDeps}" \
                --set BRAIN_SHELL_INSTALL_DIR "$out/share/brain-shell" \
                --run '[ -z "$BRAIN_SHELL_CONFIG_DIR" ] && export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"' \
                --set BRAIN_SHELL_NIX "1"
            '';

            meta = with pkgs.lib; {
              description = "Modular session shell for Hyprland built with Quickshell";
              homepage = "https://github.com/BrainTech/Brain_Shell";
              license = licenses.agpl3Plus;
              platforms = platforms.linux;
              mainProgram = "brain-shell";
            };
          };
        in {
          default = brainShellPkg;
          brain-shell = brainShellPkg;
        }
      );

      apps = forLinuxSystems (system: pkgs:
        let
          brainShellPkg = self.packages.${system}.brain-shell;
          defaultApp = {
            type = "app";
            program = "${brainShellPkg}/bin/brain-shell";
          };
        in {
          default = defaultApp;
          brain-shell = defaultApp;
        }
      );

      devShells = forLinuxSystems (system: pkgs:
        let
          brainShellDeps = getBrainShellDeps pkgs;
        in {
          default = pkgs.mkShell {
            packages = brainShellDeps ++ (with pkgs; [
              git
              python3
              nixfmt-rfc-style
            ]);
            shellHook = ''
              export QT_QPA_PLATFORMTHEME=qt6ct
              export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"
            '';
          };
        }
      );

      formatter = forLinuxSystems (_system: pkgs: pkgs.nixfmt-rfc-style);

      # Overlay to inject brain-shell into an existing nixpkgs set.
      overlays.default = final: _prev: {
        brain-shell = self.packages.${final.system}.brain-shell;
      };

      # NixOS module — system-level configuration.
      nixosModules.default = { config, pkgs, lib, ... }:
        let
          cfg = config.programs.brain-shell;
          brainShellDeps = getBrainShellDeps pkgs;
        in {
          options.programs.brain-shell = {
            enable = lib.mkEnableOption "Brain Shell session";

            terminal = lib.mkOption {
              type = lib.types.str;
              default = "kitty";
              description = "Terminal emulator used by Brain Shell keybinds.";
            };

            wallpaperDaemon = lib.mkOption {
              type = lib.types.enum [ "awww" "hyprpaper" "swaybg" ];
              default = "awww";
              description = "Wallpaper daemon to use with Brain Shell.";
            };

            autostart = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to add exec-once entries for Brain Shell via Hyprland/home-manager.";
            };
          };

          config = lib.mkIf cfg.enable {
            assertions = [
              {
                assertion = config.programs.hyprland.enable;
                message = "programs.brain-shell requires programs.hyprland.enable = true.";
              }
            ];

            # Install all runtime dependencies and the Brain Shell package itself.
            environment.systemPackages = brainShellDeps
              ++ [ self.packages.${pkgs.system}.default ];

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
        };

      # Home Manager module — user-level configuration.
      homeManagerModules = rec {
        default = { config, pkgs, lib, ... }:
          let
            cfg = config.programs.brain-shell;
            brainShellDeps = getBrainShellDeps pkgs;

            # Hyprland config injected when hyprlandIntegration.enable is true.
            # Layer rules suppress animation flicker on Brain Shell surfaces.
            hyprConfLuaWithoutExecOnce = ''
              -- Brain Shell — Hyprland integration
              -- Auto-generated by the Brain Shell Home Manager module. Do not edit.
              hl.layer_rule({ match = { namespace = "^brain-shell.*" }, no_anim = true })
              hl.layer_rule({ match = { namespace = "selection" }, no_anim = true, ignore_alpha = 1 })

              local kb_path = "${config.home.homeDirectory}/.config/Brain_Shell/Brain_ShellKeybinds.lua"
              local f = io.open(kb_path, "r")
              if f then
                  f:close()
                  dofile(kb_path)
              end
            '';

            execOnceBlockLua = ''
              hl.on("hyprland.start", function()
                  hl.exec_cmd("brain-shell")
              end)
            '';

            hyprConfLua =
              if cfg.systemd.enable
              then hyprConfLuaWithoutExecOnce
              else execOnceBlockLua + "\n" + hyprConfLuaWithoutExecOnce;

            hyprConfConfWithoutExecOnce = ''
              # Brain Shell — Hyprland integration
              # Auto-generated by the Brain Shell Home Manager module. Do not edit.
              layerrule = noanim, ^(brain-shell.*)$
              layerrule = noanim, selection
              layerrule = ignorealpha 1, selection
              source = ${config.home.homeDirectory}/.config/Brain_Shell/Brain_ShellKeybinds.conf
            '';

            execOnceBlockConf = ''
              exec-once = brain-shell
            '';

            hyprConfConf =
              if cfg.systemd.enable
              then hyprConfConfWithoutExecOnce
              else execOnceBlockConf + "\n" + hyprConfConfWithoutExecOnce;
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

              terminal = lib.mkOption {
                type = lib.types.str;
                default = "kitty";
                description = "Terminal emulator to use.";
              };

              wallpaperDaemon = lib.mkOption {
                type = lib.types.enum [ "awww" "hyprpaper" "swaybg" ];
                default = "awww";
                description = "Wallpaper daemon to use with Brain Shell.";
              };

              systemd.enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable Brain Shell as a systemd user service for autostart.";
              };

              hyprlandIntegration = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = ''
                    Inject Brain Shell layer rules and keybind source into
                    <filename>~/.config/hypr/lua.d/brain-shell.lua</filename> or <filename>~/.config/hypr/conf.d/brain-shell.conf</filename>.
                    When <option>systemd.enable</option> is false, an exec-once line
                    is prepended to launch brain-shell and its daemons.
                  '';
                };

                format = lib.mkOption {
                  type = lib.types.enum [ "lua" "conf" ];
                  default = "lua";
                  description = "Format for the injected Hyprland configuration. Hyprland 0.55+ uses Lua. Conf is available as a fallback.";
                };
              };

              installDefaultHyprlandConfig = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether to install the default Hyprland config template via Home Manager.";
              };
            };

            config = lib.mkIf cfg.enable {
              home.packages = [ cfg.package ]
                ++ cfg.extraPackages
                ++ brainShellDeps
                ++ (with pkgs; [
                  nerd-fonts.jetbrains-mono
                  nerd-fonts.symbols-only
                ]);

              home.sessionVariables = {
                BRAIN_SHELL_TERMINAL = cfg.terminal;
                BRAIN_SHELL_WALLPAPER_DAEMON = cfg.wallpaperDaemon;
              };

              # Systemd user service — handles autostart when enabled.
              systemd.user.services.brain-shell = lib.mkIf cfg.systemd.enable {
                Unit = {
                  Description = "Brain Shell session";
                  PartOf = [ "graphical-session.target" ];
                  After = [ "graphical-session.target" ];
                };
                Service = {
                  Type = "exec";
                  ExecStart = "${cfg.package}/bin/brain-shell";
                  Environment = [
                    "QT_QPA_PLATFORMTHEME=qt6ct"
                    "XDG_CURRENT_DESKTOP=Hyprland"
                    "BRAIN_SHELL_TERMINAL=${cfg.terminal}"
                    "BRAIN_SHELL_WALLPAPER_DAEMON=${cfg.wallpaperDaemon}"
                  ];
                  Restart = "on-failure";
                  RestartSec = "5s";
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };

              # Hyprland layer rules and keybind source file.
              xdg.configFile."hypr/lua.d/brain-shell.lua" =
                lib.mkIf (cfg.hyprlandIntegration.enable && cfg.hyprlandIntegration.format == "lua") {
                  text = hyprConfLua;
                };

              xdg.configFile."hypr/conf.d/brain-shell.conf" =
                lib.mkIf (cfg.hyprlandIntegration.enable && cfg.hyprlandIntegration.format == "conf") {
                  text = hyprConfConf;
                };

              # Optional: install the upstream Hyprland config template.
              xdg.configFile."hypr" = lib.mkIf cfg.installDefaultHyprlandConfig {
                source = "${cfg.package}/share/brain-shell/src/config/hypr_template";
                recursive = true;
              };
            };
          };

        brain-shell = default;
      };
    };
}