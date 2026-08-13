{ lib, ... }:

{
  services.gammastep = {
    enable = true;
    tray = false;

    dawnTime = "07:00-08:00";
    duskTime = "19:00-20:00";

    settings.general = {
      adjustment-method = "wayland";
      brightness-day = 0.95;
      brightness-night = 0.95;
      temp-night = lib.mkForce 4500;
    };
  };
}
