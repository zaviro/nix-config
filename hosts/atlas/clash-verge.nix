{ ... }:

{
  networking = {
    nameservers = [
      "223.5.5.5"
      "119.29.29.29"
    ];
    networkmanager.dns = "none";
  };

  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };
}
