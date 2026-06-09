{
  description = "Home Manager configuration of zaviro";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
     
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";  # 官方仓库
      # inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { nixpkgs, home-manager, nixvim, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."zaviro" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ 
          ./home.nix
          nixvim.homeModules.nixvim
        ];

        # Optionally use extraSpecialArgs
        # 传递nixvim给模块，以便配置中引用
        extraSpecialArgs = { inherit nixvim; };
        # to pass through arguments to home.nix
      };
    };
}
