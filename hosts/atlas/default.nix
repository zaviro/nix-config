{
  disko,
  home-manager,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    ../../modules/nixos/bundles/maintenance.nix
    ../../modules/nixos/bundles/desktop.nix
    ../../modules/nixos/tailscale.nix
    ./access.nix
    ./boot.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./home.nix
    ./storage.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";

  networking = {
    hostName = "atlas";
    networkmanager.enable = true;
  };

  services.nix-generation-cleanup.keepGenerations = 10;
  services.nixos-flake-update = {
    enable = true;
    repo = "/home/zaviro/nix-config";
    user = "zaviro";
    extraTrackedPackages = [
      "linux"
      "systemd"
    ];
  };
  nix.optimise.automatic = true;
  programs.zsh.enable = true;
  programs.steam.enable = true;
  virtualisation.docker.enable = true;

  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "libsciter"
      "obsidian"
      "spotify"
      "steam"
      "steam-unwrapped"
    ];

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };
  time.timeZone = "Asia/Shanghai";
  environment.systemPackages = with pkgs; [
    vim
    wget
    rsync
    pciutils
    usbutils
  ];
  system.stateVersion = "26.05";
}
