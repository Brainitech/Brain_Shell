{
  description = "Brain Shell - Modular session shell for Hyprland";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # Brain Shell only targets Linux (Wayland/Hyprland requirement).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Single pkgs instance per system (no repeated imports).
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        rec {
          brain-shell = pkgs.callPackage ./nix/package.nix {
            runtimeDeps = import ./nix/deps.nix pkgs;
          };
          default = brain-shell;
        }
      );

      apps = forAllSystems (
        { system, ... }:
        let
          app = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/brain-shell";
          };
        in
        {
          default = app;
          brain-shell = app;
        }
      );

      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.mkShell {
            packages = (import ./nix/deps.nix pkgs) ++ [
              pkgs.nixfmt-rfc-style
            ];
            shellHook = ''
              export QT_QPA_PLATFORMTHEME=qt6ct
              export BRAIN_SHELL_CONFIG_DIR="$HOME/.config/Brain_Shell"
            '';
          };
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt-rfc-style);

      overlays.default = final: _prev: {
        brain-shell = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      nixosModules.default = import ./nix/modules/nixos.nix self;
      homeManagerModules = {
        default = import ./nix/modules/home-manager.nix self;
        brain-shell = import ./nix/modules/home-manager.nix self;
      };
    };
}
