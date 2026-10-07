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
  description = "Minimal NixOS configuration example with Brain Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    brain-shell.url = "github:brainitech/Brain_Shell";
  };

  outputs = { self, nixpkgs, brain-shell, ... }: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        brain-shell.nixosModules.default
        {
          # Enable Brain Shell system-wide
          programs.brain-shell.enable = true;

          # Minimal required system definitions
          boot.loader.systemd-boot.enable = true;
          networking.hostName = "myhostname";
          users.users.myuser = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" "video" ];
          };
          system.stateVersion = "24.11";
        }
      ];
    };
  };
}
