{
  claudeCodePackage,
  chatgptPackage,
  codexPackage,
  nix-index-database,
  nixvim,
  pkgs,
  sops-nix,
  ...
}:

{
  home-manager.users.zaviro = {
    imports = [
      nix-index-database.homeModules.default
      nixvim.homeModules.nixvim
      sops-nix.homeManagerModules.sops
      ../../modules/home/bundles/terminal.nix
      ../../modules/home/bundles/desktop.nix
      ../../modules/home/development-tools.nix
      ../../modules/home/clash-verge.nix
      ../../modules/home/secrets.nix
    ];

    home = {
      username = "zaviro";
      homeDirectory = "/home/zaviro";
      stateVersion = "26.05";
      packages = [
        claudeCodePackage
        chatgptPackage
        codexPackage
      ];
    };

    programs.home-manager.enable = true;
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
    programs.lutris = {
      enable = true;
      extraPackages = [
        pkgs.umu-launcher
        pkgs.winetricks
      ];
      winePackages = [ pkgs.wineWow64Packages.full ];
    };
    programs.nh = {
      enable = true;
      osFlake = "/home/zaviro/nix-config";
    };

  };
}
