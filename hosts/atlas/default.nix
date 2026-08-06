{
  codexPackage,
  disko,
  home-manager,
  lib,
  nixvim,
  pkgs,
  ...
}:

{
  imports = [
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    ../../modules/nixos/common.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];

  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit nixvim; };

    users.zaviro = {
      imports = [ ../../home/zaviro ];

      # Codex 只在实际开发主机上安装，避免扩大 Ubuntu 的共享闭包。
      home.packages = [ codexPackage ];

      # Clash Verge 的全局增强文件位于应用数据目录，其他运行时数据保持可写。
      xdg.dataFile = {
        "io.github.clash-verge-rev.clash-verge-rev/profiles/Merge.yaml".source = ./clash-verge/merge.yaml;
        "io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js".source = ./clash-verge/script.js;
      };

      # 静态配置由 Home Manager 接管，Rime 方案和用户词库仍保留为可写数据。
      xdg.configFile = {
        "fcitx5/profile".text = ''
          [Groups/0]
          Name=默认
          Default Layout=us
          DefaultIM=rime

          [Groups/0/Items/0]
          Name=rime
          Layout=

          [GroupOrder]
          0=默认
        '';

        "fcitx5/config".text = ''
          [Hotkey]
          EnumerateWithTriggerKeys=True
          AltTriggerKeys=
          EnumerateForwardKeys=
          EnumerateBackwardKeys=
          EnumerateSkipFirst=False

          [Hotkey/TriggerKeys]
          0=Zenkaku_Hankaku
          1=Hangul

          [Hotkey/EnumerateGroupForwardKeys]
          0=Super+space

          [Hotkey/EnumerateGroupBackwardKeys]
          0=Shift+Super+space

          [Hotkey/ActivateKeys]
          0=Hangul_Hanja

          [Hotkey/DeactivateKeys]
          0=Hangul_Romaja

          [Hotkey/PrevPage]
          0=Up

          [Hotkey/NextPage]
          0=Down

          [Hotkey/PrevCandidate]
          0=Shift+Tab

          [Hotkey/NextCandidate]
          0=Tab

          [Hotkey/TogglePreedit]
          0=Control+Alt+P

          [Behavior]
          ActiveByDefault=False
          ShareInputState=All
          PreeditEnabledByDefault=True
          ShowInputMethodInformation=True
          showInputMethodInformationWhenFocusIn=False
          CompactInputMethodInformation=True
          ShowFirstInputMethodInformation=True
          DefaultPageSize=5
          OverrideXkbOption=False
          CustomXkbOption=
          EnabledAddons=
          DisabledAddons=
          PreloadInputMethod=True
          AllowInputMethodForPassword=False
          ShowPreeditForPassword=False
          AutoSavePeriod=30
        '';

        "fcitx5/conf/classicui.conf".text = ''
          Vertical Candidate List=False
          WheelForPaging=True
          Font="Sans Serif 15"
          MenuFont="Sans 10"
          TrayFont="Sans Bold 10"
          Theme=default-dark
          DarkTheme=default-dark
          UseDarkTheme=False
          UseAccentColor=True
          EnableFractionalScale=True
        '';

        "fcitx5/conf/notifications.conf".text = ''
          [HiddenNotifications]
          0=fcitx-rime-deploy
          1=wayland-diagnose-gnome
        '';
      };
    };
  };

  networking = {
    hostName = "atlas";
    networkmanager.enable = true;
  };

  # 优先使用国内镜像下载 Nix 构建产物，未命中时回退到官方缓存。
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];

  # Chrome 是非自由软件，只为该包开放求值许可。
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "google-chrome" ];

  boot.loader = {
    timeout = 3;
    efi.canTouchEfiVariables = true;

    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
  };

  # DATA 是 atlas 的常用数据盘；按 UUID 挂载，避免设备名变化导致挂载错盘。
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/000839b1-7b82-4c8d-8691-c5758e41ab31";
    fsType = "btrfs";
    options = [
      "compress=zstd:1"
      "nofail"
      "x-systemd.automount"
    ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  time.timeZone = "Asia/Shanghai";

  services = {
    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";

    # GNOME 由系统层选择 Fcitx5 以禁用默认 IBus，用户偏好交给 Home Manager。
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = [ pkgs.fcitx5-rime ];
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC8qsJvpWm2Ha0KnW5tvT7eIqG2hOa4+gmJgJVXfewP/ wsl-nixos"
    ];

    zaviro = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "render"
        "audio"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC8qsJvpWm2Ha0KnW5tvT7eIqG2hOa4+gmJgJVXfewP/ wsl-nixos"
      ];
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "zaviro" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.systemPackages = with pkgs; [
    google-chrome
    git
    vim
    curl
    wget
    rsync
    pciutils
    usbutils
  ];

  # 该值来自 atlas 首次安装，只约束有状态系统数据的兼容基线。
  system.stateVersion = "26.05";
}
