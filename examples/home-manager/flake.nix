/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

{
  description = "Minimal Home Manager configuration example with Brain Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brain-shell.url = "github:brainitech/Brain_Shell";
  };

  outputs = { self, nixpkgs, home-manager, brain-shell, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."myuser" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          brain-shell.homeManagerModules.default
          {
            home.username = "myuser";
            home.homeDirectory = "/home/myuser";
            home.stateVersion = "24.11";

            # Enable Brain Shell UI in user profile and autostart in Hyprland
            programs.brain-shell = {
              enable = true;
              # hyprland.enable = true; # default: true (adds brain-shell to exec-once)
              # extraPackages = [ pkgs.envycontrol ]; # optional extras
            };

            # Enable Hyprland in Home Manager (optional, if managed via HM)
            wayland.windowManager.hyprland.enable = true;
          }
        ];
      };
    };
}
