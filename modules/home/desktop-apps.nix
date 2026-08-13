{ pkgs, ... }:

{
  home.packages = with pkgs; [
    firefox
    google-chrome
    mpv
    obsidian
    readest
    rustdesk
    spotify
    tauon
    yt-dlp
  ];

  dconf.settings."org/gnome/desktop/default-applications/terminal" = {
    exec = "ghostty";
    exec-arg = "";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications."x-scheme-handler/terminal" = [ "com.mitchellh.ghostty.desktop" ];
  };
}
