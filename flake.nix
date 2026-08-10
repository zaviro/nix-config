{
  description = "Multi-host Nix configuration of zaviro";

  # 为本仓库使用 llm-agents 构建产物时建议 Numtide 二进制缓存。
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    # 两台主机与仓库 formatter 统一使用根软件集；具体版本由 flake.lock 固定。
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Disko 跟随默认分支，nixpkgs 与主软件集保持一致。
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager 与主软件集保持一致。
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixvim 与主软件集保持一致。
    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL 平台模块跟随主分支，nixpkgs 与主软件集保持一致。
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Codex 包使用独立锁定的软件集。
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      # llm-agents 使用独立锁定的 nixpkgs unstable，不强制跟随任一主机。
    };
  };

  outputs =
    {
      disko,
      nixpkgs,
      home-manager,
      nixvim,
      nixos-wsl,
      llm-agents,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      claudeCodePackage = llm-agents.packages.${system}.claude-code;
      codexPackage = llm-agents.packages.${system}.codex;

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

      nixosConfigurations."legion-wsl" = nixpkgs.lib.nixosSystem {
        inherit system;
        # 只向 NixOS 模块树暴露实际依赖，避免主机模块耦合完整 inputs。
        specialArgs = {
          inherit
            codexPackage
            home-manager
            nixos-wsl
            ;
        };
        modules = [ ./hosts/legion-wsl ];
      };

      nixosConfigurations.atlas = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            claudeCodePackage
            codexPackage
            disko
            home-manager
            nixvim
            ;
        };
        modules = [ ./hosts/atlas ];
      };
    };
}
