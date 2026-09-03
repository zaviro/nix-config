{ pkgs, ... }:

let
  dataHdd = "/dev/disk/by-id/ata-ST6000DM003-2U9186_ZR1532CA";
in
{
  fileSystems."/var/log".neededForBoot = true;

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/000839b1-7b82-4c8d-8691-c5758e41ab31";
    fsType = "btrfs";
    options = [
      "subvol=@data"
      "compress=zstd:1"
      "nofail"
      "x-systemd.automount"
    ];
  };

  systemd.services.data-hdd-standby = {
    description = "Set the data HDD standby timeout";
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = dataHdd;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.hdparm}/bin/hdparm -S 241 ${dataHdd}";
    };
  };

  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    persistentTimer = true;
    configs = {
      root = {
        SUBVOLUME = "/";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 12;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 3;
        TIMELINE_LIMIT_YEARLY = 0;
      };
      home = {
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 12;
        TIMELINE_LIMIT_DAILY = 14;
        TIMELINE_LIMIT_WEEKLY = 8;
        TIMELINE_LIMIT_MONTHLY = 6;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
  };
}
