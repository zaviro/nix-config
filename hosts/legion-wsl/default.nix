{
  home-manager,
  nixos-wsl,
  ...
}:

{
  imports = [
    nixos-wsl.nixosModules.default
    home-manager.nixosModules.home-manager
    ../../modules/nixos/bundles/maintenance.nix
    ../../modules/nixos/tailscale.nix
    ./home.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";

  networking.hostName = "legion-wsl";
  services.nix-generation-cleanup.keepGenerations = 5;
  wsl = {
    enable = true;
    defaultUser = "zaviro";
  };
  system.stateVersion = "26.05";
}
