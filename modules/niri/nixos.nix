{ pkgs, ... }:

{
  programs.niri.enable = true;

  programs.noctalia = {
    enable = true;
    systemd.enable = false;
    recommendedServices.enable = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    playerctl
    xwayland-satellite
  ];
}
