{
  claudeCodePackage,
  codexPackage,
  nixvim,
  ...
}:

{
  home-manager.users.zaviro = {
    imports = [
      nixvim.homeModules.nixvim
      ../../modules/home/bundles/terminal.nix
      ../../modules/home/bundles/desktop.nix
      ../../modules/home/development-tools.nix
      ../../modules/home/clash-verge.nix
    ];

    home = {
      username = "zaviro";
      homeDirectory = "/home/zaviro";
      stateVersion = "26.05";
      packages = [
        claudeCodePackage
        codexPackage
      ];
    };

    programs.home-manager.enable = true;
    programs.nh = {
      enable = true;
      osFlake = "/home/zaviro/nix-config";
    };

  };
}
