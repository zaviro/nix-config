{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nixfmt
    devenv
    direnv
    uv
    python3
    nodejs_24
    bun
    just
    watchexec
  ];

  programs.jujutsu = {
    enable = true;
    settings = {
      git.colocate = true;
      user = {
        name = "zaviro";
        email = "1264166738a@gmail.com";
      };
    };
  };
}
