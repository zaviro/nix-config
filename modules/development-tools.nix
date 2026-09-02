{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nixfmt
    nixd
    devenv
    uv
    python3
    nodejs_24
    bun
    just
    watchexec
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      git.colocate = true;
      aliases = {
        d = [ "diff" ];
        l = [ "log" ];
        n = [ "new" ];
      };
      user = {
        name = "zaviro";
        email = "1264166738a@gmail.com";
      };
    };
  };
}
