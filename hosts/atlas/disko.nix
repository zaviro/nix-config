{
  lib,
  ...
}:

let
  diskDevice = "/dev/disk/by-id/nvme-eui.0000000000000000a428b700fe430003";
  swapSize = "64G";
in

{
  assertions = [
    {
      assertion = lib.hasPrefix "/dev/disk/by-id/" diskDevice;
      message = "atlas diskDevice must be a full /dev/disk/by-id/ path";
    }
    {
      assertion = lib.hasPrefix "/dev/disk/by-id/nvme-" diskDevice;
      message = "atlas diskDevice must refer to an NVMe whole-disk by-id";
    }
    {
      assertion = !(lib.hasInfix "-part" diskDevice);
      message = "atlas diskDevice must refer to a whole disk, not a partition";
    }
  ];

  disko.devices.disk.main = {
    type = "disk";
    device = diskDevice;

    content = {
      type = "gpt";

      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        swap = {
          size = swapSize;
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];

            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd:1" ];
              };

              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd:1" ];
              };

              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd:1"
                  "noatime"
                ];
              };

              "@log" = {
                mountpoint = "/var/log";
                mountOptions = [
                  "compress=zstd:1"
                  "noatime"
                ];
              };

              "@snapshots-root" = {
                mountpoint = "/.snapshots";
                mountOptions = [
                  "compress=zstd:1"
                  "noatime"
                ];
              };

              "@snapshots-home" = {
                mountpoint = "/home/.snapshots";
                mountOptions = [
                  "compress=zstd:1"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
