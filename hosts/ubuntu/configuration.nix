# NixOS system configuration for the Ubuntu host.
#
# This file is the entry point for nixosConfigurations."ubuntu" in flake.nix.
# It is currently a placeholder — you can `nixos-rebuild` from this when ready.
#
# TODO: Generate hardware-configuration.nix with `nixos-generate-config --show-hardware-config`
#       and place it next to this file.

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    # ./hardware-configuration.nix
  ];

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Use our custom overlays.
  nixpkgs.overlays = [
    inputs.self.overlays.additions
    inputs.self.overlays.modifications
    inputs.self.overlays.unstable-packages
  ];

  # Enable experimental Nix features.
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Disable global flake registry and channels.
    registry = lib.mkForce { };
    nixPath = lib.mkForce [ ];
  };

  # TODO: Set your hostname.
  networking.hostName = "ubuntu";

  # TODO: Configure your user account.
  # users.users.zaviro = {
  #   isNormalUser = true;
  #   initialPassword = "changeme";
  #   extraGroups = [ "wheel" ];
  # };

  # Enable OpenSSH with key-only authentication.
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     PermitRootLogin = "no";
  #     PasswordAuthentication = false;
  #   };
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}
