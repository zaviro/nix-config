{
  description = "Multi-host Nix configuration of zaviro";

  inputs = {
    # 两台主机与仓库 formatter 统一使用根软件集；具体版本由 flake.lock 固定。
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Disko 跟随 latest 分支，nixpkgs 与主软件集保持一致。
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager 与主软件集保持一致。
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixvim 使用上游锁定并测试的 nixpkgs revision。
    nixvim.url = "github:nix-community/nixvim/main";

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
      chatgptPackage = llm-agents.packages.${system}.chatgpt;

    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

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
            chatgptPackage
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
