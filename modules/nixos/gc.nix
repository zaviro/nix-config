{
  config,
  lib,
  ...
}:

let
  cfg = config.services.nix-generation-cleanup;
in
{
  options.services.nix-generation-cleanup.keepGenerations = lib.mkOption {
    type = lib.types.nullOr lib.types.ints.positive;
    default = null;
    description = "Number of latest NixOS system generations to retain.";
  };

  config = lib.mkIf (cfg.keepGenerations != null) {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      persistent = false;
    };

    # 在原生 GC 前裁剪系统代际；GC 本身只回收不再被引用的 Store 内容。
    systemd.services.nix-gc = {
      preStart = ''
        ${lib.getExe' config.nix.package "nix-env"} \
          --profile /nix/var/nix/profiles/system \
          --delete-generations +${toString cfg.keepGenerations}
      '';

      serviceConfig = {
        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
      };
    };
  };
}
