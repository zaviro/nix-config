{ config, ... }:

{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GDM greeter 不会继承守护进程的 XDG_DATA_DIRS，显式注入桌面会话目录。
  environment.etc."gdm/env.d/00-session-dirs.env".text = ''
    XDG_DATA_DIRS=${config.services.displayManager.sessionData.desktops}/share:$XDG_DATA_DIRS
  '';
}
