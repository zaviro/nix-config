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

    # 迁移期单独固定 WSL 的软件集，避免改变 Ubuntu pin 或回退当前系统。
    nixpkgs-wsl.url = "github:NixOS/nixpkgs/624af665418d3c65d544145b4d34ad696439570e";

    # 平台模块与 Codex 包保持当前 generation 使用的精确版本。
    nixos-wsl.url = "github:nix-community/NixOS-WSL/eaeb18da90024448a60eb1ec7132eafa4003404e";
    llm-agents = {
      url = "github:numtide/llm-agents.nix/fcd7079ff30bc4774cc2db48bcc568a42098e9b0";
      # llm-agents 使用自身锁定的软件集，不强制跟随任一主机的 nixpkgs。
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

      ubuntuHome = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home/zaviro
          ./hosts/ubuntu/home.nix
        ];
        extraSpecialArgs = { inherit nixvim; };
      };
    in
    {
      formatter.${system} = nixfmt-wrapper;

      homeConfigurations = {
        # 保留旧键供现有命令使用，主机限定键用于 Ubuntu 的自动选择。
        zaviro = ubuntuHome;
        "zaviro@ubuntu" = ubuntuHome;
      };
    };
}
