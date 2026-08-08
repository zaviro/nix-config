{ pkgs, config, ... }:

let
  # 基于当前 nixpkgs 中 Niri 自带的默认配置，只替换桌面壳相关入口；
  # 其余窗口管理快捷键继续跟随当前锁定的 Niri 版本。
  niriConfig = pkgs.runCommand "niri-config.kdl" { } ''
    install -m 0644 ${pkgs.niri.doc}/share/doc/niri/default-config.kdl "$out"

    substituteInPlace "$out" \
      --replace-fail 'spawn-at-startup "waybar"' 'spawn-at-startup "dms" "run"' \
      --replace-fail 'Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }' 'Mod+T hotkey-overlay-title="Open a Terminal: Ghostty" { spawn "ghostty"; }' \
      --replace-fail 'Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }' 'Mod+D hotkey-overlay-title="Open DMS Launcher" { spawn "dms" "ipc" "spotlight" "toggle"; }' \
      --replace-fail 'Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }' 'Super+Alt+L hotkey-overlay-title="Lock the Screen" { spawn "dms" "ipc" "lock" "lock"; }'

    substituteInPlace "$out" --replace-fail 'binds {' 'binds {
    // DMS desktop-shell shortcuts. Keep Niri defaults for window/layout actions.
    Mod+Space hotkey-overlay-title="Open DMS Launcher" { spawn "dms" "ipc" "spotlight" "toggle"; }
    Mod+N hotkey-overlay-title="Toggle Notification Center" { spawn "dms" "ipc" "notifications" "toggle"; }
    Mod+Shift+Comma hotkey-overlay-title="Toggle DMS Settings" { spawn "dms" "ipc" "settings" "toggle"; }
    Mod+P hotkey-overlay-title="Toggle Notepad" { spawn "dms" "ipc" "notepad" "toggle"; }
    Mod+X hotkey-overlay-title="Toggle Power Menu" { spawn "dms" "ipc" "powermenu" "toggle"; }
    Mod+Alt+V hotkey-overlay-title="Toggle Clipboard Manager" { spawn "dms" "ipc" "clipboard" "toggle"; }
    Mod+Alt+M hotkey-overlay-title="Toggle Process List" { spawn "dms" "ipc" "processlist" "toggle"; }
'
  '';
in
{
  # NixOS 原生模块会将 Niri 会话注册到现有 GDM；GNOME 保持不变。
  programs.niri.enable = true;

  # DMS 只由 Niri 会话启动，避免登录 GNOME 时同时拉起第二套桌面壳。
  programs.dms-shell = {
    enable = true;
    systemd.enable = false;
  };

  # Niri 原生模块不启用内建 XWayland；satellite 在 PATH 中时可自动集成。
  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    xwayland-satellite
  ];

  # GDM greeter 的会话环境由 pam_getenvlist 重建，不继承守护进程的 XDG_DATA_DIRS，
  # 导致其枚举不到 sessionData.desktops 里的会话文件（gnome.desktop 等），
  # 登录界面不显示「选择会话」齿轮。所有桌面模块（GNOME/niri/Hyprland/Cosmic）
  # 都会汇入同一个 desktops 包，此处通过 GDM env.d 注入一次即覆盖全部会话。
  environment.etc."gdm/env.d/00-session-dirs.env".text = ''
    XDG_DATA_DIRS=${config.services.displayManager.sessionData.desktops}/share:$XDG_DATA_DIRS
  '';

  # atlas 的 Niri 配置属于主机专属用户配置，不进入跨主机 home/zaviro。
  home-manager.users.zaviro.xdg.configFile."niri/config.kdl".source = niriConfig;
}
