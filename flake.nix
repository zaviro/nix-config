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

    # atlas 的文件系统与 swap 继续由安装时验证过的 Disko 声明提供。
    disko = {
      url = "github:nix-community/disko/ff8702b4de27f72b4c78573dfb89ec74e36abdf1";
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

    # 平台模块与 Codex 包独立锁定，变更时需要与主机一起验证。
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/eaeb18da90024448a60eb1ec7132eafa4003404e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix/fcd7079ff30bc4774cc2db48bcc568a42098e9b0";
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
            nixvim
            ;
        };
        modules = [ ./hosts/legion-wsl ];
      };

      nixosConfigurations.atlas = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit
            codexPackage
            disko
            home-manager
            nixvim
            ;

          diskDevice = "/dev/disk/by-id/nvme-eui.0000000000000000a428b700fe430003";
          swapSize = "64G";
        };
        modules = [ ./hosts/atlas ];
      };
    };
}
