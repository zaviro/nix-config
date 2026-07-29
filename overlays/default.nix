# 预留可复用的 nixpkgs overlay；当前尚未接入任何 Flake 输出。
{ inputs, ... }:

{
  # 将 pkgs/ 中的自定义包暴露为普通 nixpkgs 属性。
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # 跨主机共享的版本覆盖、补丁或编译选项统一放在此处。
  modifications = final: prev: {
    # 示例：example = prev.example.overrideAttrs (_oldAttrs: { ... });
  };

  # 当前仍与主 nixpkgs 相同，仅保留未来分离稳定版和 unstable 的结构入口。
  # 引入独立 nixpkgs-unstable input 时，必须同步修改下面的 input 引用。
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
