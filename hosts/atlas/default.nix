{
  codexPackage,
  disko,
  home-manager,
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
    ./mihomo.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit nixvim; };

    users.zaviro = {
      imports = [ ../../home/zaviro ];

      # Codex 只在实际开发主机上安装，避免扩大 Ubuntu 的共享闭包。
      home.packages = [ codexPackage ];
    };
  };

  networking = {
    hostName = "atlas";
    networkmanager.enable = true;
  };

  boot.loader = {
    timeout = 3;
    efi.canTouchEfiVariables = true;

    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";

    # 当前 TTY 不使用输入法；未来图形会话通过 XDG autostart 启动 Fcitx5。
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = [ pkgs.qt6Packages.fcitx5-chinese-addons ];
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

  environment.systemPackages = with pkgs; [
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
