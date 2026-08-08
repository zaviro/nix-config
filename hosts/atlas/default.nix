{
  claudeCodePackage,
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
    ../../modules/nixos/gc.nix
    ../../modules/nixos/tailscale.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./niri.nix
  ];

  services.nix-generation-cleanup.keepGenerations = 10;

  nix.optimise.automatic = true;

  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };

  # 将 Zsh 注册为系统 shell，随后可安全地设为 zaviro 的登录 shell。
  programs.zsh.enable = true;

  programs.steam.enable = true;

  virtualisation.docker.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit nixvim; };

    users.zaviro = {
      imports = [ ../../home/zaviro ];

      # 图形客户端与 Agent 仅在 atlas 安装，避免扩大其他主机闭包。
      home.packages = with pkgs; [
        claudeCodePackage
        codexPackage
        firefox
        obsidian
        readest
        rustdesk
        spotify
        python3
        nodejs_24
        bun
      ];

      programs = {
        # 交互式 shell 由 Home Manager 生成，避免维护可变的 ~/.oh-my-zsh 克隆。
        zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion = {
            enable = true;
            strategy = [ "history" ];
          };
          syntaxHighlighting.enable = true;
          history = {
            ignoreAllDups = true;
            ignoreSpace = true;
            share = true;
          };
          historySubstringSearch.enable = true;
          oh-my-zsh = {
            enable = true;
            # zoxide 使用其 Home Manager 集成，避免与 Oh My Zsh 插件重复初始化。
            plugins = [
              "git"
              "fzf"
            ];
          };
          shellAliases = {
            ll = "ls -lha";
            gs = "git status";
            ga = "git add";
            gc = "git commit";
            cx = "codex";
            oc = "opencode";
            cc = "claude";
            gm = "gemini";
            ot = "openclaw tui";
            hm = "hermes";
            ld = "lazydocker";
            dps = "docker ps";
            dcu = "docker compose up -d";
            dcd = "docker compose down";
            ".." = "cd ..";
            nd = "node";
          };
        };

        # zoxide 已作为共享工具提供；此处只为 atlas 的 Zsh 启用集成。
        zoxide = {
          enable = true;
          enableZshIntegration = true;
        };

        ghostty = {
          enable = true;
          enableZshIntegration = true;
          settings.fullscreen = true;
        };
      };

      # GNOME 的默认终端设置及 XDG 终端 scheme 都指向 Ghostty。
      dconf.settings."org/gnome/desktop/default-applications/terminal" = {
        exec = "ghostty";
        exec-arg = "";
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/terminal" = [ "com.mitchellh.ghostty.desktop" ];
      };

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

  # 仅为实际使用的非自由桌面软件开放求值许可。
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "libsciter"
      "obsidian"
      "spotify"
      "steam"
      "steam-unwrapped"
    ];

  boot.loader = {
    timeout = 3;
    efi.canTouchEfiVariables = true;

    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
  };

  # 让 /var/log 挂载在启动早期可用，保证启动阶段的日志也写入独立子卷。
  fileSystems."/var/log".neededForBoot = true;

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

  # SUBVOLUME 指被快照的子卷路径，Snapper 固定使用其下名为 .snapshots 的子卷。
  # home 保留更多天/周/月，因为用户数据比系统配置更值得长期恢复。
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    # 关机错过计划时间后开机补跑，维持主力机每小时快照节奏。
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

  i18n = {
    defaultLocale = "en_US.UTF-8";

    # GNOME 由系统层选择 Fcitx5 以禁用默认 IBus，用户偏好交给 Home Manager。
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = [ pkgs.fcitx5-rime ];
        # Niri/GNOME 均为原生 Wayland 会话：GTK 走 text-input-v3，不再设置
        # GTK_IM_MODULE（X11 时代的 D-Bus im module 变量），fcitx5-diagnose
        # 已确认 Wayland 前端（input-method-v2）正在生效。
        waylandFrontend = true;
      };
    };
  };

  # waylandFrontend 会同时移除 GTK_IM_MODULE 与 QT_IM_MODULE，但非 KWin 桌面
  # 的 Qt 无法用 text-input-v2/v3（v2 仅 KWin，Qt < 6.7 不支持 v3），必须保留
  # fcitx im module 回退，否则 Qt 应用会丢失输入法。
  environment.variables.QT_IM_MODULE = "fcitx";

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
      shell = pkgs.zsh;
      extraGroups = [
        "docker"
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

  security.sudo.wheelNeedsPassword = false;

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
