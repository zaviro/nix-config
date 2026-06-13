{
  description = "Home Manager configuration of zaviro";

  inputs = {
    # Primary nixpkgs (unstable branch).
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager (master branch, follows primary nixpkgs).
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim — Neovim distribution (follows primary nixpkgs).
    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # 适配 Nix 2.25+ 移除 nix fmt 隐式 . 参数
      # 参考: https://git.dblsaiko.net/lix/diff/doc/manual/rl-next/nix-fmt-default-argument.md
      nixfmt-wrapper = pkgs.writeShellApplication {
        name = "nixfmt";
        runtimeInputs = [ pkgs.nixfmt ];
        text = ''
          if [[ $# = 0 ]]; then set -- .; fi
          exec nixfmt "$@"
        '';
      };
    in
    {
      formatter.${system} = nixfmt-wrapper;
      homeConfigurations."zaviro" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager
          nixvim.homeModules.nixvim
        ];
        extraSpecialArgs = { inherit nixvim; };
      };
    };
}
