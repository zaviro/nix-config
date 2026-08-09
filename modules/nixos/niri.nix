{ pkgs, ... }:

{
  programs.niri.enable = true;

  programs.dms-shell = {
    enable = true;
    systemd.enable = false;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    xwayland-satellite
  ];
}
